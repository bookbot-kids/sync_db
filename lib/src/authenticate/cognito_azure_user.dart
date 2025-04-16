import 'dart:async';
import 'dart:math';

import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:flutter/foundation.dart';
import 'package:queue/queue.dart';
import 'package:robust_http/connection_helper.dart';
import 'package:robust_http/exceptions.dart';
import 'package:robust_http/robust_http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sync_db/src/authenticate/cognito_auth_session.dart';
import 'package:sync_db/src/authenticate/cognito_share_pref_storage.dart';
import 'package:sync_db/src/utils/web_service_utils.dart';
import 'package:sync_db/sync_db.dart';
import 'package:synchronized/synchronized.dart';
import 'package:amazon_cognito_identity_dart_2/cognito.dart' as cognito;
import 'package:tuple/tuple.dart';

/// A class that handles the authentication of a user with Cognito.
/// And also handles the refreshing of the authentication token from azure services.
class CognitoAzureUserSession extends UserSession
    implements CognitoAuthSession {
  /// Config will need:
  /// `azureBaseUrl` for Azure authentication functions
  /// `azureKey` the secure code to request azure function
  /// `tablesToClearOnSignout` a list of tables to remove when signing out
  /// `autoRefresh` auto refresh token
  CognitoAzureUserSession(
    Map<String, dynamic> config, {
    bool autoRefresh = true,
    SharedPreferences? sharedPreferences,
  }) {
    _http = HTTP(config['azureBaseUrl'], {
      'httpRetries': 1,
      'connectTimeout': config['connectTimeout'],
      'receiveTimeout': config['receiveTimeout'],
      'proxyUrl': config['proxyUrl'],
    });

    // cognito keys
    _userPool = cognito.CognitoUserPool(
        config['cognitoPoolId'], config['cognitoClientId']);

    // azure keys are used to request azure functions
    _azureKey = config['azureKey'] ?? '';
    _azureSecret = config['azureSecret'] ?? '';
    _azureSubject = config['azureSubject'] ?? '';
    _azureIssuer = config['azureIssuer'] ?? '';
    _azureAudience = config['azureAudience'] ?? '';

    _tablesToSync = config['tablesToSync'] ?? <String>[];
    _tablesToClearOnSignout =
        List<String>.from(config['tablesToClearOnSignout'] ?? []);
    _logDebugCloud = config['logDebugCloud'] ?? false;
    _syncQueue = Queue(parallel: config['parallelTask'] ?? 1);

    final initializeListener = (SharedPreferences? prefs) {
      _userPool.storage = SharedPreferenceStorage(prefs);
      _initializeTask = _initialized();
      // try to load role first
      role = prefs!.getString(_userRoleKey) ?? _defaultRole;
    };

    if (sharedPreferences != null) {
      _sharePref = sharedPreferences;
      initializeListener(sharedPreferences);
    } else {
      _sharePrefInstance.then((prefs) {
        initializeListener(prefs);
      });
    }

    if (autoRefresh) {
      // Start the process of getting tokens
      _refreshed = refresh();
    }
  }

  late HTTP _http;
  String? _azureKey;
  late String _azureSecret;
  String? _azureSubject;
  String? _azureIssuer;
  late String _azureAudience;
  DateTime _tokenExpiry = DateTime.utc(0);
  Future<void>? _refreshed;
  late List<String> _tablesToClearOnSignout;
  Notifier signoutNotifier = Notifier(Object());
  static const _defaultRole = 'guest';
  static const _storageUriKey = 'storageUriKey';
  static const _userRoleKey = 'userRoleKey';
  SharedPreferences? _sharePref;
  final _lock = Lock();
  cognito.CognitoUser? _cognitoUser;
  cognito.CognitoUserSession? _session;
  late cognito.CognitoUserPool _userPool;
  Future? _initializeTask;
  var _tablesToSync = <String>[];
  var _logDebugCloud = false;
  late Queue _syncQueue;

  @override
  String? role = _defaultRole;

  @override
  Future<void> deleteUser(String email) async {
    var refreshToken = await token;
    var clientToken = WebServiceUtils.generateClientToken(
        _azureSecret,
        _azureSubject,
        _azureIssuer,
        _azureAudience,
        await NetworkTime.shared.now,
        jwtId: Random().nextInt(10000).toString());
    if (!await ConnectionHelper.shared.hasConnection()) {
      throw ConnectivityException('The connection is turn off',
          hasConnectionStatus: false);
    }
    if (!await ConnectionHelper.shared.hasInternetConnection()) {
      throw ConnectivityException(
          'The connection is turn on but there is no internet connection',
          hasConnectionStatus: true);
    }
    final response = await _http.post('/DeleteUser',
        parameters: {
          'email': email,
          'refresh_token': refreshToken ?? '',
          'client_token': clientToken,
          'code': _azureKey,
          'source': 'cognito'
        },
        includeHttpResponse: true);
    if (response.data == null || response.data['success'] != true) {
      throw Exception('Delete account failed, statusCode: '
          '${response.statusCode}, message: ${response.statusMessage}');
    }
  }

  @override
  Future<bool> hasSignedIn() async {
    if (_initializeTask != null) {
      await _initializeTask;
    }

    return await _checkAuthenticated();
  }

  @override
  Future<void> refresh({bool forceRefreshToken = false, String? userId}) async {
    if (_logDebugCloud) {
      Sync.shared.logger?.f('[sync_db][DEBUG] refresh start');
    }

    if (_initializeTask != null) {
      await _initializeTask;
    }

    if (_logDebugCloud) {
      Sync.shared.logger?.f('[sync_db][DEBUG] refresh initialized');
    }

    // Start some tasks to await later
    final asyncTimeStamp = NetworkTime.shared.now;
    final asyncMapped = _mappedServicePoints();

    if (_logDebugCloud) {
      Sync.shared.logger?.f('[sync_db][DEBUG] refresh start token');
    }
    final prefs = await _sharePrefInstance;
    var refreshToken = await token;
    role = prefs.getString(_userRoleKey) ?? _defaultRole;
    if (_logDebugCloud) {
      Sync.shared.logger?.f(
          '[sync_db][DEBUG] refresh refreshToken = $refreshToken, role $role');
    }

    // Refresh token is an authorisation token to get different permissions for resource tokens
    // Azure functions also need a key
    try {
      Sync.shared.logger?.i('Start to request GetResourceTokens');
      if (_logDebugCloud) {
        Sync.shared.logger
            ?.f('[sync_db][DEBUG] refresh Start to request GetResourceTokens');
      }

      final response = await _lock.synchronized(() async {
        final params = <String, dynamic>{
          'refresh_token': refreshToken ?? '',
          'code': _azureKey,
          'source': 'cognito',
        };

        if (_tablesToSync.isNotEmpty) {
          params['sync_tables'] = _tablesToSync.join(',');
        }

        if (userId != null) {
          params['user_id'] = userId;
        }

        return await _http.get('/GetResourceTokens', parameters: params);
      });

      if (_logDebugCloud) {
        Sync.shared.logger?.f(
            '[sync_db][DEBUG] refresh Finished request GetResourceTokens $response');
      }

      Sync.shared.logger?.i('Finished request GetResourceTokens');
      _tokenExpiry = (await asyncTimeStamp).add(Duration(hours: 4));

      // Setup or update ServicePoints
      final mappedServicePoints = await asyncMapped;

      if (_logDebugCloud) {
        Sync.shared.logger?.f(
            '[sync_db][DEBUG] refresh get mapped service point $mappedServicePoints');
      }

      if (response['permissions'] is List) {
        List permissions = response['permissions'];
        for (final permission in permissions) {
          if (permission is Map) {
            // ignore: unawaited_futures
            _syncQueue.add(() async {
              String tableName = permission['id'];
              if (tableName.contains('-shared')) {
                tableName = tableName.split('-shared')[0];
              }

              final servicePoint = await _lock.synchronized(() =>
                  mappedServicePoints.putIfAbsent(
                      tableName, () => ServicePoint(name: tableName)));
              servicePoint.id = permission['id'];
              if (permission['resourcePartitionKey'] is List) {
                final List partitionKeys = permission['resourcePartitionKey'];
                servicePoint.partition = partitionKeys.firstOrNull?.toString();
              } else if (permission['resourcePartitionKey'] is String) {
                servicePoint.partition = permission['resourcePartitionKey'];
              } else {
                throw Exception(
                    'Invalid partition type ${permission['resourcePartitionKey']?.runtimeType}');
              }

              servicePoint.token = permission['_token'];
              servicePoint.access = $Access
                      .fromString(permission['permissionMode'].toLowerCase()) ??
                  Access.read;
              await servicePoint.save(syncToService: false);

              if (_logDebugCloud) {
                Sync.shared.logger?.f(
                    '[sync_db][DEBUG] refresh save service point $servicePoint');
              }
            });
          }
        }
      }

      if (_logDebugCloud) {
        Sync.shared.logger
            ?.f('[sync_db][DEBUG] refresh waiting for queue to complete');
      }
      // add this line to make sure the queue is not empty, according to this bug https://github.com/rknell/dart_queue/issues/8
      unawaited(_syncQueue.add(() => Future.value()));
      await _syncQueue.onComplete;

      if (_logDebugCloud) {
        Sync.shared.logger
            ?.f('[sync_db][DEBUG] refresh set role ${response['group']}');
      }
      // set role along with the resource tokens
      if (response['group'] != null) {
        role = response['group'];
        await prefs.setString(_userRoleKey, role!);
      }

      if (_logDebugCloud) {
        Sync.shared.logger?.f('[sync_db][DEBUG] refresh completed');
      }
    } on UnexpectedResponseException catch (e, stackTrace) {
      // Only handle refresh token expiry, otherwise the rest can bubble up
      if (e.statusCode == 401) {
        // token is expired -> sign out user
        Sync.shared.logger!.i('Token expired, sign out user');
        await signout();
      } else {
        Sync.shared.logger?.e(
            'Resource tokens error ${e.url} [${e.statusCode}] ${e.errorMessage}',
            error: e,
            stackTrace: stackTrace);
        rethrow;
      }
    } on ConnectivityException catch (e, stackTrace) {
      if (_logDebugCloud) {
        Sync.shared.logger
            ?.f('[sync_db][DEBUG] Resource tokens connection error $e');
      }
      Sync.shared.logger?.w('Resource tokens connection error $e',
          error: e, stackTrace: stackTrace);
      rethrow;
    } on Exception catch (e, stackTrace) {
      if (_logDebugCloud) {
        Sync.shared.logger
            ?.f('[sync_db][DEBUG] Resource tokens unknown error $e');
      }
      Sync.shared.logger?.e('Resource tokens unknown error $e',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<ServicePoint>> servicePoints() async {
    await _refreshIfExpired();
    return ServicePoint.all();
  }

  @override
  Future<List<ServicePoint>> servicePointsForTable(String table) async {
    Sync.shared.logger?.i('servicePointsForTable $table');
    await _refreshIfExpired();
    return await ServicePoint.listByName(table);
  }

  @override
  Future<void> setToken(String token, {bool waitingRefresh = false}) {
    throw UnimplementedError();
  }

  @override
  Future<void> signout({bool notify = true}) async {
    final pref = await _sharePrefInstance;
    await pref.remove(_userRoleKey);
    await pref.remove(_storageUriKey);
    _tokenExpiry = DateTime.utc(0);
    role = _defaultRole;
    await _cognitoUser?.signOut();
    _session = null;
    _cognitoUser = null;
    Sync.shared.logger!.i('signed out, then clear tables');
    await Sync.shared.db.local.writeTxn(() async {
      for (final table in _tablesToClearOnSignout) {
        final servicePoints = await ServicePoint.listByName(table);
        for (final servicePoint in servicePoints) {
          await Sync.shared.db.local.servicePoints.delete(servicePoint.localId);
        }

        await Sync.shared.db.modelHandlers[table]?.clear();
      }
    });

    _refreshed = refresh();
    if (notify) {
      signoutNotifier.refresh();
    }
  }

  @override
  Future<String?> get storageToken async {
    await _refreshStorageIfExpired();
    return (await _sharePrefInstance).getString(_storageUriKey);
  }

  @override
  Future<String?> get token async => _session?.refreshToken?.token;

  Future<SharedPreferences> get _sharePrefInstance async {
    _sharePref ??= await SharedPreferences.getInstance();
    return _sharePref!;
  }

  Future<Map<String?, ServicePoint>> _mappedServicePoints() async {
    final servicePoints = await ServicePoint.all();
    final map = <String?, ServicePoint>{};
    for (final servicePoint in servicePoints) {
      map[servicePoint.name] = servicePoint;
    }
    return map;
  }

  // check to refresh the refresh token
  Future<void> _refreshIfExpired() async {
    try {
      await _refreshed;
    } catch (e) {
      //ignore & refresh new task
      _refreshed = refresh();
      await _refreshed;
    }

    final now = await NetworkTime.shared.now;
    if (now.isAfter(_tokenExpiry)) {
      _refreshed = refresh();
      await _refreshed;
    }
  }

  /// Check the storage token (in this case is sas uri) is null or expired
  /// If it is, then get the new one from server
  Future<void> _refreshStorageIfExpired() async {
    await _refreshIfExpired();
    final storageUri =
        (await _sharePrefInstance).getString(_storageUriKey) ?? '';
    if (storageUri.isEmpty || Uri.tryParse(storageUri) == null) {
      await _refreshStorageToken();
    } else {
      // parse date from uri
      final uri = Uri.parse(storageUri);

      // then check for expiration
      final expired = uri.queryParameters['se']!;
      final expiredDate = DateTime.parse(expired);
      final now = await NetworkTime.shared.now;
      // The token is expired in 24 hours, but we just check 23 hours because of uploading time
      if (now.isAfter(expiredDate.add(Duration(hours: -1)))) {
        await _refreshStorageToken();
      }
    }
  }

  /// Check if user's current session is valid
  Future<bool> _checkAuthenticated() async {
    if (_cognitoUser == null) {
      return false;
    }

    if (_session == null) {
      try {
        // try to get session
        _session = await _cognitoUser?.getSession();
      } catch (e) {
        // ignore
      }
    }

    if (_session == null) {
      return false;
    }

    var isValid = _session!.isValid();
    if (!isValid) {
      try {
        // try to get new session in case it's expired
        _session = await _cognitoUser!.getSession();
        return _session!.isValid();
      } on FlutterError catch (e) {
        if (e.message.contains('Local storage is missing an ID Token')) {
          return false;
        }
        rethrow;
      }
    }
    return true;
  }

  /// Get new token (sas uri) from server. It's valid in 24 hours
  Future<void> _refreshStorageToken() async {
    final prefs = await _sharePrefInstance;
    var refreshToken = await token;
    if (refreshToken != null) {
      try {
        final response = await _http.get('/GetStorageToken',
            parameters: {'refresh_token': refreshToken, 'code': _azureKey});
        final uri = response['uri'];
        await prefs.setString(_storageUriKey, uri);
      } catch (e, stackTrace) {
        Sync.shared.logger
            ?.e('Storage token error $e', error: e, stackTrace: stackTrace);
        rethrow;
      }
    } else {
      Sync.shared.logger?.i('refresh token is null');
    }
  }

  Future<void> _initialized() async {
    try {
      _cognitoUser = await _userPool.getCurrentUser();
      _session = await _cognitoUser?.getSession();
    } on CognitoClientException catch (e, stacktrace) {
      if (await ConnectionHelper.shared.hasConnection()) {
        Sync.shared.logger
            ?.e('initiate cognito error $e', error: e, stackTrace: stacktrace);
        Sync.shared.exceptionNotifier.value = Tuple3(true, e, stacktrace);
      }
    }
  }

  @override
  Future<CognitoUserInfo?> confirmEmailPasscode(
      String email, String passcode) async {
    if (_cognitoUser == null || _cognitoUser!.username != email) {
      _cognitoUser = CognitoUser(email, _userPool);
    }

    _cognitoUser?.setAuthenticationFlowType('CUSTOM_AUTH');
    final authDetails = AuthenticationDetails(
        username: email, authParameters: [], validationData: {});
    try {
      _session = await _cognitoUser?.initiateAuth(authDetails);
    } on CognitoUserCustomChallengeException catch (e, stackTrace) {
      Sync.shared.logger
          ?.i('initiate auth error $e', error: e, stackTrace: stackTrace);
      try {
        // challenge exception, then send passcode
        _session = await _cognitoUser?.sendCustomChallengeAnswer(passcode);
      } on CognitoUserCustomChallengeException {
        // if there is challenge exception, then it's not valid passcode
        throw InvalidPasscodeException('Passcode $passcode is not valid');
      }

      if (_session == null || _session?.isValid() != true) {
        // try to get new session
        _session = await _cognitoUser!.getSession();
        if (_session == null || _session?.isValid() != true) {
          throw Exception(
              'Session $_session is invalid when confirm passcode $passcode for $email');
        }
      }

      final attributes = await _cognitoUser?.getUserAttributes();
      if (attributes != null) {
        final user = CognitoUserInfo.fromUserAttributes(attributes);
        user.confirmed = true;
        user.hasAccess = true;
        return user;
      }
    } catch (e, stackTrace) {
      Sync.shared.logger
          ?.e('Verify passcode error $e', error: e, stackTrace: stackTrace);
      rethrow;
    }

    return null;
  }

  @override
  Future<bool> changePassword(String oldPassword, String newPassword) {
    throw UnimplementedError();
  }

  @override
  Future<bool> confirmForgotPassword(
      String email, String confirmationCode, String newPassword) {
    throw UnimplementedError();
  }

  @override
  Future forgotPassword(String email) {
    throw UnimplementedError();
  }

  @override
  Future<CognitoUserInfo> login(String email, String password,
      {bool passAuth = false}) {
    throw UnimplementedError();
  }

  @override
  Future<void> sendNewConfirm(String email) {
    throw UnimplementedError();
  }

  @override
  Future<CognitoUserInfo> signInOrSignUp(String email,
      {String? password, Function? signUpSuccess}) {
    throw UnimplementedError();
  }

  @override
  String? get email => _cognitoUser?.username;
}

class InvalidPasscodeException implements Exception {
  String errorMessage;
  InvalidPasscodeException(this.errorMessage);
  @override
  String toString() => errorMessage;
}

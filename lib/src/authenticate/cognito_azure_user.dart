import 'dart:math';

import 'package:amazon_cognito_identity_dart_2/cognito.dart';
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
    SharedPreferences sharedPreferences,
  }) {
    _http = HTTP(config['azureBaseUrl'], {
      'httpRetries': 1,
      'connectTimeout': config['connectTimeout'],
      'receiveTimeout': config['receiveTimeout'],
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

    _tablesToClearOnSignout = config['tablesToClearOnSignout'] ?? <String>[];

    final initializeListener = (SharedPreferences prefs) {
      _userPool.storage = SharedPreferenceStorage(prefs);
      _initializeTask = _initialized();
      // try to load role first
      role = prefs.getString(_userRoleKey) ?? _defaultRole;
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

  HTTP _http;
  String _azureKey;
  String _azureSecret;
  String _azureSubject;
  String _azureIssuer;
  String _azureAudience;
  DateTime _tokenExpiry = DateTime.utc(0);
  Future<void> _refreshed;
  List<String> _tablesToClearOnSignout;
  Notifier signoutNotifier = Notifier(Object());
  static const _defaultRole = 'guest';
  static const _storageUriKey = 'storageUriKey';
  static const _userRoleKey = 'userRoleKey';
  SharedPreferences _sharePref;
  final _lock = Lock();
  cognito.CognitoUser _cognitoUser;
  cognito.CognitoUserSession _session;
  cognito.CognitoUserPool _userPool;
  Future _initializeTask;

  @override
  String role = _defaultRole;

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
  Future<void> refresh({bool forceRefreshToken = false}) async {
    // Start some tasks to await later
    final asyncTimeStamp = NetworkTime.shared.now;
    final asyncMapped = _mappedServicePoints();
    final prefs = await _sharePrefInstance;
    var refreshToken = await token;
    role = prefs.getString(_userRoleKey) ?? _defaultRole;

    // Refresh token is an authorisation token to get different permissions for resource tokens
    // Azure functions also need a key
    try {
      Sync.shared.logger?.i('Start to request GetResourceTokens');
      final response = await _lock.synchronized(() async {
        return await _http.get('/GetResourceTokens', parameters: {
          'refresh_token': refreshToken ?? '',
          'code': _azureKey,
          'source': 'cognito'
        });
      });
      Sync.shared.logger?.i('Finished request GetResourceTokens');
      _tokenExpiry =
          (await asyncTimeStamp).add(Duration(hours: 4, minutes: 59));

      // Setup or update ServicePoints
      final mappedServicePoints = await asyncMapped;
      for (final permission in response['permissions']) {
        String tableName = permission['id'];
        if (tableName.contains('-shared')) {
          tableName = tableName.split('-shared')[0];
        }

        await Sync.shared.local.initTable(tableName);

        final servicePoint = mappedServicePoints.putIfAbsent(
            tableName, () => ServicePoint(name: tableName));
        servicePoint.id = permission['id'];
        servicePoint.partition = permission['resourcePartitionKey'].first;
        servicePoint.token = permission['_token'];
        servicePoint.access =
            $Access.fromString(permission['permissionMode'].toLowerCase());
        await servicePoint.save();
      }

      // set role along with the resource tokens
      if (response['group'] != null) {
        role = response['group'];
        await prefs.setString(_userRoleKey, role);
      }
    } on UnexpectedResponseException catch (e, stackTrace) {
      // Only handle refresh token expiry, otherwise the rest can bubble up
      if (e.statusCode == 401) {
        // token is expired -> sign out user
        await signout();
      } else {
        Sync.shared.logger?.e(
            'Resource tokens error ${e.url} [${e.statusCode}] ${e.errorMessage}',
            e,
            stackTrace);
        rethrow;
      }
    } on ConnectivityException catch (e, stackTrace) {
      Sync.shared.logger
          ?.w('Resource tokens connection error $e', e, stackTrace);
      rethrow;
    } on Exception catch (e, stackTrace) {
      Sync.shared.logger?.e('Resource tokens unknown error $e', e, stackTrace);
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
    return List<ServicePoint>.from(
        await ServicePoint.where('name = $table').load());
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

    for (final table in _tablesToClearOnSignout) {
      final servicePoints = await ServicePoint.where('name = $table').load();
      for (final servicePoint in servicePoints) {
        await servicePoint.database
            .deleteLocal(servicePoint.tableName, servicePoint.id);
      }
      await Sync.shared.local.clearTable(table);
    }

    _refreshed = refresh();
    if (notify) {
      signoutNotifier.notify();
    }
  }

  @override
  Future<String> get storageToken async {
    await _refreshStorageIfExpired();
    return (await _sharePrefInstance).getString(_storageUriKey);
  }

  @override
  Future<String> get token async => _session?.refreshToken?.token;

  Future<SharedPreferences> get _sharePrefInstance async {
    _sharePref ??= await SharedPreferences.getInstance();
    return _sharePref;
  }

  Future<Map<String, ServicePoint>> _mappedServicePoints() async {
    final servicePoints = await ServicePoint.all();
    final map = <String, ServicePoint>{};
    for (final servicePoint in servicePoints) {
      map[servicePoint.name] = servicePoint;
    }
    return map;
  }

  // check to refresh the refresh token
  Future<void> _refreshIfExpired() async {
    await _refreshed;
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
      final expired = uri.queryParameters['se'];
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
    if (_cognitoUser == null || _session == null) {
      return false;
    }

    var isValid = _session.isValid();
    if (!isValid) {
      // try to get new session in case it's expired
      _session = await _cognitoUser.getSession();
      return _session.isValid();
    }
    return true;
  }

  /// Get new token (sas uri) from server. It's valid in 24 hours
  Future<void> _refreshStorageToken() async {
    final prefs = await _sharePrefInstance;
    var refreshToken = await token;
    if (refreshToken != null) {
      try {
        final response = await _http.get('/GetStorageToken', parameters: {
          'refresh_token': refreshToken ?? '',
          'code': _azureKey
        });
        final uri = response['uri'];
        await prefs.setString(_storageUriKey, uri);
      } catch (e, stackTrace) {
        Sync.shared.logger?.e('Storage token error $e', e, stackTrace);
        rethrow;
      }
    } else {
      Sync.shared.logger?.i('refresh token is null');
    }
  }

  Future<void> _initialized() async {
    _cognitoUser = await _userPool.getCurrentUser();
    _session = await _cognitoUser?.getSession();
  }

  @override
  Future<CognitoUserInfo> confirmEmailPasscode(
      String email, String passcode) async {
    _cognitoUser ??= CognitoUser(email, _userPool);
    _cognitoUser.setAuthenticationFlowType('CUSTOM_AUTH');
    final authDetails = AuthenticationDetails(
        username: email, authParameters: [], validationData: {});
    try {
      _session = await _cognitoUser.initiateAuth(authDetails);
    } on CognitoUserCustomChallengeException catch (e, stackTrace) {
      Sync.shared.logger?.i('initiate auth error $e', e, stackTrace);
      try {
        // challenge exception, then send passcode
        _session = await _cognitoUser.sendCustomChallengeAnswer(passcode);
      } on CognitoUserCustomChallengeException {
        // if there is challenge exception, then it's not valid passcode
        throw InvalidPasscodeException('Passcode $passcode is not valid');
      }

      if (!_session.isValid()) {
        return null;
      }

      final attributes = await _cognitoUser.getUserAttributes();
      final user = CognitoUserInfo.fromUserAttributes(attributes);
      user.confirmed = true;
      user.hasAccess = true;
      return user;
    } catch (e, stackTrace) {
      Sync.shared.logger?.e('Verify passcode error $e', e, stackTrace);
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
      {String password, Function signUpSuccess}) {
    throw UnimplementedError();
  }
}

class InvalidPasscodeException implements Exception {
  String errorMessage;
  InvalidPasscodeException(this.errorMessage);
  @override
  String toString() => errorMessage;
}

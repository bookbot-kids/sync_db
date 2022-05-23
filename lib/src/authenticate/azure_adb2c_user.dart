import 'dart:math';

import 'package:robust_http/connection_helper.dart';
import 'package:robust_http/exceptions.dart';
import 'package:robust_http/robust_http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sync_db/src/utils/web_service_utils.dart';
import 'package:sync_db/sync_db.dart';
import 'package:synchronized/synchronized.dart';

class AzureADB2CUserSession extends UserSession {
  /// Config will need:
  /// `azureBaseUrl` for Azure authentication functions
  /// `azureKey` the secure code to request azure function
  /// `tablesToClearOnSignout` a list of tables to remove when signing out
  /// `autoRefresh` auto refresh token
  AzureADB2CUserSession(Map<String, dynamic> config,
      {bool autoRefresh = true}) {
    _http = HTTP(config['azureBaseUrl'], {
      'httpRetries': 1,
      'connectTimeout': config['connectTimeout'],
      'receiveTimeout': config['receiveTimeout'],
    });
    _azureKey = config['azureKey'] ?? '';
    _azureSecret = config['azureSecret'] ?? '';
    _azureSubject = config['azureSubject'] ?? '';
    _azureIssuer = config['azureIssuer'] ?? '';
    _azureAudience = config['azureAudience'] ?? '';
    _tablesToClearOnSignout = config['tablesToClearOnSignout'] ?? <String>[];
    // try to load role first
    _sharePrefInstance.then((prefs) {
      if (!prefs.containsKey(_userRoleKey) &&
          prefs.getString('user_role') != null) {
        prefs.setString(_userRoleKey, prefs.getString('user_role'));
        role = prefs.getString('user_role');
      } else {
        role = prefs.getString(_userRoleKey) ?? _defaultRole;
      }
    });

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
  static const _refreshTokenKey = 'refreshToken';
  static const _storageUriKey = 'storageUri';
  static const _userRoleKey = 'userRole';
  SharedPreferences _sharePref;
  final _lock = Lock();

  @override
  String role = _defaultRole;

  /// The token is the ID Token. This is converted to a refresh token and save in preferences.
  /// This will then start the process of getting the resource tokens.
  /// Errors will need to be handled in the view
  @override
  Future<void> setToken(String token, {bool waitingRefresh = false}) async {
    final response = await _http.get('/GetRefreshAndAccessToken',
        parameters: {'code': _azureKey, 'id_token': token});
    if (response['token']['refresh_token'] != null) {
      await (await _sharePrefInstance)
          .setString(_refreshTokenKey, response['token']['refresh_token']);
    }

    // reset expiration
    _tokenExpiry = DateTime.utc(0);

    // get new token
    _refreshed = refresh();
    if (waitingRefresh) {
      await _refreshed;
    }
  }

  /// Get resource tokens from Cosmos
  /// If there is no refresh token, guest resource tokens are returned
  @override
  Future<void> refresh({bool forceRefreshToken = false}) async {
    // Start some tasks to await later
    final asyncTimeStamp = NetworkTime.shared.now;
    final asyncMapped = _mappedServicePoints();
    final prefs = await _sharePrefInstance;
    // migrate data from old keys
    if (!prefs.containsKey(_userRoleKey) &&
        prefs.getString('user_role') != null) {
      await prefs.setString(_userRoleKey, prefs.getString('user_role'));
    }

    var refreshToken = prefs.getString(_refreshTokenKey);
    role = prefs.getString(_userRoleKey) ?? _defaultRole;

    // Refresh token is an authorisation token to get different permissions for resource tokens
    // Azure functions also need a key
    try {
      Sync.shared.logger?.i('Start to request GetResourceTokens');
      final response = await _lock.synchronized(() async {
        return await _http.get('/GetResourceTokens', parameters: {
          'refresh_token': refreshToken ?? '',
          'code': _azureKey
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
      role = response['group'];
      await prefs.setString(_userRoleKey, role);
      refreshToken = (response['refreshToken'] != null)
          ? response['refreshToken']
          : refreshToken;
      if (refreshToken != null) {
        // ignore: unawaited_futures
        prefs.setString(_refreshTokenKey, refreshToken);
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

  // check to refresh the refresh token
  Future<void> _refreshIfExpired() async {
    await _refreshed;
    final now = await NetworkTime.shared.now;
    if (now.isAfter(_tokenExpiry)) {
      _refreshed = refresh();
      await _refreshed;
    }
  }

  @override
  Future<bool> hasSignedIn() async {
    return (await _sharePrefInstance).getString(_refreshTokenKey)?.isNotEmpty ==
        true;
  }

  /// Sign out user, remove the refresh token from shared preferences
  /// and clear certain ServicePoints and databases
  @override
  Future<void> signout({bool notify = true}) async {
    final pref = await _sharePrefInstance;
    await pref.remove(_refreshTokenKey);
    await pref.remove(_userRoleKey);
    await pref.remove(_storageUriKey);
    _tokenExpiry = DateTime.utc(0);
    role = 'guest';

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
  Future<void> deleteUser(String email) async {
    final prefs = await _sharePrefInstance;
    var refreshToken = prefs.getString(_refreshTokenKey);
    var clientToken = WebServiceUtils.generateClientToken(_azureSecret, _azureSubject,
        _azureIssuer, _azureAudience, await NetworkTime.shared.now,
        jwtId: Random().nextInt(10000).toString());
    if (!await ConnectionHelper.hasConnection()) {
      throw ConnectivityException('The connection is turn off',
          hasConnectionStatus: false);
    }
    if (!await ConnectionHelper.hasInternetConnection()) {
      throw ConnectivityException(
          'The connection is turn on but there is no internet connection',
          hasConnectionStatus: true);
    }
    final response = await _http.post('/DeleteUser', parameters: {
      'email': email,
      'refresh_token': refreshToken ?? '',
      'client_token': clientToken,
      'code': _azureKey
    }, includeHttpResponse: true);
    if (response.data == null || response.data['success'] != true) {
      throw Exception('Delete account failed, statusCode: '
          '${response.statusCode}, message: ${response.statusMessage}');
    }
  }

  Future<Map<String, ServicePoint>> _mappedServicePoints() async {
    final servicePoints = await ServicePoint.all();
    final map = <String, ServicePoint>{};
    for (final servicePoint in servicePoints) {
      map[servicePoint.name] = servicePoint;
    }
    return map;
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

  /// Get new token (sas uri) from server. It's valid in 24 hours
  Future<void> _refreshStorageToken() async {
    final prefs = await _sharePrefInstance;
    var refreshToken = prefs.getString(_refreshTokenKey);
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

  Future<SharedPreferences> get _sharePrefInstance async {
    _sharePref ??= await SharedPreferences.getInstance();
    return _sharePref;
  }

  @override
  Future<String> get token async =>
      (await _sharePrefInstance).getString(_refreshTokenKey);
}

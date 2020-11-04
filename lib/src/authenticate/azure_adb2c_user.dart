import 'package:robust_http/exceptions.dart';
import 'package:robust_http/robust_http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sync_db/sync_db.dart';

class AzureADB2CUserSession extends UserSession {
  /// Config will need:
  /// `azureBaseUrl` for Azure authentication functions
  /// `azureKey` the secure code to request azure function
  /// `tablesToClearOnSignout` a list of tables to remove when signing out
  AzureADB2CUserSession(Map<String, dynamic> config) {
    _http = HTTP(config['azureBaseUrl'], {'httpRetries': 1});
    _azureKey = config['azureKey'];
    _tablesToClearOnSignout = config['tablesToClearOnSignout'];
    // Start the process of getting tokens
    _refreshed = refresh();
  }

  HTTP _http;
  String _azureKey;
  DateTime _tokenExpiry = DateTime.utc(0);
  Future<void> _refreshed;
  List<String> _tablesToClearOnSignout;
  Notifier signoutNotifier = Notifier(Object());

  @override
  String role = 'guest';

  /// The token is the ID Token. This is converted to a refresh token and save in preferences.
  /// This will then start the process of getting the resource tokens.
  /// Errors will need to be handled in the view
  @override
  Future<void> setToken(String token) async {
    final futurePreference = SharedPreferences.getInstance();
    final response = await _http.get('/GetRefreshAndAccessToken',
        parameters: {'code': _azureKey, 'id_token': token});
    final preference = await futurePreference;
    await preference.setString(
        'refreshToken', response['token']['refresh_token']);
    _refreshed = refresh();
  }

  /// Get resource tokens from Cosmos
  /// If there is no refresh token, guest resource tokens are returned
  @override
  Future<void> refresh() async {
    // Start some tasks to await later
    final asyncTimeStamp = NetworkTime.shared.now;
    final asyncMapped = _mappedServicePoints();
    final sharedPreference = await SharedPreferences.getInstance();
    var refreshToken = sharedPreference.getString('refreshToken');

    // Refresh token is an authorisation token to get different permissions for resource tokens
    // Azure functions also need a key
    try {
      final response = await _http.get('/GetResourceTokens',
          parameters: {'refresh_token': refreshToken ?? '', 'code': _azureKey});
      _tokenExpiry =
          (await asyncTimeStamp).add(Duration(hours: 4, minutes: 59));

      // Setup or update ServicePoints
      final mappedServicePoints = await asyncMapped;
      for (final permission in response['permissions']) {
        String tableName = permission['id'];
        await Sync.shared.local.initTable(tableName);

        if (tableName.contains('-shared')) {
          tableName = tableName.split('-shared')[0];
        }

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
      refreshToken = (response['refreshToken'] != null)
          ? response['refreshToken']
          : refreshToken;
      // ignore: unawaited_futures
      sharedPreference.setString('refreshToken', refreshToken);
    } on UnexpectedResponseException catch (e, stackTrace) {
      // Only handle refresh token expiry, otherwise the rest can bubble up
      if (e.response.statusCode == 401) {
        // token is expired -> sign out user
        await signout();
      } else {
        Sync.shared.logger?.e('Resource tokens error', e, stackTrace);
        throw UnexpectedResponseException(e);
      }
    }
  }

  @override
  Future<List<ServicePoint>> servicePoints() async {
    await _refreshIfExpired();
    return ServicePoint.all();
  }

  @override
  Future<List<ServicePoint>> servicePointsForTable(String table) async {
    await _refreshIfExpired();
    return List<ServicePoint>.from(
        await ServicePoint.where('name = $table').load());
  }

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
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString('refreshToken') != null;
  }

  /// Sign out user, remove the refresh token from shared preferences
  /// and clear certain ServicePoints and databases
  @override
  Future<void> signout() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('refresh_token');
    _tokenExpiry = DateTime.utc(0);
    role = 'guest';

    for (final table in _tablesToClearOnSignout) {
      final servicePoints = await ServicePoint.where('name = $table').load();
      for (final servicePoint in servicePoints) {
        servicePoint.deleteLocal();
      }
      await Sync.shared.local.clearTable(table);
    }

    _refreshed = refresh();
    signoutNotifier.notify();
  }

  Future<Map<String, ServicePoint>> _mappedServicePoints() async {
    final servicePoints = await ServicePoint.all();
    final map = <String, ServicePoint>{};
    for (final servicePoint in servicePoints) {
      map[servicePoint.name] = servicePoint;
    }
    return map;
  }
}

import 'package:basic_utils/basic_utils.dart';
import 'package:robust_http/exceptions.dart';
import 'package:robust_http/robust_http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sync_db/src/network_time.dart';
import 'package:sync_db/src/sync_db.dart';

import 'abstract.dart';

class AzureADB2CUserSession extends UserSession {
  /// Config will need:
  /// `azureBaseUrl` for Azure authentication functions
  /// `azureCode` the secure code to request azure function
  AzureADB2CUserSession(Map<String, dynamic> config) {
    _config = config;
    NetworkTime.shared.now.then((value) {
      _tokenExpiry = value;
    });

    _http = HTTP(config['azureBaseUrl'], config);
    SharedPreferences.getInstance().then((value) async {
      prefs = value;
      await resourceTokens();
    });
  }

  SharedPreferences prefs;

  Map<String, dynamic> _config;
  HTTP _http;
  final List<MapEntry> _resourceTokens = [];
  DateTime _tokenExpiry;

  @override
  Future<bool> hasSignedIn() async {
    prefs ??= await SharedPreferences.getInstance();
    return refreshToken != null && refreshToken.isNotEmpty;
  }

  @override
  String get refreshToken => prefs.getString('refresh_token');

  @override
  String get role => prefs.getString('role');

  @override
  Future<void> refresh() async {
    _tokenExpiry = await NetworkTime.shared.now;
  }

  @override
  set refreshToken(String token) {
    prefs.setString('refresh_token', token);
  }

  /// Will return either resource tokens that have not expired, or will connect to the web service to get new tokens
  /// When refresh is true it will get new resource tokens from web services
  /// If there is no refresh token, guest resource token is returned
  @override
  Future<List<MapEntry>> resourceTokens() async {
    prefs ??= await SharedPreferences.getInstance();

    _tokenExpiry ??= await NetworkTime.shared.now;

    var now = await NetworkTime.shared.now;
    if (_tokenExpiry.isAfter(now)) {
      return List<MapEntry>.from(_resourceTokens);
    }

    final expired = now.add(Duration(hours: 4, minutes: 45));

    // Refresh token is an authorisation token to get different permissions for resource tokens
    // Azure functions also need a code
    try {
      final response = await _http.get('/GetResourceTokens', parameters: {
        'refresh_token': refreshToken ?? '',
        'code': _config['azureCode']
      });

      _resourceTokens.clear();
      for (final permission in response['permissions']) {
        _resourceTokens.add(MapEntry(permission['id'], permission));
      }

      _tokenExpiry = expired;

      // set role along with the resource tokens
      if (response['group'] != null) {
        role = response['group'];
      }

      // Update new refresh token from server
      if (response['refreshToken'] is String &&
          StringUtils.isNotNullOrEmpty(response['refreshToken'])) {
        refreshToken = response['refreshToken'];
      }
    } catch (e, stackTrace) {
      if (e is UnexpectedResponseException) {
        try {
          if (e.response.statusCode == 401) {
            // token is expired, need to sign out user
            _resourceTokens.clear();
            await prefs.remove('refresh_token');
          } else {
            SyncDB.shared.logger?.e('get resource tokens error', e, stackTrace);
          }
        } catch (e) {
          // ignore
        }
      } else {
        SyncDB.shared.logger?.e('get resource tokens error', e, stackTrace);
      }
    }

    return List<MapEntry>.from(_resourceTokens);
  }

  @override
  set role(String role) {
    prefs.setString('role', role);
  }

  /// Sign out user, remove the refresh token from shared preferences and clear all resource tokens and database
  @override
  Future<void> signout() async {
    _resourceTokens?.clear();
    _tokenExpiry = null;
    await prefs.remove('refresh_token');
    await SyncDB.shared.local.cleanDatabase();
  }

  /// Fetch refresh token & resource tokens from id token
  /// Return a list of resource tokens or guest resource tokens if id token is invalid
  Future<List<MapEntry>> fetchTokens(String idToken) async {
    try {
      if (idToken != null && idToken.isNotEmpty) {
        var response = await _http.get('/GetRefreshAndAccessToken',
            parameters: {'code': _config['azureCode'], 'id_token': idToken});
        if (response['success'] == true && response['token'] != null) {
          var token = response['token'];
          refreshToken = token['refresh_token'];
        }
      }

      await refresh();
      return await resourceTokens();
    } catch (error, stackTrace) {
      SyncDB.shared.logger?.e('fetch token error', error, stackTrace);
    }

    return null;
  }
}

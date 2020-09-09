import 'dart:convert';

import 'package:amazon_cognito_identity_dart_2/cognito.dart' as cognito;
import 'package:jaguar_jwt/jaguar_jwt.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sync_db/src/abstract.dart';
import 'package:sync_db/src/graphql_service.dart';
import 'package:sync_db/src/service_point.dart';
import 'package:sync_db/src/sync_db.dart';

class CognitoUserSession extends UserSession {
  GraphQLService _service;
  CognitoUserSession(
      GraphQLService service, String clientId, Map<String, dynamic> config) {
    _clientId = config['clientId'];
    _awsUserPoolId = config['userPoolId'];
    _service = service;
    _initialize().whenComplete(() => null);
  }

  String _awsUserPoolId;
  String _clientId;
  cognito.CognitoUser _cognitoUser;
  cognito.CognitoUserSession _session;
  cognito.CognitoUserPool _userPool;

  @override
  String get role {
    var idToken = _session?.getIdToken()?.getJwtToken();
    if (idToken == null) return null;

    final parts = idToken.split('.');
    final payload = parts[1];
    final decoded = B64urlEncRfc7515.decodeUtf8(payload);
    Map data = jsonDecode(decoded);
    // get cognito group name
    if (data.containsKey('cognito:groups')) {
      var lst = data['cognito:groups'];
      return lst.isNotEmpty ? lst.first : null;
    }

    return null;
  }

  String get refreshToken => _session?.accessToken?.getJwtToken();

  @override
  Future<bool> hasSignedIn() async => await _checkAuthenticated();

  @override
  Future<void> forceRefresh() async {
    _session = await _cognitoUser.getSession();
  }

  set refreshToken(String token) => throw UnimplementedError();

  Future<List<MapEntry>> resourceTokens() async {
    if (!_session.isValid()) {
      _session = await _cognitoUser.getSession();
    }

    return null;
  }

  set role(String role) => throw UnimplementedError();

  @override
  Future<void> signout() async {
    if (_cognitoUser != null) {
      await _cognitoUser.signOut();
    }

    await Sync.shared.local.cleanDatabase();
  }

  /// Initiate user session from local storage if present
  Future<bool> _initialize() async {
    _userPool = cognito.CognitoUserPool(_awsUserPoolId, _clientId);
    final prefs = await SharedPreferences.getInstance();
    final storage = SharedPreferenceStorage(prefs);
    _userPool.storage = storage;

    _cognitoUser = await _userPool.getCurrentUser();
    if (_cognitoUser == null) {
      return false;
    }
    _session = await _cognitoUser.getSession();
    return _session.isValid();
  }

  /// Check if user's current session is valid
  Future<bool> _checkAuthenticated() async {
    if (_cognitoUser == null || _session == null) {
      return false;
    }
    return _session.isValid();
  }

  @override
  Future<List<ServicePoint>> servicePoints() async {
    var schema = await _service.schema;
    var results = <ServicePoint>[];
    schema.forEach((key, value) {
      results.add(ServicePoint(name: key));
    });

    return results;
  }

  @override
  Future<List<ServicePoint>> servicePointsForTable(String table) async {
    // Each table has only one service point
    return [ServicePoint(name: table)];
  }

  @override
  set token(String token) {
    throw UnimplementedError();
  }
}

/// Cognito shared preference storage, uses to store session keys
class SharedPreferenceStorage extends cognito.CognitoStorage {
  SharedPreferenceStorage(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<void> clear() async {
    await _prefs.clear();
  }

  @override
  Future getItem(String key) async {
    String item;
    try {
      item = json.decode(_prefs.getString(key));
    } catch (e) {
      return null;
    }
    return item;
  }

  @override
  Future removeItem(String key) async {
    final item = getItem(key);
    if (item != null) {
      await _prefs.remove(key);
      return item;
    }
    return null;
  }

  @override
  Future setItem(String key, value) async {
    await _prefs.setString(key, json.encode(value));
    return getItem(key);
  }
}

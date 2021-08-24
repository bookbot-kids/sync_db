import 'dart:convert';

import 'package:amazon_cognito_identity_dart_2/cognito.dart' as cognito;
import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';
import 'package:random_string/random_string.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sync_db/src/abstract.dart';
import 'package:sync_db/src/services/graphql_service.dart';
import 'package:sync_db/src/services/service_point.dart';
import 'package:sync_db/src/sync_db.dart';

class CognitoUserSession extends UserSession {
  CognitoUserSession(SharedPreferences prefs, GraphQLService service,
      String clientId, String poolId) {
    _clientId = clientId;
    _awsUserPoolId = poolId;
    _service = service;
    _prefs = prefs;
  }

  bool isNewUser = true;

  String _awsUserPoolId;
  String _clientId;
  cognito.CognitoUser _cognitoUser;
  SharedPreferences _prefs;
  GraphQLService _service;
  cognito.CognitoUserSession _session;
  CognitoUserInfo _userInfo;
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

  @override
  Future<void> refresh() async {
    _session = await _cognitoUser.getSession();
  }

  @override
  Future<bool> hasSignedIn() async => await _checkAuthenticated();

  @override
  Future<List<ServicePoint>> servicePoints() async {
    await _service.setup();
    var schema = await _service.schema;
    var results = <ServicePoint>[];
    var roleName = role;
    for (var tableName in schema.keys) {
      var servicePoint = await ServicePoint.searchBy(tableName) ??
          ServicePoint(name: tableName);
      var access = _createAccess(tableName, roleName);
      if (access != null) {
        servicePoint.access = access;
        if (servicePoint.access != access) {
          await servicePoint.save(syncToService: false);
        }

        results.add(servicePoint);
      }
    }

    Sync.shared.logger?.i('role $roleName has these service points: $results');
    return results;
  }

  @override
  Future<List<ServicePoint>> servicePointsForTable(String table) async {
    await _service.setup();
    // Each table has only one service point
    var roleName = role;
    var servicePoint =
        await ServicePoint.searchBy(table) ?? ServicePoint(name: table);
    var access = _createAccess(table, roleName);
    if (access != null) {
      servicePoint.access = access;
      if (servicePoint.access != access) {
        await servicePoint.save(syncToService: false);
      }

      return [servicePoint];
    }

    return [];
  }

  @override
  Future<void> signout() async {
    if (_cognitoUser != null) {
      await _cognitoUser.signOut();
    }

    await Sync.shared.local.cleanDatabase();
  }

  @override
  Future<void> setToken(String token, {bool waitingRefresh = false}) async {
    throw UnimplementedError();
  }

  Access _createAccess(String table, String roleName) {
    Access access;
    if (_service.hasPermission(roleName, table, 'read-write')) {
      access = Access.all;
    } else if (_service.hasPermission(roleName, table, 'read')) {
      access = Access.read;
    } else if (_service.hasPermission(roleName, table, 'write')) {
      access = access == Access.read ? Access.all : Access.write;
    }

    return access;
  }

  String get refreshToken => _session?.accessToken?.getJwtToken();

  set refreshToken(String token) => throw UnimplementedError();

  Future<List<MapEntry>> resourceTokens() async {
    if (!_session.isValid()) {
      _session = await _cognitoUser.getSession();
    }

    return null;
  }

  String get id => _userInfo?.id;

  set role(String role) => throw UnimplementedError();

  /// Initiate user session from local storage if present
  Future<bool> initialize() async {
    _userPool = cognito.CognitoUserPool(_awsUserPoolId, _clientId);
    _userPool.storage = SharedPreferenceStorage(_prefs);

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

    var isValid = _session.isValid();
    if (!isValid) {
      // try to get new session in case it's expired
      _session = await _cognitoUser.getSession();
    }

    return _session.isValid();
  }

  /// Get existing user from session with his/her attributes
  Future<CognitoUserInfo> getCurrentUser([bool refresh = false]) async {
    if (!(await _checkAuthenticated())) {
      return null;
    }

    if (_userInfo != null && !refresh) {
      return _userInfo;
    }

    final attributes = await _cognitoUser.getUserAttributes();
    if (attributes == null) {
      return null;
    }
    _userInfo = CognitoUserInfo.fromUserAttributes(attributes);
    _userInfo.hasAccess = true;
    return _userInfo;
  }

  Future<CognitoUserInfo> signInOrSignUp(String email,
      {Function signupCallback}) async {
    CognitoUserInfo result;
    try {
      var password = randomString(20);
      result = await signUp(email, password, email);
      if (signupCallback != null) {
        signupCallback();
      }

      result = await login(email);
      isNewUser = true;
    } on CognitoClientException catch (e) {
      if (e.code == 'UsernameExistsException') {
        // sign in
        result = await login(email);
        isNewUser = false;
      } else {
        rethrow;
      }
    }

    return result;
  }

  Future<CognitoUserInfo> signInOrSignUpPassword(String email, String password,
      {Function signupCallback}) async {
    CognitoUserInfo result;
    try {
      result = await signUp(email, password, email);
      if (signupCallback != null) {
        signupCallback();
      }

      result = await loginPassword(email, password);
      isNewUser = true;
    } on CognitoClientException catch (e) {
      if (e.code == 'UsernameExistsException') {
        // sign in
        result = await loginPassword(email, password);
        isNewUser = false;
      } else {
        rethrow;
      }
    }

    return result;
  }

  Future<String> refreshRole() async {
    await refresh();
    var newRole = role;
    await _resetSyncTime(newRole);
    return newRole;
  }

  /// Reset sync time for writable tables
  Future<void> _resetSyncTime(String roleName) async {
    var records = await ServicePoint.all();
    for (var record in records) {
      var access = _createAccess(record.name, roleName);
      if (access == Access.write || access == Access.all) {
        record.from = 0;
        await record.save(syncToService: false);
      }
    }
  }

  /// Login user
  Future<CognitoUserInfo> login(String email) async {
    email = email.toLowerCase();
    _cognitoUser = CognitoUser(email, _userPool, storage: _userPool.storage);

    final authDetails = AuthenticationDetails(
        username: email,
        authParameters: [], validationData: {});

    try {
      _session = await _cognitoUser.initiateAuth(authDetails);
    } on CognitoUserCustomChallengeException catch (e) {
      // custom challenage
      print('custom challenage $e');
    } on CognitoClientException {
      rethrow;
    } on Exception {
      rethrow;
    }

    return CognitoUserInfo(email: email);
  }

  /// Login user with email and password
  Future<CognitoUserInfo> loginPassword(String email, String password) async {
    email = email.toLowerCase();
    _cognitoUser = CognitoUser(email, _userPool, storage: _userPool.storage);
    _cognitoUser.setAuthenticationFlowType('USER_PASSWORD_AUTH');

    final authDetails = AuthenticationDetails(
        username: email,
        password: password,
        authParameters: [],
        validationData: {});

    try {
      _session = await _cognitoUser.authenticateUser(authDetails);
    } on CognitoUserCustomChallengeException catch (e) {
      // custom challenage
      print('custom challenage $e');
    } on CognitoClientException {
      rethrow;
    } on Exception {
      rethrow;
    }

    return CognitoUserInfo(email: email);
  }

  /// Sign up user
  Future<CognitoUserInfo> signUp(
      String email, String password, String name) async {
    email = email.toLowerCase();
    CognitoUserPoolData data;
    final userAttributes = [
      AttributeArg(name: 'name', value: name),
    ];
    data =
        await _userPool.signUp(email, password, userAttributes: userAttributes);

    final user = CognitoUserInfo();
    user.email = email;
    user.name = name;
    user.confirmed = data.userConfirmed;

    return user;
  }

  Future<CognitoUserInfo> answerOTPCustomChallenge(
      String email, String answer) async {
    _session = await _cognitoUser.sendCustomChallengeAnswer(answer);

    if (!_session.isValid()) {
      return null;
    }

    final attributes = await _cognitoUser.getUserAttributes();
    final user = CognitoUserInfo.fromUserAttributes(attributes);
    user.confirmed = true;
    user.hasAccess = true;

    return user;
  }

  @override
  Future<String> get storageToken => throw UnimplementedError();
}

class CognitoUserInfo {
  CognitoUserInfo({this.email, this.name});

  /// Decode user from Cognito User Attributes
  factory CognitoUserInfo.fromUserAttributes(
      List<CognitoUserAttribute> attributes) {
    final user = CognitoUserInfo();
    attributes.forEach((attribute) {
      if (attribute.getName() == 'email') {
        user.email = attribute.getValue();
      } else if (attribute.getName() == 'name') {
        user.name = attribute.getValue();
      } else if (attribute.getName() == 'sub') {
        user.id = attribute.getValue();
      }
    });
    return user;
  }

  bool confirmed = false;
  String email;
  bool hasAccess = false;
  String id;
  String name;
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
      var value = _prefs.getString(key);
      if (value != null) {
        item = json.decode(value);
      }
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

import 'dart:convert';

import 'package:amazon_cognito_identity_dart_2/cognito.dart' as cognito;
import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';
import 'package:random_string/random_string.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sync_db/src/abstract.dart';
import 'package:sync_db/src/graphql_service.dart';
import 'package:sync_db/src/service_point.dart';
import 'package:sync_db/src/sync_db.dart';

class CognitoUserSession extends UserSession {
  GraphQLService _service;
  CognitoUserSession(GraphQLService service, String clientId, String poolId) {
    _clientId = clientId;
    _awsUserPoolId = poolId;
    _service = service;
  }

  String _awsUserPoolId;
  String _clientId;
  cognito.CognitoUser _cognitoUser;
  cognito.CognitoUserSession _session;
  cognito.CognitoUserPool _userPool;
  CognitoUserInfo _userInfo;
  bool isNewUser = true;

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

  String get id => _userInfo?.id;

  set role(String role) => throw UnimplementedError();

  @override
  Future<void> signout() async {
    if (_cognitoUser != null) {
      await _cognitoUser.signOut();
    }

    await Sync.shared.local.cleanDatabase();
  }

  /// Initiate user session from local storage if present
  Future<bool> initialize() async {
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
    await _service.setup();
    var schema = await _service.schema;
    var results = <ServicePoint>[];
    var roleName = role;
    schema.forEach((key, value) {
      if (_service.hasPermission(roleName, key, 'read')) {
        results.add(ServicePoint(name: key, access: Access.read));
      } else if (_service.hasPermission(roleName, key, 'write')) {
        results.add(ServicePoint(name: key, access: Access.all));
      }
    });

    Sync.shared.logger?.i('role $roleName has these service points: $results');
    return results;
  }

  @override
  Future<List<ServicePoint>> servicePointsForTable(String table) async {
    await _service.setup();
    // Each table has only one service point
    if (_service.hasPermission(role, table, 'read')) {
      return [ServicePoint(name: table, access: Access.read)];
    } else if (_service.hasPermission(role, table, 'write')) {
      return [ServicePoint(name: table, access: Access.all)];
    }

    return [];
  }

  @override
  set token(String token) {
    throw UnimplementedError();
  }

  /// Get existing user from session with his/her attributes
  Future<CognitoUserInfo> getCurrentUser([bool refresh = false]) async {
    if (_cognitoUser == null || _session == null) {
      return null;
    }
    if (!_session.isValid()) {
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

  Future<String> refreshRole() async {
    await forceRefresh();
    return role;
  }

  /// Login user
  Future<CognitoUserInfo> login(String email) async {
    email = email.toLowerCase();
    _cognitoUser = CognitoUser(email, _userPool, storage: _userPool.storage);

    final authDetails = AuthenticationDetails(
        username: email, authParameters: [], validationData: {});

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
        authParameters: [],
        validationData: {},
        password: password);

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
}

class CognitoUserInfo {
  String id;
  String email;
  String name;
  bool confirmed = false;
  bool hasAccess = false;

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

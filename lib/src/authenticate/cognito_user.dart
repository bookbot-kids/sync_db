import 'dart:convert';

import 'package:amazon_cognito_identity_dart_2/cognito.dart' as cognito;
import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';
import 'package:random_string/random_string.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sync_db/src/abstract.dart';
import 'package:sync_db/src/authenticate/cognito_share_pref_storage.dart';
import 'package:sync_db/src/services/graphql_service.dart';
import 'package:sync_db/src/services/service_point.dart';
import 'package:sync_db/src/sync_db.dart';

import 'cognito_auth_session.dart';

enum AuthenticationType { password, passcode }

class CognitoUserSession implements UserSession, CognitoAuthSession {
  CognitoUserSession(SharedPreferences prefs, GraphQLService service,
      String clientId, String poolId,
      {AuthenticationType type = AuthenticationType.password,
      List<String>? tablesToClearOnSignOut}) {
    _clientId = clientId;
    _awsUserPoolId = poolId;
    _service = service;
    _prefs = prefs;
    _type = type;
    _userRole = prefs.getString(userRoleKey);
    _tablesToClearOnSignOut = tablesToClearOnSignOut ?? <String>[];
  }

  bool isNewUser = true;

  late String _awsUserPoolId;
  late String _clientId;
  cognito.CognitoUser? _cognitoUser;
  SharedPreferences? _prefs;
  late GraphQLService _service;
  cognito.CognitoUserSession? _session;
  CognitoUserInfo? _userInfo;
  late cognito.CognitoUserPool _userPool;
  String? _userRole;
  AuthenticationType? _type;
  late List<String> _tablesToClearOnSignOut;

  String get userRoleKey => '${_clientId}-userRole';

  @override
  String get role {
    _userRole ??= _getUserRoleInToken();
    return _userRole!;
  }

  @override
  Future<void> refresh({bool forceRefreshToken = false}) async {
    if (forceRefreshToken) {
      await _invalidateToken();
    }
    _session = await _cognitoUser!.getSession();
    _userRole = _getUserRoleInToken() ?? _userRole;
  }

  Future<void> _invalidateToken() async {
    _cognitoUser?.getSignInUserSession()?.invalidateToken();
    final clockDriftKey = '${_cognitoUser?.keyPrefix}.clockDrift';
    final clockDrift =
        int.tryParse(await (_cognitoUser?.storage.getItem(clockDriftKey))) ?? 0;
    await _cognitoUser!.storage
        .setItem(clockDriftKey, '${clockDrift - Duration.secondsPerHour * 2}');
  }

  String? _getUserRoleInToken() {
    var idToken = _session?.getIdToken().getJwtToken();
    if (idToken == null) return null;

    final parts = idToken.split('.');
    final payload = parts[1];
    final decoded = B64urlEncRfc7515.decodeUtf8(payload);
    Map data = jsonDecode(decoded);
    // get cognito group name
    var role;
    if (data.containsKey('cognito:groups')) {
      var lst = data['cognito:groups'];
      role = lst.isNotEmpty ? lst.first : null;
    }
    if (role != null) _prefs!.setString(userRoleKey, role);
    return role;
  }

  @override
  Future<bool> hasSignedIn() async => await _checkAuthenticated();

  @override
  Future<List<ServicePoint>> servicePoints() async {
    await _service.setup();
    var schema = await _service.schema;
    var results = <ServicePoint>[];
    for (var tableName in schema.keys) {
      var servicePoint = await ServicePoint.searchBy(tableName) ??
          ServicePoint(name: tableName);
      var access = _createAccess(tableName, role);
      if (access != null) {
        servicePoint.access = access;
        if (servicePoint.access != access) {
          await servicePoint.save(syncToService: false);
        }

        results.add(servicePoint);
      }
    }

    Sync.shared.logger?.i('role $role has these service points: $results');
    return results;
  }

  @override
  Future<List<ServicePoint>> servicePointsForTable(String table) async {
    await _service.setup();
    // Each table has only one service point
    var servicePoint =
        await ServicePoint.searchBy(table) ?? ServicePoint(name: table);
    var access = _createAccess(table, role);
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
  Future<void> signout({bool notify = true}) async {
    if (_cognitoUser != null) {
      await _cognitoUser!.signOut();
      await _cognitoUser!.storage.clear();
    }
    _userRole = null;
    for (final table in _tablesToClearOnSignOut) {
      final servicePoints = await ServicePoint.listByName(table);
      for (final servicePoint in servicePoints) {
        await servicePoint.deleteLocal();
      }
      await Sync.shared.modelHandlers[table]?.clear();
    }
  }

  @override
  Future<void> setToken(String token, {bool waitingRefresh = false}) async {
    throw UnimplementedError();
  }

  Access? _createAccess(String? table, String roleName) {
    Access? access;
    if (_service.hasPermission(roleName, table, 'read-write')) {
      access = Access.all;
    } else if (_service.hasPermission(roleName, table, 'read')) {
      access = Access.read;
    } else if (_service.hasPermission(roleName, table, 'write')) {
      access = access == Access.read ? Access.all : Access.write;
    }

    return access;
  }

  String? get refreshToken => _session?.accessToken.getJwtToken();

  set refreshToken(String? token) => throw UnimplementedError();

  Future<List<MapEntry>?> resourceTokens() async {
    if (!_session!.isValid()) {
      _session = await _cognitoUser!.getSession();
    }

    return null;
  }

  String? get id => _userInfo?.id;

  set role(String role) {
    _userRole = role;
    _prefs!.setString(userRoleKey, role);
  }

  String? get email => _userInfo?.email;

  /// Initiate user session from local storage if present
  Future<bool> initialize() async {
    _userPool = cognito.CognitoUserPool(_awsUserPoolId, _clientId);
    _userPool.storage = SharedPreferenceStorage(_prefs);

    _cognitoUser = await _userPool.getCurrentUser();
    if (_cognitoUser == null) {
      return false;
    }
    _session = await _cognitoUser?.getSession();
    return _session?.isValid() == true;
  }

  /// Check if user's current session is valid
  Future<bool> _checkAuthenticated() async {
    if (_cognitoUser == null || _session == null) {
      return false;
    }

    var isValid = _session?.isValid();
    if (isValid != true) {
      // try to get new session in case it's expired
      _session = await _cognitoUser?.getSession();
      return _session?.isValid() == true;
    }
    return true;
  }

  /// Get existing user from session with his/her attributes
  Future<CognitoUserInfo?> getCurrentUser([bool refresh = false]) async {
    if (!(await _checkAuthenticated())) {
      return null;
    }

    if (_userInfo != null && !refresh) {
      return _userInfo;
    }
    var attributes;
    try {
      attributes = await _cognitoUser!.getUserAttributes();
    } on CognitoClientException catch (e) {
      if (e.code == 'UserNotFoundException') {
        await _prefs!.clear();
        await signout();
        _cognitoUser = null;
        _session = null;
      }
    }

    if (attributes == null) {
      return null;
    }
    _userInfo = CognitoUserInfo.fromUserAttributes(attributes);
    _userInfo?.hasAccess = true;
    return _userInfo;
  }

  Future<String> refreshRole({bool forceRefreshToken = false}) async {
    await refresh(forceRefreshToken: forceRefreshToken);
    await _resetSyncTime(role);
    return role;
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

  /// Login user with email and password
  @override
  Future<CognitoUserInfo> login(String email, String password,
      {bool passAuth = false}) async {
    email = email.toLowerCase();
    _cognitoUser = CognitoUser(email, _userPool, storage: _userPool.storage);
    if (passAuth) _cognitoUser!.setAuthenticationFlowType('USER_PASSWORD_AUTH');
    final authDetails = AuthenticationDetails(
        username: email,
        password: password,
        authParameters: [],
        validationData: {});
    _session = await _cognitoUser!.authenticateUser(authDetails);
    return CognitoUserInfo(email: email, confirmed: true);
  }

  @override
  Future<void> sendNewConfirm(String email) async {
    _cognitoUser?.resendConfirmationCode();
  }

  @override
  Future<bool>? changePassword(String oldPassword, String newPassword) {
    return _cognitoUser?.changePassword(oldPassword, newPassword);
  }

  @override
  Future forgotPassword(String email) async {
    email = email.toLowerCase();
    if (!(await hasSignedIn())) {
      _cognitoUser = CognitoUser(email, _userPool, storage: _userPool.storage);
    }
    return _cognitoUser!.forgotPassword();
  }

  @override
  Future<bool> confirmForgotPassword(
      String email, String confirmationCode, String newPassword) async {
    if (_cognitoUser == null || _userInfo?.email != email.toLowerCase()) {
      _cognitoUser = CognitoUser(email, _userPool, storage: _userPool.storage);
    }
    return _cognitoUser!.confirmPassword(confirmationCode, newPassword);
  }

  @override
  Future<CognitoUserInfo?> confirmEmailPasscode(
      String email, String passcode) async {
    _session = await _cognitoUser?.sendCustomChallengeAnswer(passcode);

    if (_session?.isValid() != true) {
      return null;
    }

    final attributes = await _cognitoUser?.getUserAttributes();
    if (attributes != null) {
      final user = CognitoUserInfo.fromUserAttributes(attributes);
      user.confirmed = true;
      user.hasAccess = true;
      return user;
    }

    return null;
  }

  @override
  Future<String> get storageToken => throw UnimplementedError();

  @override
  Future<String> get token => throw UnimplementedError();

  @override
  Future<CognitoUserInfo> signInOrSignUp(String email,
      {String? password, Function? signUpSuccess}) {
    if (_type == AuthenticationType.password) {
      return _submitEmailPasswordAuth(email, password!,
          signUpSuccess: signUpSuccess);
    } else {
      return _submitCustomChallengeAuth(email, signUpSuccess: signUpSuccess);
    }
  }

  Future<CognitoUserInfo> _submitCustomChallengeAuth(String email,
      {Function? signUpSuccess}) async {
    CognitoUserInfo result;
    try {
      var password = randomString(20);
      result = await _signUp(email, password, email);
      signUpSuccess?.call();
      result = await _submitCustomAuth(email);
      isNewUser = true;
    } on CognitoClientException catch (e) {
      if (e.code == 'UsernameExistsException') {
        // sign in
        result = await _submitCustomAuth(email);
        isNewUser = false;
      } else {
        rethrow;
      }
    }
    return result;
  }

  Future<CognitoUserInfo> _submitEmailPasswordAuth(
      String email, String password,
      {Function? signUpSuccess}) async {
    CognitoUserInfo result;
    try {
      result = await _signUp(email, password, email);
      signUpSuccess?.call();
      if (result.confirmed!) {
        await login(email, password);
      }
      isNewUser = true;
    } on CognitoClientException catch (e) {
      if (e.code == 'UsernameExistsException') {
        // sign in
        try {
          result = await login(email, password);
          isNewUser = false;
        } on CognitoClientException catch (e) {
          if (e.code == 'UserNotConfirmedException') {
            await sendNewConfirm(email);
            result = CognitoUserInfo(email: email, confirmed: false);
            isNewUser = true;
          } else {
            rethrow;
          }
        }
      } else {
        rethrow;
      }
    }
    return result;
  }

  /// Sign up user
  Future<CognitoUserInfo> _signUp(
      String email, String password, String name) async {
    email = email.toLowerCase();
    CognitoUserPoolData data;
    final userAttributes = [
      AttributeArg(name: 'name', value: name),
    ];
    data =
        await _userPool.signUp(email, password, userAttributes: userAttributes);
    isNewUser = true;
    return CognitoUserInfo(
        email: email, name: name, confirmed: data.userConfirmed);
  }

  /// Login user with custom authentication flow
  Future<CognitoUserInfo> _submitCustomAuth(String email) async {
    email = email.toLowerCase();
    _cognitoUser = CognitoUser(email, _userPool, storage: _userPool.storage);

    final authDetails = AuthenticationDetails(
        username: email, authParameters: [], validationData: {});

    try {
      _session = await _cognitoUser!.initiateAuth(authDetails);
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

  @override
  Future<void> deleteUser(String email) {
    throw UnimplementedError();
  }
}

class CognitoUserInfo {
  CognitoUserInfo({this.email, this.name, this.confirmed});

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

  bool? confirmed = false;
  String? email;
  bool hasAccess = false;
  String? id;
  String? name;
}

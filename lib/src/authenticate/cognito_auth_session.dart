import 'cognito_user.dart';

abstract class CognitoAuthSession {
  Future<CognitoUserInfo> signInOrSignUp(String email,
      {String password, Function signUpSuccess});

  Future<CognitoUserInfo> login(String email, String password,
      {bool passAuth = false});

  Future<void> sendNewConfirm(String email);

  Future<bool> changePassword(String oldPassword, String newPassword);

  Future forgotPassword(String email);

  Future<bool> confirmForgotPassword(String email,
      String confirmationCode, String newPassword);

  Future<CognitoUserInfo> confirmEmailPasscode(
      String email, String passcode);
}

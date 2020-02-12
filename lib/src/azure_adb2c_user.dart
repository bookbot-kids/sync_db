import 'package:shared_preferences/shared_preferences.dart';

import "abstract.dart";
import 'dart:math';
import 'package:jaguar_jwt/jaguar_jwt.dart';
import 'dart:convert';
import 'robust_http.dart';

class AzureADB2CUser extends User {
  static Database _database;
  HTTP _http;
  Map<String, dynamic> _config;
  Map<String, Map> _resourceTokens = {};
  DateTime _tokenExpiry = DateTime.now();
  SharedPreferences _prefs;

  /// Config will need:
  /// baseUrl for Azure functions
  /// azure_secret, azure_audience, azure_issuer, azure_audience for client token
  AzureADB2CUser(Map<String, dynamic> config, {String refreshToken}) {
    _config = config;
    _http = HTTP(config["azure_auth_url"], config);
    SharedPreferences.getInstance().then((value) {
      _prefs = value;
      if (refreshToken != null) {
        this.refreshToken = refreshToken;
      }

      if (this.refreshToken != null) {
        resourceTokens().then((Map<String, Map> map) {});
      }
    });
  }

  /// Will return either resource tokens that have not expired, or will connect to the web service to get new tokens
  /// When refresh is true it will get new resource tokens from web services
  Future<Map<String, Map>> resourceTokens([bool refresh = false]) async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }

    if (!(await hasSignedIn())) {
      return _resourceTokens;
    }

    if (_tokenExpiry.isAfter(DateTime.now()) && refresh == false) {
      return _resourceTokens;
    }

    final expired = DateTime.now().add(Duration(hours: 5));

    // Refresh token is an authorisation token to get different permissions for resource tokens
    // Azure functions also need a code
    final response = await _http.get('/GetResourceTokens', parameters: {
      "client_token": _clientToken(),
      "refresh_token": refreshToken,
      "code": _config['azure_code']
    });

    for (final permission in response["permissions"]) {
      _resourceTokens[permission["id"]] = permission;
    }
    _tokenExpiry = expired;

    return _resourceTokens;
  }

  set refreshToken(String token) {
    _prefs.setString("refresh_token", token);
  }

  String get refreshToken => _prefs.getString("refresh_token");

  Future<bool> hasSignedIn() async {
    return refreshToken != null && refreshToken.isNotEmpty;
  }

  /// Removes the refresh token from shared preferences
  void signout() {
    _prefs.remove('refresh_token');
  }

  /// Client Token is used to secure the anonymous web services.
  /// The token is made up of:
  /// Subject: Stores the user ID of the user to which the token is issued.
  /// Issuer: Authority issuing the token, like the business name, e.g. Bookbot
  /// Audience: The audience that uses this authentication e.g. com.bookbot.bookbotapp
  /// The secret is the key used for encoding
  String _clientToken() {
    var encodedKey = base64.encode(utf8.encode(_config["azure_secret"]));
    final claimSet = JwtClaim(
        subject: _config["azure_subject"],
        issuer: _config["azure_issuer"],
        audience: <String>[_config["azure_audience"]],
        notBefore: DateTime.now(),
        jwtId: Random().nextInt(10000).toString(),
        maxAge: const Duration(minutes: 5));

    return issueJwtHS256(claimSet, encodedKey);
  }
}

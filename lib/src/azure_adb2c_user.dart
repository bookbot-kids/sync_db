import "abstract.dart";
import 'dart:math';
import 'package:jaguar_jwt/jaguar_jwt.dart';
import 'dart:convert';
import 'robust_http.dart';

class AzureADB2CUser extends User {
  static Database _database;
  HTTP _http;
  Map<String, dynamic> _config;
  Map<String, Map>_resourceTokens = {};
  DateTime _tokenExpiry = DateTime.now();

  /// Config will need:
  /// baseUrl for Azure functions
  /// azure_secret, azure_audience, azure_issuer, azure_audience for client token
  AzureADB2CUser(Map<String, dynamic> config) {
    _config = config;
    _http = HTTP(config["azure_auth_url"], config);
    resourceTokens().then((Map<String, Map> map) {});
  }
  
  /// Will return either resource tokens that have not expired, or will connect to the web service to get new tokens
  /// When refresh is true it will get new resource tokens from web services
  Future<Map<String, Map>> resourceTokens([bool refresh = false]) async {
    if (_tokenExpiry.isAfter(DateTime.now()) && refresh == false) {
      return _resourceTokens;
    }

    final expired = DateTime.now().add(Duration(hours: 5));

    // Refresh token is an authorisation token to get different permissions for resource tokens
    // Azure functions also need a code
    // TODO: setup refresh token code to get from shared preferences
    final response = await _http.get('/GetResourceTokens', parameters: {
      "client_token": _clientToken(),
      "refresh_token": _config['refresh_token'],
      "code": _config['azure_code']});

    for (final permission in response["permissions"]) {
      _resourceTokens[permission["id"]] = permission;
    }
    _tokenExpiry = expired;

    return _resourceTokens;
  }

  /// Removes the refresh token from shared preferences
  void signout() {

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
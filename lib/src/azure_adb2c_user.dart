import "abstract.dart";
import 'dart:math';
import 'package:jaguar_jwt/jaguar_jwt.dart';
import 'dart:convert';
import 'robust_http.dart';

class AzureADB2CUser extends User {
  HTTP http;
  Map<String, dynamic> config;
  Map<String, String>_resourceTokens;
  DateTime _tokenExpiry;

  /// Config will need:
  /// baseUrl for Azure functions
  /// azure_secret, azure_audience, azure_issuer, azure_audience for client token
  AzureADB2CUser(Map<String, dynamic> config) {
    this.config = config;
    http = HTTP(config["baseUrl"], config);
    resourceTokens().then((Map<String, String> map) {});
  }
  
  /// Will return either resource tokens that have not expired, or will connect to the web service to get new tokens
  /// When refresh is true it will get new resource tokens from web services
  Future<Map<String, String>> resourceTokens([bool refresh = false]) async {
    if (_tokenExpiry.isAfter(DateTime.now()) && refresh == false) {
      return _resourceTokens;
    }

    // Refresh token is an authorisation token to get different permissions for resource tokens
    // Azure functions also need a code
    // TODO: setup refresh token code
    final response = await http.get('/GetResourceTokens', parameters: {
      "client_token": _clientToken(config),
      "refresh_token": config['refresh_token'],
      "code": config['azure_code']});

    final Map<String, dynamic> tokens = jsonDecode(response);
    _resourceTokens = tokens;
    _tokenExpiry = tokens["expired_at"];

    return tokens;
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
  static String _clientToken(Map<String, dynamic> conf) {
    var encodedKey = base64.encode(utf8.encode(conf["azure_secret"]));
    final claimSet = new JwtClaim(
        subject: conf["azure_subject"],
        issuer: conf["azure_issuer"],
        audience: <String>[conf["azure_audience"]],
        notBefore: new DateTime.now(),
        jwtId: new Random().nextInt(10000).toString(),
        maxAge: const Duration(minutes: 5));

    return issueJwtHS256(claimSet, encodedKey);
  }
}
import 'package:basic_utils/basic_utils.dart';
import 'package:robust_http/exceptions.dart';
import 'package:robust_http/robust_http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sync_db/src/network_time.dart';

import "abstract.dart";
import 'dart:math';
import 'package:jaguar_jwt/jaguar_jwt.dart';
import 'dart:convert';

class AzureADB2CUser extends BaseUser {
  static Database database;
  HTTP http;
  Map<String, dynamic> config;
  List<MapEntry> _resourceTokens = List();
  DateTime _tokenExpiry;
  SharedPreferences prefs;

  /// Config will need:
  /// baseUrl for Azure functions
  /// azure_secret, azure_audience, azure_issuer, azure_audience for client token
  AzureADB2CUser(Map<String, dynamic> config, {String refreshToken}) {
    this.config = config;
    NetworkTime.shared.now.then((value) {
      _tokenExpiry = value;
    });
    http = HTTP(config["azure_auth_url"], config);
    SharedPreferences.getInstance().then((value) {
      prefs = value;
      if (refreshToken != null) {
        this.refreshToken = refreshToken;
      }

      if (this.refreshToken != null) {
        resourceTokens().then((list) {});
      }
    });
  }

  /// Will return either resource tokens that have not expired, or will connect to the web service to get new tokens
  /// When refresh is true it will get new resource tokens from web services
  Future<List<MapEntry>> resourceTokens([bool refresh = false]) async {
    if (prefs == null) {
      prefs = await SharedPreferences.getInstance();
    }

    if (!(await hasSignedIn())) {
      return List<MapEntry>.from(_resourceTokens);
    }

    if (_tokenExpiry == null) {
      _tokenExpiry = await NetworkTime.shared.now;
    }

    var now = await NetworkTime.shared.now;
    if (_tokenExpiry.isAfter(now) && refresh == false) {
      return List<MapEntry>.from(_resourceTokens);
    }

    final expired = now.add(Duration(hours: 4, minutes: 45));

    // Refresh token is an authorisation token to get different permissions for resource tokens
    // Azure functions also need a code
    try {
      final response = await http.get('/GetResourceTokens', parameters: {
        "client_token": await clientToken(),
        "refresh_token": refreshToken,
        "code": config['azure_code']
      });

      _resourceTokens.clear();
      for (final permission in response["permissions"]) {
        _resourceTokens.add(MapEntry(permission["id"], permission));
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
    } catch (e) {
      if (e is UnexpectedResponseException) {
        try {
          if (e.response.statusCode == 401) {
            // token is expired, need to sign out user
            _resourceTokens.clear();
            await prefs.remove('refresh_token');
          }
        } catch (e) {
          // ignore
        }
      }
    }

    return List<MapEntry>.from(_resourceTokens);
  }

  Future<bool> get tokenValid async {
    return _tokenExpiry.isAfter(await NetworkTime.shared.now);
  }

  set refreshToken(String token) {
    prefs.setString("refresh_token", token);
  }

  String get refreshToken => prefs.getString("refresh_token");

  set role(String role) {
    prefs.setString("role", role);
  }

  String get role => prefs.getString("role");

  Future<bool> hasSignedIn() async {
    if (prefs == null) {
      prefs = await SharedPreferences.getInstance();
    }

    return refreshToken != null && refreshToken.isNotEmpty;
  }

  /// Removes the refresh token from shared preferences
  void signout() {
    prefs.remove('refresh_token');
  }

  /// Client Token is used to secure the anonymous web services.
  /// The token is made up of:
  /// Subject: Stores the user ID of the user to which the token is issued.
  /// Issuer: Authority issuing the token, like the business name, e.g. Bookbot
  /// Audience: The audience that uses this authentication e.g. com.bookbot.bookbotapp
  /// The secret is the key used for encoding
  Future<String> clientToken() async {
    var now = (await NetworkTime.shared.now).toLocal();
    var expiry = now.add(Duration(minutes: 10));
    var encodedKey = base64.encode(utf8.encode(config["azure_secret"]));
    final claimSet = JwtClaim(
        subject: config["azure_subject"],
        issuer: config["azure_issuer"],
        audience: <String>[config["azure_audience"]],
        notBefore: now,
        defaultIatExp: false,
        expiry: expiry,
        issuedAt: now,
        jwtId: Random().nextInt(10000).toString(),
        maxAge: const Duration(minutes: 10));

    return issueJwtHS256(claimSet, encodedKey);
  }
}

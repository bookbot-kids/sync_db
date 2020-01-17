import 'dart:convert';
import 'dart:io';

import 'package:sync_db/sync_db.dart';
import 'package:flutter_test/flutter_test.dart';

import 'token_helper.dart';

void main() {
  group('HTTP: ', () {
    setUp(() {
      HTTP.baseUrl = 'https://httpstat.us/';
      HTTP.connectTimeout = 3000;
      HTTP.receiveTimeout = 3000;
    });

    test('Test full url', () async {
      expect((await HTTP.get('https://httpstat.us/200')), equals(""));
    });

    test('Test path', () async {
      expect((await HTTP.get('200')), equals(""));
    });

    test('Test bad response gets exception', () async {
      expect(HTTP.get('500'), throwsException);
    });

    // test('Test timeout', () async {
    //   TestWidgetsFlutterBinding.ensureInitialized();
    //   expect(HTTP.get('https://httpstat.us/200?sleep=5000'), throwsException);
    // });

    test('Test getting resource tokens from refresh token', () async {
      // read json configs
      final file = new File('test_configs.json');
      final configs = jsonDecode(await file.readAsString());

      var clientToken = TokenHelper.getClientToken(
          configs["jwt_secret"],
          configs["jwt_subject"],
          configs["jwt_issuer"],
          configs["jwt_audience"]);
      var baseUrl = configs['auth_url'];
      var url = '/GetResourceTokens';
      var response = await HTTP.get(url, parameters: {
        // the token to prevent spam server
        "client_token": clientToken,
        // refresh token
        "refresh_token": configs['refresh_token'],
        // azure protected function code
        "code": configs['auth_code']
      }, options: {
        "baseUrl": baseUrl,
        // set timeout longer
        "connectTimeout": 10000,
        "receiveTimeout": 10000
      });

      print(response);
      expect(response['success'], true);
      expect(response['permissions'] != null, true);
    });
  });
}

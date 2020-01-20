import 'dart:convert';
import 'dart:io';

import 'package:sync_db/sync_db.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {
  group('HTTP: ', () {
    HTTP http;
    setUp(() {
      http = HTTP('https://httpstat.us/', {"connectTimeout": 3000, "receiveTimeout": 3000});
    });

    test('Test full url', () async {
      expect((await http.get('https://httpstat.us/200')), equals(""));
    });

    test('Test path', () async {
      expect((await http.get('200')), equals(""));
    });

    test('Test bad response gets exception', () async {
      expect(http.get('500'), throwsException);
    });

    test('Test timeout', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      expect(http.get('https://httpstat.us/200?sleep=5000'), throwsException);
    });

    test('Test getting resource tokens from refresh token', () async {
      final file = new File('test/test_conf.json');
      final config = jsonDecode(await file.readAsString());

      final user = AzureADB2CUser(config);
      final tokens = await user.resourceTokens();
      print(tokens);
      //expect(tokens.c)
    });

    // test('Test getting resource tokens from refresh token', () async {
    //   // read json configs
    //   final file = new File('test_configs.json');
    //   final conf = jsonDecode(await file.readAsString());

    //   var clientToken = TokenHelper.getClientToken(
    //       conf["cosmos_secret"],
    //       conf["cosmos_issuer"],
    //       conf["cosmos_subject"],
    //       conf["cosmos_audience"]);
    //   var baseUrl = conf['auth_url'];
    //   var url = '/GetResourceTokens';
    //   var response = await HTTP.get(url, parameters: {
    //     // the token to prevent spam server
    //     "client_token": clientToken,
    //     // refresh token
    //     "refresh_token": conf['refresh_token'],
    //     // azure protected function code
    //     "code": conf['auth_code']
    //   }, options: {
    //     "baseUrl": baseUrl,
    //     // set timeout longer
    //     "connectTimeout": 10000,
    //     "receiveTimeout": 10000
    //   });

    //   print(response);
    //   expect(response['success'], true);
    //   expect(response['permissions'] != null, true);
    // });
  });
}

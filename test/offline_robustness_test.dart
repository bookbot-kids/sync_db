import 'dart:async';
import 'dart:convert';

import 'package:amazon_cognito_identity_dart_2/cognito.dart' as cognito;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:robust_http/exceptions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sync_db/src/authenticate/timeout_http_client.dart';
import 'package:sync_db/sync_db.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NetworkTime', () {
    final time = NetworkTime.shared;

    tearDown(() {
      time.lookupForTesting = null;
      time.reset();
    });

    test('callers share the lookup in flight', () async {
      time.reset();
      final pending = Completer<int>();
      var lookups = 0;
      time.lookupForTesting = (address, timeout) {
        lookups++;
        return pending.future;
      };

      final first = time.offset();
      final second = time.offset();
      await time.now;
      expect(lookups, time.lookupServers.length);

      pending.complete(1000);
      expect(await first, 1000);
      expect(await second, 1000);
      expect(lookups, time.lookupServers.length);
    });

    test('now does not wait for an unknown offset', () async {
      time.reset();
      final pending = Completer<int>();
      time.lookupForTesting = (address, timeout) => pending.future;

      final before = DateTime.now();
      final now = await time.now.timeout(const Duration(milliseconds: 200));
      expect(now.difference(before).inSeconds.abs(), lessThan(1));

      pending.complete(60 * 60 * 1000);
      await time.offset();
      final shifted = await time.now;
      expect(shifted.difference(DateTime.now()).inMinutes, closeTo(60, 1));
    });

    test('a failing server does not hide a later answer', () async {
      time.reset();
      var index = 0;
      time.lookupForTesting = (address, timeout) async {
        final position = index++;
        if (position == 0) {
          throw Exception('unreachable');
        }
        await Future<void>.delayed(Duration(milliseconds: 10 * position));
        return 500 + position;
      };

      expect(await time.offset(), 501);
    });

    test('every server failing falls back to 0 and reports the error',
        () async {
      time.reset();
      time.lookupForTesting =
          (address, timeout) async => throw Exception('down $address');

      Object? reported;
      final offset = await time.offset(errorCallback: (e, _) => reported = e);
      expect(offset, 0);
      expect(reported, isA<Exception>());
    });
  });

  group('TimeoutHttpClient', () {
    test('passes a complete response through', () async {
      final client = TimeoutHttpClient(const Duration(seconds: 1),
          inner: MockClient((request) async => http.Response('{"a":1}', 200)));
      final response = await client.post(Uri.parse('https://example.com'));
      expect(response.statusCode, 200);
      expect(response.body, '{"a":1}');
    });

    test('times out a body that stalls after the headers', () async {
      final body = StreamController<List<int>>();
      addTearDown(body.close);
      final client = TimeoutHttpClient(const Duration(milliseconds: 100),
          inner: MockClient.streaming((request, _) async {
        body.add(utf8.encode('{"partial":'));
        return http.StreamedResponse(body.stream, 200);
      }));

      await expectLater(client.post(Uri.parse('https://example.com')),
          throwsA(isA<TimeoutException>()));
    });

    test('a stalled Cognito call fails instead of hanging', () async {
      final body = StreamController<List<int>>();
      addTearDown(body.close);
      final client = cognito.Client(
          region: 'us-west-1',
          client: TimeoutHttpClient(const Duration(milliseconds: 100),
              inner: MockClient.streaming((request, _) async {
            return http.StreamedResponse(body.stream, 200);
          })));

      await expectLater(client.request('InitiateAuth', {}),
          throwsA(isA<cognito.CognitoClientException>()));
    });
  });

  group('CognitoAzureUserSession.ensureSession', () {
    const clientId = 'sync-db-test-client';
    const prefix = 'CognitoIdentityServiceProvider.$clientId';

    Future<CognitoAzureUserSession> sessionWith(
        Map<String, Object> stored) async {
      SharedPreferences.setMockInitialValues(stored);
      final prefs = await SharedPreferences.getInstance();
      final session = CognitoAzureUserSession({
        'azureBaseUrl': 'https://sync-db-test.invalid',
        // A region that does not resolve: no request reaches a real pool.
        'cognitoPoolId': 'sync-db-test_pool',
        'cognitoClientId': clientId,
        'cognitoTimeout': 2000,
      }, autoRefresh: false, sharedPreferences: prefs);
      // Waits for the session restore to finish.
      await session.hasSignedIn();
      return session;
    }

    test('a guest without a Cognito user is not affected', () async {
      final session = await sessionWith({});
      await session.ensureSession();
      expect(await session.token, isNull);
    });

    test('a signed-in user whose session cannot be reached fails as offline',
        () async {
      const user = 'teacher@example.com';
      final session = await sessionWith({
        '$prefix.LastAuthUser': json.encode(user),
        // No ID token stored, so restoring the session needs Cognito.
        '$prefix.$user.refreshToken': json.encode('refresh-token'),
        'userRoleKey': 'teacher',
      });

      await expectLater(
          session.ensureSession(), throwsA(isA<ConnectivityException>()));
      expect(await session.token, isNull);
    });

    test('a user with no tokens stored carries on as before', () async {
      const user = 'teacher@example.com';
      final session =
          await sessionWith({'$prefix.LastAuthUser': json.encode(user)});
      await session.ensureSession();
      expect(await session.token, isNull);
    });
  });

  test('network failures are told apart from auth errors', () {
    final isNetwork = CognitoAzureUserSession.isNetworkError;
    expect(isNetwork(TimeoutException('slow')), isTrue);
    expect(isNetwork(ConnectivityException('offline')), isTrue);
    expect(
        isNetwork(cognito.CognitoClientException('Unknown Error',
            code: 'Unknown error')),
        isTrue);
    expect(
        isNetwork(cognito.CognitoClientException('SocketException',
            code: 'NetworkError')),
        isTrue);
    expect(
        isNetwork(cognito.CognitoClientException('Refresh Token has expired',
            code: 'NotAuthorizedException', statusCode: 400)),
        isFalse);
    expect(
        isNetwork(Exception('Local storage is missing an ID Token')), isFalse);
  });
}

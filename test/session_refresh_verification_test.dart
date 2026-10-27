import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:robust_http/connection_helper.dart';
import 'package:robust_http/exceptions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sync_db/sync_db.dart';

/// Added by the 2026-10-27 offline verification: the token-refresh guard in
/// CognitoAzureUserSession (single flight, bounded wait, 30 s connectivity
/// back-off, explicit refresh not held back), and NetworkTime.networkNow.
///
/// The probe in `refresh()` goes through ConnectionHelper, replaced here, so
/// every call fails before any request or database access.
class _Probe implements ConnectionHelper {
  var internetChecks = 0;
  Completer<bool>? hold;

  @override
  Future<bool> hasConnection({bool includeBluetooth = false}) async => true;

  @override
  Future<bool> hasInternetConnection({int? timeoutInSeconds}) {
    internetChecks++;
    return hold?.future ?? Future.value(false);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final original = ConnectionHelper.shared;
  late _Probe probe;

  setUp(() {
    probe = _Probe();
    ConnectionHelper.shared = probe;
  });
  tearDown(() => ConnectionHelper.shared = original);

  Future<CognitoAzureUserSession> guest({int? refreshTimeout}) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final session = CognitoAzureUserSession({
      'azureBaseUrl': 'https://sync-db-test.invalid',
      'cognitoPoolId': 'sync-db-test_pool',
      'cognitoClientId': 'sync-db-test-client',
      if (refreshTimeout != null) 'refreshTimeout': refreshTimeout,
    }, autoRefresh: false, sharedPreferences: prefs);
    await session.hasSignedIn();
    return session;
  }

  test('offline: a failed refresh holds back the next sync for a while, '
      'without probing again', () async {
    final session = await guest();

    await expectLater(session.servicePointsForTable('Word'),
        throwsA(isA<ConnectivityException>()));
    expect(probe.internetChecks, 1);

    await expectLater(
        session.servicePointsForTable('Word'),
        throwsA(isA<ConnectivityException>().having(
            (e) => e.toString(), 'message', contains('Skipped token refresh'))));
    expect(probe.internetChecks, 1, reason: 'within the back-off: no probe');
  });

  test('an explicit refresh() is not held back by the back-off', () async {
    final session = await guest();
    await expectLater(session.servicePointsForTable('Word'),
        throwsA(isA<ConnectivityException>()));

    await expectLater(session.refresh(), throwsA(isA<ConnectivityException>()));
    expect(probe.internetChecks, 2);
  });

  test('concurrent syncs share one refresh', () async {
    final session = await guest();
    probe.hold = Completer<bool>();

    final first = session.servicePointsForTable('Word');
    final second = session.servicePointsForTable('Book');
    final firstDone = expectLater(first, throwsA(isA<ConnectivityException>()));
    final secondDone =
        expectLater(second, throwsA(isA<ConnectivityException>()));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(probe.internetChecks, 1);

    probe.hold!.complete(false);
    await firstDone;
    await secondDone;
    expect(probe.internetChecks, 1);
  });

  test('a refresh that never answers is given up on, and does not block the '
      'next caller', () async {
    final session = await guest(refreshTimeout: 100);
    probe.hold = Completer<bool>(); // never completed

    final watch = Stopwatch()..start();
    await expectLater(
        session.servicePointsForTable('Word'),
        throwsA(isA<ConnectivityException>()
            .having((e) => e.toString(), 'message', contains('timed out'))));
    expect(watch.elapsedMilliseconds, lessThan(2000));

    // The next one fails fast on the back-off instead of joining the stuck
    // refresh.
    watch.reset();
    await expectLater(session.servicePointsForTable('Word'),
        throwsA(isA<ConnectivityException>()));
    expect(watch.elapsedMilliseconds, lessThan(500));
  });

  group('NetworkTime.networkNow', () {
    final time = NetworkTime.shared;
    tearDown(() {
      time.lookupForTesting = null;
      time.reset();
    });

    test('waits for an offset that is still being looked up', () async {
      time.reset();
      final pending = Completer<int>();
      time.lookupForTesting = (address, timeout) => pending.future;

      final network = time.networkNow;
      var resolved = false;
      unawaited(network.then((_) => resolved = true));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(resolved, isFalse);

      pending.complete(2 * 60 * 60 * 1000);
      final value = await network;
      expect(value.difference(DateTime.now()).inMinutes, closeTo(120, 1));
    });

    test('after an all-servers failure the 0 offset is kept for the session '
        '(documents current behaviour: no retry once the network is back)',
        () async {
      time.reset();
      time.lookupForTesting = (address, timeout) async => throw Exception('x');
      expect(await time.offset(), 0);

      var asked = 0;
      time.lookupForTesting = (address, timeout) async {
        asked++;
        return 60 * 60 * 1000;
      };
      final value = await time.networkNow;
      expect(asked, 0);
      expect(value.difference(DateTime.now()).inMinutes.abs(), lessThan(1));
    });
  });
}

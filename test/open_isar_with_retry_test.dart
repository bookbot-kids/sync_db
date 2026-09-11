import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:sync_db/src/database/open_isar_with_retry.dart';

void main() {
  for (final code in [11, -30784]) {
    test('recovers from temporary environment error $code', () async {
      var calls = 0;
      final waits = <Duration>[];
      final result = await openIsarWithRetry(() async {
        if (++calls < 3) {
          throw IsarError('Cannot open Environment: MdbxError ($code): test');
        }
        return 'opened';
      }, delay: (duration) async => waits.add(duration));
      expect(result, 'opened');
      expect(calls, 3);
      expect(waits, [
        const Duration(milliseconds: 100),
        const Duration(milliseconds: 250)
      ]);
    });
  }

  test('persistent incompatibility preserves original error and stops',
      () async {
    final error = IsarError(
        'Cannot open Environment: MdbxError (-30784): MDBX_INCOMPATIBLE');
    var calls = 0;
    await expectLater(
        openIsarWithRetry(() async {
          calls++;
          throw error;
        }, delay: (_) async {}),
        throwsA(same(error)));
    expect(calls, 5);
  });

  test('does not retry disk full, corruption, or non-open errors', () async {
    for (final message in [
      'Cannot open Environment: MdbxError (28): No space left on device',
      'Cannot open Environment: MdbxError (-30796): MDBX_CORRUPTED',
      'MdbxError (11): transaction failed',
    ]) {
      final error = IsarError(message);
      var calls = 0;
      await expectLater(
          openIsarWithRetry(() async {
            calls++;
            throw error;
          }, delay: (_) async {}),
          throwsA(same(error)));
      expect(calls, 1);
    }
  });

  test('waits for explicit recovery before a fresh retry budget', () async {
    var calls = 0;
    var recoveries = 0;
    var permitted = false;
    final result = await openIsarWithRetry(
        () async {
          calls++;
          if (!permitted) {
            throw IsarError(
                'Cannot open Environment: MdbxError (11): Try again');
          }
          return 42;
        },
        delay: (_) async {},
        onOpenFailure: (error, stack) async {
          expect(calls, 5);
          recoveries++;
          permitted = true;
        });
    expect(result, 42);
    expect(recoveries, 1);
    expect(calls, 6);
  });
}

import 'package:flutter/foundation.dart';
import 'package:sync_db/sync_db.dart';

class TraceUtil {
  /// Log executing function time
  static Future<void> traceTime(String logMessage, Function func) async {
    if (kDebugMode) {
      final stopwatch = Stopwatch()..start();
      await func();
      Sync.shared.logger
          ?.i('$logMessage took ${stopwatch.elapsedMilliseconds}ms');
    } else {
      await func();
    }
  }
}

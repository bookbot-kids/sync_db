import 'package:flutter/foundation.dart';
import 'package:ntp/ntp.dart';
import 'package:singleton/singleton.dart';
import 'package:sync_db/sync_db.dart';
import 'package:universal_io/io.dart';
import 'package:collection/collection.dart';

class NetworkTime {
  factory NetworkTime() =>
      Singleton.lazy(() => NetworkTime._privateConstructor());
  NetworkTime._privateConstructor();
  static NetworkTime shared = NetworkTime();

  int? _offset;
  final lookupServers = [
    'time.google.com',
    'time.windows.com',
    'time.apple.com',
    '1.pool.ntp.org',
  ];

  /// Get server datetime and cache the offset
  Future<int?> get offset async {
    if (kIsWeb) {
      // not support for web yet
      return 0;
    }

    if (_offset == null) {
      final futures = <Future<int?>>[];
      for (final address in lookupServers) {
        futures.add(Future.sync(() async {
          try {
            return await NTP
                .getNtpOffset(
                  localTime: DateTime.now().toLocal(),
                  lookUpAddress: address,
                )
                .timeout(const Duration(seconds: 5));
          } catch (e, stacktrace) {
            Sync.shared.logger?.e('Can not get server time [${address}] $e',
                error: e, stackTrace: stacktrace);
            // Sync.shared.exceptionNotifier.value = Tuple3(false, e, stacktrace);
          }

          return null;
        }));
      }

      final results = await Future.wait(futures);
      _offset = results.whereNotNull().firstOrNull ?? 0;
      Sync.shared.logger?.i('Get ntp offset $_offset');
    }

    return _offset;
  }

  /// Get current datetime base on server offset
  Future<DateTime> get now async {
    if (kIsWeb) {
      // not support for web yet
      return DateTime.now();
    }

    final offsetValue = await offset;
    if (offsetValue == null || offsetValue == 0) {
      return DateTime.now();
    }

    return DateTime.now().toLocal().add(Duration(milliseconds: offsetValue));
  }

  /// Get current datetime base on server offset
  DateTime get timeNow {
    if (kIsWeb) {
      // not support for web yet
      return DateTime.now();
    }

    if (_offset == null || _offset == 0) {
      return DateTime.now();
    }

    return DateTime.now().toLocal().add(Duration(milliseconds: _offset!));
  }

  @visibleForTesting
  void setOffsetForTesting(int offset) {
    _offset = offset;
  }

  /// Reset the offset
  void reset() {
    // just set 0 for iOS (to use local)
    if (Platform.isIOS && _offset != null) {
      _offset = 0;
    } else {
      _offset = null;
    }
  }
}

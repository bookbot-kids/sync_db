import 'package:flutter/foundation.dart';
import 'package:ntp/ntp.dart';
import 'package:singleton/singleton.dart';
import 'package:sync_db/sync_db.dart';
import 'package:tuple/tuple.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:collection/collection.dart';

class NetworkTime {
  factory NetworkTime() =>
      Singleton.lazy(() => NetworkTime._privateConstructor());
  NetworkTime._privateConstructor();
  static NetworkTime shared = NetworkTime();

  int? _offset;
  final lookupServers = [
    'time.google.com',
    'time.apple.com',
    'time.windows.com'
  ];

  /// Get server datetime and cache the offset
  Future<int?> get offset async {
    if (UniversalPlatform.isWeb) {
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
                .timeout(const Duration(seconds: 7));
          } catch (e, stacktrace) {
            Sync.shared.logger
                ?.e('Can not get server time [${address}] $e', e, stacktrace);
            Sync.shared.exceptionNotifier.value = Tuple3(false, e, stacktrace);
          }

          return null;
        }));
      }

      final results = await Future.wait(futures);
      _offset = results.whereNotNull().firstOrNull;
    }

    return _offset;
  }

  /// Get current datetime base on server offset
  Future<DateTime> get now async {
    if (UniversalPlatform.isWeb) {
      // not support for web yet
      return DateTime.now();
    }

    var offsetValue = await offset;
    if (offsetValue == null) {
      return DateTime.now();
    }

    return DateTime.now().toLocal().add(Duration(milliseconds: offsetValue));
  }

  /// Get current datetime base on server offset
  DateTime get timeNow {
    if (UniversalPlatform.isWeb) {
      // not support for web yet
      return DateTime.now();
    }

    if (_offset == null) {
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
    _offset = null;
  }
}

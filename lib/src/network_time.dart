import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:ntp/ntp.dart';
import 'package:singleton/singleton.dart';
import 'package:sync_db/sync_db.dart';
import 'package:universal_io/io.dart';

class NetworkTime {
  factory NetworkTime() =>
      Singleton.lazy(() => NetworkTime._privateConstructor());
  NetworkTime._privateConstructor();
  static NetworkTime shared = NetworkTime();

  int? _offset;

  /// The lookup in flight, shared by every caller that asks while it runs, so
  /// a burst of saves starts one round of NTP requests instead of one each.
  Future<int>? _pendingLookup;

  /// Replaces the NTP request in tests.
  @visibleForTesting
  Future<int> Function(String address, Duration timeout)? lookupForTesting;

  final lookupServers = [
    'time.google.com',
    'time.windows.com',
    'time.apple.com',
    '1.pool.ntp.org',
  ];

  /// Get server datetime and cache the offset
  Future<int?> offset(
      {Duration timeout = const Duration(seconds: 5),
      Function(dynamic, StackTrace)? errorCallback}) async {
    if (kIsWeb) {
      // not support for web yet
      return 0;
    }

    if (_offset == null) {
      final lookup = _pendingLookup ??= _lookupOffset(timeout);
      try {
        _offset = await lookup;
      } catch (e, stacktrace) {
        _offset = 0;
        errorCallback?.call(e, stacktrace);
      } finally {
        if (identical(_pendingLookup, lookup)) {
          _pendingLookup = null;
        }
      }
    }

    return _offset;
  }

  /// Ask every server and take the first answer. `Future.any` would stop at the
  /// first *error* too, so one unreachable server would throw away the others.
  Future<int> _lookupOffset(Duration timeout) async {
    final servers = List<String>.from(lookupServers);
    final completer = Completer<int>();
    var failures = 0;
    for (final address in servers) {
      unawaited(
          Future.sync(() => _lookupServer(address, timeout)).then((value) {
        if (!completer.isCompleted) {
          completer.complete(value);
        }
      }, onError: (Object e, StackTrace stackTrace) {
        failures++;
        if (failures == servers.length && !completer.isCompleted) {
          completer.completeError(e, stackTrace);
        }
      }));
    }

    if (servers.isEmpty) {
      completer.completeError(StateError('No ntp servers to look up'));
    }

    try {
      final value = await completer.future;
      Sync.shared.logger?.i('Get ntp offset $value');
      return value;
    } catch (e) {
      Sync.shared.logger?.i('Get ntp offset failed $e');
      rethrow;
    }
  }

  Future<int> _lookupServer(String address, Duration timeout) {
    final lookup = lookupForTesting;
    if (lookup != null) {
      return lookup(address, timeout);
    }

    return NTP
        .getNtpOffset(
          localTime: DateTime.now().toLocal(),
          lookUpAddress: address,
        )
        .timeout(timeout);
  }

  /// Get current datetime base on server offset.
  ///
  /// Never waits on the network: while the offset is unknown this is the
  /// device time, and the lookup runs in the background. A save calls this
  /// inside its write transaction, which must not sit behind an NTP timeout.
  /// Use [networkNow] where a request will be rejected for a skewed clock.
  Future<DateTime> get now async {
    if (kIsWeb) {
      // not support for web yet
      return DateTime.now();
    }

    if (_offset == null) {
      unawaited(offset());
    }

    return timeNow;
  }

  /// Like [now], but waits for the offset lookup (bounded by its timeout) when
  /// it is not known yet. For request headers and tokens a server checks
  /// against its own clock; such a request needs the network anyway.
  Future<DateTime> get networkNow async {
    if (kIsWeb) {
      // not support for web yet
      return DateTime.now();
    }

    await offset();
    return timeNow;
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

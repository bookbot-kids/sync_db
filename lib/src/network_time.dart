import 'package:flutter/foundation.dart';
import 'package:ntp/ntp.dart';
import 'package:singleton/singleton.dart';
import 'package:universal_platform/universal_platform.dart';

class NetworkTime {
  factory NetworkTime() =>
      Singleton.lazy(() => NetworkTime._privateConstructor()).instance;
  NetworkTime._privateConstructor();
  static NetworkTime shared = NetworkTime();

  int _offset;

  /// Get server datetime and cache the offset
  Future<int> get offset async {
    if (UniversalPlatform.isWeb) {
      // not support for web yet
      return 0;
    }

    if (_offset == null) {
      try {
        _offset = await NTP.getNtpOffset(localTime: DateTime.now().toLocal());
      } catch (e) {
        _offset = null;
      }
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

    return DateTime.now().toLocal().add(Duration(milliseconds: _offset));
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

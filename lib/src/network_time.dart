import 'package:ntp/ntp.dart';
import 'package:universal_platform/universal_platform.dart';

class NetworkTime {
  NetworkTime._privateConstructor();
  static NetworkTime shared = NetworkTime._privateConstructor();

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
        print('server offset $_offset');
      } catch (e) {
        print('get server offset error $e');
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

    return DateTime.now()
        .toLocal()
        .add(Duration(milliseconds: offsetValue));
  }

  /// Reset the offset
  void reset() {
    _offset = null;
  }
}

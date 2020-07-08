import 'package:ntp/ntp.dart';

class NetworkTime {
  NetworkTime._privateConstructor();
  static NetworkTime shared = NetworkTime._privateConstructor();

  int _offset;

  /// Get server datetime and cache the offset
  Future<int> get offset async {
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
    var offsetValue = await offset;
    return DateTime.now()
        .toLocal()
        .add(Duration(milliseconds: offsetValue ?? 0));
  }

  /// Reset the offset
  void reset() {
    _offset = null;
  }
}

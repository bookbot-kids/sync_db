import 'package:logger/logger.dart';
import 'package:robust_http/http_log_adapter.dart';

/// An adapter to set [Logger] for this package
///
/// [Logger]:(https://pub.dev/packages/logger)
class SyncLogAdapter {
  SyncLogAdapter._privateConstructor();
  static SyncLogAdapter shared = SyncLogAdapter._privateConstructor();

  /// Logger instance to write log, must be set before using
  Logger _logger;

  Logger get logger {
    return _logger;
  }

  /// Set the same logger instance for http
  set logger(Logger value) {
    _logger = value;
    if (HttpLogAdapter.shared.logger == null) {
      HttpLogAdapter.shared.logger = value;
    }
  }
}

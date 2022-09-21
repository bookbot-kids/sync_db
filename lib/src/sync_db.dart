import 'package:isar/isar.dart';
import 'package:robust_http/connection_helper.dart';
import 'package:singleton/singleton.dart';
import 'package:sync_db/sync_db.dart';
import 'package:logger/logger.dart';
import 'package:tuple/tuple.dart';

class Sync {
  factory Sync() => Singleton.lazy(() => Sync._privateConstructor());
  Sync._privateConstructor();
  static Sync shared = Sync();

  Service? service;
  UserSession? userSession;
  Logger? logger;
  Storage? storage;
  List<SyncDelegate> delegates = [];
  late IsarDatabase db;
  final networkNotifier = Notifier<bool>(true);
  final exceptionNotifier =
      Notifier<Tuple2<dynamic, dynamic>>(Tuple2(null, null));

  bool _hasConnection = true;
  bool _hasInternet = true;
  var _isListening = false;

  bool get networkAvailable => _hasConnection && _hasInternet;

  Future<bool> connectivity() async {
    _hasConnection = await ConnectionHelper.shared.hasConnection();
    if (!_hasConnection) {
      networkNotifier.value = false;
      return false;
    }

    _hasInternet = await ConnectionHelper.shared.hasInternetConnection();
    if (!_hasInternet) {
      networkNotifier.value = false;
      return false;
    }

    return true;
  }

  /// Check for internet changed every minute
  Future<void> listenInternetChangedIfNeeded() async {
    await connectivity();
    if (networkAvailable) {
      // internet available, do nothing
      return;
    }

    if (_isListening) {
      return;
    }

    _isListening = true;
    ConnectionHelper.shared.listenInternetChanged((hasInternet) {
      _hasInternet = hasInternet;
      // ignore checking network state because there is internet connection
      networkNotifier.value = _hasInternet;
      if (hasInternet) {
        // unregister listener when internet is available
        ConnectionHelper.shared.unlistenInternetChanged();
        _isListening = false;
      }
    }, delayedInSeconds: 30);
  }
}

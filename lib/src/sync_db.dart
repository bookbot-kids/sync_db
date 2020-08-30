import 'package:robust_http/http_log_adapter.dart';

import 'abstract.dart';
import 'package:logger/logger.dart';

class SyncDB {
  SyncDB._privateConstructor();

  static SyncDB shared = SyncDB._privateConstructor();

  Database local;
  Logger logger;
  Sync sync;
  UserSession user;

  static void config(Sync sync, UserSession user, Logger logger, Database db) {
    shared.local = db;
    shared.logger = logger;
    shared.user = user;
    HttpLogAdapter.shared.logger = logger;
  }
}

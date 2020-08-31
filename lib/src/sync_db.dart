import 'package:robust_http/http_log_adapter.dart';
import 'package:sync_db/sync_db.dart';

import 'abstract.dart';
import 'package:logger/logger.dart';

class Sync {
  Sync._privateConstructor();
  static Sync shared = Sync._privateConstructor();

  Database local;
  Service service;
  UserSession user;

  static void config(
      Service service, UserSession user, Logger logger, Database db) {
    shared.service = service;
    shared.local = db;
    shared.logger = logger;
    shared.user = user;
    HttpLogAdapter.shared.logger = logger;
  }
}

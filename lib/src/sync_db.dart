import 'package:sync_db/sync_db.dart';
import 'package:logger/logger.dart';

class Sync {
  Sync._privateConstructor();
  static Sync shared = Sync._privateConstructor();

  Database local;
  Service service;
  UserSession userSession;
  Logger logger;

  static void config(
      Service service, UserSession userSession, Logger logger, Database db) {
    shared.service = service;
    shared.local = db;
    shared.logger = logger;
    shared.userSession = userSession;
  }
}

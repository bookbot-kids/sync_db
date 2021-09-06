import 'package:sync_db/src/services/sync_delegate.dart';
import 'package:sync_db/sync_db.dart';
import 'package:logger/logger.dart';

class Sync {
  Sync._privateConstructor();
  static Sync shared = Sync._privateConstructor();

  Database local;
  Service service;
  UserSession userSession;
  Logger logger;
  Storage storage;
  List<SyncDelegate> delegates = [];
}

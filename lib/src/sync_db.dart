import 'package:singleton/singleton.dart';
import 'package:sync_db/sync_db.dart';
import 'package:logger/logger.dart';

class Sync {
  factory Sync() => Singleton.lazy(() => Sync._privateConstructor()).instance;
  Sync._privateConstructor();
  static Sync shared = Sync();

  Database local;
  Service service;
  UserSession userSession;
  Logger logger;
  Storage storage;
  List<SyncDelegate> delegates = [];
}

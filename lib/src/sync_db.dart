import 'abstract.dart';
import 'package:logger/logger.dart';

class SyncDB {
  SyncDB._privateConstructor();
  static SyncDB shared = SyncDB._privateConstructor();

  Database local;
  Sync sync;
  UserSession user;
  Logger logger;
}

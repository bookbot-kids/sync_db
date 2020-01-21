import "abstract.dart";

class CosmosSync extends Sync {
  Database _database;
  User _user;
  
  Map<String, dynamic> _tableReadLock;
  Map<String, dynamic> _tableWriteLock;

  void syncAll() {

  }

  void syncRead(String table) {

  }
  
  void syncWrite(String table) {

  }
}
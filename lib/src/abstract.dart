import 'package:flutter/foundation.dart';
import 'query.dart';

abstract class UserSession {
  /// If access token is current (not expired), returns the access token _accessToken. Otherwises uses the refresh token to get a new access token.
  /// Refresh token is stored in Shared Preferences.
  Future<List<MapEntry>> resourceTokens([bool refresh = false]);

  void signout();

  Future<bool> hasSignedIn();

  set refreshToken(String token);

  String get refreshToken;

  set role(String role);

  String get role;

  Future<bool> get tokenValid;
}

abstract class Sync {
  /// Sync all tables
  Future<void> syncAll();

  /// Sync read a table
  Future<void> syncRead(String table, dynamic permission);

  /// Sync write a table
  Future<void> syncWrite(String table, dynamic permission);

  /// Sync write a record
  Future<void> syncWriteRecord(
      String table, Map<String, dynamic> map, bool isCreated,
      [bool refresh]);

  /// Sync read, write for one table only
  Future<void> syncTable(String table, [bool refresh]);

  /// Delete a record
  Future<void> deleteRecord(String table, String id, [bool refreh]);
}

abstract class Database {
  void saveMap(String tableName, String id, Map map,
      {int updatedAt, String status, dynamic transaction});

  Future<void> save(Model model, {bool syncToCloud});

  bool hasTable(String tableName);

  dynamic all(String modelName, Function instantiateModel);

  dynamic find(String modelName, String id, Model model);

  dynamic query<T>(Query query, {dynamic transaction});

  Future<void> delete(Model model);

  Future<void> deleteLocal(String modelName, String id);

  Future<void> runInTransaction(String tableName, Function action);
}

abstract class Model extends ChangeNotifier {
  DateTime createdAt;
  DateTime deletedAt;
  String id;
  DateTime updatedAt;

  Database _database;

  Database get database => _database;

  set database(Database database) => _database = database;

  Map<String, dynamic> get map;

  set map(Map<String, dynamic> map);

  String get storeName => "Model";

  String toString() => map.toString();

  Future<void> save() async => await this.database.save(this);

  Future<void> delete() => throw UnimplementedError();
}

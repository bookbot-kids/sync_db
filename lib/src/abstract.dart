import 'package:flutter/foundation.dart';
import 'package:sync_db/sync_db.dart';

const statusKey = '_status';
const idKey = 'id';
const updatedKey = 'updatedAt';
const createdKey = 'createdAt';
const deletedKey = 'deletedAt';

abstract class UserSession {
  set token(String token);
  Future<List<ServicePoint>> servicePoints();
  Future<List<ServicePoint>> servicePointsForTable(String table);
  Future<bool> hasSignedIn();
  String get role;
  Future<void> signout();
}

abstract class Database {
  Future<void> save(Model model, {bool syncToService});

  void saveMap(String tableName, Map map, {dynamic transaction});

  bool hasTable(String tableName);

  dynamic all(String modelName, Function instantiateModel);

  dynamic find(String modelName, String id, Model model);
  dynamic findMap(String modelName, String id);

  dynamic query<T>(Query query, {dynamic transaction});

  dynamic queryMap(Query query, {dynamic transaction});

  Future<void> delete(Model model);

  Future<void> deleteLocal(String modelName, String id);

  Future<void> runInTransaction(String tableName, Function action);

  /// clear all data in all tables
  Future<void> cleanDatabase();
}

abstract class Model extends ChangeNotifier {
  Database get database => Sync.shared.local;

  DateTime createdAt;
  DateTime deletedAt;
  String id;
  DateTime updatedAt;

  Map<String, dynamic> get map => {};

  set map(Map<String, dynamic> map) {}

  String get tableName => 'Model';

  Future<void> save() async => await database.save(this);

  Future<void> delete() => throw UnimplementedError();
}

import 'package:flutter/foundation.dart';
import 'package:sync_db/sync_db.dart';

const statusKey = '_status';
const idKey = 'id';
const updatedKey = 'updatedAt';
const createdKey = 'createdAt';
const deletedKey = 'deletedAt';

abstract class UserSession {
  set token(String token);
  Future<void> forceRefresh();
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
  dynamic findMap(String modelName, String id, {dynamic transaction});

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

  Map<String, dynamic> get map {
    var map = <String, dynamic>{};
    map[idKey] = id;
    map.putIfAbsent(createdKey, () => createdAt?.millisecondsSinceEpoch);
    map.putIfAbsent(updatedKey, () => updatedAt?.millisecondsSinceEpoch);
    if (deletedAt != null) {
      map[deletedKey] = deletedAt.millisecondsSinceEpoch;
    }

    return map;
  }

  set map(Map<String, dynamic> map) {
    id = map[idKey];
    if (map[createdKey] is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(map[createdKey]);
    }

    if (map[updatedAt] is int) {
      updatedAt = DateTime.fromMillisecondsSinceEpoch(map[updatedAt]);
    }

    if (map[deletedKey] is int) {
      deletedAt = DateTime.fromMillisecondsSinceEpoch(map[deletedKey]);
    }
  }

  String get tableName => throw UnimplementedError();

  Future<void> save() async => await database.save(this);

  Future<void> delete() async {
    deletedAt = await NetworkTime.shared.now;
    await save();
  }

  @override
  String toString() {
    return map.toString();
  }
}

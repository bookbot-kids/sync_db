import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sync_db/sync_db.dart';

const statusKey = '_status';
const idKey = 'id';
const updatedKey = 'updatedAt';
const createdKey = 'createdAt';
const deletedKey = 'deletedAt';

abstract class UserSession {
  Future<void> setToken(String token);

  Future<void> refresh();

  Future<List<ServicePoint>> servicePoints();

  Future<List<ServicePoint>> servicePointsForTable(String table);

  Future<bool> hasSignedIn();

  String get role;

  Future<void> signout();
}

abstract class Database {
  Future<void> save(Model model, {bool syncToService});

  Future<void> saveMap(String tableName, Map map, {dynamic transaction});

  Future<void> initTable(String tableName);

  dynamic all(String modelName, Function instantiateModel,
      {bool listenable = false});

  dynamic find(String modelName, String id, Model model,
      {bool listenable = false});

  dynamic findMap(String modelName, String id, {dynamic transaction});

  dynamic query<T extends Model>(Query query,
      {dynamic transaction, bool listenable = false});

  dynamic queryMap(Query query, {dynamic transaction});

  Future<void> clearTable(String tableName);

  Future<void> delete(Model model);

  Future<void> deleteLocal(String modelName, String id);

  Future<void> runInTransaction(String tableName, Function action);

  /// clear all data in all tables
  Future<void> cleanDatabase();

  /// Export database into json files in /export folder
  Future<void> export(List<String> tableNames);

  /// Import `data` map (table, json) into database
  Future<void> import(Map<String, Map> data);
}

class Notifier<T> extends ChangeNotifier {
  T _value;
  Notifier();

  T get value => _value;

  set value(T value) {
    _value = value;
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }

  void notify() {
    notifyListeners();
  }
}

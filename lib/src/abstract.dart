import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sync_db/sync_db.dart';

const statusKey = '_status';
const idKey = 'id';
const updatedKey = 'updatedAt';
const createdKey = 'createdAt';
const deletedKey = 'deletedAt';

abstract class UserSession {
  /// set login token. In azure b2c, it's id token
  Future<void> setToken(String token, {bool waitingRefresh = false});

  Future<String> get token;

  /// Get new token
  Future<void> refresh({bool forceRefreshToken = false});

  /// provide list of table with read/write permission
  Future<List<ServicePoint>> servicePoints();

  /// provide permission for a table
  Future<List<ServicePoint>> servicePointsForTable(String table);

  Future<bool> hasSignedIn();

  /// user role
  String get role;

  /// sign out user & clear all private keys
  Future<void> signout({bool notify = true});

  /// provide storage token to upload/download file
  Future<String> get storageToken;
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
}

class Notifier<T> extends ChangeNotifier {
  T _value;
  Notifier(this._value);

  T get value => _value;

  set value(T value) {
    _value = value;
    notifyListeners();
  }

  // Only update value without call [notifyListeners]
  void updateValue(T value) {
    _value = value;
  }

  void refresh() {
    notifyListeners();
  }

  void notify() {
    notifyListeners();
  }
}

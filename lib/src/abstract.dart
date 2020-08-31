import 'package:flutter/foundation.dart';
import 'package:sync_db/sync_db.dart';

abstract class UserSession {
  /// If access token is current (not expired), returns the access token _accessToken. Otherwises uses the refresh token to get a new access token.
  /// Refresh token is stored in Shared Preferences.
  Future<List<MapEntry>> resourceTokens();

  Future<void> signout();

  Future<bool> hasSignedIn();

  set refreshToken(String token);

  String get refreshToken;

  set role(String role);

  String get role;

  Future<void> refresh();
}

abstract class Database {
  void saveMap(String tableName, String id, Map map,
      {int updatedAt, String status, dynamic transaction});

  Future<void> save(Model model, {bool syncToService});

  bool hasTable(String tableName);

  dynamic all(String modelName, Function instantiateModel);

  dynamic find(String modelName, String id, Model model);

  dynamic query<T>(Query query, {dynamic transaction});

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

  Map<String, dynamic> get map;

  set map(Map<String, dynamic> map);

  String get tableName => 'Model';

  @override
  String toString() => map.toString();

  Future<void> save() async => await database.save(this);

  Future<void> delete() => throw UnimplementedError();
}

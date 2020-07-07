import 'package:flutter/foundation.dart';
import 'query.dart';

//AzureADB2CUser user = AzureADB2CUser.shared;
//CosmosSync sync = CosmosSync.shared;
//Database db = SemBastDatabase.shared;

abstract class BaseUser {
  /// If access token is current (not expired), returns the access token _accessToken. Otherwises uses the refresh token to get a new access token.
  /// Refresh token is stored in Shared Preferences.
  Future<List<MapEntry>> resourceTokens([bool refresh = false]);
  void signout();
  Future<bool> hasSignedIn();
  set refreshToken(String token);
  String get refreshToken;
  set role(String role);
  String get role;
  bool get tokenValid;
}

abstract class Sync {
  Future<void> syncAll();
  Future<void> syncRead(String table, dynamic permission);
  Future<void> syncWrite(String table, dynamic permission);
  Future<void> syncWriteOne(
      String table, Map<String, dynamic> map, bool isCreated,
      [bool refresh]);

  /// Sync read, write for one table only
  Future<void> syncOne(String table, [bool refresh]);
  Future<void> deleteOne(String table, String id, [bool refreh]);
}

abstract class Database {
  void saveMap(String tableName, String id, Map map,
      {int updatedAt, String status, dynamic transaction});
  Future<void> save(Model model);
  bool hasTable(String tableName);
  dynamic all(String modelName, Function instantiateModel);
  dynamic find(String modelName, String id, Model model);
  dynamic query<T>(Query query, {dynamic transaction});
  Future<void> delete(Model model);
  Future<void> deleteLocal(String modelName, String id);
  Future<void> runInTransaction(String tableName, Function action);
}

abstract class Model extends ChangeNotifier {
  static Database database;

  String id;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime deletedAt;

  //Functions to override

  Map<String, dynamic> export() {
    var map = Map<String, dynamic>();
    map["id"] = id;
    map["createdAt"] = createdAt;
    map["updatedAt"] = updatedAt;
    if (deletedAt != null) {
      map["deletedAt"] = deletedAt?.millisecondsSinceEpoch;
    }

    return map;
  }

  void import(Map<String, dynamic> map) {
    id = map["id"];
    createdAt = map["createdAt"];
    updatedAt = map["updatedAt"];

    if (map["deletedAt"] is DateTime) {
      deletedAt = map["deletedAt"];
    } else if (map["deletedAt"] is int) {
      deletedAt = DateTime.fromMillisecondsSinceEpoch(map["deletedAt"]);
    }
  }

  String toString() {
    return export().toString();
  }

  String tableName() {
    // This doesn't work for Flutter web.
    if (kIsWeb) {
      throw Exception(
          'Must be override this method and return a string on web');
    }
    return runtimeType.toString();
  }

  Future<void> save();
  Future<void> delete();
}

import 'package:flutter/foundation.dart';
import 'query.dart';

//AzureADB2CUser user = AzureADB2CUser.shared;
//CosmosSync sync = CosmosSync.shared;
//Database db = SemBastDatabase.shared;

abstract class BaseUser {
  /// If access token is current (not expired), returns the access token _accessToken. Otherwises uses the refresh token to get a new access token.
  /// Refresh token is stored in Shared Preferences.
  Future<Map<String, Map>> resourceTokens();
  void signout();
  Future<bool> hasSignedIn();
  set refreshToken(String token);
  String get refreshToken;
  set role(String role);
  String get role;
}

abstract class Sync {
  Future<void> syncAll();
  Future<void> syncRead(String table);
  Future<void> syncWrite(String table);
}

abstract class Database {
  void saveMap(String tableName, String id, Map map,
      {int updatedAt, String status});
  void save(Model model);
  bool hasTable(String tableName);
  dynamic all(String modelName, Function instantiateModel);
  dynamic find(String modelName, String id, Model model);
  dynamic query<T>(Query query);
}

abstract class Model extends ChangeNotifier {
  static Database database;

  String id;
  DateTime createdAt;
  DateTime updatedAt;

  //Functions to override

  Map<String, dynamic> export() {
    return {
      "id": id,
      "createdAt": createdAt,
      "updatedAt": updatedAt,
    };
  }

  void import(Map<String, dynamic> map) {
    id = map["id"];
    createdAt = map["createdAt"];
    updatedAt = map["updatedAt"];
  }

  String toString() {
    return export().toString();
  }

  void save();
}

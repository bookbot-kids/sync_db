import 'package:flutter/foundation.dart';
import 'query.dart';

//AzureADB2CUser user = AzureADB2CUser.shared;
//CosmosSync sync = CosmosSync.shared;
//Database db = SemBastDatabase.shared;

abstract class User {
  String role;

  /// If access token is current (not expired), returns the access token _accessToken. Otherwises uses the refresh token to get a new access token.
  /// Refresh token is stored in Shared Preferences.
  Future<Map<String, Map>> resourceTokens();
  void signout();
}

abstract class Sync {
  Future<void> syncAll();
  Future<void> syncRead(String table);
  Future<void> syncWrite(String table);
}

abstract class Database {
  void save(Model model);
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
    return {"id": id, "createdAt": createdAt, "updatedAt": updatedAt};
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
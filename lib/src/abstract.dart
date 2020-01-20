import 'package:flutter/foundation.dart';


//AzureADB2CUser user = AzureADB2CUser.shared;
//CosmosSync sync = CosmosSync.shared;
//Database db = SemBastDatabase.shared;

abstract class User {
  static Database database;

  DateTime _tokenExpiry;
  String role;

  /// If access token is current (not expired), returns the access token _accessToken. Otherwises uses the refresh token to get a new access token.
  /// Refresh token is stored in Shared Preferences.
  Future<Map<String, dynamic>> resourceTokens();
  void signout();
}

abstract class Sync {
  Database database;
  User user;
  
  Map<String, dynamic> tableReadLock;
  Map<String, dynamic> tableWriteLock;

  void syncAll();
  void syncRead(String table);
  void syncWrite(String table);
}

abstract class Database {
  Sync sync;
  dynamic database;

  void save(String modelName, Map<String, dynamic> map);
  List<dynamic> all(String modelName, Function instantiateModel);
  dynamic find(String modelName, String key, Function instantiateModel);
  List<dynamic> query(String filter, [List<dynamic> literals = const [], String order, int start, int end]);
}

abstract class Model extends ChangeNotifier {
  static Database database;

  // These will readable from outside the class, but only writeable from inside the class. Need to work out how to do that.
  String key;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime _updatedAt;

  //Functions to create
  String name() {
    return "Model";
  }

  // Function self() {
  //   return () { return new Model(); };
  // }
  Function self();

  Map<String, dynamic> export() {
    return {"key": key, "createdAt": createdAt, "updatedAt": updatedAt, "_updatedAt": _updatedAt};
  }

  void import(Map<String, dynamic> map) {
    key = map["key"];
    createdAt = map["createdAt"];
    updatedAt = map["updatedAt"];
  }

  static List<Model> all() {
    return [];
  }

  // Implement this:
  // static Model find(String key) {
  //   return Model();
  // }

  static List<Model> query(String filter, [List<dynamic> literals = const [], String order, int start, int end]) {
    return [];
  }

  // Reusable functions

  void save() {
    // on new model (id is null) _create
  }

  void _create() {
    // set id to https://pub.dev/packages/better_uuid
    // set created_at
  }

  // TODO: subscribe to changes: https://github.com/tekartik/sembast.dart/blob/master/sembast/doc/new_api.md
}
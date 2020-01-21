import 'package:flutter/foundation.dart';


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
  void syncAll();
  void syncRead(String table);
  void syncWrite(String table);
}

abstract class Database {
  void save(Model model);
  List<dynamic> all(String modelName, Function instantiateModel);
  dynamic find(String modelName, String id, Function instantiateModel);
  List<dynamic> query(String filter, [List<dynamic> literals = const [], String order, int start, int end]);
}

abstract class Model extends ChangeNotifier {
  static Database database;

  String id;
  DateTime createdAt;
  DateTime updatedAt;

  //Functions to create

  // Function self() {
  //   return () { return new Model(); };
  // }
  Function self();

  Map<String, dynamic> export() {
    return {"id": id, "createdAt": createdAt, "updatedAt": updatedAt};
  }

  void import(Map<String, dynamic> map) {
    id = map["id"];
    createdAt = map["createdAt"];
    updatedAt = map["updatedAt"];
  }

  static List<Model> all() {
    return [];
  }

  // Implement this:
  // static Model find(String id) {
  //   return Model();
  // }

  static List<Model> query(String filter, [List<dynamic> literals = const [], String order, int start, int end]) {
    return [];
  }

  // on new model (id is null) _create
  void save();

  void _create() {
    // set id to https://pub.dev/packages/better_uuid
    // set created_at
  }

  // TODO: subscribe to changes: https://github.com/tekartik/sembast.dart/blob/master/sembast/doc/new_api.md
}
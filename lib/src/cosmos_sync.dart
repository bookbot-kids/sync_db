import 'dart:convert';
import 'dart:io';

import "abstract.dart";
import "query.dart";
import "robust_http.dart";
import 'package:crypto/crypto.dart';

class CosmosSync extends Sync {
  static CosmosSync shared;
  HTTP http;
  Database _database;
  User user;
  static const String _apiVersion = "2018-12-31";
  String databaseId;
  String masterKey;

  Map<String, DateTime> _tableReadLock = {};
  Map<String, DateTime> _tableWriteLock = {};

  /// Configure the Cosmos DB, which in this case is the DB url
  /// This will require the `databaseAccount` name, and database id `dbId` in the config map
  static Future<void> config(Map config) {
    shared = CosmosSync();
    shared.http = HTTP(
        'https://${config["databaseAccount"]}.documents.azure.com/dbs/${config["dbId"]}/',
        {"connectTimeout": 60000, "receiveTimeout": 60000});
    shared.databaseId = config["dbId"];
    shared.masterKey = config["dbMasterKey"];
  }

  /// SyncAll will run the sync across the complete database.
  /// Cosmos has a resource token structure so it knows which tables have read or write sync.
  /// Reading and writing of tables is done sequentially to manage load to the server.
  Future<void> syncAll() async {
    final resourceTokens = await user.resourceTokens();
    final keys = resourceTokens.keys;

    // Loop through tables to read sync
    for (final tableName in keys) {
      await syncRead(tableName);
    }

    // Loop through tables to write sync
    for (final tableName in keys) {
      if (resourceTokens[tableName]["permissionMode"] == "All") {
        await syncWrite(tableName);
      }
    }
  }

  /// Read sync this table if it is not locked.
  Future<void> syncRead(String table) async {
    // Check if table is locked and return if it is
    if (_tableWriteLock[table] != null &&
        _tableWriteLock[table].isAfter(DateTime.now())) {
      return;
    }

    // Lock this specific table for reading
    _tableWriteLock[table] = DateTime.now().add(Duration(minutes: 1));

    // Get the last record change timestamp on server side
    final query = Query().order("_ts desc").limit(1);
    final record = _database.query(table, query)[0];
    String select;
    if (record == null || (record != null && record["_ts"] == null)) {
      select = "SELECT * FROM $table";
    } else {
      select = "SELECT * FROM $table WHERE _ts > ${record["_ts"]}";
    }
    final parameters = {"query": select};

    // TODO:
    // Get updated records from last _ts timestamp as a map
    // Compare who has the newer _ts or updated_at (if status is updated), and use that record
    // If cosmos record is newest, save all fields into sembast
  }

  /// Write sync this table if it has permission and is not locked.
  Future<void> syncWrite(String table) async {
    // Check if table is locked and return if it is
    if (_tableReadLock[table] != null &&
        _tableReadLock[table].isAfter(DateTime.now())) {
      return;
    }
    // Check if we have write permission on table
    final resourceTokens = await user.resourceTokens();
    if (resourceTokens[table]["permissionMode"] != "All") {
      return;
    }

    // Lock this specific table for reading
    _tableReadLock[table] = DateTime.now().add(Duration(minutes: 1));

    // Get created records and save to Cosmos DB
    var query = Query().where({"_status": "createdAt"}).order("createdAt asc");
    var records = _database.query<Map>(table, query);

    for (final record in records) {}

    // Get records that have been updated and update Cosmos
    query = Query().where({"_status": "updatedAt"}).order("updatedAt asc");
    records = _database.query<Map>(table, query);

    for (final record in records) {}

    // TODO:
    // Get record from Cosmos (if updated) and compare record to see which one is newer (newer _ts or updated_at)
    // Save record to Cosmos
    // (for Adrian) do another check to see if there are any local updated records after this to upload
  }

  String _getAuthorizationToken(String verb, String resourceType,
      String resourceId, String date, String masterKey) {
    List<int> base64Key = base64.decode(masterKey);
    var hmacSha256 = new Hmac(sha256, base64Key);
    var payLoad = verb.toLowerCase() +
        "\n" +
        resourceType.toLowerCase() +
        "\n" +
        resourceId +
        "\n" +
        date.toLowerCase() +
        "\n" +
        "" +
        "\n";
    var hashPayLoad = hmacSha256.convert(utf8.encode(payLoad)).bytes;
    var signature = base64.encode(hashPayLoad);
    return Uri.encodeComponent("type=master&ver=1.0&sig=$signature");
  }

  Future<void> _createDocument(
      String table, String partitionKey, Map<String, dynamic> json) async {
    var now = new DateTime.now().toUtc();
    var httpDate = HttpDate.format(now);
    var key = _getAuthorizationToken(
        "post", "docs", "dbs/${databaseId}/colls/$table", httpDate, masterKey);
    try {
      http.headers = {
        "Authorization": key,
        "Content-Type": "application/json",
        "x-ms-date": httpDate,
        "x-ms-version": _apiVersion,
        "x-ms-documentdb-partitionkey": "[\"$partitionKey\"]"
      };
      var response =
          await http.post("/dbs/${databaseId}/colls/$table/docs", data: json);
      print(response);
    } catch (e) {
      print(e);
    }
  }

  Future<void> _updateDocument(String table, String id, String partitionKey,
      Map<String, dynamic> json) async {
    var now = new DateTime.now().toUtc();
    var httpDate = HttpDate.format(now);
    var key = _getAuthorizationToken("put", "docs",
        "dbs/$databaseId/colls/$table/docs/$id", httpDate, masterKey);
    try {
      http.headers = {
        "Authorization": key,
        "Content-Type": "application/json",
        "x-ms-date": httpDate,
        "x-ms-version": _apiVersion,
        "x-ms-documentdb-partitionkey": "[\"$partitionKey\"]"
      };
      var response =
          await http.put("/dbs/$databaseId/colls/$table/docs/$id", data: json);
      print(response);
    } catch (e) {
      print(e);
    }
  }
}

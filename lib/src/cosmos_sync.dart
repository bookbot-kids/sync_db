import 'dart:io';

import "abstract.dart";
import "query.dart";
import "robust_http.dart";

import 'robust_http_log.dart';

class CosmosSync extends Sync {
  static CosmosSync shared;
  HTTP http;
  Database database;
  User user;
  static const String _apiVersion = "2018-12-31";
  String databaseId;
  String defaultPartition;
  String partitionKey;

  Map<String, DateTime> _tableReadLock = {};
  Map<String, DateTime> _tableWriteLock = {};

  /// Configure the Cosmos DB, which in this case is the DB url
  /// This will require the `databaseAccount` name, and database id `dbId` in the config map
  static Future<void> config(Map config) {
    shared = CosmosSync();
    shared.http = HTTP(
        'https://${config["databaseAccount"]}.documents.azure.com/dbs/${config["dbId"]}/',
        {"connectTimeout": 60000, "receiveTimeout": 60000},
        Log.all);
    shared.databaseId = config["dbId"];
    shared.defaultPartition = config["dbDefaultPartition"];
    shared.partitionKey = config["dbPartitionKey"];
  }

  /// SyncAll will run the sync across the complete database.
  /// Cosmos has a resource token structure so it knows which tables have read or write sync.
  /// Reading and writing of tables is done sequentially to manage load to the server.
  Future<void> syncAll() async {
    final resourceTokens = await user.resourceTokens();
    final keys = resourceTokens.keys;

    // Loop through tables to read sync
    for (final tableName in keys) {
      await syncRead(tableName, resourceTokens[tableName]["_token"]);
    }

    // await syncRead('Category', resourceTokens['Category']["_token"]);

    // Loop through tables to write sync
    for (final tableName in keys) {
      if (resourceTokens[tableName]["permissionMode"] == "All") {
        await syncWrite(tableName, resourceTokens[tableName]["_token"]);
      }
    }
  }

  /// Read sync this table if it is not locked.
  Future<void> syncRead(String table, String token) async {
    // Check if table is locked and return if it is
    if (_tableWriteLock[table] != null &&
        _tableWriteLock[table].isAfter(DateTime.now())) {
      return;
    }

    // Lock this specific table for reading
    _tableWriteLock[table] = DateTime.now().add(Duration(minutes: 1));

    // Get the last record change timestamp on server side
    final query = Query().order("_ts desc").limit(1);
    var records = await database.query(table, query);
    final record = records.isNotEmpty ? records[0] : null;
    String select;
    String partition = defaultPartition;
    if (record == null || (record != null && record["_ts"] == null)) {
      select = "SELECT * FROM $table c";
    } else {
      select = "SELECT * FROM $table c WHERE c._ts > ${record["_ts"]}";
      partition = record[partitionKey];
    }

    List<Map<String, String>> parameters = List<Map<String, String>>();
    // sample parameter
    // _addparameter(parameters, "@id", "16334e9f-06de-4a87-9c36-977f6fba2f4f");

    // TODO:
    // Get updated records from last _ts timestamp as a map
    // Compare who has the newer _ts or updated_at (if status is updated), and use that record
    // If cosmos record is newest, save all fields into sembast
    var cosmosResult =
        await _queryDocuments(token, table, partition, select, parameters);
    print(cosmosResult);
    for (var cosmosRecord in cosmosResult['Documents']) {
      final query = Query().where({"id": cosmosRecord['id']});
      var records = await database.query(table, query);
      var localRecord = records.isNotEmpty ? records[0] : null;
      if (localRecord == null) {
        // save new to local
      } else {
        // update from cosmos to local
      }
    }
  }

  /// Write sync this table if it has permission and is not locked.
  Future<void> syncWrite(String table, String token) async {
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
    var records = database.query<Map>(table, query);

    for (final record in records) {}

    // Get records that have been updated and update Cosmos
    query = Query().where({"_status": "updatedAt"}).order("updatedAt asc");
    records = database.query<Map>(table, query);

    for (final record in records) {}

    // TODO:
    // Get record from Cosmos (if updated) and compare record to see which one is newer (newer _ts or updated_at)
    // Save record to Cosmos
    // (for Adrian) do another check to see if there are any local updated records after this to upload
  }

  Future<dynamic> _queryDocuments(
      String resouceToken,
      String table,
      String partitionKey,
      String query,
      List<Map<String, String>> parameters) async {
    try {
      http.headers = {
        "authorization": Uri.encodeComponent(resouceToken),
        "content-type": "application/query+json",
        "x-ms-version": _apiVersion,
        "x-ms-documentdb-partitionkey": "[\"$partitionKey\"]",
        "x-ms-documentdb-isquery": true
      };
      var data = "{\"query\": \"$query\",\"parameters\": $parameters}";
      var response = await http.post("colls/$table/docs", data: data);
      return response;
    } catch (e) {
      print(e);
    }

    return null;
  }

  Future<void> _createDocument(String resouceToken, String table,
      String partitionKey, Map<String, dynamic> json) async {
    try {
      http.headers = {
        "authorization": resouceToken,
        "content-type": "application/json",
        "x-ms-version": _apiVersion,
        "x-ms-documentdb-partitionkey": "[\"$partitionKey\"]"
      };
      var response = await http.post("colls/$table/docs", data: json);
      print(response);
    } catch (e) {
      print(e);
    }
  }

  Future<void> _updateDocument(String resouceToken, String table, String id,
      String partitionKey, Map<String, dynamic> json) async {
    try {
      http.headers = {
        "authorization": resouceToken,
        "content-type": "application/json",
        "x-ms-version": _apiVersion,
        "x-ms-documentdb-partitionkey": "[\"$partitionKey\"]"
      };
      var response = await http.put("colls/$table/docs/$id", data: json);
      print(response);
    } catch (e) {
      print(e);
    }
  }

  void _addparameter(
      List<Map<String, String>> parameters, String key, String value) {
    parameters.add({"\"name\"": "\"$key\"", "\"value\"": "\"$value\""});
  }
}

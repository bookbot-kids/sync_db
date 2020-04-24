import 'package:dio/dio.dart' as dio;
import 'package:universal_io/io.dart';

import 'package:synchronized/synchronized.dart';

import "abstract.dart";
import "query.dart";
import "robust_http.dart";

import 'robust_http_log.dart';

class CosmosSync extends Sync {
  static CosmosSync shared;
  HTTP http;
  Database database;
  BaseUser user;
  static const String _apiVersion = "2018-12-31";
  String databaseId;
  int logLevel;
  final _lock = new Lock();
  int pageSize;

  /// Configure the Cosmos DB, which in this case is the DB url
  /// This will require the `databaseAccount` name, and database id `dbId` in the config map
  static void config(Map config) {
    shared = CosmosSync();
    shared.http = HTTP(
        'https://${config["databaseAccount"]}.documents.azure.com/dbs/${config["dbId"]}/',
        config);
    shared.logLevel = config['logLevel'] ?? Log.none;
    shared.databaseId = config["dbId"];
    shared.pageSize = config["pageSize"] ?? 100;
  }

  /// SyncAll will run the sync across the complete database.
  /// Cosmos has a resource token structure so it knows which tables have read or write sync.
  /// Reading and writing of tables is done sequentially to manage load to the server.
  Future<void> syncAll([bool refresh = false]) async {
    try {
      final resourceTokens = await user.resourceTokens(refresh);

      await _lock.synchronized(() async {
        // Loop through tables to read sync
        for (final token in resourceTokens) {
          String tableName = token.key;
          if (tableName.endsWith("-shared")) {
            tableName = tableName.replaceAll("-shared", "");
          }
          if (database.hasTable(tableName)) {
            await syncRead(tableName, token.value);
          }
        }

        // Loop through tables to write sync
        for (final token in resourceTokens) {
          String tableName = token.key;
          if (tableName.endsWith("-shared")) {
            tableName = tableName.replaceAll("-shared", "");
          }

          var permission = token.value;
          if (permission["permissionMode"] == "All" &&
              database.hasTable(tableName)) {
            await syncWrite(tableName, token.value);
          }
        }
      });

      if (logLevel > Log.none) {
        print('Sync completed');
      }
    } catch (err) {
      if (logLevel > Log.none) {
        print('Sync error: $err');
      }
    }
  }

  /// Read sync this table
  Future<void> syncRead(String table, dynamic permission) async {
    String token = permission["_token"];
    String partition = permission["resourcePartitionKey"][0];
    // Get the last record change timestamp on server side
    final query =
        Query(table).where('partition = $partition').order("_ts desc").limit(1);
    var records = await database.query(query);
    final record = records.isNotEmpty ? records[0] : null;
    String select;
    if (record == null || (record != null && record["_ts"] == null)) {
      select = "SELECT * FROM $table c";
    } else {
      select = "SELECT * FROM $table c WHERE c._ts > ${record["_ts"]}";
    }

    var parameters = List<Map<String, String>>();
    var cosmosResult =
        await _queryDocuments(token, table, partition, select, parameters);
    if (logLevel > Log.none) {
      print(cosmosResult);
    }

    for (var cosmosRecord in cosmosResult) {
      final query = Query(table).where({"id": cosmosRecord['id']}).limit(1);
      var records = await database.query(query);
      var localRecord = records.isNotEmpty ? records[0] : null;
      if (localRecord == null) {
        // save new to local, set status to synced to prevent sync again
        await database.saveMap(table, cosmosRecord['id'], cosmosRecord,
            updatedAt: cosmosRecord['_ts'] * 1000, status: 'synced');
      } else {
        // update from cosmos to local, set status to synced to prevent sync again
        var localDate = localRecord['updatedAt'] / 1000;
        if (localDate < cosmosRecord['_ts']) {
          await database.saveMap(table, cosmosRecord['id'], cosmosRecord,
              updatedAt: cosmosRecord['_ts'] * 1000, status: 'synced');
        }
      }
    }
  }

  /// Write sync this table if it has permission
  Future<void> syncWrite(String table, dynamic permission) async {
    // Check if we have write permission on table
    if (permission["permissionMode"] != "All") {
      return;
    }

    String token = permission["_token"];
    String partition = permission["resourcePartitionKey"][0];

    // Get created records and save to Cosmos DB
    var query = Query(table).where("_status = created").order("createdAt asc");
    var records = await database.query<Map>(query);

    for (final record in records) {
      var newRecord = await _createDocument(token, table, partition, record);
      // update to local & set synced status after syncing
      if (newRecord != null) {
        await database.saveMap(table, newRecord['id'], newRecord,
            status: 'synced', updatedAt: newRecord['_ts'] * 1000);
      }
    }

    // Get records that have been updated and update Cosmos
    query = Query(table).where("_status = updated").order("updatedAt asc");
    records = await database.query<Map>(query);
    List recordIds = records.map((item) => item['id']).toList();

    dynamic cosmosRecords;
    if (recordIds.isNotEmpty) {
      // get cosmos records base the local id list
      var select = "SELECT * FROM $table c ";
      var parameters = List<Map<String, String>>();
      var where = "";
      recordIds.asMap().forEach((index, value) {
        where += " c.id = @id$index OR ";
        _addParameter(parameters, "@id$index", value);
      });

      // build query & remove last OR
      select = select + " WHERE " + where.substring(0, where.length - 3);
      var cosmosResult = await _queryDocuments(
          token, table, partition, select.trim(), parameters);

      cosmosRecords = cosmosResult;
    } else {
      cosmosRecords = List();
    }

    for (final localRecord in records) {
      // compare cosmos
      for (var cosmosRecord in cosmosRecords) {
        if (cosmosRecord['id'] == localRecord['id']) {
          var localDate = localRecord['updatedAt'] / 1000;
          // if local is newest, merge and save to cosmos
          if (localDate > cosmosRecord['_ts']) {
            localRecord.forEach((key, value) {
              if (key != 'updatedAt') {
                cosmosRecord[key] = value;
              }
            });

            var updatedRecord = await _updateDocument(
                token, table, cosmosRecord['id'], partition, cosmosRecord);
            // update to local & set synced status after syncing
            if (updatedRecord != null) {
              await database.saveMap(table, updatedRecord['id'], updatedRecord,
                  status: 'synced', updatedAt: updatedRecord['_ts'] * 1000);
            }
          }
        }
      }
    }

    // TODO:
    // Get record from Cosmos (if updated) and compare record to see which one is newer (newer _ts or updated_at)
    // Save record to Cosmos
    // (for Adrian) do another check to see if there are any local updated records after this to upload
  }

  /// Cosmos API to Query documents
  ///
  /// Example:
  ///
  /// "query": "select * from docs d where d.id = @id and d.prop = @prop",
  ///
  /// "parameters": [
  ///      {"@id": "newdoc"},
  ///      {"@prop": 5}
  ///  ]
  ///
  /// Return a list of documents
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
        "x-ms-documentdb-isquery": true,
        "x-ms-max-item-count": pageSize
      };
      var data = "{\"query\": \"$query\",\"parameters\": $parameters}";
      dio.Response response =
          await http.post("colls/$table/docs", data: data, fullResponse: true);
      var responseData = response.data;
      List docs = responseData['Documents'];
      String nextToken = response.headers.value('x-ms-continuation');
      while (nextToken != null) {
        // get next page
        http.headers = {
          "authorization": Uri.encodeComponent(resouceToken),
          "content-type": "application/query+json",
          "x-ms-version": _apiVersion,
          "x-ms-documentdb-partitionkey": "[\"$partitionKey\"]",
          "x-ms-documentdb-isquery": true,
          "x-ms-max-item-count": pageSize,
          "x-ms-continuation": nextToken
        };

        response = await http.post("colls/$table/docs",
            data: data, fullResponse: true);
        docs.addAll(response.data['Documents']);
        nextToken = response.headers.value('x-ms-continuation');
      }

      return docs;
    } catch (e) {
      print(e);
    }

    return null;
  }

  /// Cosmos api to create document
  Future<dynamic> _createDocument(
      String resouceToken, String table, String partition, Map json) async {
    var now = HttpDate.format(DateTime.now().toUtc());

    // make sure there is partition in model
    json['partition'] = partition;

    // we don't want to save updatedAt & _field in cosmos
    _excludeLocalFields(json);

    try {
      http.headers = {
        "x-ms-date": now,
        "authorization": Uri.encodeComponent(resouceToken),
        "content-type": "application/json",
        "x-ms-version": _apiVersion,
        "x-ms-documentdb-partitionkey": "[\"$partition\"]"
      };
      var response = await http.post("colls/$table/docs", data: json);
      if (logLevel > Log.none) {
        print(response);
      }
      return response;
    } catch (e) {
      print(e);
    }
  }

  /// Cosmos api to update document
  Future<dynamic> _updateDocument(String resouceToken, String table, String id,
      String partition, Map json) async {
    var now = HttpDate.format(DateTime.now().toUtc());
    // make sure there is partition in model
    json['partition'] = partition;

    // we don't want to save updatedAt & _field in cosmos
    _excludeLocalFields(json);

    try {
      http.headers = {
        "x-ms-date": now,
        "authorization": Uri.encodeComponent(resouceToken),
        "content-type": "application/json",
        "x-ms-version": _apiVersion,
        "x-ms-documentdb-partitionkey": "[\"$partition\"]"
      };
      var response = await http.put("colls/$table/docs/$id", data: json);
      if (logLevel > Log.none) {
        print(response);
      }

      return response;
    } catch (e) {
      print(e);
    }
  }

  /// Remove local fields before saving to cosmos
  void _excludeLocalFields(Map map) {
    map.removeWhere((key, value) => key == 'updatedAt' || key.startsWith('_'));
  }

  /// Add parameter in list of map for cosmos query
  void _addParameter(
      List<Map<String, String>> parameters, String key, String value) {
    parameters.add({"\"name\"": "\"$key\"", "\"value\"": "\"$value\""});
  }
}

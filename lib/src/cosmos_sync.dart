import 'package:dio/dio.dart' as dio;
import 'package:pool/pool.dart' as pool;
import 'package:sync_db/src/exceptions.dart';
import 'package:sync_db/src/network_time.dart';
import 'package:universal_io/io.dart';

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
  int pageSize;
  /** Thread pool for sync all **/
  final _pool = pool.Pool(1);
  /** Thread pool for sync one **/
  final _modelPool = pool.Pool(1);

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

      await _pool.withResource(() async {
        Stopwatch s = Stopwatch()..start();
        // Loop through tables to read sync
        var tasks = List<Future>();
        for (final token in resourceTokens) {
          String tableName = token.key;
          final index = tableName.indexOf('-shared');
          if (index != -1) {
            tableName = tableName.substring(0, index);
          }

          tasks.add(_syncOne(tableName, refresh));
        }

        await Future.wait(tasks);

        var logMessage =
            'Sync completed, total time is ${s.elapsedMilliseconds / 1000} seconds';
        printLog(logMessage, logLevel);
        s.stop();
      });
    } catch (err) {
      printLog('Sync error: $err', logLevel);
    }
  }

  Future<void> deleteOne(String table, String id, [bool refreh]) async {
    throw UnimplementedError("Not ready in cosmos yet");
  }

  Future<void> syncOne(String table, [bool refresh = false]) async {
    try {
      await _modelPool.withResource(() async {
        await _syncOne(table, refresh);
      });
    } catch (err) {
      printLog('Sync $table error: $err', logLevel);
    }
  }

  Future<void> _syncOne(String table, [bool refresh = false]) async {
    Stopwatch s = Stopwatch()..start();
    final resourceTokens = await user.resourceTokens(refresh);
    try {
      var permission = resourceTokens.firstWhere(
        (element) => element.key == table,
        orElse: () => null,
      );

      if (permission != null) {
        // sync read
        if (database.hasTable(table)) {
          await syncRead(table, permission.value);
        }

        // sync write
        if (permission.value["permissionMode"] == "All" &&
            database.hasTable(table)) {
          await syncWrite(table, permission.value);
        }
      } else {
        printLog('does not have sync permission for table $table', logLevel);
      }

      var logMessage =
          'Sync table $table completed. It took ${s.elapsedMilliseconds / 1000} seconds';
      printLog(logMessage, logLevel);
    } catch (err) {
      printLog('Sync $table error: $err', logLevel);
    }
  }

  /// Read sync this table
  Future<void> syncRead(String table, dynamic permission) async {
    printLog('[start syncing read on $table]', logLevel);
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

    printLog(
        'Run table $table(${cosmosResult.length}) in transaction', logLevel);
    await database.runInTransaction(table, (txn) async {
      for (var cosmosRecord in cosmosResult) {
        final query = Query(table).where({"id": cosmosRecord['id']}).limit(1);
        var records = await database.query(query, transaction: txn);
        var localRecord = records.isNotEmpty ? records[0] : null;
        if (localRecord == null) {
          // save new to local, set status to synced to prevent sync again
          await database.saveMap(table, cosmosRecord['id'], cosmosRecord,
              updatedAt: cosmosRecord['_ts'] * 1000,
              status: 'synced',
              transaction: txn);
        } else {
          // update from cosmos to local, set status to synced to prevent sync again
          var localDate = localRecord['updatedAt'] / 1000;
          if (localDate < cosmosRecord['_ts']) {
            await database.saveMap(table, cosmosRecord['id'], cosmosRecord,
                updatedAt: cosmosRecord['_ts'] * 1000,
                status: 'synced',
                transaction: txn);
          }
        }
      }
    });

    printLog('[end syncing read on $table]', logLevel);
  }

  /// Write sync this table if it has permission
  Future<void> syncWrite(String table, dynamic permission) async {
    // Check if we have write permission on table
    if (permission["permissionMode"] != "All") {
      return;
    }

    printLog('[start syncing write on $table]', logLevel);
    String token = permission["_token"];
    String partition = permission["resourcePartitionKey"][0];

    // Get created records and save to Cosmos DB
    var query = Query(table).where("_status = created").order("createdAt asc");
    var records = await database.query<Map>(query);

    for (final record in records) {
      var newRecord = await _createDocument(token, table, partition, record);
      // update to local & set synced status after syncing
      if (newRecord != null) {
        if (newRecord is String) {
          // resolve conflict by override from cosmos into local
          String select = 'SELECT * FROM $table c WHERE c.id = @id ';
          var parameters = List<Map<String, String>>();
          _addParameter(parameters, '@id', record['id']);
          var cosmosResult = await _queryDocuments(
              token, table, partition, select, parameters);
          if (logLevel > Log.none) {
            print(cosmosResult);
          }

          dynamic cosmosRecord;
          if (cosmosResult != null && cosmosResult.length > 0) {
            cosmosRecord = cosmosResult[0];
            // update from cosmos to local, set status to synced to prevent sync again
            await database.saveMap(table, cosmosRecord['id'], cosmosRecord,
                updatedAt: cosmosRecord['_ts'] * 1000, status: 'synced');
          }
        } else {
          await database.saveMap(table, newRecord['id'], newRecord,
              status: 'synced', updatedAt: newRecord['_ts'] * 1000);
        }
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

    printLog('[end syncing write on $table]', logLevel);
  }

  Future<void> syncWriteOne(
      String table, Map<String, dynamic> localRecord, bool isCreated,
      [bool refresh = false]) async {
    try {
      final resourceTokens = await user.resourceTokens(refresh);
      _pool.withResource(
          () => _syncWriteOne(table, localRecord, isCreated, resourceTokens));
    } catch (err) {
      if (logLevel > Log.none) {
        print('Sync error: $err');
      }
    }
  }

  Future<void> _syncWriteOne(String table, Map<String, dynamic> localRecord,
      bool isCreated, List<MapEntry> resourceTokens) async {
    try {
      var resourceToken = resourceTokens
          .firstWhere((element) => element.key == table, orElse: () => null);
      if (resourceToken == null) {
        if (logLevel > Log.none) {
          print('resource token is null for $table');
        }
        return;
      }

      var permission = resourceToken.value;
      if (permission["permissionMode"] != "All") {
        return;
      }

      String token = permission["_token"];
      String partition = permission["resourcePartitionKey"][0];

      if (isCreated) {
        var newRecord =
            await _createDocument(token, table, partition, localRecord);
        // update to local & set synced status after syncing
        if (newRecord != null) {
          if (newRecord is String) {
            // resolve conflict by override from cosmos into local
            String select = 'SELECT * FROM $table c WHERE c.id = @id ';
            var parameters = List<Map<String, String>>();
            _addParameter(parameters, '@id', localRecord['id']);
            var cosmosResult = await _queryDocuments(
                token, table, partition, select, parameters);
            if (logLevel > Log.none) {
              print(cosmosResult);
            }

            dynamic cosmosRecord;
            if (cosmosResult != null && cosmosResult.length > 0) {
              cosmosRecord = cosmosResult[0];
              // update from cosmos to local, set status to synced to prevent sync again
              await database.saveMap(table, cosmosRecord['id'], cosmosRecord,
                  updatedAt: cosmosRecord['_ts'] * 1000, status: 'synced');
            }
          } else {
            await database.saveMap(table, newRecord['id'], newRecord,
                status: 'synced', updatedAt: newRecord['_ts'] * 1000);
          }
        }
      } else {
        // sync read
        String select = 'SELECT * FROM $table c WHERE c.id = @id ';
        var parameters = List<Map<String, String>>();
        _addParameter(parameters, '@id', localRecord['id']);
        var cosmosResult =
            await _queryDocuments(token, table, partition, select, parameters);
        if (logLevel > Log.none) {
          print(cosmosResult);
        }

        dynamic cosmosRecord;
        if (cosmosResult != null && cosmosResult.length > 0) {
          cosmosRecord = cosmosResult[0];
          // update from cosmos to local, set status to synced to prevent sync again
          var localDate = localRecord['updatedAt'] / 1000;
          if (localDate < cosmosRecord['_ts']) {
            await database.saveMap(table, cosmosRecord['id'], cosmosRecord,
                updatedAt: cosmosRecord['_ts'] * 1000, status: 'synced');
          }
        }

        // sync write
        if (cosmosRecord != null) {
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
                await database.saveMap(
                    table, updatedRecord['id'], updatedRecord,
                    status: 'synced', updatedAt: updatedRecord['_ts'] * 1000);
              }
            }
          }
        }
      }
    } catch (err) {
      if (logLevel > Log.none) {
        print('Sync model $table error: $err');
      }
    }
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
    var now = HttpDate.format(await NetworkTime.shared.now);

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
      // if (logLevel > Log.none) {
      //   print(response);
      // }
      return response;
    } catch (e) {
      if (e is UnexpectedResponseException) {
        try {
          if (e.response.statusCode == 409) {
            // conflict
            return 'conflict';
          }
        } catch (e) {
          // ignore
        }
      }

      print(e);
    }
  }

  /// Cosmos api to update document
  Future<dynamic> _updateDocument(String resouceToken, String table, String id,
      String partition, Map json) async {
    var now = HttpDate.format(await NetworkTime.shared.now);
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
      // if (logLevel > Log.none) {
      //   print(response);
      // }

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

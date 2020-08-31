import 'package:robust_http/robust_http.dart';
import 'package:sync_db/sync_db.dart';
import 'package:universal_io/io.dart';

class CosmosService extends Service {
  CosmosService._privateConstructor();
  Service shared = CosmosService._privateConstructor();

  Database database;
  String databaseId;
  HTTP http;
  int pageSize;
  UserSession user;

  static const String _apiVersion = '2018-12-31';

  /// synchronized lock for sync all
  final _lock = Lock();

  /// synchronized lock for each table
  final Map<String, Lock> _modelSynchronizedLocks = {};

  @override
  Future<void> deleteRecord(String table, String id, [bool refreh]) async {
    throw UnimplementedError('Not ready in cosmos yet');
  }

  /// SyncAll will run the sync across the complete database.
  /// Cosmos has a resource token structure so it knows which tables have read or write sync.
  @override
  Future<void> syncAll([bool refresh = false]) async {
    try {
      if (refresh) {
        await user.refresh();
      }

      final resourceTokens = await user.resourceTokens();

      await _lock.synchronized(() async {
        var s = Stopwatch()..start();
        // Loop through tables to read sync
        var tasks = <Future>[];
        for (final token in resourceTokens) {
          String tableName = token.key;
          final index = tableName.indexOf('-shared');
          if (index != -1) {
            tableName = tableName.substring(0, index);
          }

          tasks.add(_syncOne(tableName, token, refresh));
        }

        await Future.wait(tasks);

        var logMessage =
            'Sync completed, total time is ${s.elapsedMilliseconds / 1000} seconds';
        Sync.shared.logger?.i(logMessage);
        s.stop();
      });
    } catch (err, stackTrace) {
      SyncDB.shared.logger?.e('Sync error: $err', err, stackTrace);
    }
  }

  /// Read sync this table
  @override
  Future<void> syncRead(String table, dynamic permission) async {
    Sync.shared.logger?.i('[start syncing read on $table]');
    String token = permission['_token'];
    String partition = permission['resourcePartitionKey'][0];
    // Get the last record change timestamp on server side
    final query =
        Query(table).where('partition = $partition').order('_ts desc').limit(1);
    var records = await database.query(query);
    final record = records.isNotEmpty ? records[0] : null;
    String select;
    if (record == null || (record != null && record['_ts'] == null)) {
      select = 'SELECT * FROM $table c';
    } else {
      select = "SELECT * FROM $table c WHERE c._ts > ${record["_ts"]}";
    }

    var parameters = <Map<String, String>>[];
    var cosmosResult =
        await _queryDocuments(token, table, partition, select, parameters);

    Sync.shared.logger
        ?.i('Run table $table(${cosmosResult.length}) in transaction');
    await database.runInTransaction(table, (txn) async {
      for (var cosmosRecord in cosmosResult) {
        final query = Query(table).where({'id': cosmosRecord['id']}).limit(1);
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

    Sync.shared.logger?.i('[end syncing read on $table]');
  }

  @override
  Future<void> syncTable(String table, [bool refresh = false]) async {
    try {
      if (refresh) {
        await user.refresh();
      }

      final resourceTokens = await user.resourceTokens();
      var permission = resourceTokens.firstWhere(
        (element) => element.key == table,
        orElse: () => null,
      );
      await _modelPool.withResource(() async {
        await _syncOne(table, permission, refresh);
      });
    } catch (err, stackTrace) {
      Sync.shared.logger?.e('Sync $table error: $err', err, stackTrace);
    }
  }

  @override
  Future<void> syncTable(String table, [bool refresh = false]) async {
    try {
      if (refresh) {
        await user.refresh();
      }

      final resourceTokens = await user.resourceTokens();
      var permission = resourceTokens.firstWhere(
        (element) => element.key == table,
        orElse: () => null,
      );
      await _getModelLock(table).synchronized(() async {
        await _syncOne(table, permission, refresh);
      });
    } catch (err, stackTrace) {
      SyncDB.shared.logger?.e('Sync $table error: $err', err, stackTrace);
    }
  }

  /// Write sync this table if it has permission
  @override
  Future<void> syncWrite(String table, dynamic permission) async {
    // Check if we have write permission on table
    if (permission['permissionMode'] != 'All') {
      return;
    }

    Sync.shared.logger?.i('[start syncing write on $table]');
    String token = permission['_token'];
    String partition = permission['resourcePartitionKey'][0];

    // Get created records and save to Cosmos DB
    var query = Query(table).where('_status = created').order('createdAt asc');
    var records = await database.query<Map>(query);

    for (final record in records) {
      var newRecord = await _createDocument(token, table, partition, record);
      // update to local & set synced status after syncing
      if (newRecord != null) {
        if (newRecord is String) {
          // resolve conflict by override from cosmos into local
          var select = 'SELECT * FROM $table c WHERE c.id = @id ';
          var parameters = <Map<String, String>>[];
          _addParameter(parameters, '@id', record['id']);
          var cosmosResult = await _queryDocuments(
              token, table, partition, select, parameters);
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
    query = Query(table).where('_status = updated').order('updatedAt asc');
    records = await database.query<Map>(query);
    List recordIds = records.map((item) => item['id']).toList();

    dynamic cosmosRecords;
    if (recordIds.isNotEmpty) {
      // get cosmos records base the local id list
      var select = 'SELECT * FROM $table c ';
      var parameters = <Map<String, String>>[];
      var where = '';
      recordIds.asMap().forEach((index, value) {
        where += ' c.id = @id$index OR ';
        _addParameter(parameters, '@id$index', value);
      });

      // build query & remove last OR
      select = select + ' WHERE ' + where.substring(0, where.length - 3);
      var cosmosResult = await _queryDocuments(
          token, table, partition, select.trim(), parameters);

      cosmosRecords = cosmosResult;
    } else {
      cosmosRecords = [];
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

    Sync.shared.logger?.i('[end syncing write on $table]');
  }

  @override
  Future<void> syncWriteRecord(
      String table, Map<String, dynamic> localRecord, bool isCreated,
      [bool refresh = false]) async {
    try {
      if (refresh) {
        await user.refresh();
      }

      final resourceTokens = await user.resourceTokens();
      await _getModelLock(table).synchronized(() =>
          _syncWriteRecord(table, localRecord, isCreated, resourceTokens));
    } catch (err, stackTrace) {
      Sync.shared.logger?.e('Sync error: $err', stackTrace);
    }
  }

  /// Configure the Cosmos DB, which in this case is the DB url
  /// This will require the `databaseAccount` name, and database id `dbId` in the config map
  static void config(Map config) {
    shared.http = HTTP(
        'https://${config["databaseAccount"]}.documents.azure.com/dbs/${config["dbId"]}/',
        config);
    shared.databaseId = config['dbId'];
    shared.pageSize = config['pageSize'] ?? 100;
  }

  Future<void> _syncOne(String table, dynamic permission,
      [bool refresh = false]) async {
    var s = Stopwatch()..start();

    try {
      if (permission != null) {
        // sync read
        if (database.hasTable(table)) {
          await syncRead(table, permission.value);
        }

        // sync write
        if (permission.value['permissionMode'] == 'All' &&
            database.hasTable(table)) {
          await syncWrite(table, permission.value);
        }
      } else {
        Sync.shared.logger?.i('does not have sync permission for table $table');
      }

      var logMessage =
          'Sync table $table completed. It took ${s.elapsedMilliseconds / 1000} seconds';
      Sync.shared.logger?.i(logMessage);
    } catch (err, stackTrace) {
      Sync.shared.logger?.e('Sync $table error: $err', stackTrace);
    }
  }

  /// Configure the Cosmos DB, which in this case is the DB url
  /// This will require the `databaseAccount` name, and database id `dbId` in the config map
  static void config(Map config) {
    shared.http = HTTP(
        'https://${config["databaseAccount"]}.documents.azure.com/dbs/${config["dbId"]}/',
        config);
    shared.databaseId = config['dbId'];
    shared.pageSize = config['pageSize'] ?? 100;
  }

  /// Get synchronized lock for table
  Lock _getModelLock(String table) {
    if (!_modelSynchronizedLocks.containsKey(table)) {
      _modelSynchronizedLocks[table] = Lock();
    }

    return _modelSynchronizedLocks[table];
  }

  Future<void> _syncOne(String table, dynamic permission,
      [bool refresh = false]) async {
    var s = Stopwatch()..start();

    try {
      if (permission != null) {
        // sync read
        if (database.hasTable(table)) {
          await syncRead(table, permission.value);
        }

        // sync write
        if (permission.value['permissionMode'] == 'All' &&
            database.hasTable(table)) {
          await syncWrite(table, permission.value);
        }
      } else {
        SyncDB.shared.logger
            ?.i('does not have sync permission for table $table');
      }

      var logMessage =
          'Sync table $table completed. It took ${s.elapsedMilliseconds / 1000} seconds';
      SyncDB.shared.logger?.i(logMessage);
    } catch (err, stackTrace) {
      SyncDB.shared.logger?.e('Sync $table error: $err', stackTrace);
    }
  }

  Future<void> _syncWriteRecord(String table, Map<String, dynamic> localRecord,
      bool isCreated, List<MapEntry> resourceTokens) async {
    try {
      var resourceToken = resourceTokens
          .firstWhere((element) => element.key == table, orElse: () => null);
      if (resourceToken == null) {
        return;
      }

      var permission = resourceToken.value;
      if (permission['permissionMode'] != 'All') {
        return;
      }

      String token = permission['_token'];
      String partition = permission['resourcePartitionKey'][0];

      if (isCreated) {
        var newRecord =
            await _createDocument(token, table, partition, localRecord);
        // update to local & set synced status after syncing
        if (newRecord != null) {
          if (newRecord is String) {
            // resolve conflict by override from cosmos into local
            var select = 'SELECT * FROM $table c WHERE c.id = @id ';
            var parameters = <Map<String, String>>[];
            _addParameter(parameters, '@id', localRecord['id']);
            var cosmosResult = await _queryDocuments(
                token, table, partition, select, parameters);

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
        var select = 'SELECT * FROM $table c WHERE c.id = @id ';
        var parameters = <Map<String, String>>[];
        _addParameter(parameters, '@id', localRecord['id']);
        var cosmosResult =
            await _queryDocuments(token, table, partition, select, parameters);

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
    } catch (err, stackTrace) {
      Sync.shared.logger?.e('Sync model $table error: $err', err, stackTrace);
    }
  }

  @override
  Future<void> deleteRecord(String table, String id, [bool refreh]) async {
    throw UnimplementedError('Not ready in cosmos yet');
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
        'authorization': Uri.encodeComponent(resouceToken),
        'content-type': 'application/query+json',
        'x-ms-version': _apiVersion,
        'x-ms-documentdb-partitionkey': '[\"$partitionKey\"]',
        'x-ms-documentdb-isquery': true,
        'x-ms-max-item-count': pageSize
      };
      var data = '{\"query\": \"$query\",\"parameters\": $parameters}';
      dio.Response response = await http.post('colls/$table/docs',
          data: data, includeHttpResponse: true);
      var responseData = response.data;
      List docs = responseData['Documents'];
      var nextToken = response.headers.value('x-ms-continuation');
      while (nextToken != null) {
        // get next page
        http.headers = {
          'authorization': Uri.encodeComponent(resouceToken),
          'content-type': 'application/query+json',
          'x-ms-version': _apiVersion,
          'x-ms-documentdb-partitionkey': '[\"$partitionKey\"]',
          'x-ms-documentdb-isquery': true,
          'x-ms-max-item-count': pageSize,
          'x-ms-continuation': nextToken
        };

        response = await http.post('colls/$table/docs',
            data: data, includeHttpResponse: true);
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
        'x-ms-date': now,
        'authorization': Uri.encodeComponent(resouceToken),
        'content-type': 'application/json',
        'x-ms-version': _apiVersion,
        'x-ms-documentdb-partitionkey': '[\"$partition\"]'
      };
      var response = await http.post('colls/$table/docs', data: json);
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
        'x-ms-date': now,
        'authorization': Uri.encodeComponent(resouceToken),
        'content-type': 'application/json',
        'x-ms-version': _apiVersion,
        'x-ms-documentdb-partitionkey': '[\"$partition\"]'
      };
      var response = await http.put('colls/$table/docs/$id', data: json);
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
    parameters.add({'\"name\"': '\"$key\"', '\"value\"': '\"$value\"'});
  }
}

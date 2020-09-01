import 'package:robust_http/exceptions.dart';
import 'package:robust_http/robust_http.dart';
import 'package:sync_db/sync_db.dart';
import 'package:universal_io/io.dart';

class CosmosService extends Service {
  String databaseId;
  HTTP http;
  int pageSize;
  UserSession user;
  int readRetry = 0;
  int writeRertry = 0;

  /// Configure the Cosmos DB, which in this case is the DB url
  /// This will require the `databaseAccount` name, and database id `dbId` in the config map
  CosmosService(Map config) {
    http = HTTP(
        'https://${config["databaseAccount"]}.documents.azure.com/dbs/${config["dbId"]}/',
        config);
    databaseId = config['dbId'];
    pageSize = config['pageSize'] ?? 100;
  }

  static const String _apiVersion = '2018-12-31';

  @override
  Future<List<Map>> readRecords(String table, DateTime timestamp,
      {String paginationToken}) async {
    var result = <Map>[];
    try {
      String select;
      if (timestamp == null) {
        select = 'SELECT * FROM $table c';
      } else {
        select =
            'SELECT * FROM $table c WHERE c._ts > ${timestamp.millisecondsSinceEpoch}';
      }

      var availablePermissions =
          await (user as AzureADB2CUserSession).getAvailableTokens(table);
      for (var permission in availablePermissions) {
        var parameters = <Map<String, String>>[];
        List<Map> cosmosResult = await _queryDocuments(
            permission.token, table, permission.partition, select, parameters);
        cosmosResult.forEach((element) {
          element['serviceUpdatedAt'] = element['_ts'];
        });
        result.addAll(cosmosResult);
      }
    } on RetryFailureException {
      if (readRetry < 2) {
        readRetry++;
        await readRecords(table, timestamp, paginationToken: paginationToken);
      } else {
        readRetry = 0;
      }
    }

    return result;
  }

  @override
  Future<List<Map>> writeRecords(String table) async {
    var result = <Map>[];
    try {
      var availablePermissions =
          await (user as AzureADB2CUserSession).getAvailableTokens(table);

      // Get created records and save to Cosmos DB
      var query = Query(table)
          .where('_status = ${ModelState.created.name}')
          .order('createdAt asc');
      var createdRecords = await database.query<Map>(query);

      // Get records that have been updated and update Cosmos
      query = Query(table)
          .where('_status = ${ModelState.updated.name}')
          .order('updatedAt asc');
      var updatedRecords = await database.query<Map>(query);
      List updatedRecordIds = updatedRecords.map((item) => item['id']).toList();

      for (var permission in availablePermissions) {
        for (final record in createdRecords) {
          if (record['partition'] == permission.partition) {
            var newRecord = await _createDocument(
                permission.token, table, permission.partition, record);
            // update to local & set synced status after syncing
            if (newRecord != null) {
              newRecord['state'] = ModelState.created.name;
              newRecord['serviceUpdatedAt'] = newRecord['_ts'];
              result.add(newRecord);
            }
          }
        }

        if (updatedRecordIds.isNotEmpty) {
          // get cosmos records base the local id list
          var select = 'SELECT * FROM $table c ';
          var parameters = <Map<String, String>>[];
          var where = '';
          updatedRecordIds.asMap().forEach((index, value) {
            where += ' c.id = @id$index OR ';
            _addParameter(parameters, '@id$index', value);
          });

          // build query & remove last OR
          select = select + ' WHERE ' + where.substring(0, where.length - 3);
          var cosmosRecords = await _queryDocuments(permission.token, table,
              permission.partition, select.trim(), parameters);
          for (final localRecord in updatedRecords) {
            // compare to cosmos
            for (var cosmosRecord in cosmosRecords) {
              if (cosmosRecord['id'] == localRecord['id'] &&
                  cosmosRecord['partition'] == permission.partition) {
                var localDate = localRecord['updatedAt'] / 1000;
                // if local is newest, merge and save to cosmos
                if (localDate > cosmosRecord['_ts']) {
                  localRecord.forEach((key, value) {
                    if (key != 'updatedAt') {
                      cosmosRecord[key] = value;
                    }
                  });

                  var updatedRecord = await _updateDocument(
                      permission.token,
                      table,
                      cosmosRecord['id'],
                      permission.partition,
                      cosmosRecord);
                  // update to local & set synced status after syncing
                  if (updatedRecord != null) {
                    updatedRecord['_status'] = ModelState.updated.name;
                    updatedRecord['serviceUpdatedAt'] = updatedRecord['_ts'];
                    result.add(updatedRecord);
                  }
                } else {
                  // local is older, merge and save to local
                  cosmosRecord.forEach((key, value) {
                    if (key != 'updatedAt') {
                      localRecord[key] = value;
                    }
                  });

                  localRecord['_status'] = ModelState.synced.name;
                  await await database.saveMap(
                      table, localRecord['id'], localRecord);
                }
              }
            }
          }
        }
      }
    } on RetryFailureException {
      if (writeRertry < 2) {
        writeRertry++;
        await writeRecords(table);
      } else {
        writeRertry = 0;
      }
    }

    return result;
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
  Future<dynamic> _queryDocuments(String resouceToken, String table,
      String partitionKey, String query, List<Map<String, String>> parameters,
      {String paginationToken}) async {
    try {
      var headers = <String, dynamic>{
        'authorization': Uri.encodeComponent(resouceToken),
        'content-type': 'application/query+json',
        'x-ms-version': _apiVersion,
        'x-ms-documentdb-partitionkey': '[\"$partitionKey\"]',
        'x-ms-documentdb-isquery': true,
        'x-ms-max-item-count': pageSize
      };

      if (paginationToken != null) {
        headers['x-ms-continuation'] = paginationToken;
      }

      http.headers = headers;

      var data = '{\"query\": \"$query\",\"parameters\": $parameters}';
      var response = await http.post('colls/$table/docs',
          data: data, includeHttpResponse: true);
      var responseData = response.data;
      List docs = responseData['Documents'];

      var nextToken = response.headers.value('x-ms-continuation');
      if (nextToken != null && docs != null && docs.isNotEmpty) {
        docs.last['paginationToken'] = paginationToken;
      }

      return docs;
    } catch (e, stackTrace) {
      if (e is UnexpectedResponseException) {
        if (e.response.statusCode == 401 || e.response.statusCode == 403) {
          await user.reset();
          throw RetryFailureException();
        } else {
          Sync.shared.logger?.e('query cosmos document error', e, stackTrace);
        }
      } else {
        Sync.shared.logger?.e('query cosmos document error', e, stackTrace);
      }
    }

    return [];
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
      return response;
    } catch (e, stackTrace) {
      if (e is UnexpectedResponseException) {
        if (e.response.statusCode == 401 || e.response.statusCode == 403) {
          await user.reset();
          throw RetryFailureException();
        } else {
          Sync.shared.logger?.e('create cosmos document', e, stackTrace);
        }
      } else {
        Sync.shared.logger?.e('create cosmos document', e, stackTrace);
      }
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
      return response;
    } catch (e, stackTrace) {
      if (e is UnexpectedResponseException) {
        if (e.response.statusCode == 401 || e.response.statusCode == 403) {
          await user.reset();
          throw RetryFailureException();
        } else {
          Sync.shared.logger?.e('update cosmos document', e, stackTrace);
        }
      } else {
        Sync.shared.logger?.e('update cosmos document', e, stackTrace);
      }
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

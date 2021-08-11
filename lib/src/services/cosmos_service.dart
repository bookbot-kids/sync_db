import 'package:robust_http/exceptions.dart';
import 'package:robust_http/robust_http.dart';
import 'package:sync_db/sync_db.dart';
import 'package:universal_io/io.dart';

class CosmosService extends Service {
  /// Configure the Cosmos DB, which in this case is the DB url
  /// This will require the `cosmosDatabaseAccount` name, and database id `cosmosDatabaseId` in the config map
  CosmosService(Map config) : super(config) {
    _cosmosRetries = config['cosmosRetries'] ?? 3;
    final httpConfig = {'httpRetries': 1};
    _http = HTTP(
        'https://${config["cosmosDatabaseAccount"]}.documents.azure.com/dbs/${config["cosmosDatabaseId"]}/',
        httpConfig);
    _pageSize = config['pageSize'] ?? 1000;
  }

  HTTP _http;
  int _pageSize;
  int _cosmosRetries = 3;

  final _apiVersion = '2018-12-31';

  /// Get records from online service and send to _saveLocalRecords
  /// When accessing a web service will use the _pool to limit accesses at the same time
  /// Save the response timestamp to ServicePoint.from
  @override
  Future<void> readFromService(ServicePoint servicePoint) async {
    // query records in cosmos that have updated timestamp > given timestamp
    final query = 'SELECT * FROM c WHERE c.updatedAt > ${servicePoint.from}';
    var paginationToken;

    // Query the document with paging
    // loop while we have a `paginationToken`
    do {
      var response = await _queryDocuments(servicePoint, query,
          paginationToken: paginationToken);

      await saveLocalRecords(servicePoint, response['response']);
      paginationToken = response['paginationToken'];
      Sync.shared.logger?.i(
          'readFromService ${servicePoint.name}(${response['response']?.length}) timestamp ${servicePoint.from}, paginationToken is ${paginationToken == null ? 'null' : 'not null'}');
      // Put response timestamp in servicePoint
      try {
        final serverTimestamp = HttpDate.parse(response['responseTimestamp'])
            .millisecondsSinceEpoch;
        if (serverTimestamp > 0) servicePoint.from = serverTimestamp;
        await servicePoint.save(syncToService: false);
      } catch (e) {
        Sync.shared.logger?.e('Parse response Date stamp error', e);
      }
    } while (paginationToken != null);
  }

  /// Writes created and updated records to Cosmos DB
  @override
  Future<void> writeToService(ServicePoint servicePoint) async {
    var futures = <Future>[];

    // Get created records and save to Cosmos DB
    var query = Query(servicePoint.name)
        .where('_status = ${SyncStatus.created.name}')
        .order('createdAt asc');
    var createdRecords = await Sync.shared.local.queryMap(query);

    for (final record in createdRecords) {
      // If record has a partion and it doesn't match service point partition, then skip
      if (record['partition'] != null &&
          servicePoint.partition != record['partition']) continue;

      // if a record does not have partition, then use it from service point
      if (record['partition'] == null) {
        record['partition'] = servicePoint.partition;
      }

      // This allows multiple create records to happen at the same time with a pool limit
      futures.add(pool.withResource(() async {
        var newRecord = await _createDocument(servicePoint, record);
        await updateRecordStatus(servicePoint, newRecord);
      }));
    }

    // Get records that have been updated and update Cosmos
    query = Query(servicePoint.name)
        .where('_status = ${SyncStatus.updated.name}')
        .order('updatedAt asc');
    var updatedRecords = await Sync.shared.local.queryMap(query);

    for (final record in updatedRecords) {
      // If record has a partion and it doesn't match service point partition, then skip
      if (record['partition'] != null &&
          servicePoint.partition != record['partition']) continue;

      // if a record does not have partition, then use it from service point
      if (record['partition'] == null) {
        record['partition'] = servicePoint.partition;
      }

      futures.add(pool.withResource(() async {
        final updatedRecord = await _updateDocument(servicePoint, record);
        await updateRecordStatus(servicePoint, updatedRecord);
      }));
    }

    await Future.wait(futures);
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
  /// Return a list of documents, the last item can have a pagination token
  /// If there are any network exceptions, these will bubble up to Service
  Future<Map<String, dynamic>> _queryDocuments(
      ServicePoint servicePoint, String query,
      {List<Map<String, String>> parameters = const <Map<String, String>>[],
      String paginationToken}) async {
    var headers = <String, dynamic>{
      'authorization': Uri.encodeComponent(servicePoint.token),
      'content-type': 'application/query+json',
      'x-ms-version': _apiVersion,
      'x-ms-documentdb-partitionkey': '[\"${servicePoint.partition}\"]',
      'x-ms-documentdb-isquery': true,
      'x-ms-max-item-count': _pageSize
    };

    if (paginationToken != null) {
      headers['x-ms-continuation'] = paginationToken;
    }

    _http.headers = headers;

    var data = '{\"query\": \"$query\",\"parameters\": $parameters}';
    var response = await _http.post('colls/${servicePoint.name}/docs',
        data: data, includeHttpResponse: true);
    var responseData = response.data;
    List docs = responseData['Documents'];

    return {
      'response': docs,
      'paginationToken': response.headers.value('x-ms-continuation'),
      'responseTimestamp': response.headers.value('Date')
    };
  }

  /// Cosmos api to create document
  Future<Map<String, dynamic>> _createDocument(
      ServicePoint servicePoint, Map record) async {
    // remove underscore fields
    excludePrivateFields(record);

    Exception exception;
    for (var i = 0; i < _cosmosRetries; i++) {
      try {
        var now = HttpDate.format(await NetworkTime.shared.now);
        _http.headers = {
          'x-ms-date': now,
          'authorization': Uri.encodeComponent(servicePoint.token),
          'content-type': 'application/json',
          'x-ms-version': _apiVersion,
          'x-ms-documentdb-partitionkey': '[\"${servicePoint.partition}\"]'
        };
        return await _http.post('colls/${servicePoint.name}/docs',
            data: record);
      } on UnexpectedResponseException catch (e, stackTrace) {
        Sync.shared.logger?.e(
            'Create cosmos document $record failed. ${e.url} [${e.statusCode}] ${e.errorMessage}',
            e,
            stackTrace);
        if (e.statusCode == 409) {
          // Strange that this has happened. Record is already created. Log it and try an update.
          return await _updateDocument(servicePoint, record);
        } else {
          rethrow;
        }
      } on UnknownException catch (e, stackTrace) {
        exception = e;
        // retry if there is an exception
        Sync.shared.logger?.e(
            'Create cosmos $record document failed ${e.devDescription}',
            e,
            stackTrace);
      } on Exception catch (e, stackTrace) {
        exception = e;
        Sync.shared.logger?.e(
            'Create cosmos $record document failed without reason',
            e,
            stackTrace);
      }
    }

    throw exception ??
        Exception('Create cosmos $record document failed without reason');
  }

  /// Cosmos api to update document
  Future<dynamic> _updateDocument(ServicePoint servicePoint, Map record) async {
    // we don't want to save local private fields
    excludePrivateFields(record);

    Exception exception;
    for (var i = 0; i < _cosmosRetries; i++) {
      try {
        var now = HttpDate.format(await NetworkTime.shared.now);
        _http.headers = {
          'x-ms-date': now,
          'authorization': Uri.encodeComponent(servicePoint.token),
          'content-type': 'application/json',
          'x-ms-version': _apiVersion,
          'x-ms-documentdb-partitionkey': '[\"${servicePoint.partition}\"]'
        };
        return await _http.put(
            'colls/${servicePoint.name}/docs/${record['id']}',
            data: record);
      } on UnexpectedResponseException catch (e, stackTrace) {
        Sync.shared.logger?.e(
            'Update Cosmos document failed: ${e.url} [${e.statusCode}] ${e.errorMessage}',
            e,
            stackTrace);
        if (e.statusCode == 409) {
          // Strange that this has happened. Record does not exist. Log it and try an update
          return await _createDocument(servicePoint, record);
        } else {
          rethrow;
        }
      } on UnknownException catch (e, stackTrace) {
        exception = e;
        // retry if there is an exception
        Sync.shared.logger?.e(
            'Update cosmos $record document failed ${e.devDescription}',
            e,
            stackTrace);
      } on Exception catch (e, stackTrace) {
        exception = e;
        Sync.shared.logger?.e(
            'Update cosmos $record document failed without reason',
            e,
            stackTrace);
      }
    }

    throw exception ??
        Exception('Update cosmos $record document failed without reason');
  }

  /// Add parameter in list of map for cosmos query
  // void _addParameter(
  //     List<Map<String, String>> parameters, String key, String value) {
  //   parameters.add({'\"name\"': '\"$key\"', '\"value\"': '\"$value\"'});
  // }
}

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
    _throwOnNetworkError = config['throwOnNetworkError'] ?? true;
  }

  late HTTP _http;
  int? _pageSize;
  int _cosmosRetries = 3;
  var _throwOnNetworkError = true;

  final _apiVersion = '2018-12-31';

  static const _cosmosLastUpdatedKey = '_ts';

  /// Get records from online service and send to _saveLocalRecords
  /// When accessing a web service will use the _pool to limit accesses at the same time
  /// Save the response timestamp to ServicePoint.from
  @override
  Future<void> readFromService(ServicePoint servicePoint) async {
    // query records in cosmos that have updated timestamp > given timestamp
    final query =
        'SELECT * FROM c WHERE c.updatedAt > ${servicePoint.from} ORDER BY c.updatedAt ASC';
    var paginationToken;

    // Query the document with paging
    // loop while we have a `paginationToken`
    do {
      final response = await _queryDocuments(servicePoint, query,
          paginationToken: paginationToken);
      final docs = response['response'] ?? [];

      await saveLocalRecords(servicePoint, docs);
      paginationToken = response['paginationToken'];
      Sync.shared.logger?.i(
          'readFromService ${servicePoint.name}(${response['response']?.length ?? 0}) timestamp ${servicePoint.from}, paginationToken is ${paginationToken == null ? 'null' : 'not null'}');
      if (docs.isNotEmpty) {
        int? lastTimestamp = 0;
        if (docs.last[updatedKey] is int) {
          lastTimestamp = docs.last[updatedKey];
        } else if (docs.last[_cosmosLastUpdatedKey] is int) {
          // some table don't have the updatedAt key, then we use _ts
          lastTimestamp = docs.last[_cosmosLastUpdatedKey];
        }

        Sync.shared.logger?.i(
            'readFromService ${servicePoint.name} lastTimestamp $lastTimestamp');

        if (lastTimestamp! > 0) servicePoint.from = lastTimestamp;
        await servicePoint.save(syncToService: false);
      }
    } while (paginationToken != null);
  }

  /// Writes created and updated records to Cosmos DB
  @override
  Future<void> writeToService(ServicePoint servicePoint) async {
    var futures = <Future>[];
    final handler = Sync.shared.modelHandlers[servicePoint.name];
    if (handler == null) {
      Sync.shared.logger?.w('${servicePoint.name} does not register handler');
      return;
    }

    final createdRecords = await handler.queryStatus(SyncStatus.created);
    for (final record in createdRecords) {
      // If record has a partion and it doesn't match service point partition, then skip
      if (record.partition != null &&
          servicePoint.partition != record.partition) {
        continue;
      }

      // if a record does not have partition, then use it from service point
      record.partition ??= servicePoint.partition;

      // This allows multiple create records to happen at the same time with a pool limit
      futures.add(pool.withResource(() async {
        var newRecord = await _createDocument(servicePoint, record.map);
        if (newRecord != null) {
          await updateRecordStatus(servicePoint, newRecord);
        }
      }));
    }

    final updatedRecords = await handler.queryStatus(SyncStatus.updated);
    for (final record in updatedRecords) {
      // If record has a partion and it doesn't match service point partition, then skip
      if (record.partition != null &&
          servicePoint.partition != record.partition) continue;

      // if a record does not have partition, then use it from service point
      record.partition ??= servicePoint.partition;

      futures.add(pool.withResource(() async {
        final updatedRecord = await _updateDocument(servicePoint, record.map);
        if (updatedRecord != null) {
          await updateRecordStatus(servicePoint, updatedRecord);
        }
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
      String? paginationToken}) async {
    if (!await connectivity()) {
      throw ConnectivityException(
          'queryDocuments $query (${servicePoint.name}) $servicePoint error because there is no connection');
    }

    var headers = <String, dynamic>{
      'authorization': Uri.encodeComponent(servicePoint.token!),
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
    try {
      var response = await _http.post('colls/${servicePoint.name}/docs',
          data: data, includeHttpResponse: true);
      var responseData = response.data;
      List? docs = responseData['Documents'];

      return {
        'response': docs,
        'paginationToken': response.headers.value('x-ms-continuation'),
        'responseTimestamp': response.headers.value('Date')
      };
    } on ConnectivityException catch (e, stacktrace) {
      if (_throwOnNetworkError) {
        throw ConnectivityException(
            'queryDocuments $query (${servicePoint.name}) $servicePoint error because of connection $e, $stacktrace',
            hasConnectionStatus: e.hasConnectionStatus);
      }

      Sync.shared.logger?.w(
          'queryDocuments $query (${servicePoint.name}) $servicePoint error $e',
          e,
          stacktrace);
      return {};
    } catch (e, stacktrace) {
      Sync.shared.logger?.e(
          'queryDocuments $query (${servicePoint.name}) $servicePoint error $e',
          e,
          stacktrace);
      rethrow;
    }
  }

  /// Cosmos api to create document
  Future<Map<String, dynamic>?> _createDocument(
      ServicePoint servicePoint, Map record) async {
    if (!await connectivity()) {
      throw ConnectivityException(
          'Create cosmos $record document failed because there is no connection');
    }

    // remove underscore fields
    excludePrivateFields(record);

    Exception? exception;
    for (var i = 0; i < _cosmosRetries; i++) {
      try {
        var now = HttpDate.format(await NetworkTime.shared.now);
        _http.headers = {
          'x-ms-date': now,
          'authorization': Uri.encodeComponent(servicePoint.token!),
          'content-type': 'application/json',
          'x-ms-version': _apiVersion,
          'x-ms-documentdb-partitionkey': '[\"${servicePoint.partition}\"]'
        };
        return await (_http.post('colls/${servicePoint.name}/docs',
            data: record));
      } on ConnectivityException catch (e, stackTrace) {
        if (_throwOnNetworkError) {
          throw ConnectivityException(
              'Create cosmos $record document failed because of connection error $e, $stackTrace',
              hasConnectionStatus: e.hasConnectionStatus);
        }

        Sync.shared.logger?.w(
            'Create cosmos $record document failed because of connection error $e',
            e,
            stackTrace);
        return null;
      } on UnexpectedResponseException catch (e, stackTrace) {
        Sync.shared.logger?.e(
            'Create cosmos document $record failed. ${e.url} [${e.statusCode}] ${e.errorMessage}',
            e,
            stackTrace);
        if (e.statusCode == 409) {
          // Strange that this has happened. Record is already created. Log it and try an update.
          return await (_updateDocument(servicePoint, record));
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
    if (!await connectivity()) {
      throw ConnectivityException(
          'Update cosmos $record document failed because there is no connection');
    }

    // we don't want to save local private fields
    excludePrivateFields(record);

    Exception? exception;
    for (var i = 0; i < _cosmosRetries; i++) {
      try {
        var now = HttpDate.format(await NetworkTime.shared.now);
        _http.headers = {
          'x-ms-date': now,
          'authorization': Uri.encodeComponent(servicePoint.token!),
          'content-type': 'application/json',
          'x-ms-version': _apiVersion,
          'x-ms-documentdb-partitionkey': '[\"${servicePoint.partition}\"]'
        };
        return await _http.put(
            'colls/${servicePoint.name}/docs/${record['id']}',
            data: record);
      } on ConnectivityException catch (e, stackTrace) {
        if (_throwOnNetworkError) {
          throw ConnectivityException(
              'Update cosmos $record document failed because of connection $e $stackTrace',
              hasConnectionStatus: e.hasConnectionStatus);
        }

        Sync.shared.logger?.w(
            'Update cosmos $record document failed because of connection',
            e,
            stackTrace);
        return null;
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
}

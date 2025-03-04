import 'package:robust_http/exceptions.dart';
import 'package:robust_http/robust_http.dart';
import 'package:sync_db/sync_db.dart';
import 'package:universal_io/io.dart';

class CosmosService extends Service {
  /// Configure the Cosmos DB, which in this case is the DB url
  /// This will require the `cosmosDatabaseAccount` name, and database id `cosmosDatabaseId` in the config map
  CosmosService(Map config) : super(config) {
    _cosmosRetries = config['cosmosRetries'] ?? 3;
    final httpConfig = {
      'httpRetries': 1,
      'proxyUrl': config['proxyUrl'],
    };
    _http = HTTP(
        'https://${config["cosmosDatabaseAccount"]}.documents.azure.com/dbs/${config["cosmosDatabaseId"]}/',
        httpConfig);
    _pageSize = config['pageSize'] ?? 1000;
    _throwOnNetworkError = config['throwOnNetworkError'] ?? true;
    _logDebugCloud = config['logDebugCloud'] ?? false;
    _syncPastDuration = config['syncPastDuration'] ?? 0;
  }

  late HTTP _http;
  int? _pageSize;
  int _cosmosRetries = 3;
  var _throwOnNetworkError = true;
  var _logDebugCloud = false;

  /// The duration time to sync in the past in milliseconds
  var _syncPastDuration = 0;

  final _apiVersion = '2018-12-31';

  static const _cosmosLastUpdatedKey = '_ts';

  /// Get records from online service and send to _saveLocalRecords
  /// When accessing a web service will use the _pool to limit accesses at the same time
  /// Save the response timestamp to ServicePoint.from
  @override
  Future<void> readFromService(ServicePoint servicePoint) async {
    // query records in cosmos that have updated timestamp > given timestamp
    var lastSyncTimestamp = servicePoint.from ?? 0;
    var hasPastSync = false;
    if (_syncPastDuration > 0 && lastSyncTimestamp > 0) {
      lastSyncTimestamp = lastSyncTimestamp - _syncPastDuration;
      hasPastSync = true;
    }

    final query =
        'SELECT * FROM c WHERE c.updatedAt > $lastSyncTimestamp ORDER BY c.updatedAt ASC';
    var paginationToken;

    // Query the document with paging
    // loop while we have a `paginationToken`
    do {
      if (_logDebugCloud) {
        Sync.shared.logger?.f(
            '[sync_db][DEBUG] readFromService ${servicePoint.tableName}, $query');
      }
      final response = await _queryDocuments(servicePoint, query,
          paginationToken: paginationToken);
      final docs = response['response'] ?? [];
      if (_logDebugCloud) {
        Sync.shared.logger?.f(
            '[sync_db][DEBUG] readFromService ${servicePoint.tableName}, docs $docs');
      }
      await saveLocalRecords(servicePoint, docs,
          checkLocalExisting: hasPastSync);
      paginationToken = response['paginationToken'];
      if (_logDebugCloud) {
        Sync.shared.logger?.f(
            '[sync_db][DEBUG]  readFromService ${servicePoint.name}(${response['response']?.length ?? 0}) timestamp ${servicePoint.from}, paginationToken is ${paginationToken == null ? 'null' : 'not null'}');
      } else {
        Sync.shared.logger?.i(
            'readFromService ${servicePoint.name}(${response['response']?.length ?? 0}) timestamp ${servicePoint.from}, paginationToken is ${paginationToken == null ? 'null' : 'not null'}');
      }

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
    final handler = Sync.shared.db.modelHandlers[servicePoint.name];
    if (handler == null) {
      Sync.shared.logger?.w('${servicePoint.name} does not register handler');
      return;
    }

    final createdRecords =
        await handler.queryStatus(SyncStatus.created, filterDeletedAt: false);
    for (final record in createdRecords) {
      // If record has a partion and it doesn't match service point partition, then user shared service point
      if (record.partition != null &&
          servicePoint.partition != record.partition) {
        final sharedServicePoint = await ServicePoint().find(
            ServicePoint.sharedKey(record.tableName, record.partition ?? ''));
        if (sharedServicePoint != null) {
          servicePoint = sharedServicePoint;
        } else {
          continue;
        }
      }

      // if a record does not have partition, then use it from service point
      record.partition ??= servicePoint.partition;

      // This allows multiple create records to happen at the same time with a pool limit
      futures.add(pool.withResource(() async {
        final recordMap = record.map;
        recordMap.addAll(record.metadataMap);
        recordMap[partitionKey] = record.partition;
        var newRecord = await _createDocument(servicePoint, recordMap);
        if (newRecord != null) {
          await updateRecordStatus(servicePoint, newRecord);
        }
      }));
    }

    final updatedRecords =
        await handler.queryStatus(SyncStatus.updated, filterDeletedAt: false);
    for (final record in updatedRecords) {
      // If record has a partion and it doesn't match service point partition, then user shared service point
      if (record.partition != null &&
          servicePoint.partition != record.partition) {
        final sharedServicePoint = await ServicePoint().find(
            ServicePoint.sharedKey(record.tableName, record.partition ?? ''));
        if (sharedServicePoint != null) {
          servicePoint = sharedServicePoint;
        } else {
          continue;
        }
      }

      // if a record does not have partition, then use it from service point
      record.partition ??= servicePoint.partition;

      futures.add(pool.withResource(() async {
        // find service record to get partial update fields
        final serviceRecord =
            await ServiceRecord().findBy(record.id, record.tableName);
        if (serviceRecord != null && serviceRecord.updatedFields.isNotEmpty) {
          // partial update
          final recordMap = record.map;
          recordMap.addAll(record.metadataMap);
          recordMap[partitionKey] = record.partition;
          recordMap[updatedKey] = record.updatedAt?.millisecondsSinceEpoch ??
              (await NetworkTime.shared.now).millisecondsSinceEpoch;
          final operations = [];
          final fields = serviceRecord.updatedFields.toSet();
          fields.add(updatedKey);
          for (final field in fields) {
            operations.add({
              'op': 'set',
              'path': '/$field',
              'value': recordMap[field],
            });
          }

          // paging operations (limit = 10)
          final size = operations.length;
          const maxPage = 9;
          var shouldDeleteServiceRecord = false;
          for (var i = 0; i < size; i += maxPage) {
            final pack = operations.sublist(
                i, (i + maxPage) > size ? size : (i + maxPage));
            final updatedRecord = await _partialUpdateDocument(
                servicePoint, {'operations': pack}, recordMap);
            if (updatedRecord != null) {
              await updateRecordStatus(servicePoint, updatedRecord);
              shouldDeleteServiceRecord = true;
            }
          }

          if (shouldDeleteServiceRecord) {
            await serviceRecord.deleteLocal();
          }
        } else {
          final recordMap = record.map;
          recordMap.addAll(record.metadataMap);
          recordMap[updatedKey] = record.updatedAt?.millisecondsSinceEpoch ??
              (await NetworkTime.shared.now).millisecondsSinceEpoch;
          recordMap[partitionKey] = record.partition;
          final updatedRecord = await _updateDocument(servicePoint, recordMap);
          if (updatedRecord != null) {
            await updateRecordStatus(servicePoint, updatedRecord);
          }
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
          error: e,
          stackTrace: stacktrace);
      return {};
    } on UnexpectedResponseException catch (e, stacktrace) {
      Sync.shared.logger?.e(
          'queryDocuments $query (${servicePoint.name}) $servicePoint error $e',
          error: e,
          stackTrace: stacktrace);
      if (e.statusCode == 403) {
        // token is expired, try to get new
        await Sync.shared.userSession?.refresh(forceRefreshToken: true);
      }

      rethrow;
    } catch (e, stacktrace) {
      Sync.shared.logger?.e(
          'queryDocuments $query (${servicePoint.name}) $servicePoint error $e',
          error: e,
          stackTrace: stacktrace);
      rethrow;
    }
  }

  /// Cosmos api to create document
  Future<Map<String, dynamic>?> _createDocument(
      ServicePoint servicePoint, Map record,
      {bool retryUpdate = true, bool retryCreate = true}) async {
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
            error: e,
            stackTrace: stackTrace);
        return null;
      } on UnexpectedResponseException catch (e, stackTrace) {
        Sync.shared.logger?.e(
            'Create cosmos document $record failed. ${e.url} [${e.statusCode}] ${e.errorMessage}',
            error: e,
            stackTrace: stackTrace);
        if (e.statusCode == 409 && retryUpdate) {
          Sync.shared.logger?.i(
              'Try to update existing document $record instead of creating it');
          // Strange that this has happened. Record is already created. Log it and try an update.
          return await (_updateDocument(servicePoint, record));
        } else if (e.statusCode == 403) {
          // token is expired, try to get new
          await Sync.shared.userSession?.refresh(forceRefreshToken: true);
          if (retryCreate) {
            // get new service point
            servicePoint = (await ServicePoint.search(servicePoint.id,
                    servicePoint.name, servicePoint.partition)) ??
                servicePoint;
            // then retry once
            // ignore: unawaited_futures
            return await _createDocument(servicePoint, record,
                retryCreate: false);
          } else {
            rethrow;
          }
        } else {
          rethrow;
        }
      } on UnknownException catch (e, stackTrace) {
        exception = e;
        // retry if there is an exception
        Sync.shared.logger?.e(
            'Create cosmos $record document failed ${e.devDescription}',
            error: e,
            stackTrace: stackTrace);
      } on Exception catch (e, stackTrace) {
        exception = e;
        Sync.shared.logger?.e(
            'Create cosmos $record document failed without reason',
            error: e,
            stackTrace: stackTrace);
      }
    }

    throw exception ??
        Exception('Create cosmos $record document failed without reason');
  }

  /// Cosmos api to update document
  Future<dynamic> _updateDocument(ServicePoint servicePoint, Map record,
      {bool retryUpdate = true}) async {
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
            error: e,
            stackTrace: stackTrace);
        return null;
      } on UnexpectedResponseException catch (e, stackTrace) {
        Sync.shared.logger?.e(
            'Update Cosmos document failed: ${e.url} [${e.statusCode}] ${e.errorMessage}',
            error: e,
            stackTrace: stackTrace);
        if (e.statusCode == 409 || e.statusCode == 404) {
          Sync.shared.logger
              ?.i('Try to create new document $record instead of updating it');
          // Strange that this has happened. Record does not exist. Log it and try to create
          return await _createDocument(servicePoint, record,
              retryUpdate: false);
        } else if (e.statusCode == 403) {
          // token is expired, try to get new
          await Sync.shared.userSession?.refresh(forceRefreshToken: true);
          if (retryUpdate) {
            // get new service point
            servicePoint = (await ServicePoint.search(servicePoint.id,
                    servicePoint.name, servicePoint.partition)) ??
                servicePoint;
            // then retry once
            // ignore: unawaited_futures
            return await _updateDocument(servicePoint, record,
                retryUpdate: false);
          } else {
            rethrow;
          }
        } else {
          rethrow;
        }
      } on UnknownException catch (e, stackTrace) {
        exception = e;
        // retry if there is an exception
        Sync.shared.logger?.e(
            'Update cosmos $record document failed ${e.devDescription}',
            error: e,
            stackTrace: stackTrace);
      } on Exception catch (e, stackTrace) {
        exception = e;
        Sync.shared.logger?.e(
            'Update cosmos $record document failed without reason',
            error: e,
            stackTrace: stackTrace);
      }
    }

    throw exception ??
        Exception('Update cosmos $record document failed without reason');
  }

  /// Cosmos api to update partial document
  Future<dynamic> _partialUpdateDocument(
      ServicePoint servicePoint, Map operations, Map record,
      {bool retryUpdate = true}) async {
    if (!await connectivity()) {
      throw ConnectivityException(
          'Update cosmos $record document failed because there is no connection');
    }

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
        return await _http.patch(
            'colls/${servicePoint.name}/docs/${record['id']}',
            data: operations);
      } on ConnectivityException catch (e, stackTrace) {
        if (_throwOnNetworkError) {
          throw ConnectivityException(
              'Update partial cosmos $record document failed because of connection $e $stackTrace',
              hasConnectionStatus: e.hasConnectionStatus);
        }
        return null;
      } on UnexpectedResponseException catch (e, stackTrace) {
        Sync.shared.logger?.e(
            'Update partial Cosmos document failed: ${e.url} [${e.statusCode}] ${e.errorMessage}',
            error: e,
            stackTrace: stackTrace);
        if (e.statusCode == 409 || e.statusCode == 404) {
          // Strange that this has happened. Record does not exist. Log it and try to create
          return await _createDocument(servicePoint, record,
              retryUpdate: false);
        } else if (e.statusCode == 403) {
          // token is expired, try to get new
          await Sync.shared.userSession?.refresh(forceRefreshToken: true);
          if (retryUpdate) {
            // get new service point
            servicePoint = (await ServicePoint.search(servicePoint.id,
                    servicePoint.name, servicePoint.partition)) ??
                servicePoint;
            // then retry once
            // ignore: unawaited_futures
            return await _partialUpdateDocument(
                servicePoint, operations, record,
                retryUpdate: false);
          } else {
            rethrow;
          }
        } else {
          rethrow;
        }
      } on UnknownException catch (e, stackTrace) {
        exception = e;
        // retry if there is an exception
        Sync.shared.logger?.e(
            'Update partial cosmos $record document failed ${e.devDescription}',
            error: e,
            stackTrace: stackTrace);
      } on Exception catch (e, stackTrace) {
        exception = e;
        Sync.shared.logger?.e(
            'Update partial cosmos $record document failed without reason',
            error: e,
            stackTrace: stackTrace);
      }
    }

    throw exception ??
        Exception(
            'Update partial cosmos $record document failed without reason');
  }
}

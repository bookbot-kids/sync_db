import 'package:robust_http/exceptions.dart';
import 'package:robust_http/robust_http.dart';
import 'package:sync_db/sync_db.dart';
import 'package:universal_io/io.dart';

class CosmosService extends Service {
  /// Configure the Cosmos DB, which in this case is the DB url
  /// This will require the `databaseAccount` name, and database id `databaseId` in the config map
  CosmosService(Map config) {
    final httpConfig = {'httpRetries': 1};
    _http = HTTP(
        'https://${config["databaseAccount"]}.documents.azure.com/dbs/${config["databaseId"]}/',
        httpConfig);
    _pageSize = config['pageSize'] ?? 1000;
  }

  HTTP _http;
  int _pageSize;

  final _apiVersion = '2018-12-31';

  /// Get records from online service and send to _saveLocalRecords
  /// When accessing a web service will use the _pool to limit accesses at the same time
  /// Save the response timestamp to ServicePoint.from
  @override
  Future<void> readFromService(ServicePoint servicePoint) async {
    // query records in cosmos that have updated timestamp > given timestamp
    final query =
        'SELECT * FROM ${servicePoint.name} c WHERE c._ts > ${servicePoint.from}';
    var paginationToken;

    // Query the document with paging
    // loop while we have a `paginationToken`
    do {
      var response = {};
      await pool.withResource(() async {
        response = await _queryDocuments(servicePoint, query);
        //if (response['retry']?.)
      });

      await saveLocalRecords(servicePoint, response['response']);
      paginationToken = response['paginationToken'];
      final serverTimestamp =
          HttpDate.parse(response['responseTimestamp'])?.millisecondsSinceEpoch;
      if (serverTimestamp > 0) servicePoint.from = serverTimestamp;
      await servicePoint.save();
    } while (paginationToken == null);
  }

  @override
  Future<void> writeToService(ServicePoint servicePoint) async {
    var futures = <Future>[];
    var result = <Map>[];

    // Get created records and save to Cosmos DB
    var query = Query(servicePoint.name)
        .where(
            '_status = ${SyncStatus.created.name} & partition = ${servicePoint.partition}')
        .order('createdAt asc');
    var createdRecords = await Sync.shared.local.query<Map>(query);

    for (final record in createdRecords) {
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
    var updatedRecords = await Sync.shared.local.query<Map>(query);

    for (final record in updatedRecords) {
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
  Future<Map<String, dynamic>> _queryDocuments(
      ServicePoint servicePoint, String query,
      {List<Map<String, String>> parameters = const [{}],
      String paginationToken}) async {
    try {
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
    } catch (error, stackTrace) {
      if (error is UnexpectedResponseException) {
        if (error.response.statusCode == 401 ||
            error.response.statusCode == 403) {
          await Sync.shared.userSession.forceRefresh();
          Sync.shared.logger?.e('Resource token error', error, stackTrace);
          return {'retry': true};
        }
      }

      return {'response': []};
    }
  }

  /// Cosmos api to create document
  Future<dynamic> _createDocument(
    ServicePoint servicePoint,
    String query,
  ) async {
    var now = HttpDate.format(await NetworkTime.shared.now);

    // make sure there is partition in model
    json['partition'] = partition;

    // we don't want to save updatedAt & _field in cosmos
    excludePrivateFields(json);

    try {
      _http.headers = {
        'x-ms-date': now,
        'authorization': Uri.encodeComponent(resouceToken),
        'content-type': 'application/json',
        'x-ms-version': _apiVersion,
        'x-ms-documentdb-partitionkey': '[\"$partition\"]'
      };
      var response = await _http.post('colls/$table/docs', data: json);
      return response;
    } catch (e, stackTrace) {
      if (e is UnexpectedResponseException) {
        if (e.response.statusCode == 401 || e.response.statusCode == 403) {
          await Sync.shared.userSession.forceRefresh();
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
  Future<dynamic> _updateDocument(
    ServicePoint servicePoint,
    String query,
  ) async {
    var now = HttpDate.format(await NetworkTime.shared.now);
    // make sure there is partition in model
    json['partition'] = partition;

    // we don't want to save updatedAt & _field in cosmos
    excludePrivateFields(json);

    try {
      _http.headers = {
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

  /// Add parameter in list of map for cosmos query
  void _addParameter(
      List<Map<String, String>> parameters, String key, String value) {
    parameters.add({'\"name\"': '\"$key\"', '\"value\"': '\"$value\"'});
  }
}

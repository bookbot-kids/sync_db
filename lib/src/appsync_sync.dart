import 'dart:convert';

import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:pool/pool.dart' as pool;
import '../sync_db.dart';
import "abstract.dart";
import 'query.dart' as q;

/**
 * Aws AppSync client
 */
class AppSync extends Sync {
  static AppSync shared;
  /** Thread pool for sync all **/
  final _pool = pool.Pool(1);

  /** Thread pool for sync one **/
  final _modelPool = pool.Pool(1);
  HttpLink _httpLink;
  BaseUser user;
  Database database;
  List<Model> _models;
  Map schema;
  int logLevel = Log.none;
  GraphQLClient graphClient;

  static void config(Map config, List<Model> models) {
    shared = AppSync();
    shared._httpLink = HttpLink(
      uri: config['appsyncUrl'],
    );
    shared._models = models;
    shared.logLevel = config['logLevel'] ?? Log.none;
  }

  @override
  Future<void> syncAll() async {
    _pool.withResource(() async {
      try {
        // Get graph client base on token
        await _getGraphClient();

        // query all schema
        await _getSchema();

        if (schema == null) {
          throw SyncException('Can not get schema');
        }

        // Loop through tables to read sync
        for (var model in _models) {
          var table = model.tableName();
          if (schema.containsKey(table)) {
            await syncRead(table, graphClient);
          } else {
            printLog('table $table does not exist in schema', logLevel);
          }
        }

        // Loop through tables to write sync
        for (var model in _models) {
          var table = model.tableName();
          if (schema.containsKey(table)) {
            await syncWrite(table, graphClient);
          } else {
            printLog('table $table does not exist in schema', logLevel);
          }
        }

        printLog('Sync completed', logLevel);
      } catch (err) {
        printLog('Sync error: $err', logLevel);
      }
    });
  }

  @override
  Future<void> syncWriteOne(
      String table, Map<String, dynamic> localRecord, bool isCreated,
      [bool refresh]) async {
    _modelPool.withResource(() async {
      try {
        await _getGraphClient();
        if (schema == null) {
          await _getSchema();
        }

        if (schema == null) {
          throw SyncException('Can not get schema');
        }

        if (isCreated) {
          var fields = _getFields(table);
          var response = await _createDocument(table, fields, localRecord);

          // update to local & set synced status after syncing
          if (response != null) {
            var newRecord = response['create${table}'];
            await database.saveMap(table, newRecord['id'], newRecord,
                status: 'synced', updatedAt: newRecord['_ts'] * 1000);
          }
        } else {
          // sync read
          var fields = _getFields(table);
          var response = await _getDocument(table, fields, localRecord['id']);
          printLog(response, logLevel);
          dynamic remoteRecord;
          if (response != null) {
            remoteRecord = response['get$table'];
            // update from appsync to local, set status to synced to prevent sync again
            var localDate = localRecord['updatedAt'] / 1000;
            if (localDate < remoteRecord['_ts']) {
              await database.saveMap(table, remoteRecord['id'], remoteRecord,
                  updatedAt: remoteRecord['_ts'] * 1000, status: 'synced');
            }
          }

          // sync write
          if (remoteRecord != null) {
            if (remoteRecord['id'] == localRecord['id']) {
              var localDate = localRecord['updatedAt'] / 1000;
              // if local is newest, merge and save to appsync
              if (localDate > remoteRecord['_ts']) {
                localRecord.forEach((key, value) {
                  if (key != 'updatedAt') {
                    remoteRecord[key] = value;
                  }
                });

                var response =
                    await _updateDocument(table, fields, remoteRecord);
                // update to local & set synced status after syncing
                if (response != null) {
                  var updatedRecord = response['update${table}'];
                  await database.saveMap(
                      table, updatedRecord['id'], updatedRecord,
                      status: 'synced', updatedAt: updatedRecord['_ts'] * 1000);
                }
              }
            }
          }
        }
      } catch (err) {
        printLog('Sync error: $err', logLevel);
      }
    });
  }

  @override
  Future<void> syncRead(String table, dynamic graphClient) async {
    // Get the last record change timestamp on server side
    final query = q.Query(table).where('').order("_ts desc").limit(1);
    var records = await database.query(query);
    final record = records.isNotEmpty ? records[0] : null;
    String select;
    var fields = _getFields(table);

    int limit = 10000;
    if (record == null || (record != null && record["_ts"] == null)) {
      select = """
        query list${table}s {
          list${table}s (limit: $limit) {
            items {
              $fields
            }
          }
        }
      """;
    } else {
      select = """
      query list$table {
          list${table}s(filter: {
            _ts: {
              gt: ${record["_ts"]}
            }
          }, limit: $limit){
            items{
              $fields
            }
          }
      }
      """;
    }

    var response = await _queryDocuments(graphClient, select);
    printLog('get table $table response $response', logLevel);
    if (response != null) {
      var documents = response['list${table}s']['items'];
      if (documents != null) {
        for (var doc in documents) {
          final query = q.Query(table).where({"id": doc['id']}).limit(1);
          var records = await database.query(query);
          var localRecord = records.isNotEmpty ? records[0] : null;
          if (localRecord == null) {
            // save new to local, set status to synced to prevent sync again
            await database.saveMap(table, doc['id'], doc,
                updatedAt: doc['_ts'] * 1000, status: 'synced');
          } else {
            // update from appsync to local, set status to synced to prevent sync again
            var localDate = localRecord['updatedAt'] / 1000;
            if (localDate < doc['_ts']) {
              await database.saveMap(table, doc['id'], doc,
                  updatedAt: doc['_ts'] * 1000, status: 'synced');
            }
          }
        }
      }
    }
  }

  @override
  Future<void> syncWrite(String table, dynamic graphClient) async {
    // Get created records and save to Appsync
    var query =
        q.Query(table).where("_status = created").order("createdAt asc");
    var records = await database.query<Map>(query);

    for (final record in records) {
      var fields = _getFields(table);

      var response = await _createDocument(table, fields, record);
      // update to local & set synced status after syncing
      if (response != null) {
        var newRecord = response['create${table}'];
        await database.saveMap(table, newRecord['id'], newRecord,
            status: 'synced', updatedAt: newRecord['_ts'] * 1000);
      }
    }

    // Get records that have been updated and update to appsync
    query = q.Query(table).where("_status = updated").order("updatedAt asc");
    records = await database.query<Map>(query);

    for (final localRecord in records) {
      // get appsync record
      var fields = _getFields(table);
      var response = await _getDocument(table, fields, localRecord['id']);

      printLog(response, logLevel);
      if (response != null) {
        var remoteRecord = response['get$table'];
        if (remoteRecord != null) {
          // compare date between local & remote
          var localDate = localRecord['updatedAt'] / 1000;
          // if local is newest, merge and save to appsync
          if (localDate > remoteRecord['_ts']) {
            localRecord.forEach((key, value) {
              if (key != 'updatedAt') {
                remoteRecord[key] = value;
              }
            });

            var response = await _updateDocument(table, fields, remoteRecord);
            // update to local & set synced status after syncing
            if (response != null) {
              var updatedRecord = response['update${table}'];
              await database.saveMap(table, updatedRecord['id'], updatedRecord,
                  status: 'synced', updatedAt: updatedRecord['_ts'] * 1000);
            }
          }
        }
      }
    }
  }

  /**
   * Exclude fields from the local record before sending to server
   */
  void _excludeLocalFields(Map map) {
    map.removeWhere((key, value) =>
        key == 'updatedAt' || key == 'createdAt' || key.startsWith('_'));
  }

  /**
   * Get document by id
   */
  Future<dynamic> _getDocument(String table, String fields, String id) async {
    var query = """
          query get$table {
              get$table(id:"${id}") {
              $fields
              }
            }
          """;

    return await _queryDocuments(graphClient, query);
  }

  /**
   * Create new document
   * Return a new document
   */
  Future<dynamic> _createDocument(
      String table, String fields, Map record) async {
    _excludeLocalFields(record);
    var query = """
         mutation put${table}(\$input: Create${table}Input!) {
          create${table}(input: \$input) {
            $fields
          }
        }
      """;

    var variables = Map<String, dynamic>();
    variables['input'] = Map<String, dynamic>.from(record);
    return _mutationDocument(graphClient, query, variables);
  }

  /**
   * Update a document
   * Return an updated document
   */
  Future<dynamic> _updateDocument(
      String table, String fields, Map record) async {
    _excludeLocalFields(record);
    var query = """
              mutation update${table}(\$input: Update${table}Input!) {
                update${table}(input: \$input) {
                  $fields
                }
              }
            """;

    var variables = Map<String, dynamic>();
    variables['input'] = Map<String, dynamic>.from(record);
    return _mutationDocument(graphClient, query, variables);
  }

  /**
   * Execute mutation query like update, insert, delete
   * Return a document
   */
  Future<dynamic> _mutationDocument(GraphQLClient graphClient, String query,
      Map<String, dynamic> variables) async {
    var options =
        MutationOptions(documentNode: gql(query), variables: variables);
    var result = await graphClient.mutate(options);
    printLog('_mutationDocument ${result.data}', logLevel);
    return result.data;
  }

  /**
   * Query documents
   * Return a list of document
   */
  Future<dynamic> _queryDocuments(GraphQLClient graphClient, String query,
      [Map<String, dynamic> variables]) async {
    var options = QueryOptions(documentNode: gql(query), variables: variables);
    var result = await graphClient.query(options);
    printLog('_queryDocuments $result', logLevel);
    return result.data;
  }

  /**
   * Get graph client base on token from cognito
   */
  Future<void> _getGraphClient() async {
    final AuthLink authLink = AuthLink(getToken: () => user.refreshToken);
    final Link link = authLink.concat(shared._httpLink);
    graphClient = GraphQLClient(
      cache: InMemoryCache(),
      link: link,
    );
  }

  /**
   * Get defined schema table
   */
  Future<void> _getSchema() async {
    var query = """
      query ListSchema {
        listSchemata(limit: 1000) {
          items {
            id
            table
            types
          }
        }
      }
    """;
    var documents = await _queryDocuments(graphClient, query);
    printLog(documents, logLevel);
    if (documents != null &&
        documents is Map &&
        documents.containsKey('listSchemata')) {
      List list = documents['listSchemata']['items'];
      schema = Map.fromIterable(list, key: (e) => e['table'], value: (e) => e);
    }
  }

  /**
   * List available fields from schema for graphql query
   */
  String _getFields(String table) {
    if (schema == null || !schema.containsKey(table)) {
      return '_ts\n id';
    }

    var schemaData = schema[table];
    // generate field types
    Map types = json.decode(schemaData['types']);
    var fields = types.entries.map((e) => e.key).toList().join('\n');
    fields += '\n _ts\n id';
    return fields;
  }
}

import 'dart:convert';

import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:pool/pool.dart' as pool;
import '../sync_db.dart';
import "abstract.dart";
import 'query.dart' as q;

class AppSync extends Sync {
  static AppSync shared;
  final _pool = pool.Pool(1);
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
  }

  @override
  Future<void> syncModel(
      String table, Map<String, dynamic> localRecord, bool isCreated,
      [bool refresh]) async {
    await _getGraphClient();
    if (isCreated) {
      _excludeLocalFields(localRecord);
      var fields = localRecord.keys.toList().join('\n');
      fields += "\n _ts";
      var newQuery = """
         mutation put${table}(\$input: Create${table}Input!) {
          create${table}(input: \$input) {
            $fields
          }
        }
      """;
      var variables = Map<String, dynamic>();
      variables['input'] = Map<String, dynamic>.from(localRecord);
      var response =
          await _createOrUpdateDocument(graphClient, newQuery, variables);
      // update to local & set synced status after syncing
      if (response != null) {
        var newRecord = response['data']['create${table}'];
        await database.saveMap(table, newRecord['id'], newRecord,
            status: 'synced', updatedAt: newRecord['_ts'] * 1000);
      }
    } else {
      // sync read
      var fields = localRecord.keys.toList().join('\n');
      var query = """
         query get$table {
            get$table(id:"${localRecord['id']}") {
            $fields
            }
          }
      """;

      var response = await _queryDocuments(graphClient, query);
      printLog(response, logLevel);
      dynamic remoteRecord;
      if (response != null) {
        remoteRecord = response['data']['get$table'];
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

            _excludeLocalFields(remoteRecord);
            var fields = remoteRecord.keys.toList().join('\n');
            var updateQuery = """
              mutation update${table}(\$input: Update${table}Input!) {
                update${table}(input: \$input) {
                  $fields
                }
              }
            """;

            var variables = Map<String, dynamic>();
            variables['input'] = Map<String, dynamic>.from(remoteRecord);

            var response = await _createOrUpdateDocument(
                graphClient, updateQuery, variables);
            // update to local & set synced status after syncing
            if (response != null) {
              var updatedRecord = response['data']['update${table}'];
              await database.saveMap(table, updatedRecord['id'], updatedRecord,
                  status: 'synced', updatedAt: updatedRecord['_ts'] * 1000);
            }
          }
        }
      }
    }
  }

  @override
  Future<void> syncRead(String table, dynamic graphClient) async {
    // Get the last record change timestamp on server side
    final query = q.Query(table).where('').order("_ts desc").limit(1);
    var records = await database.query(query);
    final record = records.isNotEmpty ? records[0] : null;
    String select;
    var fields = _getFields(table).join('\n');
    fields += '\n _ts\n id';

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
      _excludeLocalFields(record);
      var fields = _getFields(table).join('\n');
      fields += '\n _ts\n id';
      var newQuery = """
         mutation put${table}(\$input: Create${table}Input!) {
          create${table}(input: \$input) {
            $fields
          }
        }
      """;
      var variables = Map<String, dynamic>();
      variables['input'] = Map<String, dynamic>.from(record);
      var response =
          await _createOrUpdateDocument(graphClient, newQuery, variables);
      // update to local & set synced status after syncing
      if (response != null) {
        var newRecord = response['data']['create${table}'];
        await database.saveMap(table, newRecord['id'], newRecord,
            status: 'synced', updatedAt: newRecord['_ts'] * 1000);
      }
    }

    // Get records that have been updated and update to appsync
    query = q.Query(table).where("_status = updated").order("updatedAt asc");
    records = await database.query<Map>(query);
    List recordIds = records.map((item) => item['id']).toList();

    dynamic remoteRecords;
    if (recordIds.isNotEmpty) {
      // TODO: fix later
      // get appsync records base the local id list
      var schemaData = schema[table];
      // generate field types
      Map types = json.decode(schemaData['types']);
      var fields = types.entries.map((e) => e.key).toList().join('\n');
      fields += '\n _ts\n id';
      var query = """
      query ListByIds{
        list${table}sByIds(ids: \$ids){
          $fields
        }
      }
      """;
      Map<String, dynamic> variables = Map();
      variables["\$id"] = recordIds;
      var response = await _queryDocuments(graphClient, query, variables);
      remoteRecords = response['list${table}sByIds'];
    } else {
      remoteRecords = List();
    }

    for (final localRecord in records) {
      // compare date between local & remote
      for (var remoteRecord in remoteRecords) {
        if (remoteRecord['id'] == localRecord['id']) {
          var localDate = localRecord['updatedAt'] / 1000;
          // if local is newest, merge and save to appsync
          if (localDate > remoteRecord['_ts']) {
            localRecord.forEach((key, value) {
              if (key != 'updatedAt') {
                remoteRecord[key] = value;
              }
            });

            _excludeLocalFields(remoteRecord);
            var fields = remoteRecord.keys.toList().join('\n');
            var updateQuery = """
              mutation update${table}(\$input: Update${table}Input!) {
                update${table}(input: \$input) {
                  $fields
                }
              }
            """;

            var variables = Map<String, dynamic>();
            variables['input'] = Map<String, dynamic>.from(remoteRecord);

            var response = await _createOrUpdateDocument(
                graphClient, updateQuery, variables);
            // update to local & set synced status after syncing
            if (response != null) {
              var updatedRecord = response['data']['update${table}'];
              await database.saveMap(table, updatedRecord['id'], updatedRecord,
                  status: 'synced', updatedAt: updatedRecord['_ts'] * 1000);
            }
          }
        }
      }
    }
  }

  void _excludeLocalFields(Map map) {
    map.removeWhere((key, value) =>
        key == 'updatedAt' || key == 'createdAt' || key.startsWith('_'));
  }

  Future<dynamic> _createOrUpdateDocument(GraphQLClient graphClient,
      String query, Map<String, dynamic> variables) async {
    var options =
        MutationOptions(documentNode: gql(query), variables: variables);
    var result = await graphClient.mutate(options);
    return result.data;
  }

  Future<dynamic> _queryDocuments(GraphQLClient graphClient, String query,
      [Map<String, dynamic> variables]) async {
    var options = QueryOptions(documentNode: gql(query), variables: variables);
    var result = await graphClient.query(options);
    return result.data;
  }

  Future<void> _getGraphClient() async {
    final AuthLink authLink = AuthLink(getToken: () => user.refreshToken);
    final Link link = authLink.concat(shared._httpLink);
    graphClient = GraphQLClient(
      cache: InMemoryCache(),
      link: link,
    );
  }

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

  List _getFields(String table) {
    if (schema == null || !schema.containsKey(table)) {
      return List();
    }

    var schemaData = schema[table];
    // generate field types
    Map types = json.decode(schemaData['types']);
    var fields = types.entries.map((e) => e.key).toList();
    return fields;
  }
}

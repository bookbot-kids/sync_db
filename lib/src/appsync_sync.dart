import 'dart:convert';

import 'package:basic_utils/basic_utils.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:synchronized/synchronized.dart';
import '../sync_db.dart';
import "abstract.dart";
import 'query.dart' as q;

/**
 * Aws AppSync client
 */
class AppSync extends Sync {
  static AppSync shared;
  /** Thread pool for sync all **/
  final _lock = Lock();

  /** Thread pool for sync one table **/
  Map<String, Lock> _modelLocks = Map<String, Lock>();

  HttpLink _httpLink;
  BaseUser user;
  Database database;
  List<Model> _models;
  Map schema;
  List permissions;
  int logLevel = Log.none;
  GraphQLClient graphClient;
  String logText = '';
  int _modelPoolSize;

  static void config(Map config, List<Model> models) {
    shared = AppSync();
    shared._httpLink = HttpLink(
      uri: config['appsyncUrl'],
    );
    shared._models = models;
    shared.logLevel = config['logLevel'] ?? Log.none;
    shared._modelPoolSize = config['modelPoolSize'] ?? 1;
  }

  /// Get sync lock for each table
  Lock _getLock(String table) {
    if (!_modelLocks.containsKey(table)) {
      _modelLocks[table] = Lock();
    }

    return _modelLocks[table];
  }

  @override
  Future<void> syncAll({bool downloadAll = false}) async {
    if (!(await user.hasSignedIn())) {
      return;
    }

    await _lock.synchronized(() async {
      try {
        Stopwatch s = Stopwatch()..start();
        await _setup();

        // Loop through tables to read sync
        var tasks = List<Future>();
        for (var model in _models) {
          var table = model.tableName();
          tasks.add(_syncOne(table, false, false, downloadAll));
        }

        await Future.wait(tasks);
        var logMessage =
            'Sync completed, total time is ${s.elapsedMilliseconds / 1000} seconds';
        printLog(logMessage, logLevel);
        logText += '\n $logMessage';
        s.stop();
      } catch (err) {
        printLog('Sync error: $err', logLevel);
      }
    });
  }

  Future<void> deleteOne(String table, String id, [bool refreh]) async {
    if (!(await user.hasSignedIn())) {
      return;
    }

    await _getLock(table).synchronized(() async {
      try {
        await _setup();

        if (schema.containsKey(table)) {
          if (hasPermission(user.role, table, 'write')) {
            var fields = _getFields(table);
            await _deleteDocument(table, fields, id);
          } else {
            printLog(
                'role ${user.role} does not have write permission in table $table',
                logLevel);
          }
        } else {
          printLog('table $table does not exist in schema', logLevel);
        }

        printLog('Delete record on $table completed', logLevel);
      } catch (err) {
        printLog('Delete record on $table error: $err', logLevel);
      }
    });
  }

  Future<void> syncOne(String table,
      [bool refresh = false, bool downloadAll = false]) async {
    await _getLock(table).synchronized(() async {
      await _syncOne(table, refresh, true, downloadAll);
    });
  }

  Future<void> _syncOne(String table,
      [bool refresh = false,
      bool setup = true,
      bool downloadAll = false]) async {
    Stopwatch s = Stopwatch()..start();
    if (!(await user.hasSignedIn())) {
      return;
    }

    try {
      if (setup) {
        await _setup();
      }

      // Sync read
      if (schema.containsKey(table)) {
        if (hasPermission(user.role, table, 'read')) {
          await syncRead(table, graphClient, downloadAll: downloadAll);
        } else {
          printLog(
              'role ${user.role} does not have read permission in table $table',
              logLevel);
        }
      } else {
        printLog('table $table does not exist in schema', logLevel);
      }

      // Sync write
      if (schema.containsKey(table)) {
        if (hasPermission(user.role, table, 'write')) {
          await syncWrite(table, graphClient);
        } else {
          printLog(
              'role ${user.role} does not have write permission in table $table',
              logLevel);
        }
      } else {
        printLog('table $table does not exist in schema', logLevel);
      }

      var logMessage =
          'Sync table $table completed. It took ${s.elapsedMilliseconds / 1000} seconds';
      printLog(logMessage, logLevel);
      logText += '\n $logMessage';
      s.stop();
    } catch (err) {
      printLog('Sync table $table error: $err', logLevel);
    }
  }

  @override
  Future<void> syncWriteOne(
      String table, Map<String, dynamic> localRecord, bool isCreated,
      [bool refresh]) async {
    if (!(await user.hasSignedIn())) {
      return;
    }

    await _getLock(table).synchronized(() async {
      try {
        await _setup();

        if (!hasPermission(user.role, table, 'write')) {
          return;
        }

        if (isCreated) {
          var fields = _getFields(table);
          var response = await _createDocument(table, fields, localRecord);

          // update to local & set synced status after syncing
          if (response != null) {
            var newRecord = response['create${table}'];
            _fixCreatedAt(newRecord);
            await database.saveMap(table, newRecord['id'], newRecord,
                status: 'synced', updatedAt: newRecord['lastSynced'] * 1000);
          }
        } else {
          // sync read
          var fields = _getFields(table);
          var response = await _getDocument(table, fields, localRecord['id']);
          // printLog(response, logLevel);
          dynamic remoteRecord;
          if (response != null) {
            if (response['get$table'] != null) {
              remoteRecord = response['get$table'];
              // update from appsync to local, set status to synced to prevent sync again
              var localDate = localRecord['updatedAt'] / 1000;
              if (localDate < remoteRecord['lastSynced']) {
                _fixCreatedAt(remoteRecord);
                await database.saveMap(table, remoteRecord['id'], remoteRecord,
                    updatedAt: remoteRecord['lastSynced'] * 1000,
                    status: 'synced');
              }
            } else {
              // if there is no record in appsync, then create a new one
              var fields = _getFields(table);
              var response = await _createDocument(table, fields, localRecord);

              // update to local & set synced status after syncing
              if (response != null && response['create${table}'] != null) {
                var newRecord = response['create${table}'];
                _fixCreatedAt(newRecord);
                await database.saveMap(table, newRecord['id'], newRecord,
                    status: 'synced',
                    updatedAt: newRecord['lastSynced'] * 1000);
              }
            }
          }

          // sync write
          if (remoteRecord != null) {
            if (remoteRecord['id'] == localRecord['id']) {
              var localDate = localRecord['updatedAt'] / 1000;
              // if local is newest, merge and save to appsync
              if (localDate > remoteRecord['lastSynced']) {
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
                  _fixCreatedAt(updatedRecord);
                  await database.saveMap(
                      table, updatedRecord['id'], updatedRecord,
                      status: 'synced',
                      updatedAt: updatedRecord['lastSynced'] * 1000);
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
  Future<void> syncRead(String table, dynamic graphClient,
      {bool downloadAll = false}) async {
    printLog('[start syncing read on $table]', logLevel);
    dynamic record;
    // don't download all for read-only table
    if (!downloadAll || !hasPermission(user.role, table, 'write')) {
      // Get the last record change timestamp on server side
      final query = q.Query(table).order("lastSynced desc").limit(1);
      var records = await database.query(query);
      record = records.isNotEmpty ? records.first : null;
    }

    String select;
    var fields = _getFields(table);

    int limit = 10000;
    String nextToken;
    List documents = List();

    while (true) {
      Map<String, dynamic> variables;
      String nextTokenParam = '';
      String nextTokenVariable = '';
      if (nextToken != null) {
        variables = Map<String, dynamic>();
        variables['nextToken'] = nextToken;
        nextTokenParam = ', nextToken: \$nextToken';
        nextTokenVariable = ' (\$nextToken: String)';
      }

      if (record == null || (record != null && record["lastSynced"] == null)) {
        select = """
        query list${table}s${nextTokenVariable}  {
          list${table}s (limit: $limit${nextTokenParam}) {
            items {
              $fields
            },
            nextToken
          }
        }
      """;
      } else {
        select = """
      query list$table${nextTokenVariable} {
          list${table}s(filter: {
            lastSynced: {
              gt: ${record["lastSynced"]}
            }
          }, limit: $limit${nextTokenParam}){
            items{
              $fields
            },
            nextToken
          }
      }
      """;
      }

      var response = await _queryDocuments(graphClient, select, variables);
      if (response != null) {
        var docs = response['list${table}s']['items'];
        if (docs != null) {
          documents.addAll(docs);
        }
      }

      nextToken = response['list${table}s']['nextToken'];
      if (nextToken == null) {
        break;
      }
    }

    // printLog('get table $table response $response', logLevel);
    if (documents.isNotEmpty) {
      try {
        // run in transaction
        printLog(
            'Run table $table(${documents.length}) in transaction', logLevel);
        await database.runInTransaction(table, (txn) async {
          for (var doc in documents) {
            final query = q.Query(table).where({"id": doc['id']}).limit(1);
            var records = await database.query(query, transaction: txn);
            var localRecord = records.isNotEmpty ? records[0] : null;
            if (localRecord == null) {
              // save new to local, set status to synced to prevent sync again
              _fixCreatedAt(doc);
              await database.saveMap(table, doc['id'], doc,
                  updatedAt: doc['lastSynced'] * 1000,
                  status: 'synced',
                  transaction: txn);
            } else {
              // update from appsync to local, set status to synced to prevent sync again
              var localDate = localRecord['updatedAt'] / 1000;
              if (localDate < doc['lastSynced']) {
                _fixCreatedAt(doc);
                await database.saveMap(table, doc['id'], doc,
                    updatedAt: doc['lastSynced'] * 1000,
                    status: 'synced',
                    transaction: txn);
              }
            }
          }
        });
      } catch (e) {
        throw e;
      }
    }

    printLog('[end syncing read on $table]', logLevel);
  }

  @override
  Future<void> syncWrite(String table, dynamic graphClient) async {
    printLog('[start syncing write on $table]', logLevel);
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
        _fixCreatedAt(newRecord);
        await database.saveMap(table, newRecord['id'], newRecord,
            status: 'synced', updatedAt: newRecord['lastSynced'] * 1000);
      }
    }

    // Get records that have been updated and update to appsync
    query = q.Query(table).where("_status = updated").order("updatedAt asc");
    records = await database.query<Map>(query);

    for (final localRecord in records) {
      // get appsync record
      var fields = _getFields(table);
      var response = await _getDocument(table, fields, localRecord['id']);

      // printLog(response, logLevel);
      if (response != null) {
        if (response['get$table'] != null) {
          var remoteRecord = response['get$table'];
          if (remoteRecord != null) {
            // compare date between local & remote
            var localDate = localRecord['updatedAt'] / 1000;
            // if local is newest, merge and save to appsync
            if (localDate > remoteRecord['lastSynced']) {
              localRecord.forEach((key, value) {
                if (key != 'updatedAt') {
                  remoteRecord[key] = value;
                }
              });

              var response = await _updateDocument(table, fields, remoteRecord);
              // update to local & set synced status after syncing
              if (response != null) {
                var updatedRecord = response['update${table}'];
                _fixCreatedAt(updatedRecord);
                await database.saveMap(
                    table, updatedRecord['id'], updatedRecord,
                    status: 'synced',
                    updatedAt: updatedRecord['lastSynced'] * 1000);
              }
            }
          }
        } else {
          // if there is no record in appsync, then create a new one
          var fields = _getFields(table);
          var response = await _createDocument(table, fields, localRecord);

          // update to local & set synced status after syncing
          if (response != null && response['create${table}'] != null) {
            var newRecord = response['create${table}'];
            _fixCreatedAt(newRecord);
            await database.saveMap(table, newRecord['id'], newRecord,
                status: 'synced', updatedAt: newRecord['lastSynced'] * 1000);
          }
        }
      }
    }

    printLog('[end syncing write on $table]', logLevel);
  }

  Future<void> _setup() async {
    // Get graph client base on token
    await _getGraphClient();

    // query all schema
    await _getSchema();

    // query permissions map
    await _getRolePermissions();
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
   * Delete a document
   * Return a delete document
   */
  Future<dynamic> _deleteDocument(
      String table, String fields, String id) async {
    var query = """
              mutation delete$table{
                delete$table(input:{
                  id: "$id"
                }){
                  $fields
                }
              }
            """;

    var variables = Map<String, dynamic>();
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
    // printLog('_mutationDocument ${result.data}', logLevel);
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
    return result.data;
  }

  /**
   * Get graph client base on token from cognito
   */
  Future<void> _getGraphClient() async {
    if (!(await user.tokenValid)) {
      await user.resourceTokens();
    }

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
    if (schema != null) {
      return;
    }

    var query = """
      query ListSchema {
        listSchemas(limit: 1000) {
          items {
            id
            table
            types
          }
        }
      }
    """;
    var documents = await _queryDocuments(graphClient, query);
    // printLog(documents, logLevel);
    if (documents != null &&
        documents is Map &&
        documents.containsKey('listSchemas')) {
      List list = documents['listSchemas']['items'];
      schema = Map.fromIterable(list, key: (e) => e['table'], value: (e) => e);
    }

    if (schema == null) {
      throw SyncException('Can not get schema');
    }
  }

  /**
   * Get defined role permissions
   */
  Future<void> _getRolePermissions() async {
    if (permissions != null) {
      return;
    }

    var query = """
      query ListRolePermissions {
        listRolePermissionss(limit: 1000) {
          items {
            id
            table
            role
            permission
          }
        }
      }
    """;
    var documents = await _queryDocuments(graphClient, query);
    // printLog(documents, logLevel);
    if (documents != null &&
        documents is Map &&
        documents.containsKey('listRolePermissionss')) {
      permissions = documents['listRolePermissionss']['items'];
    }

    if (permissions == null) {
      throw SyncException('Can not get permission');
    }
  }

  bool hasPermission(String role, String table, String checkedPermission) {
    if (permissions == null) {
      return false;
    }

    // admin has all permissions
    if (StringUtils.equalsIgnoreCase(role, 'admin')) {
      return true;
    }

    for (var item in permissions) {
      if (StringUtils.equalsIgnoreCase(item['role'], role) &&
          StringUtils.equalsIgnoreCase(item['table'], table) &&
          item['permission'] != null &&
          item['permission'].contains(checkedPermission)) {
        return true;
      }
    }

    return false;
  }

  /**
   * List available fields from schema for graphql query
   */
  String _getFields(String table) {
    if (schema == null || !schema.containsKey(table)) {
      return 'lastSynced\n id';
    }

    var schemaData = schema[table];
    // generate field types
    Map types = json.decode(schemaData['types']);
    var fields = types.entries.map((e) => e.key).toList().join('\n');
    fields += '\n lastSynced\n id\n _createdAt';
    return fields;
  }

  void _fixCreatedAt(dynamic doc) {
    if (doc['createdAt'] == null && doc.containsKey('_createdAt')) {
      doc['createdAt'] = doc['_createdAt'] * 1000;
    }
  }
}
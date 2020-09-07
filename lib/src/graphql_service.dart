import 'dart:convert';

import 'package:basic_utils/basic_utils.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:robust_http/exceptions.dart';
import '../sync_db.dart';
import 'abstract.dart';
import 'query.dart' as q;

/// Aws AppSync client
class GraphQLService extends Service {
  GraphQLClient graphClient;
  List permissions;
  Map schema;
  UserSession user;
  int pageSize;

  HttpLink _httpLink;

  List<Model> _models;

  GraphQLService(Map config, List<Model> models) {
    _httpLink = HttpLink(
      uri: config['appsyncUrl'],
    );

    _models = models;
    pageSize = config['pageSize'] ?? 100;
  }

  @override
  Future<void> readFromService(ServicePoint service) async {
    String select;
    var table = service.name;

    var fields = _getFields(table);
    // maximum limit is 1000 https://docs.aws.amazon.com/general/latest/gr/appsync.html
    final limit = 1000;
    String nextToken;

    while (true) {
      Map<String, dynamic> variables;
      var nextTokenParam = '';
      var nextTokenVariable = '';
      if (nextToken != null) {
        variables = <String, dynamic>{};
        variables['nextToken'] = nextToken;
        nextTokenParam = ', nextToken: \$nextToken';
        nextTokenVariable = ' (\$nextToken: String)';
      }

      if (service.from == null) {
        select = '''
        query list${table}s${nextTokenVariable}  {
          list${table}s (limit: $limit${nextTokenParam}) {
            items {
              $fields
            },
            nextToken
          }
        }
      ''';
      } else {
        var lastTimestamp = service.from;
        select = '''
        query list$table${nextTokenVariable} {
            list${table}s(filter: {
              lastSynced: {
                gt: ${lastTimestamp}
              }
            }, limit: $limit${nextTokenParam}){
              items{
                $fields
              },
              nextToken
            }
        }
      ''';
      }

      var response = await _queryDocuments(graphClient, select, variables);
      if (response != null) {
        var docs = response['list${table}s']['items'];
        if (docs != null) {
          docs.forEach((element) {
            element['serviceUpdatedAt'] = element['lastSynced'];
          });

          await saveLocalRecords(service, docs);
        }
      }

      nextToken = response['list${table}s']['nextToken'];
      if (nextToken == null) {
        break;
      }
    }
  }

  @override
  Future<void> writeToService(ServicePoint service) async {
    final table = service.name;
    var query = q.Query(table)
        .where('_status = ${SyncState.created.name}')
        .order('createdAt asc');
    var records = await Sync.shared.local.query<Map>(query);

    for (final record in records) {
      var fields = _getFields(table);

      var response = await _createDocument(table, fields, record);
      if (response != null) {
        var newRecord = response['create${table}'];
        _fixFields(newRecord);
        newRecord['_status'] = SyncState.created.name;
        await saveLocalRecords(service, [newRecord]);
      } else {
        Sync.shared.logger?.e('create document ${table} ${record} error');
      }
    }

    // Get records that have been updated and update to appsync
    query = q.Query(table)
        .where('_status = ${SyncState.updated.name}')
        .order('updatedAt asc');
    records = await Sync.shared.local.query<Map>(query);

    for (final localRecord in records) {
      // get appsync record
      var fields = _getFields(table);
      var response = await _getDocument(table, fields, localRecord['id']);
      if (response != null) {
        if (response['get$table'] != null) {
          var remoteRecord = response['get$table'];
          if (remoteRecord != null) {
            // compare date between local & remote
            var localDate = localRecord['updatedAt'] / 1000;
            // if local is newer, merge and save to appsync
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
                _fixFields(updatedRecord);
                await updateRecordStatus(service, localRecord);
                await saveLocalRecords(service, [updatedRecord]);
              }
            } else {
              // local is older, merge and save to local
              remoteRecord.forEach((key, value) {
                if (key != 'updatedAt') {
                  localRecord[key] = value;
                }
              });

              await updateRecordStatus(service, localRecord);
              await saveLocalRecords(service, [localRecord]);
            }
          }
        } else {
          // if there is no record in appsync, then create a new one
          var fields = _getFields(table);
          var response = await _createDocument(table, fields, localRecord);

          // update to local & set synced status after syncing
          if (response != null && response['create${table}'] != null) {
            var newRecord = response['create${table}'];
            _fixFields(newRecord);
            newRecord['_status'] = SyncState.created.name;
            await saveLocalRecords(service, [newRecord]);
          }
        }
      }
    }
  }

  Future<void> _setup() async {
    // Get graph client base on token
    await _getGraphClient();

    // query all schema
    await _getSchema();

    // query permissions map
    await _getRolePermissions();
  }

  /// Exclude fields from the local record before sending to server
  void _excludeLocalFields(Map map) {
    map.removeWhere((key, value) =>
        key == 'updatedAt' || key == 'createdAt' || key.startsWith('_'));
  }

  /// Get document by id
  Future<dynamic> _getDocument(String table, String fields, String id) async {
    var query = '''
          query get$table {
              get$table(id:"${id}") {
              $fields
              }
            }
          ''';

    return await _queryDocuments(graphClient, query);
  }

  /// Create new document and return a new document
  Future<dynamic> _createDocument(
      String table, String fields, Map record) async {
    _excludeLocalFields(record);
    var query = '''
         mutation put${table}(\$input: Create${table}Input!) {
          create${table}(input: \$input) {
            $fields
          }
        }
      ''';

    var variables = <String, dynamic>{};
    variables['input'] = Map<String, dynamic>.from(record);
    return _mutationDocument(graphClient, query, variables);
  }

  /// Update a document and return an updated document
  Future<dynamic> _updateDocument(
      String table, String fields, Map record) async {
    _excludeLocalFields(record);
    var query = '''
              mutation update${table}(\$input: Update${table}Input!) {
                update${table}(input: \$input) {
                  $fields
                }
              }
            ''';

    var variables = <String, dynamic>{};
    variables['input'] = Map<String, dynamic>.from(record);
    return _mutationDocument(graphClient, query, variables);
  }

  /// Delete a document and return a deleted document
  Future<dynamic> _deleteDocument(
      String table, String fields, String id) async {
    var query = '''
              mutation delete$table{
                delete$table(input:{
                  id: "$id"
                }){
                  $fields
                }
              }
            ''';

    var variables = <String, dynamic>{};
    return _mutationDocument(graphClient, query, variables);
  }

  /// Execute mutation query like update, insert, delete and return a document
  Future<dynamic> _mutationDocument(GraphQLClient graphClient, String query,
      Map<String, dynamic> variables) async {
    var options =
        MutationOptions(documentNode: gql(query), variables: variables);
    var result = await graphClient.mutate(options);
    // printLog('_mutationDocument ${result.data}', logLevel);
    return result.data;
  }

  /// Query documents
  Future<dynamic> _queryDocuments(GraphQLClient graphClient, String query,
      [Map<String, dynamic> variables]) async {
    var options = QueryOptions(documentNode: gql(query), variables: variables);
    var result = await graphClient.query(options);
    // printLog('_queryDocuments ${result.data}', logLevel);
    return result.data;
  }

  /// Get graph client base on token from cognito
  Future<void> _getGraphClient() async {
    await user.resourceTokens();
    final authLink = AuthLink(getToken: () => user.refreshToken);
    final link = authLink.concat(_httpLink);
    graphClient = GraphQLClient(
      cache: InMemoryCache(),
      link: link,
    );
  }

  /// Get defined schema table
  Future<void> _getSchema() async {
    if (schema != null) {
      return;
    }

    var query = '''
      query ListSchema {
        listSchemas(limit: 1000) {
          items {
            id
            table
            types
          }
        }
      }
    ''';
    var documents = await _queryDocuments(graphClient, query);
    // printLog(documents, logLevel);
    if (documents != null &&
        documents is Map &&
        documents.containsKey('listSchemas')) {
      List list = documents['listSchemas']['items'];
      schema = {for (var e in list) e['table']: e};
    }

    if (schema == null) {
      throw SyncDataException('Can not get schema');
    }
  }

  /// Get defined role permissions
  Future<void> _getRolePermissions() async {
    if (permissions != null) {
      return;
    }

    var query = '''
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
    ''';
    var documents = await _queryDocuments(graphClient, query);
    // printLog(documents, logLevel);
    if (documents != null &&
        documents is Map &&
        documents.containsKey('listRolePermissionss')) {
      permissions = documents['listRolePermissionss']['items'];
    }

    if (permissions == null) {
      throw SyncDataException('Can not get permission');
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

  /// List available fields from schema for graphql query
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

  void _fixFields(dynamic doc) {
    if (doc['createdAt'] == null && doc.containsKey('_createdAt')) {
      doc['createdAt'] = doc['_createdAt'] * 1000;
    }

    if (doc['lastSynced'] != null) {
      doc['serviceUpdatedAt'] = doc['lastSynced'];
    }
  }
}

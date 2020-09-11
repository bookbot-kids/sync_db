import 'dart:convert';

import 'package:basic_utils/basic_utils.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:robust_http/exceptions.dart';
import 'package:sync_db/src/cognito_user.dart';
import '../sync_db.dart';
import 'query.dart' as q;

/// Aws AppSync client
class GraphQLService extends Service {
  List _rolePermissions;
  Map _schema;
  CognitoUserSession user;
  GraphQLClient _graphClient;
  HttpLink _httpLink;

  /// Max error retry
  int _maxRetry = 2;

  GraphQLService(Map config) {
    _httpLink = HttpLink(
      uri: config['appsyncUrl'],
    );

    _maxRetry = config['errorRetry'] ?? 2;
  }

  @override
  Future<void> readFromService(ServicePoint service) async {
    var table = service.name;
    var fields = _getFields(table);
    // maximum limit is 1000 https://docs.aws.amazon.com/general/latest/gr/appsync.html
    final limit = 1000;
    String nextToken;
    final start = service.from;

    // ignore: unawaited_futures
    while (true) {
      var variables = <String, dynamic>{'nextToken': nextToken};
      var select = '''
        query list$table (\$nextToken: String) {
            list${table}s(filter: {
              lastSynced: {
                ge: ${start}
              }
            }, limit: $limit, nextToken: \$nextToken){
              items{
                $fields
              },
              nextToken
            }
        }
        ''';

      var response = await _queryDocuments(select, variables);
      if (response != null) {
        List docs = response['list${table}s']['items'];
        nextToken = response['list${table}s']['nextToken'];
        if (docs != null && docs.isNotEmpty) {
          // get the max timestamp
          var max = docs.first;
          docs.forEach((element) {
            if (element['lastSynced'] > max['lastSynced']) max = element;
          });

          service.from = max['lastSynced'];
          await service.save(syncToService: false);
          await saveLocalRecords(service, docs);

          Sync.shared.logger?.i(
              'readFromService $table(${docs.length}) timestamp [$start - ${service.from}], nextToken is ${nextToken == null ? 'null' : 'not null'}');
        } else {
          break;
        }
      } else {
        break;
      }

      if (nextToken == null) {
        break;
      }
    }
  }

  @override
  Future<void> writeToService(ServicePoint service) async {
    final table = service.name;
    // get created records and create in appsync
    var query = q.Query(table)
        .where('_status = ${SyncStatus.created.name}')
        .order('createdAt asc');
    var records = await Sync.shared.local.queryMap(query);

    for (final record in records) {
      var fields = _getFields(table);

      var response = await _createDocument(table, fields, record);
      if (response != null && response['create${table}'] != null) {
        await updateRecordStatus(service, response['create${table}']);
      } else {
        // try to get server record after retry failure
        response = await _getDocument(table, fields, record['id']);
        // check if record already exists
        if (response != null && response['get${table}'] != null) {
          // if it does, then update its status to synced
          await updateRecordStatus(service, response['get${table}']);
        } else {
          // otherwise just log as error
          Sync.shared.logger?.e('create document ${table} ${record} error');
        }
      }
    }

    // Get records that have been updated and update to appsync
    query = q.Query(table)
        .where('_status = ${SyncStatus.updated.name}')
        .order('updatedAt asc');
    records = await Sync.shared.local.queryMap(query);
    for (var record in records) {
      var fields = _getFields(table);
      var response = await _updateDocument(table, fields, record);
      if (response != null && response['update${table}'] != null) {
        await updateRecordStatus(service, response['update${table}']);
      } else {
        Sync.shared.logger?.e('update document ${table} ${record} error');
      }
    }
  }

  Future<void> setup() async {
    // Get graph client base on token
    await graphClient;
    // query all schema
    await schema;
    // query permissions map
    await rolePermissions;
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

    return await _queryDocuments(query);
  }

  /// Create new document and return a new document
  Future<dynamic> _createDocument(
      String table, String fields, Map record) async {
    excludePrivateFields(record);
    var query = '''
         mutation put${table}(\$input: Create${table}Input!) {
          create${table}(input: \$input) {
            $fields
          }
        }
      ''';

    var variables = <String, dynamic>{};
    variables['input'] = Map<String, dynamic>.from(record);
    return _mutationDocument(query, variables);
  }

  /// Update a document and return an updated document
  Future<dynamic> _updateDocument(
      String table, String fields, Map record) async {
    excludePrivateFields(record);
    var query = '''
              mutation update${table}(\$input: Update${table}Input!) {
                update${table}(input: \$input) {
                  $fields
                }
              }
            ''';

    var variables = <String, dynamic>{};
    variables['input'] = Map<String, dynamic>.from(record);
    return _mutationDocument(query, variables);
  }

  /// Execute mutation query like update, insert, delete and return a document
  Future<dynamic> _mutationDocument(
      String query, Map<String, dynamic> variables) async {
    for (var i = 1; i <= _maxRetry; i++) {
      var client = await graphClient;
      var options =
          MutationOptions(documentNode: gql(query), variables: variables);
      var result = await client.mutate(options);
      if (!result.hasException) {
        return result.data;
      } else {
        Sync.shared.logger?.e('mutationDocument [$query] [$variables] error',
            result.exception, StackTrace.current);
      }
    }

    return null;
  }

  /// Query documents
  Future<dynamic> _queryDocuments(String query,
      [Map<String, dynamic> variables]) async {
    for (var i = 1; i <= _maxRetry; i++) {
      var client = await graphClient;
      var options =
          QueryOptions(documentNode: gql(query), variables: variables);
      var result = await client.query(options);
      if (!result.hasException) {
        return result.data;
      } else {
        Sync.shared.logger?.e('queryDocuments [$query] [$variables] error',
            result.exception, StackTrace.current);
      }
    }

    throw RetryFailureException();
  }

  /// Get graph client base on token from cognito
  Future<GraphQLClient> get graphClient async {
    if (_graphClient == null) {
      await user.resourceTokens();
      final authLink = AuthLink(getToken: () => user.refreshToken);
      final link = authLink.concat(_httpLink);
      _graphClient = GraphQLClient(
        cache: InMemoryCache(),
        link: link,
      );
    }

    return _graphClient;
  }

  /// Get defined schema table
  Future<Map> get schema async {
    if (_schema != null) {
      return _schema;
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
    var documents = await _queryDocuments(query);
    // printLog(documents, logLevel);
    if (documents != null &&
        documents is Map &&
        documents.containsKey('listSchemas')) {
      List list = documents['listSchemas']['items'];
      _schema = {for (var e in list) e['table']: e};
    }

    if (_schema == null) {
      throw SyncDataException('Can not get schema');
    }

    return _schema;
  }

  /// Get defined role permissions
  Future<void> get rolePermissions async {
    if (_rolePermissions != null) {
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
    var documents = await _queryDocuments(query);
    //Sync.shared.logger?.i('permissions response $documents');
    if (documents != null &&
        documents is Map &&
        documents.containsKey('listRolePermissionss')) {
      _rolePermissions = documents['listRolePermissionss']['items'];
    }

    if (_rolePermissions == null) {
      throw SyncDataException('Can not get permission');
    }
  }

  bool hasPermission(String role, String table, String checkedPermission) {
    if (_rolePermissions == null) {
      return false;
    }

    // admin has all permissions
    if (StringUtils.equalsIgnoreCase(role, 'admin')) {
      return true;
    }

    for (var item in _rolePermissions) {
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
    if (_schema == null || !_schema.containsKey(table)) {
      return 'lastSynced\n id';
    }

    var schemaData = _schema[table];
    // generate field types
    Map types = json.decode(schemaData['types']);
    var fields = types.entries.map((e) => e.key).toList().join('\n');
    fields += '\n lastSynced\n id\n $createdKey\n $updatedKey\n $deletedKey\n';
    return fields;
  }
}

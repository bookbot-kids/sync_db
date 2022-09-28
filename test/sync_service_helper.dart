import 'package:robust_http/robust_http.dart';
import 'package:collection/collection.dart';
import 'package:universal_io/io.dart';

class SyncHelper {
  final Map configs;

  late HTTP _http;
  static const _apiVersion = '2018-12-31';

  SyncHelper(this.configs) {
    _http = HTTP(
        'https://${configs['cosmosDatabaseAccount']}.documents.azure.com/dbs/${configs['cosmosDatabaseId']}/');
  }

  Future<dynamic> getCosmosDocument(
      String table, String id, String token, String partition) async {
    final query = 'SELECT * FROM c WHERE c.id = @id';
    final params = {'@id': id};
    final jsonData = {
      'query': query,
      'parameters':
          params.entries.map((e) => {'name': e.key, 'value': e.value}).toList()
    };

    final headers = <String, dynamic>{
      'authorization': Uri.encodeComponent(token),
      'content-type': 'application/query+json',
      'x-ms-version': _apiVersion,
      'x-ms-documentdb-partitionkey': '[\"$partition\"]',
      'x-ms-documentdb-isquery': true,
      'x-ms-max-item-count': 1
    };

    _http.headers = headers;
    var response = await _http.post('colls/$table/docs',
        data: jsonData, includeHttpResponse: true);
    var responseData = response.data;
    List? docs = responseData['Documents'];
    return docs?.firstOrNull;
  }

  /// Cosmos api to create document
  Future<Map<String, dynamic>?> createDocument(
      String table, String token, String partition, Map record) async {
    // remove underscore fields
    excludePrivateFields(record);

    var now = HttpDate.format(DateTime.now());
    _http.headers = {
      'x-ms-date': now,
      'authorization': Uri.encodeComponent(token),
      'content-type': 'application/json',
      'x-ms-version': _apiVersion,
      'x-ms-documentdb-partitionkey': '[\"$partition\"]'
    };
    return await (_http.post('colls/$table/docs', data: record));
  }

  /// Cosmos api to update document
  Future<dynamic> updateDocument(
      String table, String token, String partition, Map record) async {
    // we don't want to save local private fields
    excludePrivateFields(record);

    var now = HttpDate.format(DateTime.now());
    _http.headers = {
      'x-ms-date': now,
      'authorization': Uri.encodeComponent(token),
      'content-type': 'application/json',
      'x-ms-version': _apiVersion,
      'x-ms-documentdb-partitionkey': '[\"$partition\"]'
    };
    return await _http.put('colls/$table/docs/${record['id']}', data: record);
  }

  Future<String> getResourceToken(String table) async {
    final _http = HTTP(null);
    final response = await _http.get(
        '${configs['azureBaseUrl']}/GetResourceTokens?refresh_token=${configs['refreshToken']}&code=${configs['azureCode']}&source=cognito');
    List permissions = response['permissions'];
    return permissions
        .firstWhereOrNull((element) => element['id'] == table)['_token'];
  }

  /// Remove private fields before saving to cosmos
  void excludePrivateFields(Map map) {
    map.removeWhere((key, value) => key.startsWith('_'));
  }
}

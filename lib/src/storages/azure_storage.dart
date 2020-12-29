import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart' as crypto;
import 'package:sync_db/sync_db.dart';
import 'package:universal_io/io.dart';

class AzureStorage extends Storage {
  AzureStorageClient _client;

  AzureStorage(Map config) : super(config) {
    _client = AzureStorageClient.parse(config['storageConnectionString']);
  }

  @override
  Future<void> readFromRemote(TransferMap transferMap) async {
    try {
      var response = await _client.getBlob(transferMap.remotePath);
      if (response.statusCode == 200) {
        var localFile = File(transferMap.localPath);
        var ios = localFile.openWrite(mode: FileMode.write);
        ios.add(await response.stream.toBytes());
        await ios.close();
      } else if (response.statusCode == 404) {
        throw FileNotFoundException('404 error on ${transferMap.remotePath}');
      } else {
        throw Exception(
            'download file with error status code ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> writeToRemote(TransferMap transferMap) async {
    try {
      var localFile = File(transferMap.localPath);
      if (!localFile.existsSync()) {
        throw FileNotFoundException(
            'Local file ${transferMap.localPath} does not exis');
      }

      var bytes = Uint8List.fromList(await localFile.readAsBytes());
      await _client.putBlob(transferMap.remotePath, bodyBytes: bytes);
    } catch (e, stackTrace) {
      Sync.shared.logger?.e('Azure Storage upload error $e', e, stackTrace);
      rethrow;
    }
  }
}

enum BlobType {
  BlockBlob,
  AppendBlob,
}

/// Azure Storage Exception
class AzureStorageException implements Exception {
  final String message;
  final int statusCode;
  final Map<String, String> headers;
  AzureStorageException(this.message, this.statusCode, this.headers);
}

/// Azure Storage Client
class AzureStorageClient {
  Map<String, String> config;
  Uint8List accountKey;

  static final String DefaultEndpointsProtocol = 'DefaultEndpointsProtocol';
  static final String EndpointSuffix = 'EndpointSuffix';
  static final String AccountName = 'AccountName';
  static final String AccountKey = 'AccountKey';

  /// Initialize with connection string.
  AzureStorageClient.parse(String connectionString) {
    try {
      var m = <String, String>{};
      var items = connectionString.split(';');
      for (var item in items) {
        var i = item.indexOf('=');
        var key = item.substring(0, i);
        var val = item.substring(i + 1);
        m[key] = val;
      }
      config = m;
      accountKey = base64Decode(config[AccountKey]);
    } catch (e) {
      throw Exception('Parse error.');
    }
  }

  @override
  String toString() {
    return config.toString();
  }

  Uri uri({String path = '/', Map<String, String> queryParameters}) {
    var scheme = config[DefaultEndpointsProtocol] ?? 'https';
    var suffix = config[EndpointSuffix] ?? 'core.windows.net';
    var name = config[AccountName];
    return Uri(
        scheme: scheme,
        host: '${name}.blob.${suffix}',
        path: path,
        queryParameters: queryParameters);
  }

  String _canonicalHeaders(Map<String, String> headers) {
    var keys = headers.keys
        .where((i) => i.startsWith('x-ms-'))
        .map((i) => '${i}:${headers[i]}\n')
        .toList();
    keys.sort();
    return keys.join();
  }

  String _canonicalResources(Map<String, String> items) {
    if (items.isEmpty) {
      return '';
    }
    var keys = items.keys.toList();
    keys.sort();
    return keys.map((i) => '\n${i}:${items[i]}').join();
  }

  void sign(http.Request request) {
    request.headers['x-ms-date'] = HttpDate.format(DateTime.now());
    request.headers['x-ms-version'] = '2016-05-31';
    var ce = request.headers['Content-Encoding'] ?? '';
    var cl = request.headers['Content-Language'] ?? '';
    var cz = request.contentLength == 0 ? '' : '${request.contentLength}';
    var cm = request.headers['Content-MD5'] ?? '';
    var ct = request.headers['Content-Type'] ?? '';
    var dt = request.headers['Date'] ?? '';
    var ims = request.headers['If-Modified-Since'] ?? '';
    var imt = request.headers['If-Match'] ?? '';
    var inm = request.headers['If-None-Match'] ?? '';
    var ius = request.headers['If-Unmodified-Since'] ?? '';
    var ran = request.headers['Range'] ?? '';
    var chs = _canonicalHeaders(request.headers);
    var crs = _canonicalResources(request.url.queryParameters);
    var name = config[AccountName];
    var path = request.url.path;
    var sig =
        '${request.method}\n${ce}\n${cl}\n${cz}\n${cm}\n${ct}\n${dt}\n${ims}\n${imt}\n${inm}\n${ius}\n${ran}\n${chs}/${name}${path}${crs}';
    var mac = crypto.Hmac(crypto.sha256, accountKey);
    var digest = base64Encode(mac.convert(utf8.encode(sig)).bytes);
    var auth = 'SharedKey ${name}:${digest}';
    request.headers['Authorization'] = auth;
    //print(sig);
  }

  /// Get Blob.
  Future<http.StreamedResponse> getBlob(String path) async {
    var request = http.Request('GET', uri(path: path));
    sign(request);
    return request.send();
  }

  /// Put Blob.
  ///
  /// `body` and `bodyBytes` are exclusive and mandatory.
  Future<void> putBlob(String path,
      {String body,
      Uint8List bodyBytes,
      String contentType,
      BlobType type = BlobType.BlockBlob}) async {
    var request = http.Request('PUT', uri(path: path));
    request.headers['x-ms-blob-type'] =
        type.toString() == 'BlobType.AppendBlob' ? 'AppendBlob' : 'BlockBlob';
    if (contentType != null) {
      request.headers['content-type'] = contentType;
    }

    if (type == BlobType.BlockBlob) {
      if (bodyBytes != null) {
        request.bodyBytes = bodyBytes;
      } else if (body != null) {
        request.body = body;
      }
    } else {
      request.body = '';
    }
    sign(request);
    var res = await request.send();
    if (res.statusCode == 201) {
      await res.stream.drain();

      if (type == BlobType.AppendBlob && (body != null || bodyBytes != null)) {
        await appendBlock(path, body: body, bodyBytes: bodyBytes);
      }
      return;
    }

    var message = await res.stream.bytesToString();
    throw AzureStorageException(message, res.statusCode, res.headers);
  }

  /// Append block to blob.
  Future<void> appendBlock(String path,
      {String body, Uint8List bodyBytes}) async {
    var request = http.Request(
        'PUT', uri(path: path, queryParameters: {'comp': 'appendblock'}));
    if (bodyBytes != null) {
      request.bodyBytes = bodyBytes;
    } else if (body != null) {
      request.body = body;
    }
    sign(request);
    var res = await request.send();
    if (res.statusCode == 201) {
      await res.stream.drain();
      return;
    }

    var message = await res.stream.bytesToString();
    throw AzureStorageException(message, res.statusCode, res.headers);
  }
}

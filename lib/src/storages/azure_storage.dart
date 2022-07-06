import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart' as crypto;
import 'package:robust_http/connection_helper.dart';
import 'package:robust_http/exceptions.dart';
import 'package:robust_http/robust_http.dart';
import 'package:sync_db/sync_db.dart';
import 'package:universal_io/io.dart';

class AzureStorage extends Storage {
  AzureStorageTrustedClient _trustedClient;
  AzureStorageUntrustedClient _untrustedClient;
  bool _isTrusted = false;

  /// If there is `storageConnectionString` in config, then it means this is trusted client with full permission on storage
  /// Otherwise it's untrusted client with few limited permission (using SAS for upload & public url for download)
  AzureStorage(Map config) : super(config) {
    _isTrusted = config['storageConnectionString'] != null;
    if (_isTrusted) {
      _trustedClient = AzureStorageTrustedClient(config);
    } else {
      _untrustedClient = AzureStorageUntrustedClient(config);
    }
  }

  @override
  Future<void> readFromRemote(TransferMap transferMap) async {
    // delegate to client storage
    if (_isTrusted) {
      await _trustedClient.readFromRemote(transferMap);
    } else {
      await _untrustedClient.readFromRemote(transferMap);
    }
  }

  @override
  Future<void> writeToRemote(TransferMap transferMap) async {
    // delegate to client storage
    if (_isTrusted) {
      await _trustedClient.writeToRemote(transferMap);
    } else {
      await _untrustedClient.writeToRemote(transferMap);
    }
  }
}

/// Azure Storage Client with full permission to storage account, using REST api
/// https://docs.microsoft.com/en-us/rest/api/storageservices/
class AzureStorageTrustedClient extends Storage {
  Map<String, String> _config;
  Uint8List _accountKey;

  static final String DefaultEndpointsProtocol = 'DefaultEndpointsProtocol';
  static final String EndpointSuffix = 'EndpointSuffix';
  static final String AccountName = 'AccountName';
  static final String AccountKey = 'AccountKey';

  /// Initialize with connection string.
  AzureStorageTrustedClient(Map config) : super(config) {
    final connection = config['storageConnectionString'];
    try {
      var m = <String, String>{};
      var items = connection.split(';');
      for (var item in items) {
        var i = item.indexOf('=');
        var key = item.substring(0, i);
        var val = item.substring(i + 1);
        m[key] = val;
      }
      _config = m;
      _accountKey = base64Decode(_config[AccountKey]);
    } catch (e) {
      throw Exception('Parse error.');
    }
  }

  @override
  Future<void> readFromRemote(TransferMap transferMap) async {
    var localFile = File(transferMap.localPath);
    IOSink ios;
    var hasError = false;
    try {
      // delete previous download file
      if (await localFile.exists()) {
        await localFile.delete();
      }

      var response = await getBlob(transferMap.remotePath);
      if (response.statusCode == 200) {
        ios = localFile.openWrite(mode: FileMode.write);
        ios?.add(await response.stream.toBytes());
      } else if (response.statusCode == 404) {
        throw FileNotFoundException('404 error on ${transferMap.remotePath}');
      } else {
        throw Exception(
            'download file with error status code ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      hasError = true;
      if (!await ConnectionHelper.shared.hasInternetConnection()) {
        throw ConnectivityException(
            'Does not have connection when download  ${transferMap.remotePath} $e $stackTrace');
      }

      rethrow;
    } finally {
      await ios?.flush();
      await ios?.close();
      if (hasError && await localFile.exists()) {
        await localFile.delete();
      }
    }
  }

  @override
  Future<void> writeToRemote(TransferMap transferMap) async {
    try {
      var localFile = File(transferMap.localPath);
      if (!localFile.existsSync()) {
        throw FileNotFoundException(
            'Local file ${transferMap.localPath} does not exist');
      }

      var bytes = Uint8List.fromList(await localFile.readAsBytes());
      await putBlob(transferMap.remotePath, bodyBytes: bytes);
    } catch (e, stackTrace) {
      Sync.shared.logger?.e('Azure Storage upload error $e', e, stackTrace);
      rethrow;
    }
  }

  @override
  String toString() {
    return _config.toString();
  }

  /// build uri from connection string
  Uri _uri({String path = '/', Map<String, String> queryParameters}) {
    var scheme = _config[DefaultEndpointsProtocol] ?? 'https';
    var suffix = _config[EndpointSuffix] ?? 'core.windows.net';
    var name = _config[AccountName];
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

  /// sign request
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
    var name = _config[AccountName];
    var path = request.url.path;
    var sig =
        '${request.method}\n${ce}\n${cl}\n${cz}\n${cm}\n${ct}\n${dt}\n${ims}\n${imt}\n${inm}\n${ius}\n${ran}\n${chs}/${name}${path}${crs}';
    var mac = crypto.Hmac(crypto.sha256, _accountKey);
    var digest = base64Encode(mac.convert(utf8.encode(sig)).bytes);
    var auth = 'SharedKey ${name}:${digest}';
    request.headers['Authorization'] = auth;
    //print(sig);
  }

  /// Get Blob.
  Future<http.StreamedResponse> getBlob(String path) async {
    var request = http.Request('GET', _uri(path: path));
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
    var request = http.Request('PUT', _uri(path: path));
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
        'PUT', _uri(path: path, queryParameters: {'comp': 'appendblock'}));
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

/// Azure storage client with limit access.
/// For download, it requires full public url of the file
/// For upload, it uses SAS url from server api with format: https://{storageAccount}.blob.core.windows.net/{container}/{blob_path}?signature
class AzureStorageUntrustedClient extends Storage {
  HTTP http;
  AzureStorageUntrustedClient(Map config) : super(config) {
    http = HTTP(null, config);
  }
  @override
  Future<void> writeToRemote(TransferMap transferMap) async {
    if (await Sync.shared.userSession.hasSignedIn() != true) {
      Sync.shared.logger?.i('Guest user does not have upload permission');
      return;
    }

    final sasUri = await Sync.shared.userSession.storageToken;
    if (sasUri?.isNotEmpty != true) {
      throw Exception('sas uri must not be null');
    }

    final uri = Uri.parse(sasUri);
    final query = uri.query; // include signature
    final domain = sasUri.replaceFirst('?$query', '');
    final uploadPath = '$domain/${transferMap.remotePath}?$query';
    var localFile = File(transferMap.localPath);
    http.headers = {
      'x-ms-blob-type': 'BlockBlob',
      HttpHeaders.contentLengthHeader: localFile.lengthSync(),
    };

    // upload file by stream
    await http.put(
      uploadPath,
      data: localFile.openRead(),
    );
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

import 'dart:async';

import 'package:mime_type/mime_type.dart';
import 'package:robust_http/connection_helper.dart';
import 'package:robust_http/exceptions.dart';
import 'package:sync_db/sync_db.dart';
import 'package:path/path.dart' as p;
import 'package:universal_io/io.dart';

class S3StorageUntrustedClient extends Storage {
  HttpClient httpClient;
  String _baseUrl;

  S3StorageUntrustedClient(Map config) : super(config) {
    _baseUrl = config['s3UploadRemoteUrl'];
    httpClient = HttpClient()
      ..connectionTimeout = Duration(seconds: config['connectTimeout'] ?? 60000)
      ..idleTimeout = Duration(seconds: config['receiveTimeout'] ?? 60000);
  }

  @override
  Future<void> writeToRemote(TransferMap transferMap) async {
    if (await Sync.shared.userSession.hasSignedIn() != true) {
      Sync.shared.logger?.i('Guest user does not have upload permission');
      return;
    }
    // upload file by stream
    await _uploadFileToS3Bucket(transferMap.localPath, transferMap.remotePath);
  }

  Future<void> _uploadFileToS3Bucket(
      String localPath, String remotePath) async {
    var localFile = File(localPath);
    if (localFile.existsSync()) {
      final mimeType = mime(localPath) ?? '*/*';
      final totalByteLength = localFile.lengthSync();
      final url =
          _baseUrl + (remotePath.startsWith('/') ? remotePath : '/$remotePath');
      final request = await httpClient.putUrl(Uri.parse(url));
      request.headers.set(HttpHeaders.contentTypeHeader, mimeType);
      request.headers.set(HttpHeaders.contentLengthHeader, totalByteLength);
      request.headers.add('filename', p.basename(localPath));
      request.contentLength = totalByteLength;

      final fileStream = localFile.openRead();
      final streamUpload = fileStream.transform<List<int>>(
        StreamTransformer.fromHandlers(
          handleData: (data, sink) {
            sink.add(data);
          },
          handleError: (error, stack, sink) {
            print(error.toString());
          },
          handleDone: (sink) {
            sink.close();
          },
        ),
      );

      await request.addStream(streamUpload);
      final httpResponse = await request.close();
      if (httpResponse.statusCode != 200) {
        if (!await ConnectionHelper.hasConnection()) {
          throw ConnectivityException('The connection is turn off',
              hasConnectionStatus: false);
        }

        if (!await ConnectionHelper.hasInternetConnection()) {
          throw ConnectivityException(
              'The connection is turn on but there is no internet connection',
              hasConnectionStatus: true);
        }

        throw Exception(
            'Error [${httpResponse.statusCode}] uploading file $remotePath, $httpResponse');
      }
    }
  }
}

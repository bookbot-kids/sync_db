import 'dart:async';

import 'package:mime_type/mime_type.dart';
import 'package:robust_http/connection_helper.dart';
import 'package:robust_http/exceptions.dart';
import 'package:robust_http/file_info.dart';
import 'package:robust_http/robust_http.dart';
import 'package:sync_db/sync_db.dart';
import 'package:universal_io/io.dart';
import 'package:path/path.dart' as p;

class S3AzureTrustedStorage extends Storage {
  late HTTP _http;
  S3AzureTrustedStorage(Map config) : super(config) {
    _http = HTTP(config['azureBaseUrl'], {
      'httpRetries': 1,
      'connectTimeout': config['connectTimeout'],
      'receiveTimeout': config['receiveTimeout'],
      'proxyUrl': config['proxyUrl'],
    });
  }

  @override
  Future<void> writeToRemote(TransferMap transferMap) async {
    if (await Sync.shared.userSession?.hasSignedIn() != true) {
      Sync.shared.logger?.i('Guest user does not have upload permission');
      return;
    }
    // upload file by stream
    await _uploadFileToS3Bucket(transferMap.localPath!, transferMap.remotePath);
  }

  Future<void> _uploadFileToS3Bucket(
      String localPath, String? remotePath) async {
    var localFile = File(localPath);
    if (localFile.existsSync()) {
      Sync.shared.logger?.i('upload to s3 from $localPath to $remotePath');
      final refreshToken = (await Sync.shared.userSession?.token) ?? '';
      final params = {
        'code': config['azureKey'],
        'refresh_token': refreshToken,
      };
      final mimeType = mime(localPath) ?? '*/*';
      final filename = p.basename(localPath);
      try {
        final result = await _http.post(
          '/S3StorageUpload',
          parameters: params,
          isMultipart: true,
          data: {
            'files': [
              FileInfo(
                localPath,
                mimeType: mimeType,
                fileName: filename,
              ),
            ],
            'upload_path': remotePath,
          },
          includeHttpResponse: true,
        );
        if (result.statusCode != 200) {
          throw Exception(
              'Error [${result.statusCode}] uploading file $remotePath, $result');
        }
      } catch (e) {
        if (!await ConnectionHelper.shared.hasConnection()) {
          throw ConnectivityException('The connection is turn off',
              hasConnectionStatus: false);
        }

        if (!await ConnectionHelper.shared.hasInternetConnection()) {
          throw ConnectivityException(
              'The connection is turn on but there is no internet connection',
              hasConnectionStatus: true);
        }

        rethrow;
      }
    } else {
      Sync.shared.logger?.i('$localPath file is not exist');
    }
  }
}

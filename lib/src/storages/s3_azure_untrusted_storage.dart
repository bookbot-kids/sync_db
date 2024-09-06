import 'dart:async';
import 'dart:math';

import 'package:robust_http/connection_helper.dart';
import 'package:robust_http/exceptions.dart';
import 'package:robust_http/robust_http.dart';
import 'package:sync_db/sync_db.dart';
import 'package:universal_io/io.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

/// Storage client to upload into s3 by using azure api
/// The file size limit is about 100MB
class S3AzureUntrustedStorage extends Storage {
  late HTTP _http;
  S3AzureUntrustedStorage(Map config) : super(config) {
    _http = HTTP(config['azureBaseUrl'], {
      'httpRetries': 1,
      'connectTimeout': config['connectTimeout'],
      'receiveTimeout': config['receiveTimeout'],
      'proxyUrl': config['proxyUrl'],
    });
  }

  @override
  Future<void> writeToRemote(TransferMap transferMap) async {
    // upload file by stream
    await _uploadFileToS3Bucket(transferMap.localPath!, transferMap.remotePath);
  }

  Future<void> _uploadFileToS3Bucket(
      String localPath, String? remotePath) async {
    var localFile = File(localPath);
    if (localFile.existsSync()) {
      Sync.shared.logger?.i('upload to s3 from $localPath to $remotePath');
      final params = {
        'code': config['azureKey'],
        'upload_path': remotePath,
      };
      try {
        final result = await _http.get(
          '/GetS3StorageUploadUrl',
          parameters: params,
        );
        if (result['success'] == true) {
          final String presignedUrl = result['url'];
          final uploader = S3Uploader(
            presignedUrl: presignedUrl,
            filePath: localPath,
            maxRetries: 3,
            initialBackoff: Duration(seconds: 1),
          );

          await uploader.upload();
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

class S3Uploader {
  final String presignedUrl;
  final String filePath;
  final int maxRetries;
  final Duration initialBackoff;

  S3Uploader({
    required this.presignedUrl,
    required this.filePath,
    this.maxRetries = 3,
    this.initialBackoff = const Duration(seconds: 1),
  });

  Future<void> upload() async {
    final file = File(filePath);
    final fileLength = await file.length();
    final fileName = p.basename(filePath);

    for (var attempt = 0; attempt < maxRetries; attempt++) {
      try {
        await _attemptUpload(file, fileLength, fileName);
        return;
      } catch (e) {
        if (attempt == maxRetries - 1) {
          Sync.shared.logger
              ?.i('Failed to upload file after $maxRetries attempts');
          rethrow;
        }
        final backoffDuration = initialBackoff * pow(2, attempt);
        Sync.shared.logger?.i(
            'Attempt ${attempt + 1} failed: $e. Retrying in ${backoffDuration.inSeconds} seconds...');
        await Future.delayed(backoffDuration);
      }
    }
  }

  Future<void> _attemptUpload(
      File file, int fileLength, String fileName) async {
    final client = http.Client();
    try {
      final request = http.Request('PUT', Uri.parse(presignedUrl));
      request.headers['Content-Type'] = 'application/octet-stream';
      request.headers['Content-Length'] = fileLength.toString();

      // Set the body to the file content
      request.bodyBytes = await file.readAsBytes();

      final response = await client.send(request);

      if (response.statusCode == 200) {
        return;
      } else {
        final responseBody = await response.stream.bytesToString();
        throw Exception(
            'Upload failed with status ${response.statusCode}: $responseBody');
      }
    } finally {
      client.close();
    }
  }
}

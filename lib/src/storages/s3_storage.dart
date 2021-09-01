import 'package:robust_http/robust_http.dart';
import 'package:sync_db/sync_db.dart';
import 'package:universal_io/io.dart';

class S3StorageUntrustedClient extends Storage {
  HTTP http;

  S3StorageUntrustedClient(Map config) : super(config) {
    http = HTTP(config['s3UploadRemoteUrl'], config);
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
      await http.put('/$remotePath', data: localFile.openRead());
    }
  }
}

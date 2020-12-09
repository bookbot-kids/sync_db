import 'package:robust_http/robust_http.dart';
import 'package:sync_db/sync_db.dart';
import 'package:pool/pool.dart';
import 'package:universal_io/io.dart';

class Storage {
  Storage(Map config) {
    _transferTimeout = config['transferTimeout'] ?? 600;
    _http = HTTP(null, config);
    _pool = Pool(config['downloadPoolSize'] ?? 8);
  }

  var _pool;
  var _transferTimeout;
  HTTP _http;

  Future<void> upload(List<Paths> paths) async {
    await transfer(paths, TransferStatus.uploading);
  }

  Future<void> download(List<Paths> paths) async {
    await transfer(paths, TransferStatus.downloading);
  }

  Future<void> transfer(List<Paths> paths, TransferStatus status) async {
    var futures = <Future>[];
    for (final path in paths) {
      final transfer = TransferMap(paths: path, transferStatus: status);
      await transfer.save();

      futures.add(_transfer(transfer));
    }

    await Future.wait(futures);
    _transferUnfinished();
  }

  Future _transfer(transfer) {
    return _pool.withResource(() async {
      if (transfer.transferStatus == TransferStatus.uploading) {
        await writeToRemote(transfer);
      } else {
        await readFromRemote(transfer);
      }
      await transfer.database.deleteLocal(transfer.tableName, transfer.id);
    });
  }

  void _transferUnfinished() {
    TransferMap.all().then((transfers) async {
      final now = await NetworkTime.shared.now;
      final past = now.subtract(Duration(seconds: _transferTimeout));

      for (final transfer in transfers) {
        // TODO: this will need to be double checked that the comparison is correct
        if (transfer.createdAt.isAfter(past)) {
          // ignore: unawaited_futures
          _transfer(transfer);
        }
      }
    });
  }

  /// Read file from cloud storage and save to file that is passed
  Future<void> readFromRemote(TransferMap transferMap) async {
    // Implementation of dio download and stream write
    try {
      var localFile = File(transferMap.localPath);
      if (localFile.existsSync()) {
        // delete the existing local file
        localFile.deleteSync();
      }

      await _http.download(transferMap.remoteUrl,
          localPath: transferMap.localPath);
    } catch (e, stackTrace) {
      Sync.shared.logger?.e('Storage download error $e', e, stackTrace);
      rethrow;
    }
  }

  /// Write file to cloud storage from file
  Future<void> writeToRemote(TransferMap transferMap) async {}
}

class Paths {
  Paths({this.localPath, this.remotePath, this.remoteUrl});
  String localPath;
  String remotePath;
  String remoteUrl;

  @override
  String toString() {
    return 'localPath = $localPath\nremotePath = $remotePath\nremoteUrl = $remoteUrl';
  }
}

class TransferMap extends Model {
  TransferMap({Paths paths, this.transferStatus}) {
    localPath = paths?.localPath;
    remotePath = paths?.remotePath;
    remoteUrl = paths?.remoteUrl;
  }

  String localPath;
  String remotePath;
  String remoteUrl;
  TransferStatus transferStatus;

  @override
  String get tableName => 'TransferMap';

  @override
  Map<String, dynamic> get map {
    var map = super.map;
    map['localPath'] = localPath;
    map['remotePath'] = remotePath;
    map['remoteUrl'] = remoteUrl;
    map['transferStatus'] = transferStatus.name;

    return map;
  }

  @override
  Future<void> setMap(Map<String, dynamic> map) async {
    await super.setMap(map);
    localPath = map['localPath'];
    remotePath = map['remotePath'];
    remoteUrl = map['remoteUrl'];
    transferStatus = $TransferStatus.fromString(map['transferStatus']);
  }

  static Future<List<TransferMap>> all() async {
    var all = await TransferMap().database.all('TransferMap', () {
      return TransferMap();
    });

    return List<TransferMap>.from(all);
  }

  static Future<TransferMap> find(String id) async =>
      await TransferMap().database.find('TransferMap', id, TransferMap());

  static Query where(dynamic condition) {
    return Query('TransferMap').where(condition, TransferMap().database, () {
      return TransferMap();
    });
  }
}

enum TransferStatus { uploading, downloading }

extension $TransferStatus on TransferStatus {
  static final string = {
    TransferStatus.uploading: 'uploading',
    TransferStatus.downloading: 'downloading'
  };

  static final toEnum = {
    'uploading': TransferStatus.uploading,
    'downloading': TransferStatus.downloading
  };

  String get name => $TransferStatus.string[this];
  static TransferStatus fromString(String value) =>
      $TransferStatus.toEnum[value];
}

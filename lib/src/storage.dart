import 'dart:io';

import 'package:sync_db/sync_db.dart';
import 'package:pool/pool.dart';

abstract class Storage {
  Storage(Map config) {
    _transferTimeout = config['transferTimeout'] ?? 600;
  }

  // Makes sure there are no more than 8 uploads/downloads at the same time
  final _pool = Pool(8);
  var _transferTimeout;

  Future<void> upload(List<Paths> paths) async {
    await transfer(paths, TransferStatus.uploading);
  }

  Future<void> download(List<Paths> paths) async {
    await transfer(paths, TransferStatus.downloading);
  }

  Future<void> transfer(List<Paths> paths, TransferStatus status) async {
    var futures = <Future>[];
    for (final path in paths) {
      final transfer = StorageTransfer(
          localPath: path.localPath,
          remote: path.storagePath,
          transferStatus: TransferStatus.uploading);
      await transfer.save();

      futures.add(_pool.withResource(() async {
        if (transfer.transferStatus == TransferStatus.uploading) {
          await writeToRemote(File(path.localPath), path.storagePath);
          await transfer.database.deleteLocal(transfer.tableName, transfer.id);
        } else {
          await readFromRemote(path.url, File(path.localPath));
          await transfer.database.deleteLocal(transfer.tableName, transfer.id);
        }
      }));
    }

    await Future.wait(futures);
    transferUnfinished();
  }

  void transferUnfinished() {
    StorageTransfer.all().then((transfers) async {
      final now = await NetworkTime.shared.now;
      final past = now.subtract(Duration(seconds: _transferTimeout));

      for (final transfer in transfers) {
        // TODO: this will need to be double checked that the comparison is correct
        if (transfer.createdAt.isAfter(past)) {
          if (transfer.transferStatus == TransferStatus.uploading) {
            // ignore: unawaited_futures
            _pool.withResource(() async {
              await writeToRemote(File(transfer.localPath), transfer.remote);
              await transfer.database
                  .deleteLocal(transfer.tableName, transfer.id);
            });
          } else {
            // ignore: unawaited_futures
            _pool.withResource(() async {
              await readFromRemote(transfer.remote, File(transfer.localPath));
              await transfer.database
                  .deleteLocal(transfer.tableName, transfer.id);
            });
          }
        }
      }
    });
  }

  /// Read file from cloud storage and save to file that is passed
  Future<void> readFromRemote(String storagePath, File file);

  /// Write file to cloud storage from file
  Future<void> writeToRemote(File file, String storagePath);
}

class Paths {
  Paths({this.localPath, this.storagePath, this.url});
  String localPath;
  String storagePath;
  String url;
}

class StorageTransfer extends Model {
  StorageTransfer({this.localPath, this.remote, this.transferStatus});

  String localPath;
  String remote;
  TransferStatus transferStatus;

  @override
  String get tableName => 'StorageTransfer';

  @override
  Map<String, dynamic> get map {
    var map = super.map;
    map['localPath'] = localPath;
    map['remote'] = remote;
    map['transferStatus'] = transferStatus.name;

    return map;
  }

  @override
  Future<void> setMap(Map<String, dynamic> map) async {
    await super.setMap(map);
    localPath = map['localPath'];
    remote = map['remote'];
    transferStatus = $TransferStatus.fromString(map['transferStatus']);
  }

  static Future<List<StorageTransfer>> all() async {
    var all = await StorageTransfer().database.all('StorageTransfer', () {
      return StorageTransfer();
    });

    return List<StorageTransfer>.from(all);
  }

  static Future<StorageTransfer> find(String id) async =>
      await StorageTransfer()
          .database
          .find('StorageTransfer', id, StorageTransfer());

  static Query where(dynamic condition) {
    return Query('StorageTransfer').where(condition, StorageTransfer().database,
        () {
      return StorageTransfer();
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
    'read': TransferStatus.downloading
  };

  String get name => $TransferStatus.string[this];
  static TransferStatus fromString(String value) =>
      $TransferStatus.toEnum[value];
}

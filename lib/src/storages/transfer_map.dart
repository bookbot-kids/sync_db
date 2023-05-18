import 'package:isar/isar.dart';
import 'package:sync_db/src/model.dart';
import 'package:sync_db/src/services/service_point.dart';
part 'transfer_map.g.dart';

enum TransferStatus { uploading, downloading }

extension $TransferStatus on TransferStatus? {
  static final string = {
    TransferStatus.uploading: 'uploading',
    TransferStatus.downloading: 'downloading'
  };

  static final toEnum = {
    'uploading': TransferStatus.uploading,
    'downloading': TransferStatus.downloading
  };

  String? get name => $TransferStatus.string[this!];
  static TransferStatus? fromString(String? value) =>
      $TransferStatus.toEnum[value!];
}

class Paths {
  Paths({
    this.localPath = '',
    this.assetPath = '',
    this.remotePath = '',
    this.remoteUrl = '',
    this.ondemandPath = '',
  });
  String localPath;
  String assetPath;
  String remotePath;
  String remoteUrl;
  String ondemandPath;

  @override
  String toString() {
    return 'localPath = $localPath\nassetPath = $assetPath remotePath = $remotePath\nremoteUrl = $remoteUrl\nondemandPath = $ondemandPath';
  }
}

@collection
class TransferMap extends Model {
  TransferMap(
      {Paths? paths, this.transferStatus = TransferStatus.downloading}) {
    localPath = paths?.localPath;
    remotePath = paths?.remotePath;
    remoteUrl = paths?.remoteUrl;
  }

  String? localPath;
  String? remotePath;
  String? remoteUrl;

  @enumerated
  TransferStatus transferStatus = TransferStatus.downloading;

  @Ignore()
  @override
  String get tableName => 'TransferMap';

  @Ignore()
  @override
  SyncPermission get syncPermission => SyncPermission.read;

  Future<List<TransferMap>> all() async {
    return db.transferMaps.filter().deletedAtIsNull().findAll();
  }

  @override
  Future<TransferMap?> find(String? id, {bool filterDeletedAt = true}) async =>
      await db.transferMaps
          .filter()
          .idEqualTo(id)
          .deletedAtIsNull()
          .findFirst();

  @override
  Future<void> deleteLocal() async {
    if (id != null) {
      await db.writeTxn(() async {
        await db.transferMaps.delete(localId);
      });
    }
  }

  @override
  Future<void> save({
    bool syncToService = true,
    bool runInTransaction = true,
    bool initialize = true,
  }) async {
    final func = () async {
      if (initialize) {
        await init();
      }

      await db.transferMaps.put(this);
    };

    if (runInTransaction) {
      return db.writeTxn(() async {
        await func();
      });
    } else {
      await func();
    }
  }

  @override
  Set<String> get keys => {};

  @override
  Future<List<T>> queryStatus<T extends Model>(SyncStatus syncStatus,
      {bool filterDeletedAt = true}) async {
    final result = filterDeletedAt
        ? await db.transferMaps
            .filter()
            .syncStatusEqualTo(syncStatus)
            .deletedAtIsNull()
            .findAll()
        : await db.transferMaps
            .filter()
            .syncStatusEqualTo(syncStatus)
            .findAll();
    return result.cast();
  }

  @override
  Future<void> clear() {
    return db.transferMaps.clear();
  }
}

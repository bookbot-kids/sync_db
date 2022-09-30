import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:sync_db/sync_db.dart';
import 'package:universal_io/io.dart';
import 'package:uuid/uuid.dart';

enum SyncPermission { user, read }

enum AssetStatus {
  none,
  asset, // flutter asset
  native, // native platform asset
  local, // local file asset
  ondemand, // on-demand resource asset. Can access on native
  deferred, // deferred components. Unlike on-demand assets, it can access on flutter side after download
}

abstract class Model extends ChangeNotifier implements ModelHandler {
  Id localId = Isar.autoIncrement;
  DateTime? createdAt;
  DateTime? deletedAt;
  String? id;
  DateTime? updatedAt;
  String metadata = '';
  String? partition;

  @Ignore()
  Map get metadataMap => metadata.isEmpty ? {} : json.decode(metadata);

  @enumerated
  SyncStatus syncStatus = SyncStatus.none;

  @override
  String toString() {
    return map.toString();
  }

  @Ignore()
  Isar get db => Sync.shared.db.local;

  @Ignore()
  SyncPermission get syncPermission => SyncPermission.user;

  @Ignore()
  Map get map {
    var map = {};
    map[idKey] = id;
    if (createdAt != null) {
      map[createdKey] = createdAt?.millisecondsSinceEpoch;
    }

    if (updatedAt != null) {
      map[updatedKey] = updatedAt?.millisecondsSinceEpoch;
    }

    if (deletedAt != null) {
      map[deletedKey] = deletedAt?.millisecondsSinceEpoch;
    }

    return map;
  }

  Future<Set<String>> setMap(Map map) async {
    id = map[idKey];
    if (map[createdKey] is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(map[createdKey]);
    }

    if (map[updatedKey] is int) {
      updatedAt = DateTime.fromMillisecondsSinceEpoch(map[updatedKey]);
    }

    if (map[deletedKey] is int) {
      deletedAt = DateTime.fromMillisecondsSinceEpoch(map[deletedKey]);
    }

    return {};
  }

  @Ignore()
  String get tableName;

  Future<void> save({
    bool syncToService = true,
    bool runInTransaction = true,
    bool initialize = true,
  });

  /// delete and sync record
  Future<void> delete() async {
    deletedAt = await NetworkTime.shared.now;
    await save();
  }

  /// delete local record
  Future<void> deleteLocal() async {}

  void setMetadata(Set<String> keys, Map data) {
    keys.addAll([
      idKey,
      createdKey,
      updatedKey,
      deletedKey,
      'partition',
    ]);

    final newMap = {};
    for (final item in data.entries) {
      if (!keys.contains(item.key)) {
        newMap[item.key] = item.value;
      }
    }
    metadata = json.encode(newMap);
  }

  /// Find record by id
  @override
  Future<Model?> find(String? id);

  /// Storage managers and functions
  /// Readme: Files are handled in groups in the record.
  /// You can upload or download all files related to this record
  /// If you need one file it will find this in `file` - but if it does not exist it will download
  /// all files related to this record

  /// See if file exists, otherwise download()
  Future<File> file({String key = 'default', bool retry = false}) async {
    final path = localFilePath(key: key)!;
    final file = File(path);
    if (await file.exists()) {
      return file;
    }

    await download(key, retry);
    return File(path);
  }

  /// Upload all files in this record to storage
  /// It will upload again, even if this has been uploaded before
  Future<void> upload([String? key, bool retry = false]) async {
    if (filePaths().containsKey(key)) {
      final path = filePaths()[key];
      if (path != null) {
        await Sync.shared.storage?.upload([path], retry: retry);
      }
    } else {
      await Sync.shared.storage
          ?.upload(List<Paths>.from(filePaths().values), retry: retry);
    }
  }

  /// Download all files in this record from storage
  /// It will download again, even if this has been downloaded before
  Future<void> download([String? key, bool retry = false]) async {
    if (filePaths().containsKey(key)) {
      final path = filePaths()[key];
      if (path != null) {
        await Sync.shared.storage?.download([path], retry: retry);
      }
    } else {
      await Sync.shared.storage
          ?.download(List<Paths>.from(filePaths().values), retry: retry);
    }
  }

  static Future<void> downloadAll<T extends Model>(List<T> records,
      {String key = 'default', retry = true}) async {
    final futures = <Future>[];
    for (final record in records) {
      // We wont be doing anything with the file, but it will download files that haven't been downloaded
      futures.add(record.file(key: key, retry: retry));
    }

    await Future.wait(futures);
  }

  /// Local filePath from key
  String? localFilePath({String key = 'default'}) {
    return filePaths()[key]!.localPath;
  }

  /// URL from it's key
  String? url({String key = 'default'}) {
    return filePaths()[key]!.remoteUrl;
  }

  /// Override this with the key, and the Paths class
  /// e.g. {'default': Paths(localPath: '/path/123.txt',
  /// remotePath: '/remote/path/123.txt', remoteUrl: 'htts://storage.azure.com/bucket/file.txt')}
  Map<String, Paths> filePaths() {
    return {};
  }

  /// For the purpose of keeping track of where the associated files are
  /// Are they assets, local or missing?
  AssetStatus assetStatus({String? key}) {
    return AssetStatus.none;
  }

  void setAssetStatus(AssetStatus assetStatus, {String? key}) {}

  static String get newId => Uuid().v4().toString();

  Future<void> init() async {
    final isCreated = id == null || createdAt == null;
    id ??= newId;
    final now = await NetworkTime.shared.now;
    createdAt ??= now;
    updatedAt = now;
    if (isCreated) {
      syncStatus = SyncStatus.created;
    } else {
      if (syncStatus == SyncStatus.created) {
        // do nothing
      } else {
        syncStatus = SyncStatus.updated;
      }
    }
  }

  Future<void> sync() async {
    // don't sync on testing
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return;
    }

    if (syncPermission == SyncPermission.user) {
      // ignore: unawaited_futures
      Sync.shared.service?.writeTable(tableName);
    }
  }

  @override
  Future<List<T>> queryStatus<T extends Model>(SyncStatus syncStatus);

  Map<String, List<String>> remapFields() => {};

  bool fieldEqual(dynamic a, dynamic b) {
    return jsonEncode(a) == jsonEncode(b);
  }
}

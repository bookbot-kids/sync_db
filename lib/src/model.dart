import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sync_db/sync_db.dart';

abstract class Model extends ChangeNotifier {
  DateTime createdAt;
  DateTime deletedAt;
  String id;
  DateTime updatedAt;

  StreamSubscription _subscription;

  @override
  String toString() {
    return map.toString();
  }

  Database get database => Sync.shared.local;

  Map<String, dynamic> get map {
    var map = <String, dynamic>{};
    map[idKey] = id;
    if (createdAt != null) {
      map[createdKey] = createdAt.millisecondsSinceEpoch;
    }

    if (updatedAt != null) {
      map[updatedKey] = updatedAt.millisecondsSinceEpoch;
    }

    if (deletedAt != null) {
      map[deletedKey] = deletedAt.millisecondsSinceEpoch;
    }

    return map;
  }

  Future<void> setMap(Map<String, dynamic> map) async {
    id = map[idKey];
    if (map[createdKey] is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(map[createdKey]);
    }

    if (map[updatedAt] is int) {
      updatedAt = DateTime.fromMillisecondsSinceEpoch(map[updatedAt]);
    }

    if (map[deletedKey] is int) {
      deletedAt = DateTime.fromMillisecondsSinceEpoch(map[deletedKey]);
    }
  }

  String get tableName;

  Future<void> save({bool syncToService = true}) async =>
      await database.save(this, syncToService: syncToService);

  Future<void> delete() async {
    deletedAt = await NetworkTime.shared.now;
    await save();
  }

  Future<void> deleteAll() async {
    var now = (await NetworkTime.shared.now).millisecondsSinceEpoch;
    await database.runInTransaction(tableName, (transaction) async {
      var list =
          await database.queryMap(Query(tableName), transaction: transaction);
      for (var item in list) {
        item[deletedKey] = now;
        item[updatedKey] = now;
        item[statusKey] = SyncStatus.updated.name;
        await database.saveMap(tableName, item, transaction: transaction);
      }
    });
  }

  /// Set the stream listener for this record. It will notify when the record in db is updated.
  /// When this happens, it will reload all the properties by `setMap`
  set stream(Stream value) {
    _subscription = value.listen((event) async {
      //var record = sembast_utils.cloneValue(event.value);
      await setMap(event.value);
      notifyListeners();
    });
  }

  /// Cancel listener
  void cancel() {
    _subscription?.cancel();
  }

  /// Get filePath from key
  /// Does local path exist - if not download()
  String localFilePath({String key = 'default'}) {
    return filePaths()[key].localPath;
  }

  Future<File> file({String key = 'default'}) async {
    final path = localFilePath(key: key);
    final file = File(path);
    if (await file.exists()) {
      return file;
    }

    await download();
    return File(path);
  }

  /// Get url from it's key
  String url({String key = 'default'}) {
    return filePaths()[key].remoteUrl;
  }

  /// Upload all files in this record to storage
  Future<void> upload() async {
    await Sync.shared.storage.upload(List<Paths>.from(filePaths().values));
  }

  /// Download all files in this record from storage
  Future<void> download() async {
    await Sync.shared.storage.download(List<Paths>.from(filePaths().values));
  }

  /// Override this with the key, and the Paths class
  /// e.g. {'default': Paths(localPath: '/path/123.txt',
  /// remotePath: '/remote/path/123.txt', remoteUrl: 'htts://storage.azure.com/bucket/file.txt')}
  Map<String, Paths> filePaths() {
    return {};
  }
}

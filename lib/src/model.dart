import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sync_db/sync_db.dart';
import 'package:universal_io/io.dart';

enum SyncOverride { none, read }

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
  SyncOverride get syncOverride => SyncOverride.none;

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

  /// Storage managers and functions
  /// Readme: Files are handled in groups in the record.
  /// You can upload or download all files related to this record
  /// If you need one file it will find this in `file` - but if it does not exist it will download
  /// all files related to this record

  /// See if file exists, otherwise download()
  Future<File> file({String key = 'default'}) async {
    final path = localFilePath(key: key);
    final file = File(path);
    if (await file.exists()) {
      return file;
    }

    await download(key);
    return File(path);
  }

  /// Upload all files in this record to storage
  /// It will upload again, even if this has been uploaded before
  Future<void> upload([String key]) async {
    if (filePaths().containsKey(key)) {
      await Sync.shared.storage.upload([filePaths()[key]]);
    } else {
      await Sync.shared.storage.upload(List<Paths>.from(filePaths().values));
    }
  }

  /// Download all files in this record from storage
  /// It will download again, even if this has been downloaded before
  Future<void> download([String key]) async {
    if (filePaths().containsKey(key)) {
      await Sync.shared.storage.download([filePaths()[key]]);
    } else {
      await Sync.shared.storage.download(List<Paths>.from(filePaths().values));
    }
  }

  static Future<void> downloadAll<T extends Model>(List<T> records,
      {String key = 'default'}) async {
    final futures = <Future>[];
    for (final record in records) {
      // We wont be doing anything with the file, but it will download files that haven't been downloaded
      futures.add(record.file(key: key));
    }
    return Future.wait(futures);
  }

  /// Local filePath from key
  String localFilePath({String key = 'default'}) {
    return filePaths()[key].localPath;
  }

  /// URL from it's key
  String url({String key = 'default'}) {
    return filePaths()[key].remoteUrl;
  }

  /// Override this with the key, and the Paths class
  /// e.g. {'default': Paths(localPath: '/path/123.txt',
  /// remotePath: '/remote/path/123.txt', remoteUrl: 'htts://storage.azure.com/bucket/file.txt')}
  Map<String, Paths> filePaths() {
    return {};
  }
}

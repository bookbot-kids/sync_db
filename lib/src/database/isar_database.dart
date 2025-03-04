import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:singleton/singleton.dart';
import 'package:sync_db/src/model.dart';
import 'package:sync_db/src/services/service_point.dart';
import 'package:sync_db/src/services/service_record.dart';
import 'package:sync_db/src/services/sync_delegate.dart';
import 'package:sync_db/src/storages/transfer_map.dart';
import 'package:sync_db/src/sync_db.dart';
import 'package:synchronized/synchronized.dart';
import 'package:universal_io/io.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast/utils/value_utils.dart';
import 'package:sembast/sembast.dart' as sembast;

class IsarDatabase {
  factory IsarDatabase() =>
      Singleton.lazy(() => IsarDatabase._privateConstructor());
  IsarDatabase._privateConstructor();
  static IsarDatabase shared = IsarDatabase();

  static const appVersionKey = 'app_version';
  Map<String, ModelHandler> modelHandlers = {};
  Map<String, Model Function()> modelInstances = {};
  bool _isInitialized = false;
  late int _maxSizeMiB;
  static final _lock = Lock();
  static Isar? _local;
  int maxSavingTime = 1000; // in ms
  Function(String)? _logCallback;

  Isar get local => IsarDatabase._local!;

  Future<void> init(
    Map<CollectionSchema<dynamic>, Model Function()> models, {
    String dbAssetPath = 'assets/db',
    String? version,
    List<String>? manifest,
    List<String> fileTypes = const ['.db', '.json'],
    int? maxSizeMiB,
    Map<String, dynamic> configs = const {},
    logDetails = false,
    Function(String)? logCallback,
  }) async {
    _logCallback = logCallback;
    maxSavingTime = configs['maxSavingTime'] ?? 1000;
    Sync.shared.savingCacheStores.clear();
    models[ServicePointSchema] = () => ServicePoint();
    models[TransferMapSchema] = () => TransferMap();
    models[ServiceRecordSchema] = () => ServiceRecord();
    _maxSizeMiB = maxSizeMiB ?? Isar.defaultMaxSizeMiB;

    String dir;
    if (!kIsWeb) {
      // get document directory
      final documentPath = await getApplicationSupportDirectory();
      await documentPath.create(recursive: true);
      dir = documentPath.path;
    } else {
      dir = '';
    }

    if (!_isInitialized || _local == null) {
      await _lock.synchronized(() async {
        _logDebug('init isar at path $dir, size $_maxSizeMiB');
        _local ??= Isar.getInstance() ??
            await Isar.open(
              models.keys.toList(),
              directory: dir,
              maxSizeMiB: _maxSizeMiB,
            );
        _isInitialized = true;
        _logDebug('init isar at path $dir completed');
      });
    }

    modelHandlers = {for (var v in models.values) v().tableName: v()};
    models.values.forEach((func) {
      final instance = func.call();
      modelInstances[instance.tableName] = func;
      _logDebug('setup model handler ${instance.tableName}');
    });

    // copy database
    if (dbAssetPath.isNotEmpty != true ||
        version?.isNotEmpty != true ||
        manifest?.isNotEmpty != true) {
      _logDebug(
          'Ignore empty params dbAssetPath $dbAssetPath, version $version, manifest $manifest');
      return;
    }

    if (kIsWeb) {
      // don't support copy snapshot on web
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final oldVersion = prefs.getString(appVersionKey);
    if (oldVersion != version) {
      _logDebug('start migrate data for version $version');
      await _lock.synchronized(() async {
        // do copy from asset
        final assetItems = manifest ?? <String>[];
        for (final asset in assetItems) {
          if (asset.startsWith(dbAssetPath) &&
              fileTypes
                  .any((element) => asset.toLowerCase().endsWith(element))) {
            final tableName = basenameWithoutExtension(asset);
            _logDebug('Copy asset $asset to $tableName');
            // copy asset to file dir
            Stopwatch? stopwatch;
            if (_logCallback != null) {
              stopwatch = Stopwatch()..start();
            }
            final assetContent = await rootBundle.load(asset);
            await importJsonSnapshotTable(
                assetContent.buffer.asUint8List(), tableName);

            _logDebug(
                'Copy db asset $asset to $tableName done in ${_logCallback != null ? '${stopwatch?.elapsedMilliseconds}ms' : ''}');
            if (_logCallback != null) {
              stopwatch?.stop();
            }
          } else {
            _logDebug('Not found asset $asset to copy');
          }
        }

        await prefs.setString(appVersionKey, version!);
        Sync.shared.logger?.i('copy done');
      });
    }
  }

  void close({bool deleteFromDisk = false}) {
    local.close(deleteFromDisk: deleteFromDisk);
    _logDebug('close isar db done deleteFromDisk $deleteFromDisk');
  }

  void _logDebug(String message) {
    _logCallback?.call(message);
  }

  /// Import isar json
  Future<void> importJsonSnapshotTable(
      Uint8List jsonData, String tableName) async {
    final modelHandler = modelInstances[tableName];
    if (modelHandler == null) {
      print('model handler $tableName not exist');
      _logDebug('model handler $tableName not exist');
      return;
    }

    await local.writeTxn(() async {
      _logDebug('Clear table $tableName');
      await modelHandler.call().clear();
      final entry = modelHandler.call();
      await entry.importJson(jsonData);
      _logDebug('Imported json for table $tableName');
    });
  }

  // Copy sembast database into isar
  @Deprecated('sembast method will be removed later')
  Future<void> migrateTableData(String tableName) async {
    final documentPath = await getApplicationSupportDirectory();
    await documentPath.create(recursive: true);
    final targetFile = File(join(documentPath.path, '$tableName.db'));
    if (await targetFile.exists()) {
      await copySnapshotTable(targetFile, tableName);
      await targetFile.delete();
    }
  }

  // Copy snapshot sembast database into isar
  @Deprecated('sembast method will be removed later')
  Future<void> copySnapshotTable(File targetFile, String tableName) async {
    final db = await databaseFactoryIo.openDatabase(targetFile.path);
    final store = sembast.StoreRef.main();
    final finder = sembast.Finder();
    final records = await store.find(db, finder: finder);
    final recordMaps = records.map((e) {
      final value = e.value;
      if (value is Map) {
        return Map<dynamic, dynamic>.from(cloneMap(value));
      }

      return {};
    }).toList();
    await db.close();
    final modelHandler = modelInstances[tableName];
    if (modelHandler == null) {
      print('model handler $tableName not exist');
      return;
    }

    await local.writeTxn(() async {
      await modelHandler.call().clear();
      Sync.shared.logger?.i('Clear table $tableName');
      for (final record in recordMaps) {
        final entry = modelHandler.call();
        final keys = await entry.setMap(record);
        entry.setMetadata(keys, record);
        await entry.init();
        entry.syncStatus = SyncStatus.synced;
        await entry.save(
            syncToService: false, runInTransaction: false, initialize: false);
        Sync.shared.logger?.i('save done $tableName ${entry.id}');
      }
    });
  }

  @Deprecated('sembast method will be removed later')
  Future<void> copySnapShotTables(
      List<String> tableNames, String dbAssetPath) async {
    if (kIsWeb || dbAssetPath.isNotEmpty != true) {
      return;
    }
    // get document directory
    final documentPath = await getApplicationSupportDirectory();
    await documentPath.create(recursive: true);
    final dir = documentPath.path;

    final futures = <Future>[];
    for (final tableName in tableNames) {
      final fileName = '${tableName}.db';
      final targetPath = dir.isEmpty ? fileName : join(dir, fileName);
      final tableAssetPath = '$dbAssetPath$fileName';
      // copy asset to file dir
      final assetContent = await rootBundle.load(tableAssetPath);
      final targetFile = File(targetPath);
      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      final bytes = assetContent.buffer
          .asUint8List(assetContent.offsetInBytes, assetContent.lengthInBytes);
      await targetFile.writeAsBytes(bytes);
      futures.add(copySnapshotTable(targetFile, tableName));
    }
    await Future.wait(futures);
  }
}

import 'package:flutter/services.dart';
import 'package:isar/isar.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast/utils/value_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sync_db/src/model.dart';
import 'package:sync_db/src/services/service_point.dart';
import 'package:sync_db/src/services/sync_delegate.dart';
import 'package:sync_db/src/storages/transfer_map.dart';
import 'package:sync_db/src/sync_db.dart';
import 'package:universal_io/io.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:sembast/sembast.dart' as sembast;

class IsarDatabase {
  static const appVersionKey = 'app_version';
  Map<String, ModelHandler> modelHandlers = {};
  Map<String, Model Function()> modelInstances = {};
  late Isar local;
  bool _isInitialized = false;

  Future<void> init(
    Map<CollectionSchema<dynamic>, Model Function()> models, {
    String dbAssetPath = 'assets/db',
    String? version,
    List<String>? manifest,
  }) async {
    models[ServicePointSchema] = () => ServicePoint();
    models[TransferMapSchema] = () => TransferMap();

    String? dir;
    if (!UniversalPlatform.isWeb) {
      // get document directory
      final documentPath = await getApplicationSupportDirectory();
      await documentPath.create(recursive: true);
      dir = documentPath.path;
    }

    if (!_isInitialized) {
      final isar = await Isar.open(
        models.keys.toList(),
        directory: dir,
      );

      local = isar;
      _isInitialized = true;
    }

    modelHandlers = {for (var v in models.values) v().tableName: v()};
    models.values.forEach((func) {
      final instance = func.call();
      modelInstances[instance.tableName] = func;
    });

    // copy database
    if (dbAssetPath.isNotEmpty != true ||
        version?.isNotEmpty != true ||
        manifest?.isNotEmpty != true) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final oldVersion = prefs.getString(appVersionKey);
    if (oldVersion != version) {
      // do copy from asset
      final futures = <Future>[];
      for (final asset in manifest!) {
        if (asset.startsWith(dbAssetPath)) {
          final fileName = basename(asset);
          Sync.shared.logger?.i('copy database $fileName');
          final targetPath = dir == null ? fileName : join(dir, fileName);
          futures.add(_copySnapshotTable(
              asset, targetPath, basenameWithoutExtension(asset)));
        }
      }

      await Future.wait(futures);
      await prefs.setString(appVersionKey, version!);
      Sync.shared.logger?.i('copy done');
    }
  }

  void close({bool deleteFromDisk = false}) {
    local.close(deleteFromDisk: deleteFromDisk);
  }

  Future<void> _copySnapshotTable(
      String assetPath, String targetPath, String tableName) async {
    try {
      final assetContent = await rootBundle.load(assetPath);
      final targetFile = File(targetPath);
      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      final bytes = assetContent.buffer
          .asUint8List(assetContent.offsetInBytes, assetContent.lengthInBytes);
      await targetFile.writeAsBytes(bytes);
      final db = await databaseFactoryIo.openDatabase(targetPath);
      final store = sembast.StoreRef.main();
      final finder = sembast.Finder();
      final records = await store.find(db, finder: finder);
      final recordMaps = records
          .map((e) => Map<dynamic, dynamic>.from(cloneMap(e.value)))
          .toList();
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
    } catch (e, stacktrace) {
      Sync.shared.logger
          ?.e('Copy snapshot $assetPath failed $e', e, stacktrace);
    }
  }
}

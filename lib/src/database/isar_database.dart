import 'dart:async';

import 'open_isar_with_retry.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:isar_community/isar.dart';
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

  /// Opens the database and imports bundled snapshots when [version] changes.
  ///
  /// Tables listed in [invalidateSyncStateForTables] are authoritative
  /// replacements of locally synced data. Their service points are deleted
  /// with the import so their next authenticated sync starts from zero.
  Future<void> init(
    Map<CollectionSchema<dynamic>, Model Function()> models, {
    List<CollectionSchema<dynamic>> localSchemas = const [],
    Set<String> invalidateSyncStateForTables = const {},
    String dbAssetPath = 'assets/db',
    String? version,
    List<String>? manifest,
    List<String> fileTypes = const ['.db', '.json'],
    int? maxSizeMiB,
    Map<String, dynamic> configs = const {},
    logDetails = false,
    Future<void> Function(IsarError, StackTrace)? onOpenFailure,
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
            await openIsarWithRetry(
                () => Isar.open(
                      // Local-only collections are opened alongside the synced models,
                      // but never registered as model handlers - nothing syncs them.
                      [...models.keys, ...localSchemas],
                      directory: dir,
                      maxSizeMiB: _maxSizeMiB,
                    ),
                log: _logDebug,
                onOpenFailure: onOpenFailure);
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
        // A large table ships as Table.001.json, Table.002.json... so that it
        // is never read into memory whole. Group each table's parts.
        final tables = <String, List<String>>{};
        for (final asset in manifest ?? <String>[]) {
          if (asset.startsWith(dbAssetPath) &&
              fileTypes
                  .any((element) => asset.toLowerCase().endsWith(element))) {
            final tableName = basenameWithoutExtension(asset).split('.').first;
            tables.putIfAbsent(tableName, () => []).add(asset);
          }
        }
        for (final entry in tables.entries) {
          final tableName = entry.key;
          final assets = entry.value..sort();
          _logDebug('Copy asset ${assets.join(', ')} to $tableName');
          Stopwatch? stopwatch;
          if (_logCallback != null) {
            stopwatch = Stopwatch()..start();
          }
          await importJsonSnapshotTableParts(
            tableName,
            [
              for (final asset in assets)
                () async => (await rootBundle.load(asset)).buffer.asUint8List()
            ],
            invalidateSyncState:
                invalidateSyncStateForTables.contains(tableName),
          );
          _logDebug(
              'Copy db asset ${assets.length} file(s) to $tableName done in ${_logCallback != null ? '${stopwatch?.elapsedMilliseconds}ms' : ''}');
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
    _logCallback?.call('[DEBUG] [IsarDatabase] $message');
  }

  /// Replaces one Isar collection with a JSON snapshot.
  ///
  /// When [invalidateSyncState] is true, all remote partition cursors for the
  /// table are removed together with the old rows.
  ///
  /// Not one transaction. MDBX cannot reuse pages freed inside a transaction
  /// until it commits, so clearing and importing together needed room for the
  /// old and the new table at once: 275 MiB for the 597k-word Spanish
  /// dictionary, over a 256 MiB cap. Clearing commits first, and the new rows
  /// then go in chunks of about [chunkBytes] of JSON, each committed, which
  /// also bounds the native memory one import holds.
  ///
  /// The file's structure is checked before anything is cleared, so a
  /// malformed snapshot keeps the old rows and their cursors. A failure part
  /// way through leaves the table partial; [init] records the new version only
  /// after every table imports, so the next launch imports it again.
  Future<void> importJsonSnapshotTable(
    Uint8List jsonData,
    String tableName, {
    bool invalidateSyncState = false,
    int chunkBytes = 8 * 1024 * 1024,
  }) =>
      importJsonSnapshotTableParts(
        tableName,
        [() async => jsonData],
        invalidateSyncState: invalidateSyncState,
        chunkBytes: chunkBytes,
      );

  /// [importJsonSnapshotTable] for a table shipped as several JSON arrays,
  /// read one at a time through [parts] so only one is in memory at once.
  /// Every part is checked before the old rows are cleared.
  Future<void> importJsonSnapshotTableParts(
    String tableName,
    List<Future<Uint8List> Function()> parts, {
    bool invalidateSyncState = false,
    int chunkBytes = 8 * 1024 * 1024,
  }) async {
    final modelHandler = modelInstances[tableName];
    if (modelHandler == null) {
      print('model handler $tableName not exist');
      _logDebug('model handler $tableName not exist');
      return;
    }

    // Loaded twice, check then import, rather than holding every part at once.
    for (final load in parts) {
      final bytes = await load();
      splitJsonArray(bytes, bytes.length + 1);
    }
    var chunkCount = 0;
    Stopwatch? stopwatch;
    if (_logCallback != null) {
      stopwatch = Stopwatch()..start();
    }

    await local.writeTxn(() async {
      _logDebug('Clear table $tableName');
      await modelHandler.call().clear();
      if (invalidateSyncState) {
        // Replacing a table destroys records that may still exist in the
        // remote partition. Its incremental cursor can no longer describe
        // the local table, so remove every partition's service point. The
        // next authenticated sync obtains a fresh token and starts at zero.
        // Cleared with the old rows, so rows and cursors never disagree.
        final servicePointIds = await local.servicePoints
            .filter()
            .nameEqualTo(tableName)
            .localIdProperty()
            .findAll();
        if (servicePointIds.isNotEmpty) {
          await local.servicePoints.deleteAll(servicePointIds);
        }
        _logDebug(
            'Invalidated ${servicePointIds.length} sync service point(s) for $tableName');
      }
    });

    for (final load in parts) {
      for (final chunk in splitJsonArray(await load(), chunkBytes)) {
        await local.writeTxn(() => modelHandler.call().importJson(chunk));
        chunkCount++;
      }
    }
    _logDebug(
        'Imported json for table $tableName in $chunkCount chunk(s) from ${parts.length} part(s) done in ${_logCallback != null ? '${stopwatch?.elapsedMilliseconds}ms' : ''}');
  }

  /// Cuts a JSON array into smaller arrays of whole elements, each about
  /// [maxBytes] long (one element larger than that becomes its own chunk).
  ///
  /// Scans bytes only - no decoding - but checks the structure: the input must
  /// be a single array with balanced brackets and closed strings, or this
  /// throws [FormatException] before the caller has changed anything.
  @visibleForTesting
  static List<Uint8List> splitJsonArray(Uint8List json, int maxBytes) {
    const openArray = 0x5B, closeArray = 0x5D, openObject = 0x7B;
    const closeObject = 0x7D, quote = 0x22, backslash = 0x5C, comma = 0x2C;
    bool isSpace(int b) => b == 0x20 || b == 0x0A || b == 0x0D || b == 0x09;

    var i = 0;
    // A UTF-8 byte order mark is not part of the JSON.
    if (json.length >= 3 && json[0] == 0xEF && json[1] == 0xBB && json[2] == 0xBF) {
      i = 3;
    }
    while (i < json.length && isSpace(json[i])) {
      i++;
    }
    if (i >= json.length || json[i] != openArray) {
      throw const FormatException('Snapshot is not a JSON array');
    }

    final chunks = <Uint8List>[];
    var depth = 0;
    var inString = false;
    var escaped = false;
    var elementStart = -1; // first byte of the current run of elements
    var runStart = -1;
    var closed = false;

    void emit(int end) {
      // [runStart, end) holds whole elements separated by commas.
      final chunk = Uint8List(end - runStart + 2);
      chunk[0] = openArray;
      chunk.setRange(1, chunk.length - 1, json, runStart);
      chunk[chunk.length - 1] = closeArray;
      chunks.add(chunk);
      runStart = -1;
    }

    for (; i < json.length; i++) {
      final b = json[i];
      if (inString) {
        if (escaped) {
          escaped = false;
        } else if (b == backslash) {
          escaped = true;
        } else if (b == quote) {
          inString = false;
        }
        continue;
      }
      if (b == quote) {
        inString = true;
        if (depth == 1 && elementStart < 0) elementStart = i;
      } else if (b == openArray || b == openObject) {
        if (depth == 1 && elementStart < 0) elementStart = i;
        depth++;
      } else if (b == closeArray || b == closeObject) {
        depth--;
        if (depth < 0) {
          throw const FormatException('Unbalanced brackets in snapshot');
        }
        if (depth == 0) {
          // The array itself closed: flush what is left.
          if (runStart >= 0) emit(_trimEnd(json, i, isSpace));
          closed = true;
          i++;
          break;
        }
      } else if (b == comma && depth == 1) {
        if (elementStart < 0) {
          throw const FormatException('Empty element in snapshot');
        }
        runStart = runStart < 0 ? elementStart : runStart;
        elementStart = -1;
        if (i - runStart >= maxBytes) {
          emit(i);
        }
      } else if (depth == 1 && elementStart < 0 && !isSpace(b)) {
        elementStart = i; // a number, true, false or null
      }
      if (depth == 1 && runStart < 0 && elementStart >= 0) {
        runStart = elementStart;
      }
    }

    if (inString || !closed) {
      throw const FormatException('Snapshot JSON is truncated');
    }
    while (i < json.length && isSpace(json[i])) {
      i++;
    }
    if (i != json.length) {
      throw const FormatException('Unexpected data after the snapshot array');
    }
    return chunks;
  }

  static int _trimEnd(Uint8List json, int end, bool Function(int) isSpace) {
    while (end > 0 && isSpace(json[end - 1])) {
      end--;
    }
    return end;
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

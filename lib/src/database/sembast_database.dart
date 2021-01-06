import 'dart:convert';

import 'package:basic_utils/basic_utils.dart';
import 'package:flutter/services.dart';
import 'package:sembast/utils/sembast_import_export.dart';
import 'package:sync_db/sync_db.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast_web/sembast_web.dart';
import 'package:universal_io/prefer_universal/io.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:uuid/uuid.dart';
import 'package:sembast/sembast.dart' as sembast;
import 'package:sembast/src/utils.dart' as sembast_utils;

class SembastDatabase extends Database {
  SembastDatabase._privateConstructor();
  static SembastDatabase shared = SembastDatabase._privateConstructor();

  final Map<String, sembast.Database> _database = {};

  /// Opens up each table connected to each model, which is stored in a separate file.
  /// `dbAssetPath` the asset path to import database
  Future<void> init(List<String> tableNames,
      {String dbAssetPath = 'assets/db'}) async {
    // need to setup the ServicePoint in sembast
    tableNames.add(ServicePoint().tableName);
    tableNames.add(TransferMap().tableName);

    if (UniversalPlatform.isWeb) {
      // Open all databases for web
      final futures = <Future>[];
      for (final tableName in tableNames) {
        futures.add(initTable(tableName, dbAssetPath: dbAssetPath));
      }
      await Future.wait(futures);
    } else {
      // get document directory
      final documentPath = await getApplicationSupportDirectory();
      await documentPath.create(recursive: true);

      // Open all databases
      final futures = <Future>[];
      for (final tableName in tableNames) {
        futures.add(initTable(tableName,
            path: documentPath.path, dbAssetPath: dbAssetPath));
      }

      await Future.wait(futures);
    }
  }

  /// Config a table if it doesn't
  @override
  Future<void> initTable(String tableName,
      {String path, String dbAssetPath = 'assets/db'}) async {
    if (_database[tableName] == null) {
      if (UniversalPlatform.isWeb) {
        final dbPath = _generateDatabasePath(tableName);
        if (StringUtils.isNotNullOrEmpty(dbAssetPath) &&
            !File(dbPath).existsSync()) {
          // do the import for that table when empty
          await _import(tableName, dbPath, dbAssetPath);
        }

        Sync.shared.logger?.d('model $tableName has path $dbPath');
        shared._database[tableName] =
            await databaseFactoryWeb.openDatabase(dbPath);
      } else {
        if (path == null) {
          final documentPath = await getApplicationSupportDirectory();
          await documentPath.create(recursive: true);
          path = documentPath.path;
        }

        final dbPath = _generateDatabasePath(tableName, path: path);
        Sync.shared.logger?.d('model $tableName has path $dbPath');
        if (StringUtils.isNotNullOrEmpty(dbAssetPath) &&
            !File(dbPath).existsSync()) {
          // do the import for that table when empty
          await _import(tableName, dbPath, dbAssetPath);
        }

        shared._database[tableName] =
            await databaseFactoryIo.openDatabase(dbPath);
      }
    }
  }

  /// Import snapshot data from asset if it exists
  Future<void> _import(String table, String dest, String assetPath) async {
    final assetContent = await _loadAsset('$assetPath/$table.db');
    if (assetContent != null) {
      Sync.shared.logger?.d('Copy asset $table table to path $dest');
      final bytes = assetContent.buffer
          .asUint8List(assetContent.offsetInBytes, assetContent.lengthInBytes);
      await File(dest).writeAsBytes(bytes);
    }
  }

  /// Read from asset if exist
  Future<dynamic> _loadAsset(String path) async {
    try {
      return await rootBundle.load(path);
    } catch (_) {
      return null;
    }
  }

  /// Get database file path
  static String _generateDatabasePath(String table, {String path}) {
    var fileName = table + '.db';
    return path == null ? fileName : join(path, fileName);
  }

  @override
  Future<void> export(List<String> tableNames) async {
    final docDir = await getApplicationSupportDirectory();
    var exportDir = Directory(join(docDir.path, 'export'));
    if (!exportDir.existsSync()) {
      exportDir.createSync(recursive: true);
    }

    for (final name in tableNames) {
      var content = await exportDatabase(shared._database[name]);
      var json = jsonEncode(content);
      final dbPath = join(exportDir.path, name + '.db');
      await File(dbPath).writeAsString(json);
      Sync.shared.logger?.i('export $name into $dbPath');
    }
  }

  @override
  Future<void> import(Map<String, Map> data) async {
    var dbFactory;
    String dbDir;
    if (UniversalPlatform.isWeb) {
      dbFactory = databaseFactoryWeb;
    } else {
      dbFactory = databaseFactoryIo;
      var path = await getApplicationSupportDirectory();
      await path.create(recursive: true);
      dbDir = path.path;
    }

    for (var key in data.keys) {
      var content = data[key];
      final dbPath = _generateDatabasePath(key, path: dbDir);
      var db = await importDatabase(content, dbFactory, dbPath);
      shared._database[key] = db;
    }
  }

  /// Get all records in the table. Disable stream listener if `listenable = false`
  @override
  Future<List<Model>> all(String modelName, Function instantiateModel,
      {bool listenable = false}) async {
    var q = Query(modelName).where(
      '',
      null,
      instantiateModel,
    );

    return await query<Model>(q, listenable: listenable);
  }

  /// Find model instance by id. Disable stream listener if `listenable = false`
  @override
  Future<Model> find(String modelName, String id, Model model,
      {bool listenable = false}) async {
    final store = sembast.StoreRef.main();
    var recordRef = await store.record(id);
    final record = await recordRef.get(_database[modelName]);
    if (record != null && record[deletedKey] == null) {
      await model.setMap(sembast_utils.cloneValue(record));
      if (listenable) {
        model.stream = recordRef.onSnapshot(_database[modelName]);
      }

      return model;
    }

    return null;
  }

  /// Find map instance by id
  /// Will allow getting deleted records
  @override
  Future<dynamic> findMap(String modelName, String id,
      {dynamic transaction}) async {
    final store = sembast.StoreRef.main();
    var result =
        await store.record(id).get(transaction ?? _database[modelName]);
    return sembast_utils.cloneValue(result);
  }

  /// Query the table with the Query class. Disable stream listener if `listenable = false`
  /// Return the list of model
  @override
  Future<List<T>> query<T extends Model>(Query query,
      {dynamic transaction, bool listenable = false}) async {
    // TODO: will add filter deletedAt is null into query
    var records = await queryMap(query, transaction: transaction);
    var results = <T>[];
    final store = sembast.StoreRef.main();
    for (var record in records) {
      if (query.instantiateModel != null && record[deletedKey] == null) {
        final model = query.instantiateModel();
        await model.setMap(record);
        if (listenable) {
          model.stream =
              store.record(model.id).onSnapshot(_database[query.tableName]);
        }

        results.add(model);
      }
    }

    return results;
  }

  /// Query the table with the Query class
  /// Return the list of map
  @override
  Future<List<Map>> queryMap(Query query, {dynamic transaction}) async {
    final store = sembast.StoreRef.main();
    var results = <Map>[];
    var finder = sembast.Finder();

    // parse condition query
    if (query.condition != null) {
      if (query.condition is String) {
        // search text with format `a matches text`
        if (query.isMatches == true) {
          List<String> conditions = query.condition.split(RegExp('\\s+'));
          if (conditions.length >= 3) {
            var left = conditions[0];
            var filterOperator = conditions[1];
            var searchText = query.condition.substring(
                left.length + filterOperator.length + 2); // include 2 spaces
            var filter = _buildFilter(
                left, filterOperator, searchText, query.caseSensitive);
            finder.filter = filter;
          }
        } else {
          // remove spaces
          query.condition.replaceAll('  ', ' ');
          // check one filter a > b
          List<String> conditions = query.condition.split(RegExp('\\s+'));
          if (conditions.length == 3) {
            var filter = _buildFilter(conditions[0], conditions[1],
                conditions[2], query.caseSensitive);
            finder.filter = filter;
          } else if (query.condition.toLowerCase().contains(' or ') ||
              query.condition.toLowerCase().contains(' and ')) {
            // multiple filter a = x or b > 2 or a is null
            var filters = <sembast.Filter>[];
            for (var i = 0; i < conditions.length; i += 4) {
              var filter = _buildFilter(conditions[i], conditions[i + 1],
                  conditions[i + 2], query.caseSensitive);
              filters.add(filter);
            }

            if (query.condition.toLowerCase().contains(' or ')) {
              finder.filter = sembast.Filter.or(filters);
            } else {
              finder.filter = sembast.Filter.and(filters);
            }
          }
        }
      } else if (query.condition is Map) {
        Map conditions = query.condition;
        // AND/OR query conditions
        if (conditions.length > 1) {
          var filters = <sembast.Filter>[];
          conditions.forEach((key, value) {
            if (query.isMatches == true) {
              filters.add(sembast.Filter.matchesRegExp(
                  key, RegExp(value, caseSensitive: query.caseSensitive)));
            } else {
              filters.add(sembast.Filter.equals(key, value));
            }
          });

          if (query.filterOperator.toLowerCase() == 'or') {
            finder.filter = sembast.Filter.or(filters);
          } else {
            finder.filter = sembast.Filter.and(filters);
          }
        } else {
          var entry = conditions.entries.toList()[0];
          if (query.isMatches == true) {
            finder.filter = sembast.Filter.matchesRegExp(entry.key,
                RegExp(entry.value, caseSensitive: query.caseSensitive));
          } else {
            finder.filter = sembast.Filter.equals(entry.key, entry.value);
          }
        }
      }
    }

    // query order
    if (query.ordering != null) {
      var sort = query.ordering.split(' ');
      if (sort.length == 2) {
        var isAscending = 'asc' == sort[1].toLowerCase().trim();
        finder.sortOrder = sembast.SortOrder(sort[0].trim(), isAscending);
      }
    }

    if (query.resultLimit != null) {
      finder.limit = query.resultLimit;
    }

    final db = _database[query.tableName];
    var records = await store.find(transaction ?? db, finder: finder);
    for (var record in records) {
      var value = sembast_utils.cloneValue(record.value);
      results.add(value);
    }

    return results;
  }

  @override
  Future<void> runInTransaction(String tableName, Function action) async {
    final db = _database[tableName];
    await db.transaction((transaction) async {
      await action(transaction);
    });
  }

  @override
  Future<void> save(Model model, {bool syncToService = true}) async {
    final isCreated = (model.id == null) || (model.createdAt == null);

    // Set id and createdAt if new record. ID is a random UUID
    model.id ??= Uuid().v4().toString();

    model.createdAt ??= await NetworkTime.shared.now;
    model.updatedAt = await NetworkTime.shared.now;

    // Export model as map
    final map = model.map;

    if (isCreated) {
      map[statusKey] = SyncStatus.created.name;
    } else {
      var currentRecord = await findMap(model.tableName, model.id);
      if (currentRecord == null ||
          currentRecord[statusKey] == SyncStatus.created.name) {
        // keep it as created status
        map[statusKey] = SyncStatus.created.name;
      } else {
        map[statusKey] = SyncStatus.updated.name;
      }
    }

    // Get DB
    final name = model.tableName;
    final store = sembast.StoreRef.main();

    // Store and then start the sync
    await store.record(model.id).put(_database[name], map);

    // sync to server
    if (syncToService &&
        (model.syncPermission == SyncPermission.user ||
            model.syncPermission == SyncPermission.all)) {
      // ignore: unawaited_futures
      Sync.shared.service.writeTable(name);
    }
  }

  /// Saving the map bypasses going through the model
  /// The map will come from a service.
  @override
  Future<void> saveMap(String tableName, Map map, {dynamic transaction}) async {
    map.putIfAbsent(idKey, () => Uuid().v4().toString());
    map.putIfAbsent(statusKey, () => SyncStatus.synced.name);

    final now = (await NetworkTime.shared.now).millisecondsSinceEpoch;
    map.putIfAbsent(createdKey, () => now);
    map[updatedKey] = now;

    final store = sembast.StoreRef<String, dynamic>.main();
    await store
        .record(map[idKey])
        .put(transaction ?? _database[tableName], map);
  }

  /// Import data from sembast file (in text string) -> this is not supported for web
  static Future<void> importTable(String data, Model model) async {
    if (!UniversalPlatform.isWeb) {
      final path = await getApplicationDocumentsDirectory();
      await path.create(recursive: true);
      final name = model.tableName;
      final dbPath = join(path.path, name + '.db');
      var file = File(dbPath);
      // delete the old database file if it exist
      if (await file.exists()) {
        await file.delete();
      }

      // then write the new one
      await file.writeAsString(data);
    }
  }

  @override
  Future<void> clearTable(String tableName) async {
    var db = _database[tableName];
    final store = sembast.StoreRef.main();
    await store.delete(db, finder: sembast.Finder());
  }

  @override
  Future<void> cleanDatabase() async {
    for (var tableName in _database.keys) {
      var db = _database[tableName];
      final store = sembast.StoreRef.main();
      await store.delete(db, finder: sembast.Finder());
      await store.drop(db);
      await db.close();
    }

    _database.clear();
    shared = SembastDatabase._privateConstructor();
  }

  /// Delete by setting deletedAt and sync
  @override
  Future<void> delete(Model model) async {
    model.deletedAt = await NetworkTime.shared.now;
    await save(model);
  }

  /// Delete sembast local record if exists
  @override
  Future<void> deleteLocal(String modelName, String id) async {
    final store = sembast.StoreRef.main();
    if (await store.record(id).exists(_database[modelName])) {
      await store.record(id).delete(_database[modelName]);
    }
  }

  sembast.Filter _buildFilter(String left, String filterOperator, String right,
      [bool caseSensitive = false]) {
    dynamic value;
    right = right.trim();
    if (int.tryParse(right) != null) {
      value = int.parse(right);
    } else if (double.tryParse(right) != null) {
      value = double.parse(right);
    } else if (right.toLowerCase() == 'true' ||
        right.toLowerCase() == 'false') {
      value = right.toLowerCase() == 'true';
    } else {
      value = right;
    }

    switch (filterOperator.trim()) {
      case '<':
        return sembast.Filter.lessThan(left.trim(), value);
      case '<=':
        return sembast.Filter.lessThanOrEquals(left.trim(), value);
      case '>':
        return sembast.Filter.greaterThan(left.trim(), value);
      case '>=':
        return sembast.Filter.greaterThanOrEquals(left.trim(), value);
      case '=':
        return sembast.Filter.equals(left.trim(), value);
      case '!=':
        return sembast.Filter.notEquals(left.trim(), value);
      case 'is':
        return sembast.Filter.isNull(left.trim());
      case 'not':
        return sembast.Filter.notNull(left.trim());
      case 'matches':
        return sembast.Filter.matchesRegExp(
            left.trim(), RegExp(value, caseSensitive: caseSensitive));
      case 'contains':
        return sembast.Filter.equals(left.trim(), value, anyInList: true);
      case 'matchesAny':
        return sembast.Filter.matchesRegExp(
            left.trim(), RegExp(value, caseSensitive: caseSensitive),
            anyInList: true);
      default:
        return null;
    }
  }
}

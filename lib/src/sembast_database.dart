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

  final Map<String, sembast.Database> _db = {};
  List<Model> _models = [];
  Sync _sync;

  /// Get all records in the table
  @override
  Future<List<Model>> all(String modelName, Function instantiateModel) async {
    final store = sembast.StoreRef.main();
    var records = await store.find(_db[modelName], finder: sembast.Finder());

    var models = <Model>[];
    for (final record in records) {
      final model = instantiateModel();
      model.import(_fixType(record.value));
      if (model.deletedAt == null) {
        models.add(model);
      }
    }
    return models;
  }

  @override
  Future<void> cleanDatabase() async {
    for (var model in _models) {
      var db = _db[model.tableName];
      final store = sembast.StoreRef.main();
      await store.delete(db, finder: sembast.Finder());
      await store.drop(db);
      await db.close();
    }

    _db.clear();
    _models.clear();
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
    if (await store.record(id).exists(_db[modelName])) {
      await store.record(id).delete(_db[modelName]);
    }
  }

  /// Find model instance by id
  @override
  Future<Model> find(String modelName, String id, Model model) async {
    final store = sembast.StoreRef.main();
    final record = await store.record(id).get(_db[modelName]);
    if (record != null) {
      model.map = _fixType(record);
      if (model.deletedAt == null) {
        return model;
      }
    }

    return null;
  }

  /// Check whether database table has initialized
  @override
  bool hasTable(String tableName) {
    return _db[tableName] != null;
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
          List<String> conditions = query.condition.split(' ');
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
          List<String> conditions = query.condition.split(' ');
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

    final db = _db[query.tableName];
    var records = await store.find(transaction ?? db, finder: finder);
    for (var record in records) {
      var value = sembast_utils.cloneValue(record.value);
      results.add(value);
    }

    return results;
  }

  /// Query the table with the Query class
  /// Return the list of model
  @override
  Future<List<T>> query<T>(Query query, {dynamic transaction}) async {
    var records = await queryMap(query, transaction: transaction);
    var results = <T>[];
    for (var record in records) {
      if (query.instantiateModel != null) {
        final model = query.instantiateModel();
        model.import(_fixType(record));
        if (model.deletedAt == null) {
          results.add(model);
        }
      } else {
        // clone map for writable
        var value = sembast_utils.cloneValue(record);
        results.add(value);
      }
    }

    return results;
  }

  @override
  Future<void> runInTransaction(String tableName, Function action) async {
    final db = _db[tableName];
    await db.transaction((transaction) async {
      await action(transaction);
    });
  }

  @override
  Future<void> save(Model model, {bool syncToService = true}) async {
    // Get DB
    final name = model.tableName;
    final db = _db[name];
    final store = sembast.StoreRef.main();

    // Set id and createdAt if new record. ID is a random UUID
    final create = (model.id == null) || (model.createdAt == null);
    model.id ??= Uuid().v4().toString();

    model.createdAt ??= await NetworkTime.shared.now;

    // Export model as map and convert DateTime to int
    model.updatedAt = await NetworkTime.shared.now;
    final map = model.map;
    for (final entry in map.entries) {
      if (entry.value is DateTime) {
        map[entry.key] = (entry.value as DateTime).millisecondsSinceEpoch;
      }
    }
    map['_status'] = create ? 'created' : 'updated';

    // Store and then start the sync
    await store.record(model.id).put(db, map);

    // sync to server
    if (syncToService) {
      //_sync.writeTable(name);
    }
  }

  /// Saving the map bypasses going through the model
  /// The map will come from a service.
  @override
  Future<void> saveMap(String tableName, Map map, {dynamic transaction}) async {
    map.putIfAbsent('id', () => Uuid().v4().toString());
    map.putIfAbsent('_status', () => SyncState.synced.name);

    final now = (await NetworkTime.shared.now).millisecondsSinceEpoch;
    map.putIfAbsent('createdAt', () => now);
    map.putIfAbsent('updatedAt', () => now);

    final store = sembast.StoreRef<String, dynamic>.main();
    await store.record(map['id']).put(transaction ?? _db[tableName], map);
  }

  /// Connects online services to the Sembast Database
  /// Opens up each table connected to each model, which is stored in a separate file.
  static Future<void> config(Sync remoteSync, List<Model> models) async {
    shared._models = models;
    shared._sync = remoteSync;

    await shared._initDatabase();
  }

  /// Import data from sembast file (in text string) -> this is not supported for web
  static Future<void> importTable(String data, Model model) async {
    if (!UniversalPlatform.isWeb) {
      final dir = await getApplicationDocumentsDirectory();
      await dir.create(recursive: true);
      final name = model.tableName;
      final dbPath = join(dir.path, name + '.db');
      var file = File(dbPath);
      // delete the old database file if it exist
      if (await file.exists()) {
        await file.delete();
      }

      // then write the new one
      await file.writeAsString(data);
    }
  }

  /// initialize and open database for web & other platforms
  Future<void> _initDatabase() async {
    if (UniversalPlatform.isWeb) {
      // Open all databases for web
      for (final model in _models) {
        final name = model.tableName;
        final dbPath = name + '.db';
        _db[name] = await databaseFactoryWeb.openDatabase(dbPath);
      }
    } else {
      // get document dir
      final dir = await getApplicationDocumentsDirectory();
      // make sure it exists
      await dir.create(recursive: true);

      // Open all databases
      for (final model in _models) {
        final name = model.tableName;
        final dbPath = join(dir.path, name + '.db');
        Sync.shared.logger?.d('model $name has path $dbPath');
        _db[name] = await databaseFactoryIo.openDatabase(dbPath);
      }
    }
  }

  Future<void> clearTable(String tableName) async {
    var db = _db[tableName];
    final store = sembast.StoreRef.main();
    await store.delete(db, finder: sembast.Finder());
  }

  sembast.Filter _buildFilter(String left, String filterOperator, String right,
      [bool caseSensitive = false]) {
    switch (filterOperator.trim()) {
      case '<':
        return sembast.Filter.lessThan(left.trim(), right.trim());
      case '<=':
        return sembast.Filter.lessThanOrEquals(left.trim(), right.trim());
      case '>':
        return sembast.Filter.greaterThan(left.trim(), right.trim());
      case '>=':
        return sembast.Filter.greaterThanOrEquals(left.trim(), right.trim());
      case '=':
        return sembast.Filter.equals(left.trim(), right.trim());
      case '!=':
        return sembast.Filter.notEquals(left.trim(), right.trim());
      case 'is':
        return sembast.Filter.isNull(left.trim());
      case 'not':
        return sembast.Filter.notNull(left.trim());
      case 'matches':
        return sembast.Filter.matchesRegExp(
            left.trim(), RegExp(right.trim(), caseSensitive: caseSensitive));
      case 'contains':
        return sembast.Filter.equals(left.trim(), right.trim(),
            anyInList: true);
      case 'matchesAny':
        return sembast.Filter.matchesRegExp(
            left.trim(), RegExp(right.trim(), caseSensitive: caseSensitive),
            anyInList: true);
      default:
        return null;
    }
  }

  Map<String, dynamic> _fixType(Map<String, dynamic> map) {
    var copiedMap = {}..addAll(map);

    copiedMap['createdAt'] =
        DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0);
    copiedMap['updatedAt'] =
        DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0);
    if (map['deletedAt'] is int) {
      copiedMap['deletedAt'] =
          DateTime.fromMillisecondsSinceEpoch(map['deletedAt']);
    }

    return copiedMap;
  }

  /// Custom Sembast cooperator in case has slow sort query on web https://github.com/tekartik/sembast.dart/issues/189
  /// Since version 2.4.6 this issue has been fixed, so assume that we don't need to call this function.
  /// Notice: In case we need it, make sure it should be called before any query operators.
  static void enableSembastCooperator(bool enable,
      {int delayMicroseconds, int pauseMicroseconds}) {
    if (enable == true) {
      // ignore: invalid_use_of_visible_for_testing_member
      sembast.enableSembastCooperator(
          delayMicroseconds: delayMicroseconds,
          pauseMicroseconds: pauseMicroseconds);
    } else {
      // ignore: invalid_use_of_visible_for_testing_member
      sembast.disableSembastCooperator();
    }
  }

  // Note on subscribe to changes from Sembast: https://github.com/tekartik/sembast.dart/blob/master/sembast/doc/new_api.md

}

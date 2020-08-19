import 'package:sync_db/src/network_time.dart';
import 'package:uuid/uuid.dart';

import "abstract.dart";
import 'locator/locator.dart';
import 'locator/sembast_base.dart';
import "query.dart";
import 'package:sembast/sembast.dart' as Sembast;
import 'package:sembast/src/utils.dart' as SembastUtils;

class SembastDatabase extends Database {
  SembastDatabase._privateConstructor();
  static SembastDatabase shared = SembastDatabase._privateConstructor();
  Map<String, Sembast.Database> _db = {};
  List<Model> _models = List();
  Sync _sync;
  //Map<String, List<String>> _dateTimeKeyNames = {};

  /// Connects sync to the Sembest Database
  /// Opens up each table connected to each model, which is stored in a separate file.
  static Future<void> config(Sync remoteSync, List<Model> models) async {
    shared._models = models;
    shared._sync = remoteSync;

    // The locator that uses conditionally importing for web & mobile platform
    SembastLocator locator = Locator();
    // initialize database
    await locator.initDatabase(shared._db, models);
  }

  static Future<void> importTable(String data, Model model) async {
    SembastLocator locator = Locator();
    await locator.import(data, model);
  }

  /// Custom sembasr cooperator in case has slow sort query on web https://github.com/tekartik/sembast.dart/issues/189
  /// Since version 2.4.6 this issue has been fixed, so assume that we don't need to call this function.
  /// Notice: In case we need it, make sure it should be called before any query operators.
  static void enableSembastCooperator(bool enable,
      {int delayMicroseconds, int pauseMicroseconds}) {
    if (enable == true) {
      // ignore: invalid_use_of_visible_for_testing_member
      Sembast.enableSembastCooperator(
          delayMicroseconds: delayMicroseconds,
          pauseMicroseconds: pauseMicroseconds);
    } else {
      // ignore: invalid_use_of_visible_for_testing_member
      Sembast.disableSembastCooperator();
    }
  }

  /// Check whether database table has initialized
  bool hasTable(String tableName) {
    return _db[tableName] != null;
  }

  Future<void> cleanDatabase() async {
    for (var model in _models) {
      var db = _db[model.name];
      final store = Sembast.StoreRef.main();
      await store.delete(db, finder: Sembast.Finder());
      await store.drop(db);
      await db.close();
    }

    _db.clear();
    _models.clear();
    shared = SembastDatabase._privateConstructor();
  }

  Future<void> clearTable(String tableName) async {
    var db = _db[tableName];
    final store = Sembast.StoreRef.main();
    await store.delete(db, finder: Sembast.Finder());
  }

  Future<void> save(Model model, {bool syncToCloud = true}) async {
    // Get DB
    final name = model.name;
    final db = _db[name];
    final store = Sembast.StoreRef.main();

    // Set id and createdAt if new record. ID is a random UUID
    final create = (model.id == null) || (model.createdAt == null);
    if (model.id == null) {
      model.id = Uuid().v4().toString();
    }

    if (model.createdAt == null) {
      model.createdAt = await NetworkTime.shared.now;
    }

    // Export model as map and convert DateTime to int
    model.updatedAt = await NetworkTime.shared.now;
    final map = model.map;
    for (final entry in map.entries) {
      if (entry.value is DateTime) {
        map[entry.key] = (entry.value as DateTime).millisecondsSinceEpoch;
      }
    }
    map["_status"] = create ? "created" : "updated";

    // Store and then start the sync
    await store.record(model.id).put(db, map);

    // sync to server
    if (syncToCloud) {
      _sync.syncWriteRecord(name, map, create).then((value) => null);
    }
  }

  /// Save record map to sembast
  Future<void> saveMap(String tableName, String id, Map map,
      {int updatedAt, String status, dynamic transaction}) async {
    final store = Sembast.StoreRef<String, dynamic>.main();
    final create = id == null;
    if (create) {
      id = Uuid().v4().toString();
      map['id'] = id;
    }

    if (!map.containsKey('createdAt')) {
      map['createdAt'] = (await NetworkTime.shared.now).millisecondsSinceEpoch;
    }

    if (updatedAt == null) {
      map['updatedAt'] = (await NetworkTime.shared.now).millisecondsSinceEpoch;
    } else {
      map['updatedAt'] = updatedAt;
    }

    if (status == null) {
      map["_status"] = create ? "created" : "updated";
    } else {
      map["_status"] = status;
    }

    if (transaction != null) {
      try {
        await store.record(id).put(transaction, map);
      } catch (e) {
        print('put error $e');
        throw e;
      }
    } else {
      final db = _db[tableName];
      await store.record(id).put(db, map);
    }
  }

  Future<void> runInTransaction(String tableName, Function action) async {
    final db = _db[tableName];
    await db.transaction((txn) async {
      await action(txn);
    });
  }

  /// Delete by setting deletedAt and sync
  Future<void> delete(Model model) async {
    model.deletedAt = await NetworkTime.shared.now;
    await save(model);
  }

  /// Delete sembast local record if exist
  Future<void> deleteLocal(String modelName, String id) async {
    final store = Sembast.StoreRef.main();
    if (await store.record(id).exists(_db[modelName])) {
      await store.record(id).delete(_db[modelName]);
    }
  }

  /// Get all model instances in a table
  Future<List<Model>> all(String modelName, Function instantiateModel) async {
    final store = Sembast.StoreRef.main();
    var records = await store.find(_db[modelName], finder: Sembast.Finder());

    List<Model> models = [];
    for (final record in records) {
      final model = instantiateModel();
      model.import(_fixType(record.value));
      if (model.deletedAt == null) {
        models.add(model);
      }
    }
    return models;
  }

  /// Find model instance by id
  Future<Model> find(String modelName, String id, Model model) async {
    final store = Sembast.StoreRef.main();
    final record = await store.record(id).get(_db[modelName]);
    if (record != null) {
      model.map = _fixType(record);
      if (model.deletedAt == null) {
        return model;
      }
    }

    return null;
  }

  /// Query the table with the Query class
  Future<List<T>> query<T>(Query query, {dynamic transaction}) async {
    final store = Sembast.StoreRef.main();
    List<T> results = [];
    var finder = Sembast.Finder();

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
            List<Sembast.Filter> filters = List<Sembast.Filter>();
            for (var i = 0; i < conditions.length; i += 4) {
              var filter = _buildFilter(conditions[i], conditions[i + 1],
                  conditions[i + 2], query.caseSensitive);
              filters.add(filter);
            }

            if (query.condition.toLowerCase().contains(' or ')) {
              finder.filter = Sembast.Filter.or(filters);
            } else {
              finder.filter = Sembast.Filter.and(filters);
            }
          }
        }
      } else if (query.condition is Map) {
        Map conditions = query.condition;
        // AND/OR query conditions
        if (conditions.length > 1) {
          List<Sembast.Filter> filters = List<Sembast.Filter>();
          conditions.forEach((key, value) {
            if (query.isMatches == true) {
              filters.add(Sembast.Filter.matchesRegExp(
                  key, RegExp(value, caseSensitive: query.caseSensitive)));
            } else {
              filters.add(Sembast.Filter.equals(key, value));
            }
          });

          if (query.filterOperator.toLowerCase() == 'or') {
            finder.filter = Sembast.Filter.or(filters);
          } else {
            finder.filter = Sembast.Filter.and(filters);
          }
        } else {
          var entry = conditions.entries.toList()[0];
          if (query.isMatches == true) {
            finder.filter = Sembast.Filter.matchesRegExp(entry.key,
                RegExp(entry.value, caseSensitive: query.caseSensitive));
          } else {
            finder.filter = Sembast.Filter.equals(entry.key, entry.value);
          }
        }
      }
    }

    // query order
    if (query.ordering != null) {
      var sort = query.ordering.split(" ");
      if (sort.length == 2) {
        var isAscending = "asc" == sort[1].toLowerCase().trim();
        finder.sortOrder = Sembast.SortOrder(sort[0].trim(), isAscending);
      }
    }

    if (query.resultLimit != null) {
      finder.limit = query.resultLimit;
    }

    final db = _db[query.tableName];
    var records = await store.find(transaction ?? db, finder: finder);
    for (var record in records) {
      if (query.instantiateModel != null) {
        final model = query.instantiateModel();
        model.import(_fixType(record.value));
        if (model.deletedAt == null) {
          results.add(model);
        }
      } else {
        // clone map for writable
        var value = SembastUtils.cloneValue(record.value);
        results.add(value);
      }
    }

    return results;
  }

  Sembast.Filter _buildFilter(String left, String filterOperator, String right,
      [bool caseSensitive = false]) {
    switch (filterOperator.trim()) {
      case '<':
        return Sembast.Filter.lessThan(left.trim(), right.trim());
      case '<=':
        return Sembast.Filter.lessThanOrEquals(left.trim(), right.trim());
      case '>':
        return Sembast.Filter.greaterThan(left.trim(), right.trim());
      case '>=':
        return Sembast.Filter.greaterThanOrEquals(left.trim(), right.trim());
      case '=':
        return Sembast.Filter.equals(left.trim(), right.trim());
      case '!=':
        return Sembast.Filter.notEquals(left.trim(), right.trim());
      case 'is':
        return Sembast.Filter.isNull(left.trim());
      case 'not':
        return Sembast.Filter.notNull(left.trim());
      case 'matches':
        return Sembast.Filter.matchesRegExp(
            left.trim(), RegExp(right.trim(), caseSensitive: caseSensitive));
      case 'contains':
        return Sembast.Filter.equals(left.trim(), right.trim(),
            anyInList: true);
      case 'matchesAny':
        return Sembast.Filter.matchesRegExp(
            left.trim(), RegExp(right.trim(), caseSensitive: caseSensitive),
            anyInList: true);
      default:
        return null;
    }
  }

  Map<String, dynamic> _fixType(Map<String, dynamic> map) {
    Map<String, dynamic> copiedMap = {}..addAll(map);

    copiedMap["createdAt"] =
        DateTime.fromMillisecondsSinceEpoch(map["createdAt"] ?? 0);
    copiedMap["updatedAt"] =
        DateTime.fromMillisecondsSinceEpoch(map["updatedAt"] ?? 0);
    if (map["deletedAt"] is int) {
      copiedMap["deletedAt"] =
          DateTime.fromMillisecondsSinceEpoch(map["deletedAt"]);
    }

    return copiedMap;
  }

  // Note on subscribe to changes from Sembast: https://github.com/tekartik/sembast.dart/blob/master/sembast/doc/new_api.md
}

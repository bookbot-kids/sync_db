import 'package:uuid/uuid.dart';

import "abstract.dart";
import 'locator/locator.dart';
import 'locator/sembast_base.dart';
import "query.dart";
import 'package:sembast/sembast.dart' as Sembast;
import 'package:sembast/src/utils.dart' as SembastUtils;

class SembastDatabase extends Database {
  SembastDatabase._privateConstructor();
  static final SembastDatabase shared = SembastDatabase._privateConstructor();
  Sync _sync;
  Map<String, Sembast.Database> _db = {};
  //Map<String, List<String>> _dateTimeKeyNames = {};

  /// Connects sync to the Sembest Database
  /// Opens up each table connected to each model, which is stored in a separate file.
  static Future<void> config(Sync sync, List<Model> models) async {
    shared._sync = sync;

    SembastLocator locator = Locator();
    await locator.initDatabase(shared._db, models);
  }

  static Future<void> importTable(String data, Model model) async {
    SembastLocator locator = Locator();
    await locator.import(data, model);
  }

  /// Check whether database table has initialized
  bool hasTable(String tableName) {
    return _db[tableName] != null;
  }

  Future<void> save(Model model) async {
    // Get DB
    final name = model.tableName();
    final db = _db[name];
    final store = Sembast.StoreRef.main();

    // Set id and createdAt if new record. ID is a random UUID
    final create = (model.id == null) || (model.createdAt == null);
    if (model.id == null) {
      model.id = Uuid().v4().toString();
    }

    if (model.createdAt == null) {
      model.createdAt = DateTime.now().toUtc();
    }

    // Export model as map and convert DateTime to int
    model.updatedAt = DateTime.now().toUtc();
    final map = model.export();
    for (final entry in map.entries) {
      if (entry.value is DateTime) {
        map[entry.key] = (entry.value as DateTime).millisecondsSinceEpoch;
      }
    }
    map["_status"] = create ? "created" : "updated";

    // Store and then start the sync
    await store.record(model.id).put(db, map);
    //_sync.syncWrite(name);
  }

  Future<void> saveMap(String tableName, String id, Map map,
      {int updatedAt, String status}) async {
    final db = _db[tableName];
    final store = Sembast.StoreRef.main();
    final create = id == null;
    if (create) {
      id = Uuid().v4().toString();
      map['id'] = id;
    }

    if (!map.containsKey('createdAt')) {
      map['createdAt'] = DateTime.now().toUtc().millisecondsSinceEpoch;
    }

    if (updatedAt == null) {
      map['updatedAt'] = DateTime.now().toUtc().millisecondsSinceEpoch;
    } else {
      map['updatedAt'] = updatedAt;
    }

    if (status == null) {
      map["_status"] = create ? "created" : "updated";
    } else {
      map["_status"] = status;
    }

    await store.record(id).put(db, map);
  }

  Future<void> delete(Model model) async {
    model.deletedAt = DateTime.now();
    await save(model);
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
      model.import(_fixType(record));
      if (model.deletedAt == null) {
        return model;
      }
    }

    return null;
  }

  /// Query the table with the Query class
  Future<List<T>> query<T>(Query query) async {
    final store = Sembast.StoreRef.main();
    List<T> results = [];
    var finder = Sembast.Finder();

    // parse condition query
    if (query.condition != null) {
      if (query.condition is String) {
        // remove spaces
        query.condition.replaceAll('  ', ' ');
        // check one filter a > b
        List<String> conditions = query.condition.split(' ');
        if (conditions.length == 3) {
          var filter =
              _buildFilter(conditions[0], conditions[1], conditions[2]);
          finder.filter = filter;
        } else if (query.condition.toLowerCase().contains(' or ') ||
            query.condition.toLowerCase().contains(' and ')) {
          // multiple filter a = x or b > 2
          List<Sembast.Filter> filters = List<Sembast.Filter>();
          for (var i = 0; i < conditions.length; i += 4) {
            var filter = _buildFilter(
                conditions[i], conditions[i + 1], conditions[i + 2]);
            filters.add(filter);
          }

          if (query.condition.toLowerCase().contains(' or ')) {
            finder.filter = Sembast.Filter.or(filters);
          } else {
            finder.filter = Sembast.Filter.and(filters);
          }
        }
      } else if (query.condition is Map) {
        Map conditions = query.condition;
        // AND/OR query conditions
        if (conditions.length > 1) {
          List<Sembast.Filter> filters = List<Sembast.Filter>();
          conditions.forEach((key, value) {
            filters.add(Sembast.Filter.equals(key, value));
          });

          if (query.filterOperator.toLowerCase() == 'or') {
            finder.filter = Sembast.Filter.or(filters);
          } else {
            finder.filter = Sembast.Filter.and(filters);
          }
        } else {
          var entry = conditions.entries.toList()[0];
          finder.filter = Sembast.Filter.equals(entry.key, entry.value);
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
    var records = await store.find(db, finder: finder);
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

  Sembast.Filter _buildFilter(
      String left, String filterOperator, String right) {
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

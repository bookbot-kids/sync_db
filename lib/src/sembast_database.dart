import "abstract.dart";
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart' as Sembast;
import 'package:sembast/sembast_io.dart';
import 'package:better_uuid/uuid.dart';

class SembastDatabase extends Database {
  static SembastDatabase shared;
  Sync _sync;
  Map<String, Sembast.Database> _db = {};

  /// Connects sync to the Sembest Database
  /// Opens up each table connected to each model, which is stored in a separate file. 
  static Future<void> config(Sync sync, List<String> models) async {
    shared = SembastDatabase();
    shared._sync = sync;

    // get the application documents directory
    final dir = await getApplicationDocumentsDirectory();
    // make sure it exists
    await dir.create(recursive: true);
    final store = Sembast.StoreRef.main();

    // Open all dbs
    for (final name in models) {
      final dbPath = join(dir.path, name + ".db");
      // open the database
      shared._db[name] = await databaseFactoryIo.openDatabase(dbPath);

      // Warms up the database so it can work later (seems to be a bug in Sembast)
      await store.record("Cold start").put(shared._db[name], "Warm up");
      await store.record("Cold start").delete(shared._db[name]);
    }
  }

  Future<void> save(Model model) async {
    // Get DB
    final name = model.runtimeType.toString();
    final db = _db[name];
    final store = Sembast.StoreRef.main();

    // Set id and createdAt if new record. ID is random
    final create = (model.id == null) || (model.createdAt == null);
    if (create) {
      model.id = Uuid.v4().toString();
      model.createdAt = DateTime.now();
    }

    // Export model as map and convert DateTime to int
    model.updatedAt = DateTime.now();
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

  Future<List<Model>> all(String modelName, Function instantiateModel) async {
    final store = Sembast.StoreRef.main();
    var records = await store.find(_db[modelName], finder: Sembast.Finder());

    List<Model> models = [];
    for (final record in records) {
      final model = instantiateModel();
      model.import(record.value);
      models.add(model);
    }
    return Future<List<Model>>.value(models);
  }

  Future<Model> find(String modelName, String id, Function instantiateModel) async {
    final store = Sembast.StoreRef.main();
    final record = await store.record(id).get(_db[modelName]);
    final model = instantiateModel();
    model.import(record);
    return Future<Model>.value(model);
  }

  List<dynamic> query(String filter, [List<dynamic> literals = const [], String order, int start, int end]) {

  }
}
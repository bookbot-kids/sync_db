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

  static Future<void> config(Sync sync, List<String> models) async {
    shared = SembastDatabase();
    shared._sync = sync;

    // get the application documents directory
    final dir = await getApplicationDocumentsDirectory();
    // make sure it exists
    await dir.create(recursive: true);

    for (final name in models) {
      final dbPath = join(dir.path, name + ".db");
      print(dbPath);
      // open the database
      shared._db[name] = await databaseFactoryIo.openDatabase(dbPath);
    }
  }

  void save(Model model) {
    final name = model.runtimeType.toString();
    final db = _db[name];
    final store = Sembast.StoreRef.main();
    final create = model.id == null;

    if (create) {
      model.id = Uuid.v4().toString();
    }

    final map = model.export();
    map["_status"] = create ? "created" : "updated";
    store.record(model.id).put(db, map).then((dynamic record) {
      //_sync.syncWrite(name);
    });
  }

  List<dynamic> all(String modelName, Function instantiateModel) {

  }

  dynamic find(String modelName, String id, Function instantiateModel) {

  }

  List<dynamic> query(String filter, [List<dynamic> literals = const [], String order, int start, int end]) {

  }
}
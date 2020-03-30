import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sync_db/src/abstract.dart';
import 'package:sembast/sembast.dart' as Sembast;
import 'package:sync_db/src/locator/sembast_base.dart';

SembastLocator getLocator() => SembastMobileLocator();

class SembastMobileLocator extends SembastLocator {
  @override
  Future<void> initDatabase(
      Map<String, Sembast.Database> map, List<Model> models) async {
    final dir = await getApplicationDocumentsDirectory();
    // make sure it exists
    await dir.create(recursive: true);
    final store = Sembast.StoreRef.main();

    // Open all databases
    for (final model in models) {
      final name = model.tableName();
      final dbPath = join(dir.path, name + ".db");
      print('model $name has path $dbPath');
      map[name] = await databaseFactoryIo.openDatabase(dbPath);

      // Warms up the database so it can work later (seems to be a bug in Sembast)
      await store.record("Cold start").put(map[name], "Warm up");
      await store.record("Cold start").delete(map[name]);
    }
  }

  @override
  Future<void> import(String content, Model model) async {
    final dir = await getApplicationDocumentsDirectory();
    // make sure it exists
    await dir.create(recursive: true);
    final name = model.tableName();
    final dbPath = join(dir.path, name + ".db");
    var file = File(dbPath);
    if (await file.exists()) {
      await file.delete();
    }

    await file.writeAsString(content);
  }
}

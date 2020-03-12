import 'package:sembast_web/sembast_web.dart';
import 'package:sync_db/src/abstract.dart';
import 'package:sembast/sembast.dart' as Sembast;
import 'package:sync_db/src/locator/sembast_base.dart';

SembastLocator getLocator() => SembastWebLocator();

class SembastWebLocator extends SembastLocator {
  @override
  Future<void> initDatabase(
      Map<String, Sembast.Database> map, List<Model> models) async {
    final store = Sembast.StoreRef.main();

    // Open all databases
    for (final model in models) {
      final name = model.runtimeType.toString();
      final dbPath = name + ".db";
      map[name] = await databaseFactoryWeb.openDatabase(dbPath);

      // Warms up the database so it can work later (seems to be a bug in Sembast)
      await store.record("Cold start").put(map[name], "Warm up");
      await store.record("Cold start").delete(map[name]);
    }
  }
}

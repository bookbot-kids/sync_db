import 'package:sembast_web/sembast_web.dart';
import 'package:sync_db/src/abstract.dart';
import 'package:sembast/sembast.dart' as Sembast;
import 'package:sync_db/src/locator/sembast_base.dart';

SembastLocator getLocator() => SembastWebLocator();

class SembastWebLocator extends SembastLocator {
  @override
  Future<void> initDatabase(
      Map<String, Sembast.Database> map, List<Model> models) async {
    // Open all databases
    for (final model in models) {
      final name = model.tableName();
      final dbPath = name + ".db";
      map[name] = await databaseFactoryWeb.openDatabase(dbPath);
    }
  }

  @override
  Future<void> import(String content, Model model) async {
    print('Not support import in web');
  }
}

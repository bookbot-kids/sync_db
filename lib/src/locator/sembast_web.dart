import 'package:sembast_web/sembast_web.dart';
import 'package:sync_db/src/abstract.dart';
import 'package:sembast/sembast.dart' as Sembast;
import 'package:sync_db/src/locator/sembast_base.dart';

/// This method is used to overwrite the abstract in `locator.dart` to return locator for web
SembastLocator getLocator() => SembastWebLocator();

/// The Locator is using for web only
class SembastWebLocator extends SembastLocator {
  @override
  Future<void> initDatabase(
      Map<String, Sembast.Database> map, List<Model> models) async {
    // Open all databases
    for (final model in models) {
      final name = model.name;
      final dbPath = name + ".db";
      map[name] = await databaseFactoryWeb.openDatabase(dbPath);
    }
  }

  @override
  Future<void> import(String content, Model model) async {
    throw Exception('Not support to import data in web');
  }
}

import 'package:sembast/sembast.dart' as Sembast;

import '../abstract.dart';
import 'locator.dart';

/// The abstract locator, determine whether it's web locator or mobile (desktop) locator
abstract class SembastLocator implements Locator {
  /// Initialize database. Setting up model here.
  void initDatabase(Map<String, Sembast.Database> map, List<Model> models);

  /// Import the data into a table (it will overwrite the old file)
  /// content: the string content from sembast_table.db file (sembast stores file in string content)
  /// model: The model which has table name to import.
  Future<void> import(String content, Model model);
}

import 'package:sembast/sembast.dart' as Sembast;

import '../abstract.dart';
import 'locator.dart';

abstract class SembastLocator implements Locator {
  void initDatabase(Map<String, Sembast.Database> map, List<Model> models);
}

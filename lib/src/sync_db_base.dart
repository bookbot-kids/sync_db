import 'package:flutter/foundation.dart';

// Put public facing types in this file.

/// Checks if you are awesome. Spoiler: you are.
class Awesome {
  bool get isAwesome => true;
}

/// There are 4 main classes - web access class, the DB model class, DB dependency, and the DB sync dependency class
/// 
/// DB static model
/// model - get all - list of objects
/// model - find by id/key - use dart dictonary syntax -> single model object
/// model - where (query) - list of objects
/// ordering (sort)
/// limit/offset

class Model extends ChangeNotifier {
  // Open Database and set to static property
  // Database path or file name can be overridden
  // queries returned as arrays - convert to object
  // subscribe to changes: https://github.com/tekartik/sembast.dart/blob/master/sembast/doc/new_api.md
  // on model save add uuid, created/updated
  // after 0.5 seconds start sync

}
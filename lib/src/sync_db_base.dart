import 'package:flutter/foundation.dart';

// Put public facing types in this file.

/// Checks if you are awesome. Spoiler: you are.
class Awesome {
  bool get isAwesome => true;
}

/// There are 3 main classes - web access class, the DB model class and the DB sync class
/// 
/// DB static model
/// model - get all - list of objects
/// model - find by id/key - use dart dictonary syntax -> single model object
/// model - where (query) - list of objects
/// ordering (sort)
/// limit/offset

class Model extends ChangeNotifier {
  /// A static default DB class that comes from configuration
  /// 
}
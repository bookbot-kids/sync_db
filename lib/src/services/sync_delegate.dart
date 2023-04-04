import 'dart:typed_data';

import 'package:sync_db/src/model.dart';
import 'package:sync_db/src/services/service_point.dart';
import 'package:tuple/tuple.dart';

/// The external sync delegate
/// Client app uses this one to inject data with the same format into database
abstract class SyncDelegate {
  /// Sync read data for a table.
  /// The `token` param can be null.
  /// Return a list of records (must not be null) and map of resource token permissions
  /// Make sure the data list is correct format
  Future<Tuple2<List, Map>> syncRead(String? token);

  bool get readOnly => false;
  String get tableName => '';
}

abstract class ModelHandler {
  Future<List<T>> queryStatus<T extends Model>(SyncStatus syncStatus,
      {bool filterDeletedAt = true});
  Future<Model?> find(String? id, {bool filterDeletedAt = true});
  Future<void> clear();
  Future<List<Map<String, dynamic>>> exportJson(
      {Function(Uint8List)? callback});
  Future<void> importJson(dynamic jsonData);
}

abstract class ModelDelegate {
  Future<String?> partitionForModel(Model model);
}

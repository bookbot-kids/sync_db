import 'package:isar/isar.dart';
import 'package:sync_db/sync_db.dart';
part 'class.g.dart';

@collection
class ClassRoom extends Model {
  String name = '';
  String teacherId = '';

  @override
  String get tableName => 'Class';

  @override
  Future<List<T>> queryStatus<T extends Model>(SyncStatus syncStatus,
      {bool filterDeletedAt = true}) async {
    final result = await $ClassRoom.queryStatus(syncStatus,
        filterDeletedAt: filterDeletedAt);
    return result.cast();
  }

  @override
  Future<void> save({
    bool syncToService = true,
    bool runInTransaction = true,
    bool initialize = true,
  }) =>
      $ClassRoom(this).save(
          syncToService: syncToService,
          runInTransaction: runInTransaction,
          initialize: initialize);

  @override
  Future<void> clear() => $ClassRoom(this).clear();

  @Ignore()
  @override
  Map get map => $ClassRoom(this).map;

  @override
  Future<Set<String>> setMap(Map map) async =>
      await $ClassRoom(this).setMap(map);

  @override
  Future<ClassRoom?> find(String? id, {bool filterDeletedAt = true}) =>
      $ClassRoom.find(id, filterDeletedAt: filterDeletedAt);

  @override
  Future<void> deleteLocal() => $ClassRoom(this).deleteLocal();
}

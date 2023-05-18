import 'package:isar/isar.dart';
import 'package:sync_db/sync_db.dart';
part 'service_record.g.dart';

@collection
class ServiceRecord extends Model {
  String name = '';

  @ModelSet()
  List<String> updatedFields = [];

  void appendFields(Iterable<String> items) {
    updatedFields = updatedFields.addItems(items, isSet: true);
  }

  @override
  Future<void> clear() async {
    await db.serviceRecords.clear();
  }

  @override
  Future<void> deleteLocal() async {
    if (id != null) {
      await db.writeTxn(() async {
        await db.serviceRecords.delete(localId);
      });
    }
  }

  Future<ServiceRecord?> findBy(String? id, String name) async {
    return await ServiceRecord()
        .db
        .serviceRecords
        .filter()
        .idEqualTo(id)
        .nameEqualTo(name)
        .deletedAtIsNull()
        .findFirst();
  }

  @override
  Future<ServiceRecord?> find(String? id, {bool filterDeletedAt = true}) async {
    return filterDeletedAt
        ? await ServiceRecord()
            .db
            .serviceRecords
            .filter()
            .idEqualTo(id)
            .deletedAtIsNull()
            .findFirst()
        : await ServiceRecord()
            .db
            .serviceRecords
            .filter()
            .idEqualTo(id)
            .findFirst();
  }

  @override
  Future<List<T>> queryStatus<T extends Model>(SyncStatus syncStatus,
      {bool filterDeletedAt = true}) async {
    final result = filterDeletedAt
        ? await db.serviceRecords
            .filter()
            .syncStatusEqualTo(syncStatus)
            .deletedAtIsNull()
            .findAll()
        : await db.serviceRecords
            .filter()
            .syncStatusEqualTo(syncStatus)
            .findAll();
    return result.cast();
  }

  @override
  Future<void> save(
      {bool syncToService = true,
      bool runInTransaction = true,
      bool initialize = true}) async {
    final func = () async {
      if (initialize) {
        await init();
      }
      await db.serviceRecords.put(this);
    };

    if (runInTransaction) {
      return db.writeTxn(() async {
        await func();
      });
    } else {
      await func();
    }
  }

  @override
  Set<String> get keys => {};

  @Ignore()
  @override
  String get tableName => 'ServiceRecord';
}

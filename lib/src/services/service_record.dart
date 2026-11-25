import 'package:isar_community/isar.dart';
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

  /// Drops [sent] from the stored log of [id]'s changed fields, and the log
  /// itself once it is empty. Reads the log again inside the transaction, so
  /// fields a save appended while the request was in flight are kept.
  ///
  /// When the record was saved again after the values sent ([sentUpdatedAt]),
  /// a sent field may hold a newer value than the one that went up, so the
  /// whole log stays and the next write sends it again.
  static Future<void> removeSentFields(
      String? id, String name, Set<String> sent,
      {required int sentUpdatedAt,
      required Future<Model?> Function() findRecord}) async {
    if (id == null) return;
    final db = ServiceRecord().db;
    await db.writeTxn(() async {
      final record = await findRecord();
      final storedUpdatedAt = record?.updatedAt?.millisecondsSinceEpoch ?? 0;
      if (storedUpdatedAt > sentUpdatedAt) return;

      final current = await db.serviceRecords
          .filter()
          .idEqualTo(id)
          .nameEqualTo(name)
          .findFirst();
      if (current == null) return;
      final remaining =
          current.updatedFields.where((f) => !sent.contains(f)).toList();
      if (remaining.isEmpty) {
        await db.serviceRecords.delete(current.localId);
      } else {
        current.updatedFields = remaining;
        await db.serviceRecords.put(current);
      }
    });
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
  @Ignore()
  Set<String> get keys => {};

  @Ignore()
  @override
  String get tableName => 'ServiceRecord';
}

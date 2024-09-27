import 'package:isar/isar.dart';
import 'package:sync_db/sync_db.dart';
part 'service_point.g.dart';

/// The ServicePoint class keeps a record of access and the timestamp of where to sync from
@collection
class ServicePoint extends Model {
  ServicePoint({this.name = '', this.access = Access.read});

  String name = ''; // The table name
  int? from = 0; // From is the timestamp the sync point in time
  @enumerated
  Access access = Access.read;
  String? token;

  @Ignore()
  @override
  SyncPermission get syncPermission => SyncPermission.read;

  @override
  String get tableName => 'ServicePoint';

  static Future<List<ServicePoint>> all() async {
    return ServicePoint().db.servicePoints.where().findAll();
  }

  @override
  Future<ServicePoint?> find(String? id, {bool filterDeletedAt = true}) async {
    return filterDeletedAt
        ? await ServicePoint()
            .db
            .servicePoints
            .filter()
            .idEqualTo(id)
            .deletedAtIsNull()
            .findFirst()
        : await ServicePoint()
            .db
            .servicePoints
            .filter()
            .idEqualTo(id)
            .findFirst();
  }

  static Future<List<ServicePoint>> listByName(String name) async {
    return ServicePoint()
        .db
        .servicePoints
        .filter()
        .nameEqualTo(name)
        .deletedAtIsNull()
        .findAll();
  }

  static Future<ServicePoint?> searchBy(String name,
      {String? partition}) async {
    var filter = ServicePoint().db.servicePoints.filter().nameEqualTo(name);
    if (partition != null) {
      filter = filter.partitionEqualTo(partition);
    }

    return filter.deletedAtIsNull().findFirst();
  }

  static Future<ServicePoint?> search(
      String? id, String name, String? partition) {
    return ServicePoint()
        .db
        .servicePoints
        .filter()
        .idEqualTo(id)
        .nameEqualTo(name)
        .partitionEqualTo(partition)
        .deletedAtIsNull()
        .findFirst();
  }

  @Ignore()
  String get key => '$name-$partition';

  @override
  Future<void> deleteLocal() async {
    if (id != null) {
      await db.writeTxn(() async {
        await db.servicePoints.delete(localId);
      });
    }
  }

  @override
  Future<void> save({
    bool syncToService = true,
    bool runInTransaction = true,
    bool initialize = true,
  }) async {
    final func = () async {
      if (initialize) {
        await init();
      }
      await db.servicePoints.put(this);
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
  Future<List<T>> queryStatus<T extends Model>(SyncStatus syncStatus,
      {bool filterDeletedAt = true}) async {
    final result = filterDeletedAt
        ? await db.servicePoints
            .filter()
            .syncStatusEqualTo(syncStatus)
            .deletedAtIsNull()
            .findAll()
        : await db.servicePoints
            .filter()
            .syncStatusEqualTo(syncStatus)
            .findAll();
    return result.cast();
  }

  @override
  Future<void> clear() async {
    await db.servicePoints.clear();
  }

  static String sharedKey(String name, String partition) {
    return '$name-$partition';
  }

  @override
  @Ignore()
  Set<String> get keys => {};
}

enum Access { all, read, write }

extension $Access on Access {
  static final string = {
    Access.all: 'all',
    Access.read: 'read',
    Access.write: 'write',
  };

  static final toEnum = {
    'all': Access.all,
    'read': Access.read,
    'write': Access.write,
  };

  String? get name => $Access.string[this];
  static Access? fromString(String? value) => $Access.toEnum[value!];
}

enum SyncStatus { created, updated, synced, none }

extension $SyncStatus on SyncStatus {
  static final string = {
    SyncStatus.created: 'created',
    SyncStatus.updated: 'updated',
    SyncStatus.synced: 'synced',
  };

  static final toEnum = {
    'created': SyncStatus.created,
    'updated': SyncStatus.updated,
    'synced': SyncStatus.synced,
  };

  String? get name => $SyncStatus.string[this];
  static SyncStatus? fromString(String value) => $SyncStatus.toEnum[value];
}

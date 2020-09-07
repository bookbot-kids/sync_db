import 'package:sync_db/sync_db.dart';
import 'package:synchronized/synchronized.dart';
import 'package:pool/pool.dart';

abstract class Service {
  // Make sure there are no more than 8 server downloads at the same time
  final _pool = Pool(8, timeout: Duration(seconds: 60));
  // The same table/partition will only have one access at a time
  final Map<String, Lock> _serviceLock = {};

  /// Sync everything
  Future<void> sync() async {
    await _syncServicePoints(await Sync.shared.userSession.servicePoints());
  }

  /// Sync a table to service
  Future<void> syncTable(String table) async {
    await _syncServicePoints(
        await Sync.shared.userSession.servicePointsForable(table));
  }

  Future<void> _syncServicePoints(List<ServicePoint> servicePoints) async {
    var futures = <Future>[];
    for (final servicePoint in servicePoints) {
      futures.add(readServicePoint(servicePoint));
      futures.add(writeServicePoint(servicePoint));
    }
    await Future.wait(futures);
  }

  /// Write created or updated records in this table
  Future<void> writeTable(String table) async {
    final servicePoints =
        await Sync.shared.userSession.servicePointsForable(table);
    var futures = <Future>[];
    for (final servicePoint in servicePoints) {
      futures.add(writeServicePoint(servicePoint));
    }
    await Future.wait(futures);
  }

  Future<void> readServicePoint(ServicePoint service) async {
    // Needs all or read access
    if (service.access == Access.write) return;

    // Get lock for only running one service point at a time
    final lock = _serviceLock.putIfAbsent(service.key, () => Lock());
    await lock.synchronized(() async {
      await readFromService(service);
    });
  }

  Future<void> writeServicePoint(ServicePoint service) async {
    // Needs all or write access
    if (service.access == Access.read) return;

    // Get lock for only running one service point at a time
    final lock = _serviceLock.putIfAbsent(service.key, () => Lock());
    await lock.synchronized(() async {
      await writeToService(service);
    });
  }

  /// Get records from online service and send to _saveLocalRecords
  /// When accessing a web service will use the _pool to limit accesses at the same time
  /// Convert server timestamps to serviceUpdatedAt
  Future<void> readFromService(ServicePoint service);

  /// Write records to online services and update record status with _updateRecordStatus
  /// Convert server timestamps to serviceUpdatedAt
  Future<void> writeToService(ServicePoint service);

  /// Compare and save record coming from services
  /// When accessing a web service will use the _pool to limit accesses at the same time
  Future<void> saveLocalRecords(
      ServicePoint service, List<Map> records, int responseTimestamp) async {
    // if access is read -> put all records in transaction and save
    // if access is all -> get records in updated state and compare timestamp
    // save over records in transaction that are allowed,
    // save servicepoint last timestamp on last record

    final database = Sync.shared.local;
    var lastTimestamp = DateTime.utc(0);
    Map<String, Map> transientRecords = {};

    await database.runInTransaction(service.name, (transaction) async {
      // Get updating records to compare
      if (service.access == Access.all) {
        // Get transient records
      }
      for (final map in records) {
        final existingRecord = transientRecords[map['id']];

        if (existingRecord == null ||
            map['updatedAt'] > existingRecord['updatedAt']) {
          database.saveMap(service.name, map);
        }

        //map['serviceUpdatedAt'];
      }
    });
  }

  /// On response check to see if there has been a local change in that time
  /// if there has, do not update record to synced
  Future<void> updateRecordStatus(ServicePoint service, Map record) async {
    // record['_status'] = SyncState.synced.name;
  }
}

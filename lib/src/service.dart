import 'package:sync_db/sync_db.dart';
import 'package:synchronized/synchronized.dart';
import 'package:pool/pool.dart';

abstract class Service {
  // Make sure there are no more than 8 server downloads at the same time
  final pool = Pool(8, timeout: Duration(seconds: 60));
  // The same table/partition will only have one access at a time
  final Map<String, Lock> _serviceLock = {};

  /// Sync everything
  Future<void> sync() async {
    var servicePoints = await Sync.shared.userSession.servicePoints();
    await _syncServicePoints(servicePoints);
  }

  /// Sync a table to service
  Future<void> syncTable(String table) async {
    await _syncServicePoints(
        await Sync.shared.userSession.servicePointsForTable(table));
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
        await Sync.shared.userSession.servicePointsForTable(table);
    var futures = <Future>[];
    Sync.shared.logger?.i('writeTable $table');
    for (final servicePoint in servicePoints) {
      futures.add(writeServicePoint(servicePoint));
    }
    await Future.wait(futures);
  }

  Future<void> readServicePoint(ServicePoint service) async {
    // Needs all or read access
    if (service.access == null || service.access == Access.write) return;

    Sync.shared.logger?.i('readServicePoint ${service.name}');
    // Get lock for only running one service point at a time
    final lock = _serviceLock.putIfAbsent(service.key, () => Lock());
    await lock.synchronized(() async {
      Sync.shared.logger?.i('start readFromService ${service.name}');
      await readFromService(service);
      Sync.shared.logger?.i('end readFromService ${service.name}');
    });
  }

  Future<void> writeServicePoint(ServicePoint service) async {
    // Needs all or write access
    if (service.access == null || service.access == Access.read) return;

    Sync.shared.logger?.i('writeServicePoint ${service.name}');
    // Get lock for only running one service point at a time
    final lock = _serviceLock.putIfAbsent(service.key, () => Lock());
    await lock.synchronized(() async {
      Sync.shared.logger?.i('start writeToService ${service.name}');
      await writeToService(service);
      Sync.shared.logger?.i('end writeToService ${service.name}');
    });
  }

  /// Get records from online service and send to _saveLocalRecords
  /// When accessing a web service will use the _pool to limit accesses at the same time
  /// Save the response timestamp to ServicePoint.from
  Future<void> readFromService(ServicePoint service);

  /// Write records to online services and update record status with _updateRecordStatus
  /// When accessing a web service will use the _pool to limit accesses at the same time
  Future<void> writeToService(ServicePoint service);

  /// Compare and save record coming from services
  Future<void> saveLocalRecords(ServicePoint service, List records) async {
    final database = Sync.shared.local;
    //var lastTimestamp = DateTime.utc(0);
    var transientRecords = <String, Map>{};

    await database.runInTransaction(service.name, (transaction) async {
      // Get updating records to compare
      if (service.access == Access.all) {
        final query =
            Query(service.name).where({statusKey: SyncStatus.updated.name});
        transientRecords =
            await database.queryMap(query, transaction: transaction);
      }

      // Check all records can be saved - don't save over records that have been updated locally
      for (final record in records) {
        final existingRecord = transientRecords[record[idKey]];
        if (existingRecord == null ||
            record[updatedKey] > existingRecord[updatedKey]) {
          record[statusKey] = SyncStatus.synced.name;
          await database.saveMap(service.name, record,
              transaction: transaction);
        }
      }
    });
  }

  /// On response check to see if there has been a local change in that time
  /// if there has, do not update record to synced
  Future<void> updateRecordStatus(ServicePoint service, Map record) async {
    final database = Sync.shared.local;

    await database.runInTransaction(service.name, (transaction) async {
      final liveRecord = database.findMap(service.name, record[idKey],
          transaction: transaction);
      if (liveRecord[updatedKey] == record[updatedKey]) {
        record[statusKey] = SyncStatus.synced.name;
        database.saveMap(service.name, record, transaction: transaction);
      }
    });
    // TODO: Also check if model fields are different from record map. If not, change to updated state,
    // not sync
  }

  /// Remove private fields before saving to cosmos
  void excludePrivateFields(Map map) {
    map.removeWhere((key, value) => key.startsWith('_'));
  }
}

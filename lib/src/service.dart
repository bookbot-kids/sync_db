import 'package:sync_db/sync_db.dart';
import 'package:synchronized/synchronized.dart';

abstract class Service {
  static Service shared;

  Database database;

  Map<String, Access> _serviceAccess = {};
  final Map<String, Lock> _serviceLock = {};
  final Map<String, ServiceModel> _serviceModel = {};

  /// Configure service access, so we know whether to read, write or do nothing.
  /// Will also:
  /// • Setup table locks so a table can only be read or written to,
  /// one at a time.
  /// • Keep track of timestamp of where to sync from for each table.
  void setAccess(Map<String, Access> serviceAccess) async {
    _serviceAccess = serviceAccess;
    for (final table in _serviceAccess.keys) {
      // Add locks that haven't been added before
      if (!_serviceLock.containsKey(table)) _serviceLock[table] = Lock();

      // Find or create service models that haven't been added
      if (!_serviceModel.containsKey(table)) {
        final result = await ServiceModel.where('name = $table').load();
        if (result.isNotEmpty) {
          _serviceModel[table] = result.first;
        } else {
          final service = ServiceModel(name: table);
          // ignore: unawaited_futures
          service.save();
          _serviceModel[table] = service;
        }
      }
    }
  }

  /// Sync everything
  Future<void> sync() async {
    var futures = <Future>[];
    for (final service in _serviceAccess.keys) {
      futures.add(syncTable(service));
    }
    await Future.wait(futures);
  }

  /// Sync a table to service
  Future<void> syncTable(String table) async {
    // This ends here if there is no table access or no read access
    if (!_serviceAccess.containsKey(table) ||
        _serviceAccess[table] == Access.write) {
      return;
    }

    //TODO: If table has partitions - loop through each partition

    // This is to prevent multiple reads or multiple writes at the same time on the same table
    await _serviceLock[table].synchronized(() async {
      final serviceUpdatedAt =
          await readRecords(table, _serviceModel[table].from);
      // Update service model with lastSyncTime
    });

    await writeTable(table);
  }

  /// Write created or updated records in this table
  Future<void> writeTable(String table) async {
    // See if there is service access
    // Service lock
    // update records
  }

  /// Get records from online services
  Future<DateTime> readRecords(String table, DateTime timestamp);

  /// Write records to online services
  Future<void> writeRecords(String table);

  /// Compare and save record coming from services
  // ignore: unused_element
  void _saveLocalRecords(String table, List<Map> records) {
    // Will do asyncronously inside the function
    // if access is read -> put all records in transaction and save
    // if access is all -> get records in updated state and compare timestamp
    // save over records in transaction that are allowed
  }

  void _updateRecordStatus(String table, Map record) {
    // Will be asyncronous inside function
    // On response - check to see if there has been a local change in that time
    // - if there has, do not update record to synced
  }
}

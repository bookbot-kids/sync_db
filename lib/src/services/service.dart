import 'dart:async';

import 'package:queue/queue.dart';
import 'package:sync_db/sync_db.dart';
import 'package:synchronized/synchronized.dart';
import 'package:pool/pool.dart';

abstract class Service {
  // Make sure there are no more than 8 server downloads at the same time
  final pool = Pool(8, timeout: Duration(seconds: 60));
  // The same table/partition will only have one access at a time
  final Map<String, Lock> _serviceLock = {};
  late Queue _syncQueue;

  /// Ignore read write tables
  List<String> ignoreTables = [];

  /// ignore read tables
  List<String> ignoreReadTables = [];

  /// ignore write tables
  List<String> ignoreWriteTables = [];

  var _logDebugCloud = false;

  Service(Map config) {
    _syncQueue = Queue(parallel: config['parallelTask'] ?? 1);
    ignoreTables = List<String>.from(config['tablesToIgnore'] ?? []);
    ignoreReadTables = List<String>.from(config['tablesToIgnoreRead'] ?? []);
    ignoreWriteTables = List<String>.from(config['tablesToIgnoreWrite'] ?? []);
    _logDebugCloud = config['logDebugCloud'] ?? false;
  }

  /// Sync everything
  Future<void> sync({bool syncDelegate = true}) async {
    if (!await connectivity()) {
      return;
    }

    var servicePoints = await Sync.shared.userSession?.servicePoints() ?? [];
    await _syncServicePoints(servicePoints);
    if (syncDelegate) {
      await syncDelegates();
    }
  }

  // Sync external data from delegates
  Future<void> syncDelegates() async {
    if (!Sync.shared.networkAvailable || Sync.shared.syncDelegates.isEmpty) {
      return;
    }

    for (final delegate in Sync.shared.syncDelegates) {
      // ignore: unawaited_futures
      _syncQueue.add(() async {
        if (!Sync.shared.networkAvailable) {
          return;
        }

        final token = await Sync.shared.userSession?.token;
        final data = await delegate.syncRead(token);
        final records = data.item1;
        final permissions = data.item2;
        if (delegate.readOnly) {
          final servicePoint = ServicePoint(
            name: delegate.tableName,
            access: Access.read,
          );
          await saveLocalRecords(servicePoint, records);
        } else {
          if (records.isNotEmpty && permissions.isNotEmpty) {
            for (final item in permissions.entries) {
              final partitionKey = item.key;
              final permission = item.value[0];
              String tableName = permission['id'];
              String token = permission['_token'];
              final access = $Access
                      .fromString(permission['permissionMode'].toLowerCase()) ??
                  Access.read;
              // create service point for each user
              final servicePoint = ServicePoint(
                name: tableName,
                access: access,
              );
              servicePoint.token = token;
              servicePoint.id = ServicePoint.sharedKey(tableName, partitionKey);
              servicePoint.partition = partitionKey;
              await servicePoint.save();

              final savingRecords = records
                  .where((element) => element['partition'] == partitionKey)
                  .toList();
              await saveLocalRecords(servicePoint, savingRecords);
            }
          }
        }
      });
    }

    unawaited(_syncQueue.add(() => Future.value()));
    await _syncQueue.onComplete;
  }

  /// Sync a table to service
  Future<void> syncTable(String table) async {
    if (_logDebugCloud) {
      Sync.shared.logger?.f('[sync_db][DEBUG] syncTable');
    }
    await _syncServicePoints(
        await Sync.shared.userSession?.servicePointsForTable(table) ?? []);
  }

  Future<void> _syncServicePoints(List<ServicePoint> servicePoints) async {
    // manage exceptions here
    // If authentication error - log it - it's not supposed to happen
    // Connectivity - once connectivity is lost, do a connectivity check each minute.
    // If it is flagged as having no connectivity - do not allow it to start another network process
    // Once connectivity is returned restart the sync here, and for storage
    // If can connect to google, but not our servers - log this

    if (_logDebugCloud) {
      Sync.shared.logger
          ?.f('[sync_db][DEBUG] _syncServicePoints start $servicePoints');
    }
    final tasks = <Future<void>>[];
    for (final servicePoint in servicePoints) {
      if (!Sync.shared.networkAvailable) break;
      // Each partition must finish reading before writing. Keep the returned
      // future: queue completion alone does not propagate task failures.
      tasks.add(_syncQueue.add<void>(() async {
        if (!Sync.shared.networkAvailable) return;
        try {
          await readServicePoint(servicePoint);
          await writeServicePoint(servicePoint);
        } catch (_) {
          await Sync.shared.listenInternetChangedIfNeeded();
          rethrow;
        }
      }));
    }
    await Future.wait(tasks);

    if (_logDebugCloud) {
      Sync.shared.logger?.f('[sync_db][DEBUG] _syncServicePoints completed');
    }
  }

  /// Write created or updated records in this table
  Future<void> writeTable(String table) async {
    if (!Sync.shared.networkAvailable) {
      return;
    }

    final servicePoints =
        await Sync.shared.userSession?.servicePointsForTable(table) ?? [];
    var futures = <Future>[];
    Sync.shared.logger?.i('writeTable $table');
    for (final servicePoint in servicePoints) {
      if (!Sync.shared.networkAvailable) {
        return;
      }
      futures.add(writeServicePoint(servicePoint));
    }
    await Future.wait(futures);
  }

  Future<void> readServicePoint(ServicePoint service,
      {bool fullRefresh = false}) async {
    if (fullRefresh &&
        (ignoreTables.contains(service.name) ||
            ignoreReadTables.contains(service.name) ||
            service.access == Access.write)) {
      throw StateError(
          'Cannot refresh unreadable service point ${service.key}');
    }
    // ignore given table from sync
    if (ignoreTables.contains(service.name)) return;
    if (ignoreReadTables.contains(service.name)) return;
    // Needs all or read access
    if (service.access == Access.write) return;

    Sync.shared.logger?.i('readServicePoint ${service.name}');
    // Get lock for only running one service point at a time
    final lock = _serviceLock.putIfAbsent(service.key, () => Lock());
    await lock.synchronized(() async {
      if (fullRefresh) {
        // Removing local records invalidates the incremental cursor. Reset it
        // under the same lock as reads/writes so an older read cannot win.
        service.from = 0;
        await service.save(syncToService: false);
      }
      await readFromService(service, fullRefresh: fullRefresh);
      Sync.shared.logger?.i('[end readFromService ${service.name}]');
    });
  }

  Future<void> writeServicePoint(ServicePoint service) async {
    // ignore given table from sync
    if (ignoreTables.contains(service.name)) return;
    if (ignoreWriteTables.contains(service.name)) return;
    // Needs all or write access
    if (service.access == Access.read) return;

    // don't sync if there is no internet connection
    if (!Sync.shared.networkAvailable) {
      return;
    }

    Sync.shared.logger?.i('writeServicePoint ${service.name}');
    // Get lock for only running one service point at a time
    final lock = _serviceLock.putIfAbsent(service.key, () => Lock());
    await lock.synchronized(() async {
      await writeToService(service);
      Sync.shared.logger?.i('[end writeToService ${service.name}]');
    });
  }

  /// Get records from online service and send to _saveLocalRecords
  /// When accessing a web service will use the _pool to limit accesses at the same time
  /// Save the response timestamp to ServicePoint.from
  Future<void> readFromService(ServicePoint service,
      {bool fullRefresh = false});

  /// Write records to online services and update record status with _updateRecordStatus
  /// When accessing a web service will use the _pool to limit accesses at the same time
  Future<void> writeToService(ServicePoint service);

  /// Compare and save record coming from services
  Future<void> saveLocalRecords(ServicePoint service, List records,
      {bool checkLocalExisting = false}) async {
    if (records.isEmpty) return;
    final handler = Sync.shared.db.modelHandlers[service.name];
    if (handler == null) {
      Sync.shared.logger?.w('${service.name} does not register handler');
      return;
    }

    await Sync.shared.db.local.writeTxn(() async {
      var transientRecords = <String, dynamic>{};
      // Get updating records to compare
      if (service.access == Access.all) {
        final recentUpdatedRecords = await handler
            .queryStatus(SyncStatus.updated, filterDeletedAt: false);
        transientRecords = {
          for (var record in recentUpdatedRecords) record.id!: record
        };
      }

      // Check all records can be saved - don't save over records that have been updated locally (unless read only)
      for (Map record in records) {
        var existingRecord = transientRecords[record[idKey]];
        if (checkLocalExisting && existingRecord == null) {
          existingRecord =
              await handler.find(record[idKey], filterDeletedAt: false);
        }

        if (existingRecord == null ||
            record[updatedKey] >
                (existingRecord.updatedAt?.millisecondsSinceEpoch ?? 0) ||
            service.access == Access.read) {
          // save record
          existingRecord ??=
              Sync.shared.db.modelInstances[service.name]?.call();
          await existingRecord.init();
          existingRecord.syncStatus = SyncStatus.synced;
          final keys = await existingRecord.setMap(record);
          existingRecord.setMetadata(keys, record);
          if (record['partition'] != null) {
            // init() may choose the current account's default partition.
            // A downloaded document's partition is authoritative.
            existingRecord.partition = record['partition'];
          }
          await existingRecord.save(
              syncToService: false, runInTransaction: false, initialize: false);
        }
      }
    });
  }

  /// On response check to see if there has been a local change in that time
  /// if there has, do not update record to synced
  Future<void> updateRecordStatus(
      ServicePoint service, Map serverRecord) async {
    if (serverRecord.isEmpty) return;
    final handler = Sync.shared.db.modelHandlers[service.name];
    if (handler == null) {
      Sync.shared.logger?.w('${service.name} does not register handler');
      return;
    }

    await Sync.shared.db.local.writeTxn(() async {
      final localRecord =
          await handler.find(serverRecord[idKey], filterDeletedAt: false);
      if (localRecord != null) {
        final localUpdatedAt =
            localRecord.updatedAt?.millisecondsSinceEpoch ?? 0;
        final serverUpdatedAt = serverRecord[updatedKey];
        if (serverUpdatedAt > localUpdatedAt) {
          // Server is newer: set status to synced and overwrite server to local
          localRecord.syncStatus = SyncStatus.synced;
          final keys = await localRecord.setMap(serverRecord);
          localRecord.setMetadata(keys, serverRecord);
          await localRecord.save(
              syncToService: false, runInTransaction: false, initialize: false);
        } else if (serverUpdatedAt == localUpdatedAt) {
          // Server and local have the same update time: set status to synced and only write metadata from server into local
          localRecord.syncStatus = SyncStatus.synced;
          final keys = localRecord.keys;
          localRecord.setMetadata(keys, serverRecord);
          await localRecord.save(
              syncToService: false, runInTransaction: false, initialize: false);
        } else {
          // Local is newer: mark it as updated and sync again next time, don't overwrite record
          localRecord.syncStatus = SyncStatus.updated;
          await localRecord.save(
              syncToService: false, runInTransaction: false, initialize: false);
        }
      }
    });
  }

  /// A function to handle connectivity checks
  Future<bool> connectivity() async {
    return await Sync.shared.connectivity();
  }

  /// Remove private fields before saving to cosmos
  void excludePrivateFields(Map map) {
    map.removeWhere((key, value) => key.startsWith('_'));
  }
}

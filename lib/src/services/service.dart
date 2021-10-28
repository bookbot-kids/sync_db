import 'dart:async';

import 'package:connectivity/connectivity.dart';
import 'package:queue/queue.dart';
import 'package:robust_http/robust_http.dart';
import 'package:sync_db/sync_db.dart';
import 'package:synchronized/synchronized.dart';
import 'package:pool/pool.dart';
import 'package:universal_platform/universal_platform.dart';

/// Check if there is any connection (not work for windows)
Future<bool> get hasConnection async =>
    UniversalPlatform.isWindows ||
    await Connectivity().checkConnectivity() != ConnectivityResult.none;

abstract class Service {
  // Make sure there are no more than 8 server downloads at the same time
  final pool = Pool(8, timeout: Duration(seconds: 60));
  // The same table/partition will only have one access at a time
  final Map<String, Lock> _serviceLock = {};
  Queue _syncQueue;
  Timer _connectivityTimer;
  var _isNetworkFailure = false;
  var _isStartingConnectionTimer = false;
  String _testConnectionUrl = '';

  Service(Map config) {
    _syncQueue = Queue(parallel: config['parallelTask'] ?? 1);
    _testConnectionUrl =
        config['testConnectionUrl'] ?? 'https://www.google.com';
  }

  /// Sync everything
  Future<void> sync({bool syncDelegate = true}) async {
    var servicePoints = await Sync.shared.userSession.servicePoints();
    await _syncServicePoints(servicePoints);
    if (syncDelegate) {
      await syncDelegates();
    }
  }

  // Sync external data from delegates
  Future<void> syncDelegates() async {
    for (final delegate in Sync.shared.delegates) {
      final token = await Sync.shared.userSession.token;
      final records = await delegate.syncRead(token);
      // create a fake service point with read only permission to save records
      final servicePoint = ServicePoint(
        name: delegate.tableName,
        access: Access.read,
      );
      await saveLocalRecords(servicePoint, records);
    }
  }

  /// Sync a table to service
  Future<void> syncTable(String table) async {
    await _syncServicePoints(
        await Sync.shared.userSession.servicePointsForTable(table));
  }

  Future<void> _syncServicePoints(List<ServicePoint> servicePoints) async {
    // TODO: manage exceptions here
    // If authentication error - log it - it's not supposed to happen
    // Connectivity - once connectivity is lost, do a connectivity check each minute.
    // If it is flagged as having no connectivity - do not allow it to start another network process
    // Once connectivity is returned restart the sync here, and for storage
    // If can connect to google, but not our servers - log this
    for (final servicePoint in servicePoints) {
      // ignore: unawaited_futures
      _syncQueue.add(() async {
        if (!_isNetworkFailure) {
          try {
            await readServicePoint(servicePoint);
            await writeServicePoint(servicePoint);
          } catch (e) {
            if (!await connectivity()) {
              Sync.shared.logger?.i('There is no connection, start timer');
              _isNetworkFailure = true;
              _startConnectivityTimer(() {
                // restart the function
                _syncServicePoints(servicePoints);
              });
            }

            rethrow;
          }
        }
      });
    }

    if (servicePoints.isNotEmpty) {
      await _syncQueue.onComplete;
    }
  }

  // start timer and check connection status every minute
  void _startConnectivityTimer(Function callback) {
    if (_isStartingConnectionTimer) {
      Sync.shared.logger?.i('Timer is already running');
      return;
    }

    _isStartingConnectionTimer = true;
    _connectivityTimer = Timer.periodic(Duration(minutes: 1), (timer) async {
      _isNetworkFailure = !await connectivity();
      Sync.shared.logger?.i('Timer checking, connection is $_isNetworkFailure');
      // stop timer if there is connection
      if (!_isNetworkFailure) {
        Sync.shared.logger?.i('Connection is restored, stop timer');
        _stopConnectivityTimer();
        callback();
      }
    });
  }

  void _stopConnectivityTimer() {
    _connectivityTimer?.cancel();
    _connectivityTimer = null;
    _isStartingConnectionTimer = false;
  }

  /// Write created or updated records in this table
  Future<void> writeTable(String table) async {
    final servicePoints =
        await Sync.shared.userSession.servicePointsForTable(table);
    var futures = <Future>[];
    Sync.shared.logger?.i('writeTable $table');
    for (final servicePoint in servicePoints) {
      futures.add(Future.sync(() async {
        if (!_isNetworkFailure) {
          try {
            await writeServicePoint(servicePoint);
          } catch (e) {
            if (!await connectivity()) {
              Sync.shared.logger?.i('There is no connection, start timer');
              _isNetworkFailure = true;
              _startConnectivityTimer(() {
                // restart the function
                writeTable(table);
              });
            }

            rethrow;
          }
        }
      }));
    }
    await Future.wait(futures);
  }

  Future<void> readServicePoint(ServicePoint service) async {
    // Needs all or read access
    if (service.access == Access.write) return;

    Sync.shared.logger?.i('readServicePoint ${service.name}');
    // Get lock for only running one service point at a time
    final lock = _serviceLock.putIfAbsent(service.key, () => Lock());
    await lock.synchronized(() async {
      await readFromService(service);
      Sync.shared.logger?.i('[end readFromService ${service.name}]');
    });
  }

  Future<void> writeServicePoint(ServicePoint service) async {
    // Needs all or write access
    if (service.access == Access.read) return;

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
  Future<void> readFromService(ServicePoint service);

  /// Write records to online services and update record status with _updateRecordStatus
  /// When accessing a web service will use the _pool to limit accesses at the same time
  Future<void> writeToService(ServicePoint service);

  /// Compare and save record coming from services
  Future<void> saveLocalRecords(ServicePoint service, List records) async {
    if (records.isEmpty) return;
    final database = Sync.shared.local;
    //var lastTimestamp = DateTime.utc(0);

    await database.runInTransaction(service.name, (transaction) async {
      // Get updating records to compare
      var transientRecords = <String, Map>{};
      if (service.access == Access.all) {
        final query =
            Query(service.name).where({statusKey: SyncStatus.updated.name});
        final recentUpdatedRecords =
            await database.queryMap(query, transaction: transaction);
        transientRecords = {
          for (var record in recentUpdatedRecords) record[idKey]: record
        };
      }

      // Check all records can be saved - don't save over records that have been updated locally (unless read only)
      for (final record in records) {
        final existingRecord = transientRecords[record[idKey]];
        if (existingRecord == null ||
            record[updatedKey] > existingRecord[updatedKey] ||
            service.access == Access.read) {
          record[statusKey] = SyncStatus.synced.name;
          await database.saveMap(service.name, record,
              transaction: transaction);
        }
      }
    });
  }

  /// On response check to see if there has been a local change in that time
  /// if there has, do not update record to synced
  Future<void> updateRecordStatus(
      ServicePoint service, Map serverRecord) async {
    final database = Sync.shared.local;

    await database.runInTransaction(service.name, (transaction) async {
      final localRecord = await database
          .findMap(service.name, serverRecord[idKey], transaction: transaction);
      if (serverRecord[updatedKey] >= localRecord[updatedKey]) {
        serverRecord[statusKey] = SyncStatus.synced.name;
        await database.saveMap(service.name, serverRecord,
            transaction: transaction);
      } else {
        // in case local is newer, mark it as updated and sync again next time
        localRecord[statusKey] = SyncStatus.updated.name;
        await database.saveMap(service.name, localRecord,
            transaction: transaction);
      }
    });
  }

  /// A function to handle connectivity checks
  /// Detect connection by checking wifi/mobile status and connect to test site
  Future<bool> connectivity() async {
    if (!await hasConnection) return false;
    try {
      final _http = HTTP(null, {
        'connectTimeout': 10000, // timeout in 10 seconds
        'receiveTimeout': 10000,
      });
      final response =
          await _http.head(_testConnectionUrl, includeHttpResponse: true);
      if (response.statusCode != 200) {
        return false;
      }
    } catch (e) {
      return false;
    }

    return true;
  }

  /// Remove private fields before saving to cosmos
  void excludePrivateFields(Map map) {
    map.removeWhere((key, value) => key.startsWith('_'));
  }
}

import 'package:sync_db/sync_db.dart';
import 'package:synchronized/synchronized.dart';

enum Access { all, read, write }

enum ModelState { created, updated, synced }

extension $ModelState on ModelState {
  static final string = {
    ModelState.created: 'created',
    ModelState.updated: 'updated',
    ModelState.synced: 'synced',
  };

  static final toEnum = {
    'created': ModelState.created,
    'updated': ModelState.updated,
    'synced': ModelState.synced,
  };

  String get name => $ModelState.string[this];
  static ModelState fromString(String value) => $ModelState.toEnum[value];
}

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
  Future<void> sync({bool startUp = false}) async {
    if (startUp) {
      // Change updated records to stale records
    }

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

    // This is to prevent multiple reads or multiple writes at the same time on the same table
    await _serviceLock[table].synchronized(() async {
      var paginationToken;

      while (paginationToken == null) {
        final result = await readRecords(table, _serviceModel[table].from);
        // if record is in middle of update - do not touch
      }
    });

    // TODO: Change stale records to updated
    await writeTable(table);
  }

  /// Write created or updated records in this table
  Future<void> writeTable(String table) async {
    // Create/Write records
    // Check if records have been updated since
  }

  /// Get records from online services
  Future<List<Map>> readRecords(String table, DateTime timestamp,
      {String paginationToken});

  /// Write records to online services and return written records
  Future<List<Map>> writeRecords(String table);
}

/// The ServiceModel class keeps a record of the timestamp of where to sync from
class ServiceModel extends Model {
  ServiceModel({String name});

  DateTime from;
  String name;

  @override
  Map<String, dynamic> get map {
    return {
      'id': id,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'deletedAt': deletedAt,
      'name': name,
      'from': from
    };
  }

  @override
  String get tableName => 'ServiceModel';

  @override
  set map(Map<String, dynamic> map) {
    id = map['id'];
    createdAt = map['createdAt'];
    updatedAt = map['updatedAt'];
    deletedAt = map['deletedAt'];
    name = map['name'];
    from = map['from'];
  }

  static Future<List<ServiceModel>> all() async {
    var all = await ServiceModel().database.all('ServiceModel', () {
      return ServiceModel();
    });

    return List<ServiceModel>.from(all);
  }

  static Future<ServiceModel> find(String id) async =>
      await ServiceModel().database.find('ServiceModel', id, ServiceModel());

  static Query where(dynamic condition) {
    return Query('ServiceModel').where(condition, ServiceModel().database, () {
      return ServiceModel();
    });
  }
}

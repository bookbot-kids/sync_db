import 'package:sync_db/sync_db.dart';

/// The ServicePoint class keeps a record of access and the timestamp of where to sync from
class ServicePoint extends Model {
  ServicePoint({this.name, this.access});

  String name; // The table name
  int from = 0; // From is the timestamp the sync point in time
  String partition;
  Access access;
  String token;

  @override
  Map<String, dynamic> get map {
    var map = super.map;
    map['name'] = name;
    map['from'] = from;
    map['partition'] = partition;
    map['access'] = access.name;
    map['token'] = token;
    return map;
  }

  @override
  String get tableName => 'ServicePoint';

  @override
  set map(Map<String, dynamic> map) {
    super.map = map;
    name = map['name'];
    from = map['from'];
    partition = map['partition'];
    access = $Access.fromString(map['access']);
    token = map['token'];
  }

  static Future<List<ServicePoint>> all() async {
    var all = await ServicePoint().database.all('ServicePoint', () {
      return ServicePoint();
    });

    return List<ServicePoint>.from(all);
  }

  static Future<ServicePoint> find(String id) async =>
      await ServicePoint().database.find('ServicePoint', id, ServicePoint());

  static Query where(dynamic condition) {
    return Query('ServicePoint').where(condition, ServicePoint().database, () {
      return ServicePoint();
    });
  }

  static Future<ServicePoint> searchBy(String name, {String partition}) async {
    var partitionQuery = partition != null ? ' and partition = $partition' : '';
    var list = List<ServicePoint>.from(
        await where('name = $name${partitionQuery}').limit(1).load());
    return list.isNotEmpty ? list.first : null;
  }

  String get key => '$name-$partition';
}

enum Access { all, read, write }

extension $Access on Access {
  static final string = {
    Access.all: 'all',
    Access.read: 'read',
    Access.write: 'write',
  };

  static final toEnum = {
    'created': Access.all,
    'updated': Access.read,
    'write': Access.write,
  };

  String get name => $Access.string[this];
  static Access fromString(String value) => $Access.toEnum[value];
}

enum SyncStatus { created, updated, synced }

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

  String get name => $SyncStatus.string[this];
  static SyncStatus fromString(String value) => $SyncStatus.toEnum[value];
}

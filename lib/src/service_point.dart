import 'package:sync_db/sync_db.dart';

/// The ServicePoint class keeps a record of access and the timestamp of where to sync from
class ServicePoint extends Model {
  ServicePoint({String name});

  String name; // The table name
  int from;
  String partition;
  Access access;
  String token;

  @override
  Map<String, dynamic> get map {
    return {
      'id': id,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'name': name,
      'from': from,
      'partition': partition,
      'access': access.name,
      'token': token,
    };
  }

  @override
  String get tableName => 'ServicePoint';

  @override
  set map(Map<String, dynamic> map) {
    id = map['id'];
    createdAt = map['createdAt'];
    updatedAt = map['updatedAt'];
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

enum SyncState { created, updated, synced }

extension $SyncState on SyncState {
  static final string = {
    SyncState.created: 'created',
    SyncState.updated: 'updated',
    SyncState.synced: 'synced',
  };

  static final toEnum = {
    'created': SyncState.created,
    'updated': SyncState.updated,
    'synced': SyncState.synced,
  };

  String get name => $SyncState.string[this];
  static SyncState fromString(String value) => $SyncState.toEnum[value];
}

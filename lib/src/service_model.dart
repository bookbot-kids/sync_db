import 'package:sync_db/sync_db.dart';

enum Access { all, read, write }
enum ModelState { created, updated, synced }

/// The ServiceModel class keeps a record of the timestamp of where to sync from
class ServiceModel extends Model {
  ServiceModel({String name});

  String name; // The table name
  DateTime from;
  String partition;
  String access;
  String token;
  DateTime expiry;

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

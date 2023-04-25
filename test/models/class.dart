import 'package:equatable/equatable.dart';
import 'package:isar/isar.dart';
import 'package:isar/src/native/isar_core.dart';
import 'package:sync_db/sync_db.dart';
import 'dart:typed_data';
import 'package:collection/collection.dart';

import 'reward.dart';

part 'class.g.dart';

@collection
class ClassRoom extends Model {
  String name = '';
  String teacherId = '';
  int _level = 1;

  int get level => _level != minLong ? _level : 1;

  set level(value) {
    _level = value;
  }

  @ModelSet()
  List<String> readingBookIds = [];
  @ModelIgnore()
  List<ClassReward> rewards = [];

  @override
  String get tableName => 'Class';

  @override
  Future<List<T>> queryStatus<T extends Model>(SyncStatus syncStatus,
      {bool filterDeletedAt = true}) async {
    final result = await $ClassRoom.queryStatus(syncStatus,
        filterDeletedAt: filterDeletedAt);
    return result.cast();
  }

  @override
  Future<void> save({
    bool syncToService = true,
    bool runInTransaction = true,
    bool initialize = true,
  }) =>
      $ClassRoom(this).save(
          syncToService: syncToService,
          runInTransaction: runInTransaction,
          initialize: initialize);

  @override
  Future<void> clear() => $ClassRoom(this).clear();

  @Ignore()
  @override
  Map get map {
    final result = $ClassRoom(this).map;
    result['rewards'] = rewards
        .map((e) => '${e.name};${e.token};${e.enabled}')
        .toSet()
        .toList();
    return result;
  }

  @override
  Future<Set<String>> setMap(Map map) async {
    final keys = await $ClassRoom(this).setMap(map);
    if (map['rewards'] != null) {
      List rewardStrings = map['rewards'];
      rewards = rewardStrings
          .map((e) {
            List<String> rewardFields = e?.split(';') ?? [];
            if (rewardFields.length == 3) {
              return ClassReward.from(
                rewardFields[0],
                int.tryParse(rewardFields[1]) ?? 1,
                rewardFields[2].toLowerCase() == 'true',
              );
            }
            return null;
          })
          .whereNotNull()
          .toSet()
          .toList();
    }
    keys.addAll(['rewards']);
    return keys;
  }

  @override
  Future<ClassRoom?> find(String? id, {bool filterDeletedAt = true}) =>
      $ClassRoom.find(id, filterDeletedAt: filterDeletedAt);

  @override
  Future<void> deleteLocal() => $ClassRoom(this).deleteLocal();

  @override
  Future<List<Map<String, dynamic>>> exportJson(
      {Function(Uint8List)? callback}) {
    return $ClassRoom(this).exportJson(callback: callback);
  }

  @override
  Future<void> importJson(jsonData) {
    return $ClassRoom(this).importJson(jsonData);
  }
}

@Embedded(ignore: {'props', 'stringify'})
class ClassReward with EquatableMixin implements Reward {
  @override
  String name = '';
  @override
  int token = 0;
  @override
  bool enabled = false;

  ClassReward();

  ClassReward.from(this.name, this.token, this.enabled);

  @override
  List<Object?> get props => [name, token];
}

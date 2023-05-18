import 'dart:convert';
import 'dart:typed_data';

import 'package:enum_to_string/enum_to_string.dart';
import 'package:equatable/equatable.dart';
import 'package:isar/isar.dart';
import 'package:sync_db/sync_db.dart';
import 'package:collection/collection.dart';
part 'event.g.dart';

enum TrackingType {
  googleAnalytics,
  facebookPixel,
  activeCampaign,
  mixpanel,
}

/// Because isar does not support Map type,
/// so we have to convert Map from old model into List<Embedded> in isar, and have to use getter setter map for these properties
@collection
class Event extends Model {
  String type = 'analytics'; // default type is for analytics purpose
  @ModelIgnore()
  List<EventData> eventData = [];
  @ModelIgnore()
  List<EventTriggerAction> triggerAction = [];

  @override
  String get tableName => 'Event';

  @override
  Future<List<T>> queryStatus<T extends Model>(SyncStatus syncStatus,
      {bool filterDeletedAt = true}) async {
    final result =
        await $Event.queryStatus(syncStatus, filterDeletedAt: filterDeletedAt);
    return result.cast();
  }

  @override
  Future<void> save({
    bool syncToService = true,
    bool runInTransaction = true,
    bool initialize = true,
  }) =>
      $Event(this).save(
          syncToService: syncToService,
          runInTransaction: runInTransaction,
          initialize: initialize);

  @override
  Future<void> clear() => $Event(this).clear();

  @override
  Future<Event?> find(String? id, {bool filterDeletedAt = true}) =>
      $Event.find(id, filterDeletedAt: filterDeletedAt);

  @Ignore()
  @override
  Map get map {
    final result = $Event(this).map;
    result['eventData'] = {for (var v in eventData) v.name: v.fromJson()};
    result['triggerAction'] = {
      for (var v in triggerAction) v.trackingType.name: v.fromJson()
    };
    return result;
  }

  @override
  Future<Set<String>> setMap(Map map) async {
    final keys = await $Event(this).setMap(map);
    final newEventData = map['eventData'];
    if (newEventData != null) {
      eventData = List<EventData>.from(newEventData.entries.map((e) {
        final item = EventData.from(e.key, '');
        item.toJson(e.value);
        return item;
      }).toList());
    }

    final newTriggerAction = map['triggerAction'];
    if (newTriggerAction != null) {
      triggerAction =
          List<EventTriggerAction>.from(newTriggerAction.entries.map((e) {
        final item = EventTriggerAction.from(
            EnumToString.fromString(TrackingType.values, e.key)!, '');
        item.toJson(e.value);
        return item;
      }).toList());
    }

    // return custom keys here to exclude from metadata json
    keys.addAll([
      'eventData',
      'triggerAction',
    ]);
    return keys;
  }

  @Ignore()
  @override
  Set<String> get keys => $Event(this).keys
    ..addAll([
      'eventData',
      'triggerAction',
    ]);
}

@Embedded(ignore: {'props', 'stringify'})
class EventData with EquatableMixin {
  String name = '';
  String jsonData = '';

  EventData();
  EventData.from(this.name, this.jsonData);
  dynamic fromJson() {
    try {
      Map m = json.decode(jsonData);
      return m;
    } catch (e) {
      return jsonData;
    }
  }

  void toJson(dynamic value) => jsonData = json.encode(value);

  @override
  List<Object?> get props => [name, jsonData];
}

@Embedded(ignore: {'props', 'stringify'})
class EventTriggerAction with EquatableMixin {
  @Enumerated(EnumType.name)
  TrackingType trackingType = TrackingType.googleAnalytics;
  String jsonData = '';

  EventTriggerAction();
  EventTriggerAction.from(this.trackingType, this.jsonData);

  Map fromJson() => jsonData.isEmpty ? {} : json.decode(jsonData);
  void toJson(Map value) => jsonData = json.encode(value);

  @override
  List<Object?> get props => [trackingType, jsonData];
}

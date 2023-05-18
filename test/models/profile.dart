import 'dart:convert';

import 'package:enum_to_string/enum_to_string.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:sync_db/sync_db.dart';
import 'package:collection/collection.dart';

import 'class.dart';
import 'languages.dart';

part 'profile.g.dart';

enum Bot { yellow, orange, red, blue, green, purple }

enum Onboarding { intro, bookIntro, stamp }

enum InviteStatus { none, invited, connected }

/// Because isar does not support Map type,
/// so we have to convert Map from old model into List<Embedded> in isar, and have to use getter setter map for these properties
@collection
class Profile extends Model {
  String name = '';

  /// Wrap progress properties into a class type
  @ModelIgnore()
  List<ProfileProgress> progresses = [];

  /// Wrap multiple level properties into a class type
  @ModelIgnore()
  List<ProfileLevel> levels = [];

  @Enumerated(EnumType.name)
  Bot bot = Bot.yellow;
  String botType = '';
  String dob = '';
  List<String> about = [];
  @Enumerated(EnumType.name)
  Onboarding onboarding = Onboarding.intro;

  bool readToMe = false;
  bool autoTurnPage = false;

  @ModelIgnore()
  List<ProfileScriptStatus> scriptStatuses = [];

  @ModelIgnore()
  List<ProfileTeacherInfo> teacherInfo = [];

  int lastRead = NetworkTime.shared.timeNow.millisecondsSinceEpoch;
  @ModelSet()
  List<String> favourites = [];
  @ModelSet()
  List<String> completedBooks = [];
  String email = '';
  String lastName = '';

  @Enumerated(EnumType.name)
  InviteStatus inviteStatus = InviteStatus.none;

  @ModelSet()
  List<String> classesIds = [];
  @ModelSet()
  List<String> teacherIds = [];

  @Ignore()
  List<ClassRoom>? _classes;

  /// count read book for progress tracker
  int trackerBooksRead = 0;

  /// count read word for progress tracker
  int trackerWords = 0;

  /// count practice word for progress tracker
  int trackerPractice = 0;

  /// count read book for progress sticker
  int stickerBooksRead = 0;

  @visibleForTesting
  @override
  String get tableName => 'Profile';

  Future<List<ClassRoom>?> getClassess() async {
    if (_classes == null && classesIds.isNotEmpty) {
      _classes = [];
      for (final classId in classesIds) {
        final clazz =
            await db.classRooms.filter().idEqualTo(classId).findFirst();
        if (clazz != null) {
          _classes?.add(clazz);
        }
      }
    }
    return _classes;
  }

  @override
  Future<List<T>> queryStatus<T extends Model>(SyncStatus syncStatus,
      {bool filterDeletedAt = true}) async {
    final result = await $Profile.queryStatus(syncStatus,
        filterDeletedAt: filterDeletedAt);
    return result.cast();
  }

  @override
  Future<void> save({
    bool syncToService = true,
    bool runInTransaction = true,
    bool initialize = true,
  }) =>
      $Profile(this).save(
          syncToService: syncToService,
          runInTransaction: runInTransaction,
          initialize: initialize);

  @override
  Future<void> clear() => $Profile(this).clear();

  @Ignore()
  @override
  Map get map {
    // Break multiple levels properties
    final result = $Profile(this).map;
    result['displayLevels'] = {
      for (var v in levels) v.language.name: v.displayLevel
    };

    result['libraryLevels'] = {
      for (var v in levels) v.language.name: v.libraryLevel
    };

    result['levelsCompletedAt'] = {
      for (var v in levels) v.language.name: v.toLevelsCompletedAtMap()
    };

    result['averageAccuracies'] = {
      for (var v in progresses) v.language.name: v.averageAccuracy
    };

    result['averageFluencies'] = {
      for (var v in progresses) v.language.name: v.averageFluency
    };

    result['scriptStatuses'] = {
      for (var v in scriptStatuses) v.name: v.enabled
    };
    result['teacherInfo'] = {for (var v in teacherInfo) v.id: v.fromJson()};
    return result;
  }

  @override
  Future<Set<String>> setMap(Map map) async {
    final keys = await $Profile(this).setMap(map);
    final progresMap = <LibraryLanguage, ProfileProgress>{};
    final levelMap = <LibraryLanguage, ProfileLevel>{};

    if (map['displayLevels'] != null) {
      Map displayLevels = map['displayLevels'];
      for (final item in displayLevels.entries) {
        final language =
            EnumToString.fromString(LibraryLanguage.values, item.key) ??
                LibraryLanguage.en;
        levelMap.putIfAbsent(language, () => ProfileLevel.from(language));
        levelMap[language]?.displayLevel =
            item.value.toDouble(); // handle int value from server
      }
    }

    if (map['libraryLevels'] != null) {
      Map libraryLevels = map['libraryLevels'];
      for (final item in libraryLevels.entries) {
        final language =
            EnumToString.fromString(LibraryLanguage.values, item.key) ??
                LibraryLanguage.en;
        levelMap.putIfAbsent(language, () => ProfileLevel.from(language));
        levelMap[language]?.libraryLevel =
            item.value.toInt(); // handle double value from server
      }
    }

    if (map['levelsCompletedAt'] != null) {
      Map levelsCompletedAt = map['levelsCompletedAt'];
      for (final item in levelsCompletedAt.entries) {
        final language =
            EnumToString.fromString(LibraryLanguage.values, item.key) ??
                LibraryLanguage.en;
        levelMap.putIfAbsent(language, () => ProfileLevel.from(language));
        levelMap[language]?.levelsCompletedAt =
            levelMap[language]?.levelsCompletedAt.toList() ?? [];
        item.value.forEach((key, value) {
          levelMap[language]
              ?.levelsCompletedAt
              .add(LevelEntry.from(key, value));
        });
      }
    }

    if (map['averageAccuracies'] != null) {
      Map averageAccuracies = map['averageAccuracies'];
      for (final item in averageAccuracies.entries) {
        final language =
            EnumToString.fromString(LibraryLanguage.values, item.key) ??
                LibraryLanguage.en;
        progresMap.putIfAbsent(language, () => ProfileProgress.from(language));
        progresMap[language]?.averageAccuracy =
            item.value.toDouble(); // handle int value from server
      }
    }

    if (map['averageFluencies'] != null) {
      Map averageFluencies = map['averageFluencies'];
      for (final item in averageFluencies.entries) {
        final language =
            EnumToString.fromString(LibraryLanguage.values, item.key) ??
                LibraryLanguage.en;
        progresMap.putIfAbsent(language, () => ProfileProgress.from(language));
        progresMap[language]?.averageFluency =
            item.value.toDouble(); // handle int value from server
      }
    }

    final newScriptStatuses = map['scriptStatuses'];
    if (newScriptStatuses != null) {
      scriptStatuses = List<ProfileScriptStatus>.from(newScriptStatuses.entries
          .map((e) => ProfileScriptStatus.from(e.key, e.value))
          .toList());
    }

    final newTeacherInfo = map['teacherInfo'];
    if (newTeacherInfo != null) {
      teacherInfo =
          List<ProfileTeacherInfo>.from(newTeacherInfo.entries.map((e) {
        final item = ProfileTeacherInfo.from(e.key);
        Map data = e.value;
        item.toJson(data);
        return item;
      }).toList());
    }

    progresses = [];
    for (final entry in progresMap.entries) {
      progresses.add(entry.value);
    }

    levels = [];
    for (final entry in levelMap.entries) {
      levels.add(entry.value);
    }

    // return custom keys here to exclude from metadata json
    keys.addAll([
      'displayLevels',
      'libraryLevels',
      'levelsCompletedAt',
      'scriptStatuses',
      'averageAccuracies',
      'averageFluencies',
      'teacherInfo'
    ]);

    return keys;
  }

  @Ignore()
  @override
  Set<String> get keys => $Profile(this).keys
    ..addAll([
      'displayLevels',
      'libraryLevels',
      'levelsCompletedAt',
      'scriptStatuses',
      'averageAccuracies',
      'averageFluencies',
      'teacherInfo'
    ]);

  @override
  Future<Profile?> find(String? id, {bool filterDeletedAt = true}) =>
      $Profile.find(id, filterDeletedAt: filterDeletedAt);

  @override
  Map<String, List<String>> remapFields() => {
        'progresses': [
          'averageAccuracies',
          'averageFluencies',
        ],
        'levels': [
          'displayLevels',
          'libraryLevels',
          'levelsCompletedAt',
        ]
      };

  @override
  Future<void> deleteLocal() => $Profile(this).deleteLocal();

  @override
  Future<List<Map<String, dynamic>>> exportJson(
      {Function(Uint8List)? callback}) {
    return $Profile(this).exportJson(callback: callback);
  }

  @override
  Future<void> importJson(jsonData) {
    return $Profile(this).importJson(jsonData);
  }

  void resetTracker() {
    trackerBooksRead = 0;
    trackerWords = 0;
    trackerPractice = 0;
  }
}

/*
// Embeded classes
*/

@Embedded(ignore: {'props', 'stringify'})
class ProfileTeacherInfo with EquatableMixin {
  String id = '';
  String jsonInfo = '';

  Map fromJson() => jsonInfo.isEmpty ? {} : json.decode(jsonInfo);
  void toJson(Map value) => jsonInfo = json.encode(value);

  ProfileTeacherInfo();
  ProfileTeacherInfo.from(this.id);

  @override
  List<Object?> get props => [id, jsonInfo];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileTeacherInfo &&
          id == other.id &&
          jsonInfo == other.jsonInfo;

  @override
  int get hashCode => Object.hash(id, jsonInfo);
}

@Embedded(ignore: {'props', 'stringify'})
class ProfileScriptStatus with EquatableMixin {
  String name = '';
  bool enabled = false;

  ProfileScriptStatus();
  ProfileScriptStatus.from(this.name, this.enabled);

  @override
  List<Object?> get props => [name, enabled];
}

@Embedded(ignore: {'props', 'stringify'})
class LevelEntry with EquatableMixin {
  String name = '';
  int level = 0;

  LevelEntry();
  LevelEntry.from(this.name, this.level);

  @override
  List<Object?> get props => [name, level];
}

/// Level embedded object
/// WARNING: to use double property here, we have to make sure to call `.toDouble()` in setMap because int value can come from server
@Embedded(ignore: {'props', 'stringify'})
class ProfileLevel with EquatableMixin {
  @Enumerated(EnumType.name)
  LibraryLanguage language = LibraryLanguage.en;
  List<LevelEntry> levelsCompletedAt = [];
  double displayLevel = 1.0; // must be handle .toDouble()
  int libraryLevel = 1;

  ProfileLevel();
  ProfileLevel.from(this.language);

  Map toLevelsCompletedAtMap() =>
      {for (var v in levelsCompletedAt) v.name: v.level};

  @override
  List<Object?> get props => [
        language,
        levelsCompletedAt,
        displayLevel,
        libraryLevel,
      ];
}

/// Progress embedded object
/// WARNING: to use double property here, we have to make sure to call `.toDouble()` in setMap because int value can come from server
@Embedded(ignore: {'props', 'stringify'})
class ProfileProgress with EquatableMixin {
  @Enumerated(EnumType.name)
  LibraryLanguage language = LibraryLanguage.en;
  double averageAccuracy = 0.0;
  double averageFluency = 0.0;

  ProfileProgress();
  ProfileProgress.from(this.language);

  @override
  List<Object?> get props => [language, averageAccuracy, averageFluency];
}

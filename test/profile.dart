import 'dart:convert';

import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:sync_db/sync_db.dart';

import 'class.dart';
import 'languages.dart';

part 'profile.g.dart';

enum Bot { orange, yellow, red, blue, green, purple }

enum Onboarding { intro, bookIntro, stamp }

enum InviteStatus { none, invited, connected }

@collection
class Profile extends Model {
  String name = '';

  @ModelIgnore()
  List<ProfileProgress> progresses = [];

  @enumerated
  Bot bot = Bot.orange;
  String dob = '';
  List<String> about = [];
  @enumerated
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

  @enumerated
  InviteStatus inviteStatus = InviteStatus.none;

  @ModelSet()
  List<String> classesIds = [];
  @ModelSet()
  List<String> teacherIds = [];

  @Ignore()
  List<ClassRoom>? _classes;

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
  Future<List<T>> queryStatus<T extends Model>(SyncStatus syncStatus) async {
    final result = await $Profile.queryStatus(syncStatus);
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
    final result = $Profile(this).map;
    result['displayLevels'] = {
      for (var v in progresses) v.language.name: v.displayLevel
    };

    result['libraryLevels'] = {
      for (var v in progresses) v.language.name: v.libraryLevel
    };

    result['levelsCompletedAt'] = {
      for (var v in progresses) v.language.name: v.toLevelsCompletedAtMap()
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

    if (map['displayLevels'] != null) {
      Map displayLevels = map['displayLevels'];
      for (final item in displayLevels.entries) {
        final language =
            EnumToString.fromString(LibraryLanguage.values, item.key) ??
                LibraryLanguage.en;
        progresMap.putIfAbsent(language, () => ProfileProgress());
        progresMap[language]?.displayLevel = item.value;
      }
    }

    if (map['libraryLevels'] != null) {
      Map libraryLevels = map['libraryLevels'];
      for (final item in libraryLevels.entries) {
        final language =
            EnumToString.fromString(LibraryLanguage.values, item.key) ??
                LibraryLanguage.en;
        progresMap.putIfAbsent(language, () => ProfileProgress());
        progresMap[language]?.libraryLevel = item.value;
      }
    }

    if (map['levelsCompletedAt'] != null) {
      Map levelsCompletedAt = map['levelsCompletedAt'];
      for (final item in levelsCompletedAt.entries) {
        final language =
            EnumToString.fromString(LibraryLanguage.values, item.key) ??
                LibraryLanguage.en;
        progresMap.putIfAbsent(language, () => ProfileProgress());
        progresMap[language]?.levelsCompletedAt =
            progresMap[language]?.levelsCompletedAt.toList() ?? [];
        item.value.forEach((key, value) {
          progresMap[language]
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
        progresMap.putIfAbsent(language, () => ProfileProgress());
        progresMap[language]?.averageAccuracy = item.value;
      }
    }

    if (map['averageFluencies'] != null) {
      Map averageFluencies = map['averageFluencies'];
      for (final item in averageFluencies.entries) {
        final language =
            EnumToString.fromString(LibraryLanguage.values, item.key) ??
                LibraryLanguage.en;
        progresMap.putIfAbsent(language, () => ProfileProgress());
        progresMap[language]?.averageFluency = item.value;
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

  @override
  Future<Profile?> find(String? id) => $Profile.find(id);
}

/*
// Embeded classes
*/

@embedded
class ProfileTeacherInfo {
  String id = '';
  String jsonInfo = '';

  Map fromJson() => jsonInfo.isEmpty ? {} : json.decode(jsonInfo);
  void toJson(Map value) => jsonInfo = json.encode(value);

  ProfileTeacherInfo();
  ProfileTeacherInfo.from(this.id);
}

@embedded
class ProfileScriptStatus {
  String name = '';
  bool enabled = false;

  ProfileScriptStatus();
  ProfileScriptStatus.from(this.name, this.enabled);
}

@embedded
class LevelEntry {
  String name = '';
  int level = 0;

  LevelEntry();
  LevelEntry.from(this.name, this.level);
}

@embedded
class ProfileProgress {
  @enumerated
  LibraryLanguage language = LibraryLanguage.en;
  List<LevelEntry> levelsCompletedAt = [];
  double displayLevel = 0.0;
  int libraryLevel = 0;
  double averageAccuracy = 0.0;
  double averageFluency = 0.0;

  ProfileProgress();
  ProfileProgress.from(this.language);

  Map toLevelsCompletedAtMap() =>
      {for (var v in levelsCompletedAt) v.name: v.level};
}

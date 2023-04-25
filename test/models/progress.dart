import 'package:enum_to_string/enum_to_string.dart';
import 'package:equatable/equatable.dart';
import 'package:isar/isar.dart';
import 'package:sync_db/sync_db.dart';
import 'package:collection/collection.dart';
import 'dart:typed_data';

import 'languages.dart';
import 'profile.dart';

part 'progress.g.dart';

/// Because isar does not support Map type,
/// so we have to convert Map from old model into List<Embedded> in isar, and have to use getter setter map for these properties
@collection
class Progress extends Model {
  String? profileId;
  String? bookId;
  int currentPage = 0;
  int rating = 0;

  @Ignore()
  Profile? _profile;

  @Enumerated(EnumType.name)
  LibraryLanguage bookLanguage = LibraryLanguage.en;

  // Properties to clear on completion
  List<double> progress = []; // Percentage that has been read
  List<bool> correct = [];
  // Fluency = words per second
  double fluency = 0.0;
  // Accuracy = correct to incorrect words
  double accuracy = 0.0;
  List<double> accuracies = []; // accuracy per page
  List<double> fluencies = []; // fluency per page
  int level = 0;
  int pageReadCount = 0;
  // All word read in the book that are read correctly (true) or incorrectly (false) and later corrected
  @ModelIgnore()
  List<ProgressCorrectWords> correctWords = [];
  @ModelIgnore()
  List<ProgressCorrectWords> incorrectWords = [];
  int readToMeTime = 0;
  int readingTime = 0;
  int? completedAt;

  List<String> markers = [];
  @ModelSet()
  List<String> readWords = [];

  @ModelSet()
  List<String> readPracticeWords = [];

  @override
  String get tableName => 'Progress';

  @override
  Future<List<T>> queryStatus<T extends Model>(SyncStatus syncStatus,
      {bool filterDeletedAt = true}) async {
    final result = await $Progress.queryStatus(syncStatus,
        filterDeletedAt: filterDeletedAt);
    return result.cast();
  }

  @override
  Future<void> save({
    bool syncToService = true,
    bool runInTransaction = true,
    bool initialize = true,
  }) =>
      $Progress(this).save(
          syncToService: syncToService,
          runInTransaction: runInTransaction,
          initialize: initialize);

  @override
  Future<void> clear() => $Progress(this).clear();

  @Ignore()
  @override
  Map get map {
    final result = $Progress(this).map;
    result['correctWords'] = {for (var v in correctWords) v.word: v.correct};
    result['incorrectWords'] = {
      for (var v in incorrectWords) v.word: v.correct
    };
    return result;
  }

  @override
  Future<Set<String>> setMap(Map map) async {
    final keys = await $Progress(this).setMap(map);
    final newCorrectWords = map['correctWords'];
    if (newCorrectWords != null) {
      correctWords = List<ProgressCorrectWords>.from(newCorrectWords.entries
          .map((e) => ProgressCorrectWords.from(e.key, e.value))
          .toList());
    }

    final newIncorrectWords = map['incorrectWords'];
    if (newIncorrectWords != null) {
      incorrectWords = List<ProgressCorrectWords>.from(newIncorrectWords.entries
          .map((e) => ProgressCorrectWords.from(e.key, e.value))
          .toList());
    }

    // return custom keys here to exclude from metadata json
    keys.addAll(['correctWords', 'incorrectWords']);
    return keys;
  }

  Future<Profile?> getProfile() async {
    _profile ??= await $Profile.find(profileId);
    return _profile;
  }

  @override
  Future<Progress?> find(String? id, {bool filterDeletedAt = true}) =>
      $Progress.find(id, filterDeletedAt: filterDeletedAt);

  @override
  Future<void> deleteLocal() => $Progress(this).deleteLocal();

  @override
  Future<List<Map<String, dynamic>>> exportJson(
      {Function(Uint8List)? callback}) {
    return $Progress(this).exportJson(callback: callback);
  }

  @override
  Future<void> importJson(jsonData) {
    return $Progress(this).importJson(jsonData);
  }
}

@Embedded(ignore: {'props', 'stringify'})
class ProgressCorrectWords with EquatableMixin {
  String word = '';
  bool correct = false;

  ProgressCorrectWords();
  ProgressCorrectWords.from(this.word, this.correct);

  @override
  bool operator ==(Object other) =>
      other is ProgressCorrectWords && other.word == word;

  @override
  int get hashCode => word.hashCode;

  @override
  List<Object?> get props => [word, correct];
}

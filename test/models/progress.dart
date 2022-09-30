import 'package:enum_to_string/enum_to_string.dart';
import 'package:equatable/equatable.dart';
import 'package:isar/isar.dart';
import 'package:sync_db/sync_db.dart';
import 'package:collection/collection.dart';

import 'languages.dart';
import 'profile.dart';

part 'progress.g.dart';

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
  int pageReadCount = 0;
  // All word read in the book that are read correctly (true) or incorrectly (false) and later corrected
  List<ProgressCorrectWords> correctWords = [];
  List<ProgressCorrectWords> incorrectWords = [];
  int readToMeTime = 0;
  int readingTime = 0;
  int? completedAt;

  List<String> markers = [];

  @override
  String get tableName => 'Progress';

  @override
  Future<List<T>> queryStatus<T extends Model>(SyncStatus syncStatus) async {
    final result = await $Progress.queryStatus(syncStatus);
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

    keys.addAll(['correctWords', 'incorrectWords']);
    return keys;
  }

  Future<Profile?> getProfile() async {
    _profile ??= await $Profile.find(profileId);
    return _profile;
  }

  @override
  Future<Progress?> find(String? id) => $Progress.find(id);
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

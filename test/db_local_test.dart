import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:sync_db/sync_db.dart';
import 'dart:io' as io;

import 'models/class.dart';
import 'models/languages.dart';
import 'models/profile.dart';
import 'models/progress.dart';

void main() {
  final db = IsarDatabase();
  TestWidgetsFlutterBinding.ensureInitialized();
  // fix dio request error https://github.com/flutter/flutter/issues/48050#issuecomment-572359109
  io.HttpOverrides.global = null;
  setUpAll(() async {
    print('initialize');
    MethodChannel('plugins.flutter.io/path_provider')
        .setMockMethodCallHandler((call) async => '.');

    MethodChannel('plugins.flutter.io/path_provider_macos')
        .setMockMethodCallHandler((call) async => '.');

    await Isar.initializeIsarCore(download: true);
    await db.init({
      ProfileSchema: () => Profile(),
      ClassRoomSchema: () => ClassRoom(),
      ProgressSchema: () => Progress(),
    });
    Sync.shared.db = db;
  });

  group('Profile read/write', () {
    test('write data', () async {
      final profile = Profile();
      profile.email = 'test@gmail.com';
      profile.id = '1234567';
      profile.name = 'jack';
      await profile.save(syncToService: false);
      assert(profile.localId > 0);
      assert(profile.createdAt != null);
    });

    test('read data', () async {
      final profile = await $Profile.find('1234567');
      assert(profile != null);
      assert(profile!.localId > 0);
      assert(profile?.createdAt != null);
      assert(profile?.syncStatus == SyncStatus.created);
    });

    test('update data', () async {
      final profile = await $Profile.find('1234567');
      assert(profile != null);
      profile?.completedBooks = profile.completedBooks.addItem('1234');
      await profile?.save(syncToService: false);
      assert(profile!.completedBooks.isNotEmpty);
    });
  });

  group('Progress read/write', () {
    test('write data', () async {
      final progress = Progress();
      progress.id = '1234567';
      progress.bookLanguage = LibraryLanguage.en;
      progress.correctWords = [
        ProgressCorrectWords.from('A', true),
        ProgressCorrectWords.from('B', false),
      ];

      progress.incorrectWords = [
        ProgressCorrectWords.from('C', true),
        ProgressCorrectWords.from('D', false),
      ];
      await progress.save(syncToService: false);
      assert(progress.localId > 0);
      assert(progress.createdAt != null);
      expect(progress.incorrectWords.length, equals(2));
    });

    test('read data', () async {
      final progress = await $Progress.find('1234567');
      expect(progress, isNotNull);
      expect(progress!.localId, greaterThan(0));
      expect(progress.syncStatus, equals(SyncStatus.created));
      expect(progress.incorrectWords.length, equals(2));
    });

    test('update data', () async {
      final progress = await $Progress.find('1234567');
      expect(progress, isNotNull);
      progress!.incorrectWords =
          progress.incorrectWords.addItem(ProgressCorrectWords.from('E', true));
      await progress.save(syncToService: false);
      expect(progress.incorrectWords.length, equals(3));
    });
  });

  tearDownAll(() {
    print('tearDown');
    db.close(deleteFromDisk: true);
  });
}

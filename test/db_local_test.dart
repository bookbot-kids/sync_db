import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:sync_db/sync_db.dart';
import 'profile.dart';
import 'class.dart';
import 'dart:io' as io;

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
    });
    Sync.shared.db = db;
  });

  group('Local read/write', () {
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

  tearDownAll(() {
    print('tearDown');
    db.close(deleteFromDisk: true);
  });
}

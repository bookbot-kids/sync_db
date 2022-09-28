import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:sync_db/sync_db.dart';
import 'package:universal_io/io.dart';
import 'profile.dart';
import 'class.dart';
import 'dart:io' as io;
import 'package:collection/collection.dart';
import 'sync_service_helper.dart';

void main() {
  final db = IsarDatabase();
  late SyncHelper syncHelper;
  TestWidgetsFlutterBinding.ensureInitialized();
  // fix dio request error https://github.com/flutter/flutter/issues/48050#issuecomment-572359109
  io.HttpOverrides.global = null;
  late Map configs;
  setUpAll(() async {
    print('initialize');
    configs = jsonDecode(await File('test/keys.json').readAsString());
    syncHelper = SyncHelper(configs);
    MethodChannel('plugins.flutter.io/path_provider')
        .setMockMethodCallHandler((call) async => '.');

    MethodChannel('plugins.flutter.io/path_provider_macos')
        .setMockMethodCallHandler((call) async => '.');

    await Isar.initializeIsarCore(download: true);

    // Local DB
    final sync = Sync.shared;
    await db.init({
      ClassRoomSchema: () => ClassRoom(),
      ProfileSchema: () => Profile(),
    });
    sync.db = db;
  });

  group('Sync', () {
    test('test profile read and update', () async {
      final resourceToken = await syncHelper.getResourceToken('Profile');
      // read cosmos record
      var record = await syncHelper.getCosmosDocument(
          'Profile',
          configs['testProfileId'],
          resourceToken,
          configs['testProfilePartition']);
      assert(record != null);
      expect(record['id'], equals(configs['testProfileId']));
      expect(record['partition'], equals(configs['testProfilePartition']));

      // save to local
      var profile = Profile();
      await profile.setMap(record);
      profile.syncStatus = SyncStatus.created;
      await profile.save(syncToService: false, initialize: false);
      expect(profile.localId, greaterThan(0));
      expect(profile.createdAt, isNotNull);

      // then query, update and send to cosmos
      final localProfile = await $Profile.find(record['id']);
      assert(localProfile != null);
      profile = localProfile!;
      // update properties
      profile.bot = Bot.yellow;
      profile.partition ??= configs['testProfilePartition'];
      final updatedMap = profile.map;
      updatedMap.addAll(profile.metadataMap);
      updatedMap[partitionKey] = profile.partition;
      await syncHelper.updateDocument('Profile', resourceToken,
          configs['testProfilePartition'], updatedMap);

      // read from cosmos again
      record = await syncHelper.getCosmosDocument(
          'Profile',
          configs['testProfileId'],
          resourceToken,
          configs['testProfilePartition']);
      expect(record['id'], equals(configs['testProfileId']));
      expect(record['bot'], equals('yellow'));
      await profile.setMap(record);
      profile.syncStatus = SyncStatus.synced;
      await profile.save(syncToService: false, initialize: false);
      expect(profile.id, equals(record['id']));
      expect(profile.partition, equals(record['partition']));
      expect(
          ListEquality().equals(profile.completedBooks,
              List<String>.from(record['completedBooks'])),
          true);
      expect(
          ListEquality().equals(
              profile.classesIds, List<String>.from(record['classesIds'])),
          true);
    });

    test('test create profile', () async {
      // create profile
      final profile = Profile();
      profile.name = 'Test';
      await profile.init();
      profile.partition = configs['testProfilePartition'];
      await profile.save(syncToService: false);
      print('create new profile ${profile.id} $profile');
      final resourceToken = await syncHelper.getResourceToken('Profile');
      final createdMap = profile.map;
      createdMap.addAll(profile.metadataMap);
      createdMap[partitionKey] = profile.partition;
      final createdRecord = await syncHelper.createDocument('Profile',
          resourceToken, configs['testProfilePartition'], createdMap);
      expect(createdRecord, isNotNull);
      expect(profile.id, isNotNull);
      final profileId = profile.id!;

      // read cosmos record
      var record = await syncHelper.getCosmosDocument(
          'Profile', profileId, resourceToken, configs['testProfilePartition']);
      assert(record != null);
      expect(record['id'], equals(createdRecord!['id']));
      expect(record['name'], equals(createdRecord['name']));
      expect(record['partition'], equals(createdRecord['partition']));
      expect(record['name'], equals(profile.name));
    });
  });

  tearDownAll(() {
    print('tearDown');
    db.close(deleteFromDisk: true);
  });
}

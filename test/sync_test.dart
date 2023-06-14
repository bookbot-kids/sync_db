import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:sync_db/sync_db.dart';
import 'package:universal_io/io.dart';
import 'package:collection/collection.dart';
import 'models/class.dart';
import 'models/event.dart';
import 'models/languages.dart';
import 'models/profile.dart';
import 'models/progress.dart';
import 'sync_service_helper.dart';

void main() {
  late SyncHelper syncHelper;
  TestWidgetsFlutterBinding.ensureInitialized();
  // fix dio request error https://github.com/flutter/flutter/issues/48050#issuecomment-572359109
  HttpOverrides.global = null;
  late Map configs;
  setUpAll(() async {
    print('initialize');
    final isarFile = File('default.isar');
    if (await isarFile.exists()) {
      await isarFile.delete();
    }

    final isarLockFile = File('default.isar.lock');
    if (await isarLockFile.exists()) {
      await isarLockFile.delete();
    }

    configs = jsonDecode(await File('test/keys.json').readAsString());
    syncHelper = SyncHelper(configs);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => '.');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            MethodChannel('plugins.flutter.io/path_provider_macos'),
            (call) async => '.');

    await Isar.initializeIsarCore(download: true);

    // Local DB
    final sync = Sync.shared;
    await sync.db.init({
      ClassRoomSchema: () => ClassRoom(),
      ProfileSchema: () => Profile(),
      ProgressSchema: () => Progress(),
      EventSchema: () => Event(),
    });
  });

  group('Sync1', () {
    test('test profile read and full update', () async {
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
      updatedMap[updatedKey] = profile.updatedAt?.millisecondsSinceEpoch ??
          (await NetworkTime.shared.now).millisecondsSinceEpoch;
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
      final createdRecord = await syncHelper.createRecord(
          'Profile', profile, configs['testProfilePartition'],
          resourceToken: resourceToken);
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

    test('test profile read and partial update', () async {
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
      profile.syncStatus = SyncStatus.synced;
      await profile.save(syncToService: false, initialize: false);
      expect(profile.syncStatus, equals(SyncStatus.synced));
      expect(profile.localId, greaterThan(0));
      expect(profile.createdAt, isNotNull);

      // then query, update and send to cosmos by partial api
      final localProfile = await $Profile.find(record['id']);
      assert(localProfile != null);
      profile = localProfile!;
      // update properties
      profile.bot = Bot.values[Random().nextInt(Bot.values.length)];
      if (profile.levels.isNotEmpty) {
        profile.levels.first.libraryLevel = Random().nextInt(7);
      } else {
        final item = ProfileLevel.from(LibraryLanguage.en);
        item.libraryLevel = Random().nextInt(7);
        item.displayLevel = Random().nextDouble() * 10;
        profile.levels = profile.levels.addItem(item);
      }
      await profile.save();
      expect(profile.syncStatus, equals(SyncStatus.updated));

      final updatedMap = profile.map;
      updatedMap.addAll(profile.metadataMap);
      updatedMap[partitionKey] = configs['testProfilePartition'];
      updatedMap[updatedKey] = profile.updatedAt?.millisecondsSinceEpoch ??
          (await NetworkTime.shared.now).millisecondsSinceEpoch;
      final serviceRecord =
          await ServiceRecord().findBy(profile.id, profile.tableName);
      expect(serviceRecord, isNotNull);

      final operations = [];
      final fields = serviceRecord!.updatedFields.toSet();
      fields.add(updatedKey);
      for (final field in fields) {
        operations.add({
          'op': 'set',
          'path': '/$field',
          'value': updatedMap[field],
        });
      }

      await syncHelper.partialUpdateDocument(
          'Profile',
          resourceToken,
          configs['testProfilePartition'],
          {'operations': operations},
          updatedMap);

      // read from cosmos again
      record = await syncHelper.getCosmosDocument(
          'Profile',
          configs['testProfileId'],
          resourceToken,
          configs['testProfilePartition']);
      expect(record['id'], equals(configs['testProfileId']));
      expect(record['bot'], profile.bot.name);
      await profile.setMap(record);
      profile.syncStatus = SyncStatus.synced;
      await profile.save(syncToService: false, initialize: false);
      Map libraryLevels = record['libraryLevels'];
      // expect updated properties
      expect(libraryLevels[LibraryLanguage.en.name],
          profile.levels.first.libraryLevel);
      expect(profile.id, equals(record['id']));
      expect(
          ListEquality().equals(profile.completedBooks,
              List<String>.from(record['completedBooks'])),
          true);
      expect(
          ListEquality().equals(
              profile.classesIds, List<String>.from(record['classesIds'])),
          true);
    });

    test('test create event', () async {
      final resourceToken = await syncHelper.getResourceToken('Event');
      final event = Event();
      event.type = 'bookRating';
      // send event data by list
      event.eventData.add(EventData.from('rating', '5'));
      event.eventData.add(EventData.from('bookId', configs['testBookId']));
      await event.save();
      print('Create new event ${event.id}');

      // create on cosmos
      final createdMap = event.map;
      createdMap.addAll(event.metadataMap);
      createdMap[partitionKey] = configs['testDefaultPartition'];
      final createdRecord = await syncHelper.createDocument(
          'Event', resourceToken, configs['testDefaultPartition'], createdMap);
      expect(createdRecord, isNotNull);
      expect(event.id, isNotNull);
      final eventId = event.id!;

      // read from cosmos again
      var record = await syncHelper.getCosmosDocument(
          'Event', eventId, resourceToken, configs['testDefaultPartition']);
      expect(record['id'], equals(eventId));
      // check event data with json map
      expect(record['eventData']['bookId'], equals(configs['testBookId']));
      expect(record['eventData']['rating'], equals('5'));
    });
  });

  group('Sync2', () {
    test('test memory update', () async {
      // create record
      final progress = Progress();
      progress.profileId = configs['testProfileId'];
      progress.bookId = configs['testBookId'];
      progress.accuracy = 0.95;
      progress.fluency = 0.9;
      progress.readingTime = 40;
      progress.completedAt = DateTime.now().millisecondsSinceEpoch;
      progress.correctWords = [
        ProgressCorrectWords.from('test1', true),
        ProgressCorrectWords.from('test2', true),
      ];
      progress.incorrectWords = [
        ProgressCorrectWords.from('test3', true),
        ProgressCorrectWords.from('test4', true),
      ];
      await progress.init();
      progress.partition = configs['testProfilePartition'];
      await progress.save();
      print('create new progress ${progress.id} $progress');

      // sync to cosmos
      final resourceToken = await syncHelper.getResourceToken('Progress');
      await syncHelper.createRecord(
          'Progress', progress, configs['testProfilePartition'],
          resourceToken: resourceToken);

      // save record to updated state
      progress.readingTime = 20;
      progress.syncStatus = SyncStatus.synced;
      await progress.save();
      expect(progress.syncStatus, equals(SyncStatus.updated));

      // update record in memory
      progress.readingTime = 30;
      progress.fluency = 0.2;

      // sync to cosmos again
      final updateResponse = await syncHelper.updateRecord(
          'Progress', progress, configs['testProfilePartition'],
          resourceToken: resourceToken);
      // and validate result
      expect(progress.readingTime != updateResponse['readingTime'], true);
      expect(progress.fluency != updateResponse['fluency'], true);
    });
  });
  tearDownAll(() {
    print('tearDown');
    Sync.shared.db.close(deleteFromDisk: true);
  });
}

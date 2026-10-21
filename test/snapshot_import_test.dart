import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sync_db/sync_db.dart';
import 'package:universal_io/io.dart';

import 'models/event.dart';
import 'models/profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory testDirectory;
  final bundledAssets = <String, Uint8List>{};

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    testDirectory = await Directory.systemTemp.createTemp('snapshot_import_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => testDirectory.path,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
      if (message == null) {
        return null;
      }
      final name = utf8.decode(message.buffer.asUint8List(
        message.offsetInBytes,
        message.lengthInBytes,
      ));
      final bytes = bundledAssets[name];
      return bytes == null ? null : ByteData.sublistView(bytes);
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider_macos'),
      (call) async => testDirectory.path,
    );

    await Isar.initializeIsarCore(download: true);
    await Sync.shared.db.init({
      ProfileSchema: Profile.new,
      EventSchema: Event.new,
    });
  });

  setUp(() async {
    final db = Sync.shared.db.local;
    await db.writeTxn(() async {
      await db.profiles.clear();
      await db.events.clear();
      await db.servicePoints.clear();
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(IsarDatabase.appVersionKey);
    bundledAssets.clear();
  });

  tearDownAll(() async {
    Sync.shared.db.close(deleteFromDisk: true);
    if (await testDirectory.exists()) {
      await testDirectory.delete(recursive: true);
    }
  });

  test('replaces rows and removes every service point for the table', () async {
    final snapshot = await _profileSnapshot('snapshot', 'From snapshot');
    await _saveProfile('old-local', 'Old local row');
    await _saveEvent('local-event');
    await _saveServicePoint('profile-a', 'Profile', 'a', 100);
    await _saveServicePoint('profile-b', 'Profile', 'b', 200);
    await _saveServicePoint('event-a', 'Event', 'a', 300);

    await Sync.shared.db.importJsonSnapshotTable(
      snapshot,
      'Profile',
      invalidateSyncState: true,
    );

    final profiles = await Sync.shared.db.local.profiles.where().findAll();
    expect(profiles.map((profile) => profile.id), ['snapshot']);
    expect(profiles.single.name, 'From snapshot');
    expect(await ServicePoint.listByName('Profile'), isEmpty);

    final unrelatedPoints = await ServicePoint.listByName('Event');
    expect(unrelatedPoints, hasLength(1));
    expect(unrelatedPoints.single.from, 300);
    expect(await Sync.shared.db.local.events.where().count(), 1,
        reason: 'snapshot replacement must not touch another table');
  });

  test('a snapshot imported in many chunks keeps every row', () async {
    for (var i = 0; i < 60; i++) {
      await _saveProfile('p$i', 'Name, with [brackets] and "quotes" $i');
    }
    final snapshot = await _exportProfiles();
    await Sync.shared.db.local
        .writeTxn(() => Sync.shared.db.local.profiles.clear());
    await _saveProfile('old-local', 'Old local row');

    await Sync.shared.db.importJsonSnapshotTable(snapshot, 'Profile',
        chunkBytes: 300);

    final profiles = await Sync.shared.db.local.profiles.where().findAll();
    expect(profiles.map((p) => p.id).toSet(),
        {for (var i = 0; i < 60; i++) 'p$i'});
    expect(profiles.firstWhere((p) => p.id == 'p7').name,
        'Name, with [brackets] and "quotes" 7');
  });

  test('a table shipped in parts is imported from all of them', () async {
    for (var i = 0; i < 4; i++) {
      await _saveProfile('p$i', 'Name $i');
    }
    final all = jsonDecode(utf8.decode(await _exportProfiles())) as List;
    await Sync.shared.db.local
        .writeTxn(() => Sync.shared.db.local.profiles.clear());
    await _saveProfile('old-local', 'Old local row');
    bundledAssets['test_assets/Profile.001.json'] =
        Uint8List.fromList(utf8.encode(jsonEncode(all.sublist(0, 2))));
    bundledAssets['test_assets/Profile.002.json'] =
        Uint8List.fromList(utf8.encode(jsonEncode(all.sublist(2))));

    await Sync.shared.db.init(
      {ProfileSchema: Profile.new, EventSchema: Event.new},
      dbAssetPath: 'test_assets/',
      version: 'snapshot-test-parts',
      // Out of order on purpose: parts are imported in name order.
      manifest: const [
        'test_assets/Profile.002.json',
        'test_assets/Profile.001.json'
      ],
    );

    final profiles = await Sync.shared.db.local.profiles.where().findAll();
    expect(profiles.map((p) => p.id).toSet(), {'p0', 'p1', 'p2', 'p3'});
  });

  test('a broken part keeps the old rows: every part is checked first',
      () async {
    await _saveProfile('old-local', 'Old local row');
    final good = await _profileSnapshot('snapshot', 'From snapshot');
    await _saveProfile('old-local', 'Old local row');

    await expectLater(
      Sync.shared.db.importJsonSnapshotTableParts('Profile', [
        () async => good,
        () async => Uint8List.fromList(utf8.encode('[{"id": "x"')),
      ]),
      throwsFormatException,
    );

    final profiles = await Sync.shared.db.local.profiles.where().findAll();
    expect(profiles.map((p) => p.id), ['old-local']);
  });

  group('splitJsonArray', () {
    List<Object?> decodeAll(List<Uint8List> chunks) => [
          for (final chunk in chunks) ...(jsonDecode(utf8.decode(chunk)) as List)
        ];
    Uint8List bytes(String s) => Uint8List.fromList(utf8.encode(s));

    test('keeps every element, whatever is inside the strings', () {
      final elements = [
        for (var i = 0; i < 40; i++)
          {'id': '$i', 'text': 'a,b]c}{"[\\ ${'x' * i}', 'n': i, 'l': [1, 2]}
      ];
      final source = jsonEncode(elements);
      final chunks = IsarDatabase.splitJsonArray(bytes(source), 120);
      expect(chunks.length, greaterThan(5));
      expect(decodeAll(chunks), elements);
    });

    test('handles whitespace, primitives, one huge element and empty arrays',
        () {
      expect(
          decodeAll(IsarDatabase.splitJsonArray(
              bytes(' \n[ 1 , "two" ,null, {"a": [3]} ]\n'), 2)),
          [1, 'two', null, {'a': [3]}]);
      final huge = {'id': 'x' * 1000};
      expect(decodeAll(IsarDatabase.splitJsonArray(bytes(jsonEncode([huge, huge])), 10)),
          [huge, huge]);
      expect(IsarDatabase.splitJsonArray(bytes('[]'), 10), isEmpty);
    });

    test('rejects input that is not one complete array', () {
      for (final bad in [
        '',
        '{"a": 1}',
        '[{"a": 1}',
        '[{"a": "1}]',
        '[1]]',
        '[1] [2]',
        '[1,,2]',
      ]) {
        expect(() => IsarDatabase.splitJsonArray(bytes(bad), 10),
            throwsFormatException,
            reason: bad);
      }
      expect(
          () => IsarDatabase.splitJsonArray(
              Uint8List.fromList(const [0, 1, 2, 3]), 10),
          throwsFormatException);
    });
  });

  test('keeps service points when invalidation is not requested', () async {
    final snapshot = await _profileSnapshot('snapshot', 'From snapshot');
    await _saveProfile('old-local', 'Old local row');
    await _saveServicePoint('profile-a', 'Profile', 'a', 100);

    await Sync.shared.db.importJsonSnapshotTable(snapshot, 'Profile');

    final points = await ServicePoint.listByName('Profile');
    expect(points, hasLength(1));
    expect(points.single.from, 100);
  });

  test('empty replacement still invalidates the table service points',
      () async {
    final emptySnapshot = await _emptyProfileSnapshot();
    await _saveProfile('old-local', 'Old local row');
    await _saveServicePoint('profile-a', 'Profile', 'a', 100);

    await Sync.shared.db.importJsonSnapshotTable(
      emptySnapshot,
      'Profile',
      invalidateSyncState: true,
    );

    expect(await Sync.shared.db.local.profiles.where().count(), 0);
    expect(await ServicePoint.listByName('Profile'), isEmpty);
  });

  test('invalidation is safe when the table has no service point', () async {
    final snapshot = await _profileSnapshot('snapshot', 'From snapshot');

    await Sync.shared.db.importJsonSnapshotTable(
      snapshot,
      'Profile',
      invalidateSyncState: true,
    );

    expect(await Sync.shared.db.local.profiles.where().count(), 1);
    expect(await ServicePoint.listByName('Profile'), isEmpty);
  });

  test('failed import preserves both existing rows and service points',
      () async {
    await _saveProfile('old-local', 'Old local row');
    await _saveServicePoint('profile-a', 'Profile', 'a', 100);

    await expectLater(
      Sync.shared.db.importJsonSnapshotTable(
        Uint8List.fromList(const [0, 1, 2, 3]),
        'Profile',
        invalidateSyncState: true,
      ),
      throwsA(anything),
    );

    final profiles = await Sync.shared.db.local.profiles.where().findAll();
    expect(profiles.map((profile) => profile.id), ['old-local']);
    final points = await ServicePoint.listByName('Profile');
    expect(points, hasLength(1));
    expect(points.single.from, 100);
  });

  test('versioned init invalidates only configured snapshot tables', () async {
    const profileAsset = 'test_assets/Profile.json';
    const eventAsset = 'test_assets/Event.json';
    bundledAssets[profileAsset] =
        await _profileSnapshot('snapshot-profile', 'From snapshot');
    bundledAssets[eventAsset] = await _eventSnapshot('snapshot-event');
    await _saveProfile('old-profile', 'Old local row');
    await _saveEvent('old-event');
    await _saveServicePoint('profile-a', 'Profile', 'a', 100);
    await _saveServicePoint('event-a', 'Event', 'a', 200);

    await Sync.shared.db.init(
      {
        ProfileSchema: Profile.new,
        EventSchema: Event.new,
      },
      dbAssetPath: 'test_assets/',
      version: 'snapshot-test-v1',
      manifest: const [profileAsset, eventAsset],
      invalidateSyncStateForTables: const {'Profile'},
    );

    expect(
      (await Sync.shared.db.local.profiles.where().findAll())
          .map((profile) => profile.id),
      ['snapshot-profile'],
    );
    expect(
      (await Sync.shared.db.local.events.where().findAll())
          .map((event) => event.id),
      ['snapshot-event'],
    );
    expect(await ServicePoint.listByName('Profile'), isEmpty);
    final eventPoints = await ServicePoint.listByName('Event');
    expect(eventPoints, hasLength(1));
    expect(eventPoints.single.from, 200);

    // The same app version must not replace the table or invalidate a new
    // cursor again.
    await _saveProfile('created-after-import', 'Keep me');
    await _saveServicePoint('profile-new', 'Profile', 'new', 300);
    await Sync.shared.db.init(
      {
        ProfileSchema: Profile.new,
        EventSchema: Event.new,
      },
      dbAssetPath: 'test_assets/',
      version: 'snapshot-test-v1',
      manifest: const [profileAsset, eventAsset],
      invalidateSyncStateForTables: const {'Profile'},
    );

    expect(await Sync.shared.db.local.profiles.where().count(), 2);
    final newProfilePoints = await ServicePoint.listByName('Profile');
    expect(newProfilePoints, hasLength(1));
    expect(newProfilePoints.single.from, 300);
  });

  test('failed versioned migration is retried with the same version', () async {
    const profileAsset = 'test_assets/Profile.json';
    const eventAsset = 'test_assets/Event.json';
    bundledAssets[profileAsset] =
        await _profileSnapshot('snapshot-profile', 'From snapshot');
    // Built while the table is empty, so the export holds only this row
    // whatever the old rows below do in the meantime.
    final eventSnapshot = await _eventSnapshot('snapshot-event');
    bundledAssets[eventAsset] = Uint8List.fromList(const [0, 1, 2, 3]);
    await _saveProfile('old-profile', 'Old local row');
    await _saveEvent('old-event');
    await _saveServicePoint('profile-a', 'Profile', 'a', 100);
    await _saveServicePoint('event-a', 'Event', 'a', 200);

    Future<void> migrate() => Sync.shared.db.init(
          {
            ProfileSchema: Profile.new,
            EventSchema: Event.new,
          },
          dbAssetPath: 'test_assets/',
          version: 'snapshot-test-retry',
          manifest: const [profileAsset, eventAsset],
          invalidateSyncStateForTables: const {'Profile', 'Event'},
        );

    await expectLater(migrate(), throwsA(anything));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(IsarDatabase.appVersionKey),
        isNot('snapshot-test-retry'));
    expect(await ServicePoint.listByName('Event'), hasLength(1),
        reason: 'the failed table import and its invalidation must roll back');

    bundledAssets[eventAsset] = eventSnapshot;
    await migrate();

    expect(prefs.getString(IsarDatabase.appVersionKey), 'snapshot-test-retry');
    expect(await ServicePoint.listByName('Profile'), isEmpty);
    expect(await ServicePoint.listByName('Event'), isEmpty);
    expect(await Sync.shared.db.local.profiles.where().count(), 1);
    expect(await Sync.shared.db.local.events.where().count(), 1);
  });
}

Future<Uint8List> _profileSnapshot(String id, String name) async {
  await _saveProfile(id, name);
  final bytes = await _exportProfiles();
  await Sync.shared.db.local.writeTxn(
    () => Sync.shared.db.local.profiles.clear(),
  );
  return bytes;
}

Future<Uint8List> _emptyProfileSnapshot() async {
  await Sync.shared.db.local.writeTxn(
    () => Sync.shared.db.local.profiles.clear(),
  );
  return _exportProfiles();
}

Future<Uint8List> _eventSnapshot(String id) async {
  await _saveEvent(id);
  Uint8List? result;
  await Event().exportJson(
    callback: (bytes) => result = Uint8List.fromList(bytes),
  );
  await Sync.shared.db.local.writeTxn(
    () => Sync.shared.db.local.events.clear(),
  );
  return result!;
}

Future<Uint8List> _exportProfiles() async {
  Uint8List? result;
  await Profile().exportJson(
    callback: (bytes) => result = Uint8List.fromList(bytes),
  );
  return result!;
}

Future<void> _saveProfile(String id, String name) async {
  final profile = Profile()
    ..id = id
    ..name = name;
  await profile.save(syncToService: false);
}

Future<void> _saveEvent(String id) async {
  final event = Event()..id = id;
  await event.save(syncToService: false);
}

Future<void> _saveServicePoint(
  String id,
  String table,
  String partition,
  int cursor,
) async {
  final point = ServicePoint(name: table)
    ..id = id
    ..partition = partition
    ..token = 'token-$partition'
    ..from = cursor;
  await point.save(syncToService: false);
}

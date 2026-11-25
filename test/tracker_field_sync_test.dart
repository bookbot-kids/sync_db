import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:robust_http/exceptions.dart';
import 'package:robust_http/robust_http.dart';
import 'package:sync_db/sync_db.dart';

import 'models/profile.dart';

/// Regression cover for counters that were saved on the device and then lost
/// (an app's reward tracker reset to 0 while the rest of the Profile synced).

class _Session extends Fake implements UserSession {
  _Session(this.point);
  final ServicePoint point;
  @override
  Future<List<ServicePoint>> servicePointsForTable(String table) async =>
      [point];
}

/// Cosmos as far as one partition's documents are concerned.
class _Cosmos extends Fake implements HTTP {
  final documents = <String, Map<String, dynamic>>{};
  final requests = <String>[];

  /// When set, the next PATCH waits for it before applying.
  Future<void>? holdNextPatch;

  @override
  Map<String, dynamic> headers = {};

  @override
  Future<dynamic> post(String url,
      {Map<String, dynamic> parameters = const {},
      dynamic data,
      bool isMultipart = false,
      bool includeHttpResponse = false}) async {
    final record = Map<String, dynamic>.from(data as Map);
    final id = record['id'] as String;
    if (documents.containsKey(id)) {
      requests.add('POST 409');
      throw UnexpectedResponseException(url, 409, 'Conflict');
    }
    requests.add('POST');
    documents[id] = record;
    return Map<String, dynamic>.from(record);
  }

  @override
  Future<dynamic> put(String url,
      {Map<String, dynamic> parameters = const {},
      dynamic data,
      bool isMultipart = false,
      bool includeHttpResponse = false}) async {
    final record = Map<String, dynamic>.from(data as Map);
    requests.add('PUT');
    documents[record['id'] as String] = record;
    return Map<String, dynamic>.from(record);
  }

  @override
  Future<dynamic> patch(String url,
      {Map<String, dynamic> parameters = const {},
      dynamic data,
      bool isMultipart = false,
      bool includeHttpResponse = false}) async {
    final document = documents[url.split('/').last]!;
    final operations = (data as Map)['operations'] as List;
    final hold = holdNextPatch;
    if (hold != null) {
      holdNextPatch = null;
      await hold;
    }
    requests.add(
        'PATCH ${operations.map((o) => (o['path'] as String).substring(1)).join(',')}');
    for (final operation in operations) {
      document[(operation['path'] as String).substring(1)] = operation['value'];
    }
    return Map<String, dynamic>.from(document);
  }
}

class _CosmosService extends CosmosService {
  _CosmosService(HTTP http)
      : super({
          'cosmosDatabaseAccount': 'unused',
          'cosmosDatabaseId': 'unused',
        }, http: http);
  @override
  Future<bool> connectivity() async => true;
}

/// The test binding blocks the network, so use the IsarCore binary shipped in
/// isar_community_flutter_libs on macOS, and download it elsewhere.
Future<void> _initializeIsarCore() async {
  final config = File('.dart_tool/package_config.json');
  if (Platform.isMacOS && config.existsSync()) {
    final packages = (jsonDecode(config.readAsStringSync())['packages'] as List)
        .cast<Map<String, dynamic>>();
    final libs = packages.firstWhere(
        (p) => p['name'] == 'isar_community_flutter_libs',
        orElse: () => {});
    final root = libs['rootUri'] as String?;
    if (root != null) {
      final base =
          config.absolute.uri.resolve(root.endsWith('/') ? root : '$root/');
      final dylib = base.resolve('macos/libisar.dylib').toFilePath();
      if (File(dylib).existsSync()) {
        await Isar.initializeIsarCore(
            libraries: {Abi.macosArm64: dylib, Abi.macosX64: dylib});
        return;
      }
    }
  }
  await Isar.initializeIsarCore(download: true);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late ServicePoint point;
  late _Cosmos cosmos;
  late _CosmosService service;
  const account = 'family-a';

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('tracker_field_sync_');
    for (final channel in [
      'plugins.flutter.io/path_provider',
      'plugins.flutter.io/path_provider_macos'
    ]) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              MethodChannel(channel), (_) async => directory.path);
    }
    await _initializeIsarCore();
    await Sync.shared.db.init({
      ProfileSchema: () => Profile(),
      ServiceRecordSchema: () => ServiceRecord(),
    });
  });

  setUp(() async {
    await Sync.shared.db.local
        .writeTxn(() async => Sync.shared.db.local.clear());
    point = ServicePoint(name: 'Profile', access: Access.all)
      ..id = 'Profile'
      ..partition = account
      ..token = 'test-token';
    await point.save(syncToService: false);
    cosmos = _Cosmos();
    service = _CosmosService(cosmos);
    Sync.shared.service = service;
    Sync.shared.userSession = _Session(point);
  });

  tearDownAll(() async {
    Sync.shared.service = null;
    Sync.shared.userSession = null;
    Sync.shared.db.close(deleteFromDisk: true);
    await directory.delete(recursive: true);
  });

  /// Distinct `updatedAt` values between saves.
  Future<void> tick() => Future.delayed(const Duration(milliseconds: 5));

  Future<Profile> createSynced() async {
    final profile = Profile()
      ..name = 'child'
      ..partition = account;
    await profile.save();
    await service.writeTable('Profile');
    return profile;
  }

  Future<Profile> stored(String? id) async => (await Profile().find(id))!;

  void earnCounters(Profile profile) {
    profile.trackerWords += 3;
    profile.trackerBooksRead += 1;
    profile.stickerBooksRead += 1;
  }

  void expectCountersOnServer(String? id) {
    final server = cosmos.documents[id]!;
    expect(server['trackerWords'], 3);
    expect(server['trackerBooksRead'], 1);
    expect(server['stickerBooksRead'], 1);
  }

  test('the object passed to the first save becomes an update once synced',
      () async {
    final profile = await createSynced();
    expect((await stored(profile.id)).syncStatus, SyncStatus.synced);

    await tick();
    earnCounters(profile);
    await profile.save();

    expect(profile.syncStatus, SyncStatus.updated);
    expect((await ServiceRecord().findBy(profile.id, 'Profile'))!.updatedFields,
        containsAll(['trackerWords', 'trackerBooksRead', 'stickerBooksRead']));

    await service.writeTable('Profile');
    // A partial update, not a second create followed by a whole-document PUT.
    expect(cosmos.requests.where((r) => r.startsWith('POST')), ['POST']);
    expect(cosmos.requests, isNot(contains('PUT')));
    expectCountersOnServer(profile.id);
  });

  test('a record not yet created stays created', () async {
    final profile = Profile()
      ..name = 'child'
      ..partition = account;
    await profile.save();
    await tick();
    profile.name = 'renamed';
    await profile.save();

    expect(profile.syncStatus, SyncStatus.created);
    await service.writeTable('Profile');
    expect(cosmos.requests, ['POST']);
    expect(cosmos.documents[profile.id]!['name'], 'renamed');
  });

  test('a pull fetched before a save does not overwrite it', () async {
    final profile = Profile()
      ..name = 'child'
      ..partition = account;
    await profile.save();
    await service.writeTable('Profile');
    // The object still says `created` in memory, as it did before the fix
    // when an app kept it as its current record.
    profile.syncStatus = SyncStatus.created;

    await tick();
    final fetched = Map<String, dynamic>.of(cosmos.documents[profile.id]!);
    earnCounters(profile);
    await profile.save();
    await service.saveLocalRecords(point, [fetched]);

    expect((await stored(profile.id)).trackerWords, 3);
    await service.writeTable('Profile');
    expectCountersOnServer(profile.id);
  });

  test('a pull still applies a newer server copy over a synced record',
      () async {
    final profile = await createSynced();
    await tick();
    final newer = Map<String, dynamic>.of(cosmos.documents[profile.id]!)
      ..['name'] = 'from another device'
      ..['updatedAt'] = DateTime.now().millisecondsSinceEpoch + 1000;
    await service.saveLocalRecords(point, [newer]);

    expect((await stored(profile.id)).name, 'from another device');
  });

  test('a pull keeps a pending change newer than the server copy', () async {
    final profile = await createSynced();
    final fetched = Map<String, dynamic>.of(cosmos.documents[profile.id]!);
    await tick();
    final current = await stored(profile.id);
    earnCounters(current);
    await current.save();

    await service.saveLocalRecords(point, [fetched]);
    expect((await stored(profile.id)).trackerWords, 3);
  });

  test('a server copy without updatedAt does not throw or overwrite', () async {
    final profile = await createSynced();
    await tick();
    final current = await stored(profile.id);
    earnCounters(current);
    await current.save();

    final legacy = Map<String, dynamic>.of(cosmos.documents[profile.id]!)
      ..remove('updatedAt');
    await service.saveLocalRecords(point, [legacy]);
    expect((await stored(profile.id)).trackerWords, 3);
  });

  test('fields saved during an in-flight partial update are still sent',
      () async {
    final created = await createSynced();
    final profile = await stored(created.id);

    // A first change and its partial update, held on the way.
    await tick();
    profile.favourites = ['book-a'];
    await profile.save();
    final release = Completer<void>();
    cosmos.holdNextPatch = release.future;
    final firstWrite = service.writeTable('Profile');
    await tick();

    // Counters saved while that request is in flight.
    earnCounters(profile);
    await profile.save();

    release.complete();
    await firstWrite;
    // The record changed after what was sent, so the log stays whole and
    // the next write sends it again (resending favourites is harmless).
    expect((await ServiceRecord().findBy(profile.id, 'Profile'))!.updatedFields,
        containsAll(['trackerWords', 'trackerBooksRead', 'stickerBooksRead']));

    // A different change saved before the next write.
    await tick();
    final copy = await stored(profile.id);
    copy.name = 'renamed';
    await copy.save();
    await service.writeTable('Profile');

    expectCountersOnServer(profile.id);
    expect(cosmos.documents[profile.id]!['favourites'], ['book-a']);
    expect(cosmos.documents[profile.id]!['name'], 'renamed');
    expect(await ServiceRecord().findBy(profile.id, 'Profile'), isNull);
  });

  test('a field saved again during its own partial update is sent again',
      () async {
    final created = await createSynced();
    final profile = await stored(created.id);

    await tick();
    profile.trackerWords = 3;
    await profile.save();
    final release = Completer<void>();
    cosmos.holdNextPatch = release.future;
    final firstWrite = service.writeTable('Profile');
    await tick();

    // The same field and another one change while the request is in flight.
    profile.trackerWords = 6;
    profile.favourites = ['book-a'];
    await profile.save();

    release.complete();
    await firstWrite;
    expect(cosmos.documents[profile.id]!['trackerWords'], 3);

    await service.writeTable('Profile');
    expect(cosmos.documents[profile.id]!['trackerWords'], 6);
    expect(cosmos.documents[profile.id]!['favourites'], ['book-a']);
    expect((await stored(profile.id)).syncStatus, SyncStatus.synced);
  });

  test('a pull repairs a create whose response was lost', () async {
    final profile = Profile()
      ..name = 'child'
      ..partition = account;
    await profile.save();
    // The create reached the server, but the app never heard back.
    final row = await stored(profile.id);
    cosmos.documents[profile.id!] = Map<String, dynamic>.from(row.map)
      ..addAll(Map<String, dynamic>.from(row.metadataMap))
      ..['updatedAt'] = row.updatedAt!.millisecondsSinceEpoch
      ..['partition'] = account;
    expect(row.syncStatus, SyncStatus.created);

    await service
        .saveLocalRecords(point, [Map.of(cosmos.documents[profile.id]!)]);

    expect((await stored(profile.id)).syncStatus, SyncStatus.synced);
    await service.writeTable('Profile');
    expect(cosmos.requests, isEmpty);
  });

  test('fields sent with nothing saved meanwhile are cleared', () async {
    final created = await createSynced();
    final profile = await stored(created.id);
    await tick();
    profile.favourites = ['book-a'];
    await profile.save();
    await service.writeTable('Profile');

    expect(await ServiceRecord().findBy(profile.id, 'Profile'), isNull);
    expect(cosmos.requests.last, 'PATCH favourites,updatedAt');
  });
}

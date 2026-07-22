import 'package:flutter_test/flutter_test.dart';
import 'package:sync_db/sync_db.dart';

import 'models/profile.dart';

void main() {
  late CosmosService service;

  setUp(() {
    service = CosmosService({
      'cosmosDatabaseAccount': 'test',
      'cosmosDatabaseId': 'test',
      'tablesRequireIdPartition': ['Profile'],
    });
  });

  test('required id partition is assigned from the record id', () {
    final record = Profile()
      ..id = 'user-a'
      ..partition = null;

    expect(service.preparePartitionForWrite(record), isTrue);
    expect(record.partition, 'user-a');
  });

  test('mismatched required id partition is rejected', () {
    final record = Profile()
      ..id = 'user-a'
      ..partition = 'user-b';

    expect(service.preparePartitionForWrite(record), isFalse);
    expect(record.partition, 'user-b');
  });

  test('service point snapshot is not changed by account transition', () {
    final original = ServicePoint(name: 'User', access: Access.all)
      ..id = 'User'
      ..partition = 'user-a'
      ..token = 'token-a';
    final snapshot = service.snapshotServicePoint(original);

    original.partition = 'user-b';
    original.token = 'token-b';

    expect(snapshot.partition, 'user-a');
    expect(snapshot.token, 'token-a');
  });
}

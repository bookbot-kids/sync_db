import 'package:sync_db/sync_db.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HTTP: ', () {
    setUp(() {
      HTTP.baseUrl = 'https://httpstat.us/';
      HTTP.connectTimeout = 3000;
      HTTP.receiveTimeout = 3000;
    });
  
    test('Test full url', () async {
      expect((await HTTP.get('https://httpstat.us/200')).statusCode, equals(200));
    });

    test('Test path', () async {
      expect((await HTTP.get('200')).statusCode, equals(200));
    });

    test('Test bad response gets exception', () async {
      expect(HTTP.get('500'), throwsException);
    });

    test('Test timeout', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      expect(HTTP.get('https://httpstat.us/200?sleep=5000'), throwsException);
    });
  });
}

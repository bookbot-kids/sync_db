import 'dart:convert';

import 'package:sync_db/sync_db.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter/services.dart';
import 'package:universal_io/io.dart';

class Test extends Model {
  static Database database;
  String test = "Barf";

  Map<String, dynamic> export() {
    return {
      "id": id,
      "createdAt": createdAt,
      "updatedAt": updatedAt,
      "test": test
    };
  }

  void import(Map<String, dynamic> map) {
    id = map["id"];
    createdAt = map["createdAt"];
    updatedAt = map["updatedAt"];
    test = map["test"];
  }

  Future<void> save() async {
    await Test.database.save(this);
  }

  static Future<List<Test>> all() async {
    var all = await Test.database.all("Test", () {
      return Test();
    });

    return List<Test>.from(all);
  }

  static Future<Test> find(String id) async {
    return await Test.database.find("Test", id, Test());
  }

  static Query where(dynamic condition) {
    return Query("Test").where(condition, Test.database, () {
      return Test();
    });
  }
}

void main() {
  group('HTTP: ', () {
    HTTP http;
    setUp(() {
      http = HTTP('https://httpstat.us/',
          {"connectTimeout": 3000, "receiveTimeout": 3000});
    });

    test('Test full url', () async {
      expect((await http.get('https://httpstat.us/200')), equals(""));
    });

    test('Test path', () async {
      expect((await http.get('200')), equals(""));
    });

    test('Test bad response gets exception', () async {
      expect(http.get('500'), throwsException);
    });

    test('Test timeout', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      expect(http.get('https://httpstat.us/200?sleep=5000'), throwsException);
    });

    test('Test getting resource tokens from refresh token', () async {
      final file = new File('test/test_conf.json');
      final config = jsonDecode(await file.readAsString());

      final user = AzureADB2CUser(config);
      final tokens = await user.resourceTokens();
      print(tokens);
      expect(tokens, isNotNull);
    });

    test('Test model creation', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      const MethodChannel channel =
          MethodChannel('plugins.flutter.io/path_provider');
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        return ".";
      });

      await SembastDatabase.config(null, [Test()]);
      Test.database = SembastDatabase.shared;
      await Test().save();

      print(await Test.all());
      print(await Test.find("85523e33-644f-4ed4-9c85-d8d0ec20fcc0"));
    });
  });
}

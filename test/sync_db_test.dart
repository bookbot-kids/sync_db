import 'dart:convert';

import 'package:sync_db/sync_db.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter/services.dart';
import 'package:universal_io/io.dart';

class Test extends Model {
  String testString = "Test String";

  Map<String, dynamic> get map => $Test(this).map;
  set map(Map<String, dynamic> map) => $Test(this).map = map;
}

extension $Test on Test {
  Map<String, dynamic> get map {
    return {
      "id": id,
      "createdAt": createdAt,
      "updatedAt": updatedAt,
      "deletedAt": deletedAt,
      "testString": testString
    };
  }

  set map(Map<String, dynamic> map) {
    id = map["id"];
    createdAt = map["createdAt"];
    updatedAt = map["updatedAt"];
    deletedAt = map["deletedAt"];
    testString = map["testString"];
  }

  static Future<List<Test>> all() async {
    var all = await Test().database.all("Test", () {
      return Test();
    });

    return List<Test>.from(all);
  }

  static Future<Test> find(String id) async =>
      await Test().database.find("Test", id, Test());

  static Query where(dynamic condition) {
    return Query("Test").where(condition, Test().database, () {
      return Test();
    });
  }
}

void main() {
  group('HTTP: ', () {
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

      Test test = Test();
      await SembastDatabase.config(null, []);
      test.database = SembastDatabase.shared;
      await test.save();

      print(await $Test.all());
      print(await $Test.find("85523e33-644f-4ed4-9c85-d8d0ec20fcc0"));
    });
  });
}

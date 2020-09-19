import 'dart:convert';

import 'package:sync_db/sync_db.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter/services.dart';
import 'package:universal_io/io.dart';

class Category extends Model {
  String image;
  String name;

  @override
  String get tableName => 'Category';

  @override
  Map<String, dynamic> get map => $Category(this).map;

  @override
  Future<void> setMap(Map<String, dynamic> map) async =>
      $Category(this).map = map;
}

extension $Category on Category {
  Map<String, dynamic> get map {
    return {
      'id': id,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'deletedAt': deletedAt,
      'name': name,
      'image': image
    };
  }

  set map(Map<String, dynamic> map) {
    id = map['id'];
    createdAt = map['createdAt'];
    updatedAt = map['updatedAt'];
    deletedAt = map['deletedAt'];
    name = map['name'];
    image = map['image'];
  }

  static Future<Category> find(String id) async =>
      await Category().database.find('Category', id, Category());
}

// class Series extends Model {
//   String name;
// }

enum Layout { fixed, responsive }

extension $Layout on Layout {
  static final layoutString = {
    Layout.fixed: 'fixed',
    Layout.responsive: 'responsive'
  };
  static final layoutEnum = {
    'fixed': Layout.fixed,
    'responsive': Layout.responsive
  };

  String get name => $Layout.layoutString[this];
  static Layout fromString(String value) => $Layout.layoutEnum[value];
}

class Test extends Model {
  Category category2;
  Layout layout = Layout.fixed;
  String testString = 'Test String';

  String categoryId;

  @override
  String get tableName => 'Test';

  @override
  Map<String, dynamic> get map => $Test(this).map;

  @override
  Future<void> setMap(Map<String, dynamic> map) async => $Test(this).map = map;

  @override
  Database get database => SembastDatabase.shared;
}

extension $Test on Test {
  Map<String, dynamic> get map {
    return {
      'id': id,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'deletedAt': deletedAt,
      'testString': testString,
      'layout': layout.name,
      'categoryId': categoryId,
      'category2Id': category2.id
    };
  }

  set map(Map<String, dynamic> map) {
    id = map['id'];
    createdAt = map['createdAt'];
    updatedAt = map['updatedAt'];
    deletedAt = map['deletedAt'];
    testString = map['testString'];
    layout = $Layout.fromString(map['layout']);
    categoryId = map['categoryId'];
    $Category.find(map['category2Id']).then((value) => category2 = value);
  }

  Future<Category> get category async => $Category.find(categoryId);

  static Future<List<Test>> all() async {
    var all = await Test().database.all('Test', () {
      return Test();
    });

    return List<Test>.from(all);
  }

  static Future<Test> find(String id) async =>
      await Test().database.find('Test', id, Test());

  static Query where(dynamic condition) {
    return Query('Test').where(condition, Test().database, () {
      return Test();
    });
  }
}

void main() {
  group('HTTP: ', () {
    test('Test getting resource tokens from refresh token', () async {
      final file = File('test/test_conf.json');
      final config = jsonDecode(await file.readAsString());

      final user = AzureADB2CUserSession(config);
      // final tokens = await user.resourceTokens();
      // print(tokens);
      // expect(tokens, isNotNull);
    });

    test('Test model creation', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      const channel = MethodChannel('plugins.flutter.io/path_provider');
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        return '.';
      });

      var test = Test();
      await SembastDatabase.shared.init([]);
      await test.save();

      print(await $Test.all());
      print(await $Test.find('85523e33-644f-4ed4-9c85-d8d0ec20fcc0'));
    });
  });
}

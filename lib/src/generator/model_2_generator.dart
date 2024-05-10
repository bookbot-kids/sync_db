import 'package:isar/isar.dart';
import 'package:recase/recase.dart';
import 'package:source_gen/source_gen.dart';
import 'package:build/build.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:sync_db/src/generator/model_annotation.dart';

T? cast<T>(x) => x is T ? x : null;

class Model2Generator extends Generator {
  @override
  String generate(LibraryReader library, BuildStep buildStep) {
    final values = <String>{};
    library.allElements.forEach((element) {
      final classElement = cast<ClassElement>(element);
      if (classElement != null && // not null
              !(classElement is EnumElement) && // not enum
              (TypeChecker.fromRuntime(Embedded).hasAnnotationOfExact(element,
                      throwOnUnresolved: false) !=
                  true) // not embeded type
              &&
              (TypeChecker.fromRuntime(ModelIgnore).hasAnnotationOfExact(
                      element,
                      throwOnUnresolved: false) !=
                  true) // not ignore model
          ) {
        var value = generateForClass(classElement, library.element);
        values.add(value);
      }
    });

    return values.join('\n\n');
  }

  String generateForClass(ClassElement element, LibraryElement libElement) {
    final output = <String>[];
    final modelName = element.name;
    var collectionName = modelName.camelCase;
    if (!collectionName.endsWith('s')) {
      collectionName += 's';
    }

    final ignoreDeprepcated = TypeChecker.fromRuntime(ModelLinter)
            .firstAnnotationOfExact(element, throwOnUnresolved: false)
            ?.getField('ignoreDeprepcated')
            ?.toBoolValue() ??
        false;

    var parentType =
        element.supertype?.getDisplayString(withNullability: false);

    String getterMap;
    String setterMap;
    final hasParent = parentType != null && parentType != 'Model';
    if (!hasParent) {
      getterMap = '''
        var map = {};
        map[idKey] = id;
        if (createdAt != null) {
          map[createdKey] = createdAt?.millisecondsSinceEpoch;
        }

        if (updatedAt != null) {
          map[updatedKey] = updatedAt?.millisecondsSinceEpoch;
        }

        if (deletedAt != null) {
          map[deletedKey] = deletedAt?.millisecondsSinceEpoch;
        }
      ''';

      setterMap = '''
        final keys = <String>{};
        id = map[idKey];
        if (map[createdKey] is int) {
          createdAt = DateTime.fromMillisecondsSinceEpoch(map[createdKey]);
        }

        if (map[updatedKey] is int) {
          updatedAt = DateTime.fromMillisecondsSinceEpoch(map[updatedKey]);
        }

        if (map[deletedKey] is int) {
          deletedAt = DateTime.fromMillisecondsSinceEpoch(map[deletedKey]);
        }
      ''';
    } else {
      getterMap = 'var map = \$${parentType}(this).map;';
      setterMap = 'final keys = await \$${parentType}(this).setMap(map);';
    }

    final getterFields = <String>[];
    final setterFields = <String>[];
    final keyFields = <String>[];

    final comparisonFields = <String>[];
    comparisonFields.add('''
if (deletedAt != other.deletedAt) {
      result.add('deletedAt');
}
''');

    // loop through fields
    for (var field in element.fields) {
      final name = field.name;
      final typeName = field.type.element?.displayName ?? '';
      final typeFullName = field.type.getDisplayString(withNullability: true);
      final fieldElement = field.type.element;
      print(
          'Type ${field.type.element} \n, fieldName $name, typeName $typeName');
      // ignore static, private fields or property start with $
      if (field.isStatic || name.startsWith('_') || name.startsWith('\$')) {
        continue;
      }

      // Only generate field that has both getter and setter
      if (element.lookUpGetter(name, libElement) == null ||
          element.lookUpSetter(name, libElement) == null) {
        continue;
      }

      final isNullable = TypeChecker.fromRuntime(ModelNullable)
          .hasAnnotationOfExact(field, throwOnUnresolved: false);

      // add comparison
      final addComparisonCallback = () {
        if (typeName == 'List') {
          comparisonFields.add('''
        if (!DeepCollectionEquality().equals($name, other.$name)) {
          result.add('$name');
        }
        ''');
        } else {
          comparisonFields.add('''
        if ($name != other.$name) {
          result.add('$name');
        }
''');
        }
      };

      if (TypeChecker.fromRuntime(ModelIgnore)
          .hasAnnotationOfExact(field, throwOnUnresolved: false)) {
        final ignoreEqual = TypeChecker.fromRuntime(ModelIgnore)
            .firstAnnotationOfExact(field, throwOnUnresolved: false)
            ?.getField('ignoreEqual')
            ?.toBoolValue();
        if (ignoreEqual != true) {
          addComparisonCallback();
        }

        final ignoreKey = TypeChecker.fromRuntime(ModelIgnore)
            .firstAnnotationOfExact(field, throwOnUnresolved: false)
            ?.getField('ignoreKey')
            ?.toBoolValue();
        if (ignoreKey == false) {
          keyFields.add("result.add('$name');");
        }
        continue;
      }

      addComparisonCallback();

      // enum
      if (fieldElement is EnumElement) {
        final type = field.type.element!.name;
        if (isNullable) {
          getterFields.add(
              "if($name != null) {map['${name}'] = EnumToString.convertToString(${name});}");
        } else {
          getterFields
              .add("map['${name}'] = EnumToString.convertToString(${name});");
        }

        setterFields.add('''
        if(map['${name}'] != null) { 
          final value = EnumToString.fromString(${type}.values, map['${name}']);
          if(value != null) {
            ${name} = value;
          } 
        }
        keys.add('$name');
        ''');
        keyFields.add("result.add('$name');");
      } else if (TypeChecker.fromRuntime(ModelSet).hasAnnotationOfExact(field,
          throwOnUnresolved: false)) //list but treat as set
      {
        final regex = RegExp('<[a-zA-Z0-9]*>');
        final match = regex.firstMatch(typeFullName)?.group(0) ?? '';
        final listType = match.replaceAll('<', '').replaceAll('>', '');
        final isNullableType = listType.contains('?');
        getterFields.add("map['${name}'] = ${name}.toSet().toList();");
        if (listType == 'double') {
          setterFields.add('''
        ${name} = Set<$listType>.from(map['${name}']?.map((e) => e.toDouble()).toList() ?? <$listType>[]).toList();
        keys.add('$name');
        ''');
          keyFields.add("result.add('$name');");
        } else {
          final filter = isNullableType ? '' : '?.whereNotNull()';
          setterFields.add('''
        ${name} = Set<$listType>.from((map['${name}'] as List?)$filter ?? <$listType>[]).toList();
        keys.add('$name');
        ''');
          keyFields.add("result.add('$name');");
        }
      } else if (typeName == 'List') // list
      {
        final regex = RegExp('<[a-zA-Z0-9]*>');
        final match = regex.firstMatch(typeFullName)?.group(0) ?? '';
        final listType = match.replaceAll('<', '').replaceAll('>', '');
        final isNullableType = listType.contains('?');
        getterFields.add("map['${name}'] = ${name};");
        if (listType == 'double') {
          setterFields.add('''
        ${name} = List<$listType>.from(map['${name}']?.map((e) => e.toDouble()).toList() ?? <$listType>[]);
        keys.add('$name');
        ''');
          keyFields.add("result.add('$name');");
        } else {
          final filter = isNullableType ? '' : '?.whereNotNull()';
          setterFields.add('''
        ${name} = List<$listType>.from((map['${name}'] as List?)$filter ?? <$listType>[]);
        keys.add('$name');
        ''');
          keyFields.add("result.add('$name');");
        }
      } else if (typeName == 'double') {
        //double
        getterFields.add("map['${name}'] = ${name};");
        setterFields.add('''
        if(map['${name}'] != null) { ${name} = map['${name}'] is int ? map['${name}'].toDouble(): map['${name}']; }
        keys.add('$name');
        ''');
        keyFields.add("result.add('$name');");
      } else if (typeName == 'int') {
        //double
        getterFields.add("map['${name}'] = ${name};");
        setterFields.add('''
        if(map['${name}'] != null) { ${name} = map['${name}'].toInt(); }
        keys.add('$name');
        ''');
        keyFields.add("result.add('$name');");
      } else if (typeName == 'DateTime') {
        // DateTime
        getterFields.add("map['${name}'] = ${name}?.millisecondsSinceEpoch;");
        setterFields.add('''
        if(map['${name}'] is int) { ${name} = DateTime.fromMillisecondsSinceEpoch(map['$name']); }
        keys.add('$name');
        ''');
        keyFields.add("result.add('$name');");
      } else {
        // the rest types
        getterFields.add("map['${name}'] = ${name};");
        setterFields.add('''
        if(map['${name}'] != null) { ${name} = map['${name}']; }
        keys.add('$name');
        ''');
        keyFields.add("result.add('$name');");
      }
    }

    final getFields = getterFields.join('\n');
    final setFields = setterFields.join('\n');
    var dbMethods = '''
      /// Save record and sync to service
      Future<void> save({bool syncToService = true, bool runInTransaction = true, bool initialize = true}) async {
        final callback = () async {
          if (initialize) {
            await init();
          }

          await saveInternal(() async {
            if (syncToService && syncStatus == SyncStatus.updated) {
              final other = await find(id, filterDeletedAt: false);
              if (other != null) {
                final diff = compare(other);
                if (diff.isNotEmpty) {
                  var recordLog = await ServiceRecord().findBy(id, tableName);
                  recordLog ??= ServiceRecord();
                  recordLog.id = id;
                  recordLog.name = tableName;
                  recordLog.appendFields(diff);
                  await recordLog.save(runInTransaction: false);
                }
              }
            }
            await Sync.shared.db.local.$collectionName.put(this);
          });
        };

        if (runInTransaction) {
          await Sync.shared.db.local.writeTxn(() async {
             await callback();
          });

          if (syncToService) {
            // ignore: unawaited_futures
            sync();
          }
        } else {
            await callback();
            if (syncToService) {
              // ignore: unawaited_futures
              sync();
            }
        }     
      }

      /// Get all records
      static Future<List<$modelName>> all({bool filterDeletedAt = true}) {
          final collection = Sync.shared.db.local.$collectionName;
          return filterDeletedAt
              ? collection.filter().getAll()
              : collection.where().findAll();
      }

      /// Find record by id
      static Future<$modelName?> find(String? id, {bool filterDeletedAt = true}) async {
        final filter = await Sync.shared.db.local.$collectionName.filter().idEqualTo(id);
        return filterDeletedAt? filter.getFirst() : filter.findFirst();
      }

      /// List records by sync status
      static Future<List<$modelName>> queryStatus(SyncStatus status, {bool filterDeletedAt = true}) async {
        final filter = await Sync.shared.db.local.$collectionName.filter().syncStatusEqualTo(status);
        return filterDeletedAt? filter.getAll(): filter.findAll();
      }

      /// delete and sync record
      Future<void> delete({bool syncToService = true}) async {
        deletedAt = await NetworkTime.shared.now;
        await save(syncToService: syncToService);
      }

      /// delete local record without syncing
      Future<void> deleteLocal() async {
        if (id != null) {
          await db.writeTxn(() async {
            await db.$collectionName.delete(localId);
          });
        }
      }

      /// Clear all records and reset the auto increment value
      Future<void> clear() {
        return db.$collectionName.clear();
      }

      Set<String> compare($modelName other) {
        final result = ${hasParent ? '\$${parentType}(this).compare(other);' : '<String>{};'}
        ${comparisonFields.join('\n')}
        final list = <String>[];
        final remap = remapFields();
        for (final item in result) {
          if (remap.containsKey(item)) {
            list.addAll(remap[item]!);
          } else {
            list.add(item);
          }
        }
        return list.toSet();
      }

       /// Export all data into json
      Future<List<Map<String, dynamic>>> exportJson(
        {Function(Uint8List)? callback}) async {
        final where = Sync.shared.db.local.$collectionName.where();
        if (callback != null) {
          await where.exportJsonRaw(callback);
          return [];
        }

        return where.exportJson();
      }

      /// Import json into this collection
      Future<void> importJson(dynamic jsonData) async {
        if (jsonData is Uint8List) {
          await Sync.shared.db.local.$collectionName.importJsonRaw(jsonData);
        } else if (jsonData is List<Map<String, dynamic>>) {
          await Sync.shared.db.local.$collectionName.importJson(jsonData);
        } else {
          throw UnsupportedError('Json type is not supported');
        }
      }
''';

    if (element.isAbstract) {
      dbMethods = '''
      Set<String> compare($modelName other) {
        final result = <String>{};
        ${comparisonFields.join('\n')}
        final list = <String>[];
        final remap = remapFields();
        for (final item in result) {
          if (remap.containsKey(item)) {
            list.addAll(remap[item] ?? []);
          } else {
            list.add(item);
          }
        }
        return list.toSet();
      } 
''';
    }
    // generate texts
    output.add('// $modelName model generator');
    if (ignoreDeprepcated) {
      output.add('// ignore_for_file: deprecated_member_use_from_same_package');
    }

    output.add('''
    extension \$$modelName on $modelName {

      Map get map {
        $getterMap
        $getFields
        return map;
      }

      Future<Set<String>> setMap(Map map) async {
        $setterMap
        $setFields
        return keys;
      }

      Set<String> get keys {
        ${hasParent ? 'final result = \$${parentType}(this).keys;' : 'final result = <String>{};'}        
        ${keyFields.join('\n')}
        return result;
      }

      $dbMethods
    }
      ''');

    if (!element.isAbstract) {
      output.add('''
    extension ${modelName}QAfterFilterCondition on QueryBuilder<$modelName, $modelName, QAfterFilterCondition> {
      Future<List<$modelName>> getAll() async {
        return deletedAtIsNull().findAll();
      }

      Future<$modelName?> getFirst() async {
        return deletedAtIsNull().findFirst();
      }
    }

    extension ${modelName}QFilterCondition on QueryBuilder<$modelName, $modelName, QFilterCondition> {
      Future<List<$modelName>> getAll() async {
        return deletedAtIsNull().findAll();
      }

      Future<$modelName?> getFirst() async {
        return deletedAtIsNull().findFirst();
      }
    }
''');
    }

    return output.join('\n');
  }
}

import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';
import 'package:build/build.dart';

T cast<T>(x) => x is T ? x : null;

class ModelGenerator extends Generator {
  @override
  String generate(LibraryReader library, BuildStep buildStep) {
    final values = <String>{};
    library.allElements.forEach((element) {
      final classElement = cast<ClassElement>(element);
      if (classElement != null && !classElement.isEnum) {
        var value = generateForClass(classElement, library.element);
        values.add(value);
      }
    });

    return values.join('\n\n');
  }

  String generateForClass(ClassElement element, LibraryElement libElement) {
    var getterFields = [];
    var setterFields = [];

    var parentType =
        element.supertype?.getDisplayString(withNullability: false);
    var getterMap;
    var setterMap;
    if (parentType == null || parentType == 'Model') {
      getterMap = '''
        var map = <String, dynamic>{};
        map[idKey] = id;
        if (createdAt != null) {
          map[createdKey] = createdAt.millisecondsSinceEpoch;
        }

        if (updatedAt != null) {
          map[updatedKey] = updatedAt.millisecondsSinceEpoch;
        }

        if (deletedAt != null) {
          map[deletedKey] = deletedAt.millisecondsSinceEpoch;
        }
      ''';

      setterMap = '''
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
      setterMap = 'await \$${parentType}(this).setMap(map);';
    }

    for (var field in element.fields) {
      var name = field.name;
      var type = field.type?.getDisplayString(withNullability: false);

      // ignore static, private fields or property start with $
      if (field.isStatic || name.startsWith('_') || name.startsWith('\$')) {
        continue;
      }

      // Only generate field that has both getter and setter
      if (element.lookUpGetter(name, libElement) == null ||
          element.lookUpSetter(name, libElement) == null) {
        continue;
      }

      ClassElement typeClass = field.type.element;
      // working on enum
      if (typeClass.isEnum) {
        getterFields
            .add("map['${name}'] = EnumToString.convertToString(${name});");
        setterFields.add(
            "if(map['${name}'] != null) { ${name} = EnumToString.fromString(${type}.values, map['${name}']); }");
        continue;
      }

      // working on List object
      if (field.type.isDartCoreList) {
        // find list type
        var regex = RegExp('<[a-zA-Z0-9]*>');
        var match = regex.firstMatch(type);
        if (match != null) {
          var listType = match.group(0).replaceAll('<', '').replaceAll('>', '');
          // custom list type
          if (_isCustomType(listType)) {
            var idsName = '${name}Ids';
            getterFields
                .add("map['$idsName'] = ${name}.map((e) => e.id).toList();");
            setterFields.add(
                "${name} = await \$${listType}.findByIds(map['${idsName}']);");
            continue;
          } else if (['int', 'double', 'String', 'bool', 'num']
              .contains(listType)) {
            getterFields.add("map['${name}'] = ${name};");
            setterFields.add(
                "${name} = List<$listType>.from(map['${name}'] ?? <$listType>[]);");
            continue;
          }
        }
      }

      // working on Set object
      if (field.type.isDartCoreSet) {
        // find set type
        var regex = RegExp('<[a-zA-Z0-9]*>');
        var match = regex.firstMatch(type);
        if (match != null) {
          var setType = match.group(0).replaceAll('<', '').replaceAll('>', '');
          // custom set type
          if (_isCustomType(setType)) {
            var idsName = '${name}Ids';
            getterFields
                .add("map['$idsName'] = ${name}.map((e) => e.id).toList();");
            setterFields.add(
                "${name} = Set<$setType>.from(await \$${setType}.findByIds(map['${idsName}']));");
            continue;
          } else if (['int', 'double', 'String', 'bool', 'num']
              .contains(setType)) {
            getterFields.add("map['${name}'] = ${name};");
            setterFields.add(
                "${name} = Set<$setType>.from(map['${name}'] ?? <$setType>[]);");
            continue;
          }
        }
      }

      if (_isCustomType(type)) {
        var idName = '${name}Id';
        getterFields.add("map['$idName'] = ${name}?.id;");
        setterFields.add(
            "if(map['${idName}'] != null) { ${name} = await \$${type}.find(map['${idName}']); }");
      } else if (type == 'double') {
        getterFields.add("map['${name}'] = ${name};");
        setterFields.add(
            "if(map['${name}'] != null) { ${name} = map['${name}'] is int ? map['${name}'].toDouble(): map['${name}']; }");
      } else {
        getterFields.add("map['${name}'] = ${name};");
        setterFields
            .add("if(map['${name}'] != null) ${name} = map['${name}'];");
      }
    }

    final getFields = getterFields.join('\n');
    final setFields = setterFields.join('\n');

    var modelName = element.name;
    final output = <String>[];
    output.add('// $modelName model generator');
    output.add('''
    extension \$$modelName on $modelName {

      Map<String, dynamic> get map {
        $getterMap
        $getFields
        return map;
      }

      Future<void> setMap(Map<String, dynamic> map) async {
        if (map == null) return;
        $setterMap
        $setFields
      }

      static Future<List<$modelName>> all({bool listenable = false}) async {
        var all = await $modelName().database.all('$modelName', () {
          return $modelName();
        }, listenable: listenable);
        return List<$modelName>.from(all);
      }

      static Future<$modelName> find(String id, {bool listenable = false}) async {
        return id == null ? null : await $modelName().database.find('$modelName', id, $modelName(), listenable: listenable);
      }

      static Future<List<$modelName>> findByIds(List ids, {bool listenable = false}) async {
        if (ids == null || ids.isEmpty) return <$modelName>[];
        final construct = ids.map((id) => 'id = \$id');
        final list = List<$modelName>.from(await where(construct.join(' or ')).load(listenable: listenable));
        final results = <$modelName>[];
        ids.forEach((id) {
          final item =
              list.firstWhere((element) => element?.id == id, orElse: () => null);
          if (item != null) {
            results.add(item);
          }
        });
        return results;
      }

      static Query where(dynamic condition) {
        return Query('$modelName').where(condition, $modelName().database, () {
          return $modelName();
        });
      }
    }
      ''');

    print('output:\n=========\n ${output.join("\n")}\n=========\n');
    return output.join('\n');
  }

  bool _isPrimitiveType(String typeName) {
    return ['int', 'String', 'bool', 'double'].contains(typeName);
  }

  bool _isCustomType(String typeName) {
    if (_isPrimitiveType(typeName)) return false;

    var listType = ['Set', 'List', 'Map', 'Future', 'Object', 'dynamic'];
    for (var type in listType) {
      if (typeName.startsWith(type)) {
        return false;
      }
    }

    return true;
  }
}

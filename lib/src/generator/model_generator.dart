import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';
import 'package:build/build.dart';

class ModelGenerator extends Generator {
  @override
  String generate(LibraryReader library, BuildStep buildStep) {
    final values = <String>{};
    library.allElements.forEach((element) {
      final classElement = element as ClassElement;
      if (!classElement.isEnum) {
        var value = generateForClass(classElement, library.element);
        values.add(value);
      }
    });

    return values.join('\n\n');
  }

  String generateForClass(ClassElement element, LibraryElement libElement) {
    var getterFields = [];
    var setterFields = [];

    for (var field in element.fields) {
      var name = field.name;
      var type = field.type?.getDisplayString(withNullability: false);

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
            "${name} = EnumToString.fromString(${type}.values, map['${name}']);");
        continue;
      }

      // working on List object
      if (field.type.isDartCoreList) {
        // find list type
        var regex = RegExp('<[a-zA-Z0-9]*>');
        var match = regex.firstMatch(type);
        if (match != null) {
          var listType = match.group(0).replaceAll('<', '').replaceAll('>', '');
          // only process for custom list type
          if (_isCustomType(listType)) {
            var idsName = '${name}Ids';
            getterFields
                .add("map['$idsName'] = ${name}.map((e) => e.id).toList();");
            setterFields.add(
                "${name} = await \$${listType}.findByIds(map['${idsName}']);");
            continue;
          }
        }
      }

      if (_isCustomType(type)) {
        var idName = '${name}Id';
        getterFields.add("map['$idName'] = ${name}.id;");
        setterFields.add("${name} = await \$${type}.find(map['${idName}']);");
      } else {
        getterFields.add("map['${name}'] = ${name};");
        setterFields.add("${name} = map['${name}'];");
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

        $getFields
        return map;
      }

      Future<void> setMap(Map<String, dynamic> map) async {
        id = map[idKey];
        if (map[createdKey] is int) {
          createdAt = DateTime.fromMillisecondsSinceEpoch(map[createdKey]);
        }

        if (map[updatedAt] is int) {
          updatedAt = DateTime.fromMillisecondsSinceEpoch(map[updatedAt]);
        }

        if (map[deletedKey] is int) {
          deletedAt = DateTime.fromMillisecondsSinceEpoch(map[deletedKey]);
        }

        $setFields
      }

      static Future<List<$modelName>> all({bool listenable}) async {
        var all = await $modelName().database.all('$modelName', () {
          return $modelName();
        }, listenable: listenable);
        return List<$modelName>.from(all);
      }

      static Future<$modelName> find(String id, {bool listenable}) async {
        return id == null ? null : await $modelName().database.find('$modelName', id, $modelName(), listenable: listenable);
      }

      static Future<List<$modelName>> findByIds(List ids, {bool listenable}) async {
        if (ids == null || ids.isEmpty) return <$modelName>[];
        final construct = ids.map((id) => 'id = \$id');
        return List<$modelName>.from(await where(construct.join(' or ')).load(listenable: listenable));
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

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
      var type = field.type.getDisplayString();

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

    final output = <String>[];
    output.add('// ${element.name} model generator');
    output.add('''
    class \$${element.name} extends ${element.name} {

      @override
      Map<String, dynamic> get map {
        var map = super.map;
        $getFields
        return map;
      }

      @override
      Future<void> setMap(Map<String, dynamic> map) async {
        await super.setMap(map);
        $setFields
      }

      static Future<List<${element.name}>> all() async {
        var all = await ${element.name}().database.all('${element.name}', () {
          return ${element.name}();
        });
        return List<${element.name}>.from(all);
      }

      static Future<${element.name}> find(String id) async {
        return await ${element.name}().database.find('${element.name}', id, ${element.name}());
      }

      static Future<List<${element.name}>> findByIds(List ids) async {
        if (ids == null || ids.isEmpty) return <${element.name}>[];
        final construct = ids.map((id) => 'id = \$id');
        return List<${element.name}>.from(await where(construct.join(' or ')).load());
      }

      static Query where(dynamic condition) {
        return Query('${element.name}').where(condition, ${element.name}().database, () {
          return ${element.name}();
        });
      }

      @override
      String toString() {
        return map.toString();
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

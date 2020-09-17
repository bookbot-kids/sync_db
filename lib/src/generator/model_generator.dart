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
        var value = generateForClass(classElement);
        values.add(value);
      }
    });

    return values.join('\n\n');
  }

  String generateForClass(ClassElement element) {
    final output = <String>[];
    var map = {for (var e in element.fields) e.name: e.type};
    // ignore tableName getter
    map.remove('tableName');
    final getFields = map.keys.map((e) => "map['$e'] = $e;").join('\n');
    final setFields = map.keys.map((e) => "$e = map['$e'];").join('\n');
    output.add('// ${element.name} model generation');
    output.add('''
    class \$${element.name} extends ${element.name} {

      @override
      Map<String, dynamic> get map {
        var map = super.map;
        $getFields
        return map;
      }

      @override
      set map(Map<String, dynamic> map) {
        super.map = map;
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
}

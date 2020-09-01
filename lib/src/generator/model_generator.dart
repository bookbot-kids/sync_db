import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';
import 'package:build/build.dart';

class ModelGenerator extends Generator {
  @override
  String generate(LibraryReader library, BuildStep buildStep) {
    final values = <String>{};
    library.allElements.forEach((element) {
      final classElement = element as ClassElement;
      var value = generateForClass(classElement);
      values.add(value);
    });

    return values.join('\n\n');
  }

  String generateForClass(ClassElement element) {
    final output = <String>[];
    final map = {for (var e in element.fields) e.name: e.type};
    final getFields = map.keys.map((e) => "'$e': $e,").join('\n');
    final setFields = map.keys.map((e) => "$e = map['$e'];").join('\n');
    output.add('// ${element.name} model generation');
    output.add('''
    class \$${element.name} extends ${element.name} {
      @override
      Map<String, dynamic> get map => <String, dynamic>{
        $getFields
      };

      @override
      set map(Map<String, dynamic> map) {
        $setFields
      }

      @override
      String toString() => '${element.name}';
    }
      ''');

    print('output: ${output.join("\n")}');
    return output.join('\n');
  }
}

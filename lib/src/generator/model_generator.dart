import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';
import 'package:build/build.dart';
import 'package:analyzer/dart/element/type.dart';

import 'model_annotation.dart';

T? cast<T>(x) => x is T ? x : null;

class ModelGenerator extends Generator {
  static final primitiveTypes = ['int', 'double', 'String', 'bool', 'num'];
  static final _propertyTypeChecker =
      const TypeChecker.fromRuntime(ModelProperty);

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

      // ignore static, private fields or property start with $
      if (field.isStatic || name.startsWith('_') || name.startsWith('\$')) {
        continue;
      }

      // Only generate field that has both getter and setter
      if (element.lookUpGetter(name, libElement) == null ||
          element.lookUpSetter(name, libElement) == null) {
        continue;
      }

      var type = field.type.element!.displayName;
      var isEnumParam = false;
      String? type2;
      String? type3;
      if (_propertyTypeChecker.hasAnnotationOfExact(field,
          throwOnUnresolved: false)) {
        // final name = _propertyTypeChecker
        //     .firstAnnotationOfExact(field, throwOnUnresolved: false)
        //     .getField('name')
        //     ?.toStringValue();
        type = _propertyTypeChecker
                .firstAnnotationOfExact(field, throwOnUnresolved: false)!
                .getField('type')
                ?.toStringValue() ??
            field.type.element!.displayName;
        isEnumParam = _propertyTypeChecker
                .firstAnnotationOfExact(field, throwOnUnresolved: false)!
                .getField('isEnumParam')
                ?.toBoolValue() ??
            false;

        type2 = _propertyTypeChecker
            .firstAnnotationOfExact(field, throwOnUnresolved: false)!
            .getField('type2')
            ?.toStringValue();
        type3 = _propertyTypeChecker
            .firstAnnotationOfExact(field, throwOnUnresolved: false)!
            .getField('type3')
            ?.toStringValue();
      } else {
        // try to get generic type if property does not have annotation
        final genericTypes = _getGenericTypes(field.type);
        if (genericTypes.isNotEmpty && field.type.isDartCoreList) {
          type = 'List<${genericTypes.first.type}>';
        } else if (genericTypes.isNotEmpty && field.type.isDartCoreSet) {
          type = 'Set<${genericTypes.first.type}>';
        } else if (genericTypes.length > 1 && field.type.isDartCoreMap) {
          type =
              'Map<${genericTypes.elementAt(0).type}, ${genericTypes.elementAt(1).type}>';
        }
      }

      final typeClass = field.type.element as ClassElement;
      // working on enum
      if (typeClass.isEnum) {
        final type = typeClass.displayName;
        getterFields.add(
            "map['${name}'] = ${name} == null ? null : EnumToString.convertToString(${name});");
        setterFields.add(
            "if(map['${name}'] != null) { ${name} = EnumToString.fromString(${type}.values, map['${name}'])!; }");
        continue;
      }

      // working on List object
      if (field.type.isDartCoreList) {
        // find list type
        var regex = RegExp('<[a-zA-Z0-9]*>');
        var match = regex.firstMatch(type);
        if (match != null) {
          var listType =
              match.group(0)!.replaceAll('<', '').replaceAll('>', '');
          // enum list
          if (isEnumParam) {
            getterFields.add(
                "map['${name}'] = EnumToString.toList((${name} ?? []).where((element) => element != null).toList());");
            setterFields.add(
                "${name} = EnumToString.fromList(${listType}.values, (map['${name}'] ?? []).where((element) => element != null).toList()).toList();");
            continue;
          } else if (_isCustomType(listType)) {
            // custom list type
            var idsName = '${name}Ids';
            getterFields
                .add("map['$idsName'] = ${name}.map((e) => e.id).toList();");
            setterFields.add(
                "${name} = await \$${listType}.findByIds(map['${idsName}']);");
            continue;
          } else if (primitiveTypes.contains(listType)) {
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
          var setType = match.group(0)!.replaceAll('<', '').replaceAll('>', '');
          if (isEnumParam) {
            getterFields.add(
                "map['${name}'] = EnumToString.toList((${name} ?? []).where((element) => element != null).toList());");
            setterFields.add(
                "${name} = EnumToString.fromList(${setType}.values, (map['${name}'] ?? []).where((element) => element != null).toList()).toSet();");
            continue;
          } else if (_isCustomType(setType)) {
            // custom set type
            var idsName = '${name}Ids';
            getterFields
                .add("map['$idsName'] = ${name}.map((e) => e.id).toList();");
            setterFields.add(
                "${name} = Set<$setType>.from(await \$${setType}.findByIds(map['${idsName}']));");
            continue;
          } else if (primitiveTypes.contains(setType)) {
            getterFields.add("map['${name}'] = ${name}.toList();");
            setterFields.add(
                "${name} = Set<$setType>.from(map['${name}'] ?? <$setType>[]);");
            continue;
          }
        }
      }

      // working on Map object
      if (field.type.isDartCoreMap) {
        // in case predefine map key (type2) & value (type3)
        if (type2 != null && type3 != null) {
          final isMapValue = type3.startsWith('Map');
          if (_isPrimitiveType(type2)) {
            if (isMapValue) {
              getterFields.add(
                  '$name?.map((key, value) => MapEntry<$type2, $type3>(key, value));');
              setterFields.add('''
              map['$name']?.forEach((key, value) {
                    $name[key] = $type3.from(value);
              });
              ''');
            } else {
              getterFields.add("map['${name}'] = ${name};");
              setterFields.add(
                  "${name} = Map<$type2,$type3>.from(map['${name}'] ?? {});");
            }
          } else {
            if (isMapValue) {
              getterFields.add('''
              map['$name'] = $name?.map((key, value) =>
                    MapEntry<String, $type3>(EnumToString.convertToString(key), value)) ?? {};
              ''');
              setterFields.add('''
              map['$name']?.forEach((key, value) {
                  final itemKey = EnumToString.fromString($type2.values, key ?? '');
                  if(itemKey != null) {
                    $name[itemKey] = $type3.from(value ?? {});
                  }                  
              });
            ''');
            } else {
              getterFields.add('''
              map['$name'] = $name?.map((key, value) =>
                    MapEntry<String, $type3>(EnumToString.convertToString(key), value)) ?? {};
              ''');
              setterFields.add('''
              map['$name']?.forEach((key, value) {
                  final itemKey = EnumToString.fromString($type2.values, key ?? '');
                  if(itemKey != null) {
                    $name[itemKey] = value;
                  }                  
              });
            ''');
            }
          }

          continue;
        } else {
          // find map type if not define
          final regex = RegExp('<[a-zA-Z0-9, ]*>');
          var match = regex.firstMatch(type.replaceFirst('Map', ''));
          if (match != null) {
            var mapTypes =
                match.group(0)!.replaceAll('<', '').replaceAll('>', '');
            final types = mapTypes.split(',');
            final type1 = types[0].trim();
            final type2 = types[1].trim();
            // custom map type, atm only support Enum as key
            if (_isCustomType(type1)) {
              getterFields.add('''
              map['$name'] = $name?.map((key, value) =>
                    MapEntry<String, dynamic>(EnumToString.convertToString(key), value)) ?? {};
              ''');
              setterFields.add('''
              map['$name']?.forEach((key, value) {
                  final itemKey = EnumToString.fromString($type1.values, key ?? '');
                  if(itemKey != null) {
                    $name[itemKey] = value;
                  }                  
              });
            ''');
              continue;
            } else if (primitiveTypes.contains(type1)) {
              getterFields.add("map['${name}'] = ${name};");
              setterFields.add(
                  "${name} = Map<$type1,$type2>.from(map['${name}'] ?? <$type1,$type2>{});");
              continue;
            }
          }
        }
      }

      if (_isCustomType(type)) {
        // custom class
        var idName = '${name}Id';
        getterFields.add("map['$idName'] = ${name}?.id;");
        setterFields.add(
            "if(map['${idName}'] != null) { ${name} = await \$${type}.find(map['${idName}']); }");
      } else if (type == 'double') {
        //double
        getterFields.add("map['${name}'] = ${name};");
        setterFields.add(
            "if(map['${name}'] != null) { ${name} = map['${name}'] is int ? map['${name}'].toDouble(): map['${name}']; }");
      } else if (type == 'DateTime') {
        // DateTime
        getterFields.add("map['${name}'] = ${name}?.millisecondsSinceEpoch;");
        setterFields.add(
            "if(map['${name}'] is int) { ${name} = DateTime.fromMillisecondsSinceEpoch(map['$name']); }");
      } else {
        // the rest types
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
        var all = await $modelName().database?.all('$modelName', () {
          return $modelName();
        }, listenable: listenable) ?? [];
        return List<$modelName>.from(all);
      }

      static Future<$modelName?> find(String? id, {bool listenable = false}) async {
        return id == null ? null : await $modelName().database?.find('$modelName', id, $modelName(), listenable: listenable);
      }

      static Future<List<$modelName>> findByIds(List? ids, {bool listenable = false}) async {
        if (ids == null || ids.isEmpty) return <$modelName>[];
        final construct = ids.map((id) => 'id = \$id');
        final list = List<$modelName>.from(await where(construct.join(' or ')).load(listenable: listenable));
        final results = <$modelName>[];
        for (var id in ids) {
          final items = list.where((element) => element.id == id);
          if (items.isNotEmpty) {
            results.add(items.first);
          }
        }
        return results;
      }

      static DbQuery where(dynamic condition) {
        return DbQuery('$modelName').where(condition, $modelName().database, () {
          return $modelName();
        });
      }
    }
      ''');

    print('output:\n=========\n ${output.join("\n")}\n=========\n');
    return output.join('\n');
  }

  bool _isPrimitiveType(String typeName) {
    return ['int', 'String', 'bool', 'double', 'DateTime'].contains(typeName);
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

  Iterable<DartType> _getGenericTypes(DartType type) {
    return type is ParameterizedType ? type.typeArguments : const [];
  }
}

extension $DartType on DartType {
  String get type {
    if (isDartCoreBool) return 'bool';
    if (isDartCoreInt) return 'int';
    if (isDartCoreDouble) return 'double';
    if (isDartCoreList) return 'List';
    if (isDartCoreMap) return 'Map';
    if (isDartCoreNum) return 'num';
    if (isDartCoreSet) return 'Set';
    if (isDartCoreString) return 'String';
    if (isDynamic) return 'dynamic';
    if (isVoid) return 'bool';
    if (isDartCoreIterable) return 'Iterable';
    return name ?? '';
  }
}

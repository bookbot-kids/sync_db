// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enum_fixture.dart';

// **************************************************************************
// Model2Generator
// **************************************************************************

// EnumFixture model generator
extension $EnumFixture on EnumFixture {
  Map get map {
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

    map['staticMapping'] = EnumName(staticMapping).name;
    map['interfaceMapping'] = (() {
      try {
        // Explicit Object? also supports non-String declared getter types.
        // ignore: omit_local_variable_types
        final Object? enumMapping = interfaceMapping.value;
        if (enumMapping is String) return enumMapping;
      } catch (_) {
        // Legacy custom getters may throw; fall back to the enum name.
      }
      return EnumName(interfaceMapping).name;
    })();
    map['shadowedName'] = EnumName(shadowedName).name;
    map['enumName'] = EnumName(enumName).name;
    map['unannotated'] = EnumName(unannotated!).name;
    map['throwing'] = (() {
      try {
        // Explicit Object? also supports non-String declared getter types.
        // ignore: omit_local_variable_types
        final Object? enumMapping = throwing.value;
        if (enumMapping is String) return enumMapping;
      } catch (_) {
        // Legacy custom getters may throw; fall back to the enum name.
      }
      return EnumName(throwing).name;
    })();
    map['nullableMapping'] = (() {
      try {
        // Explicit Object? also supports non-String declared getter types.
        // ignore: omit_local_variable_types
        final Object? enumMapping = nullableMapping.value;
        if (enumMapping is String) return enumMapping;
      } catch (_) {
        // Legacy custom getters may throw; fall back to the enum name.
      }
      return EnumName(nullableMapping).name;
    })();
    map['plain'] = EnumName(plain).name;
    if (optional != null) {
      map['optional'] = EnumName(optional!).name;
    }
    map['mapped'] = (() {
      try {
        // Explicit Object? also supports non-String declared getter types.
        // ignore: omit_local_variable_types
        final Object? enumMapping = mapped.value;
        if (enumMapping is String) return enumMapping;
      } catch (_) {
        // Legacy custom getters may throw; fall back to the enum name.
      }
      return EnumName(mapped).name;
    })();
    map['enhanced'] = (() {
      try {
        // Explicit Object? also supports non-String declared getter types.
        // ignore: omit_local_variable_types
        final Object? enumMapping = enhanced.value;
        if (enumMapping is String) return enumMapping;
      } catch (_) {
        // Legacy custom getters may throw; fall back to the enum name.
      }
      return EnumName(enhanced).name;
    })();
    map['mixed'] = (() {
      try {
        // Explicit Object? also supports non-String declared getter types.
        // ignore: omit_local_variable_types
        final Object? enumMapping = mixed.value;
        if (enumMapping is String) return enumMapping;
      } catch (_) {
        // Legacy custom getters may throw; fall back to the enum name.
      }
      return EnumName(mixed).name;
    })();
    return map;
  }

  Future<Set<String>> setMap(Map map) async {
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

    if (map['staticMapping'] != null) {
      final enumName = (map['staticMapping'] as String).toLowerCase();
      for (final value in StaticMappingEnum.values) {
        if (EnumName(value).name.toLowerCase() == enumName) {
          staticMapping = value;
          break;
        }
      }
    }
    keys.add('staticMapping');

    if (map['interfaceMapping'] != null) {
      final enumName = (map['interfaceMapping'] as String).toLowerCase();
      for (final value in InterfaceMappingEnum.values) {
        if ((() {
              try {
                // Explicit Object? also supports non-String declared getter types.
                // ignore: omit_local_variable_types
                final Object? enumMapping = value.value;
                if (enumMapping is String) return enumMapping;
              } catch (_) {
                // Legacy custom getters may throw; fall back to the enum name.
              }
              return EnumName(value).name;
            })()
                .toLowerCase() ==
            enumName) {
          interfaceMapping = value;
          break;
        }
      }
    }
    keys.add('interfaceMapping');

    if (map['shadowedName'] != null) {
      final enumName = (map['shadowedName'] as String).toLowerCase();
      for (final value in ShadowedNameEnum.values) {
        if (EnumName(value).name.toLowerCase() == enumName) {
          shadowedName = value;
          break;
        }
      }
    }
    keys.add('shadowedName');

    if (map['enumName'] != null) {
      final enumName = (map['enumName'] as String).toLowerCase();
      for (final value in FixtureEnum.values) {
        if (EnumName(value).name.toLowerCase() == enumName) {
          this.enumName = value;
          break;
        }
      }
    }
    keys.add('enumName');

    if (map['unannotated'] != null) {
      final enumName = (map['unannotated'] as String).toLowerCase();
      for (final value in FixtureEnum.values) {
        if (EnumName(value).name.toLowerCase() == enumName) {
          unannotated = value;
          break;
        }
      }
    }
    keys.add('unannotated');

    if (map['throwing'] != null) {
      final enumName = (map['throwing'] as String).toLowerCase();
      for (final value in GetterEnum.values) {
        if ((() {
              try {
                // Explicit Object? also supports non-String declared getter types.
                // ignore: omit_local_variable_types
                final Object? enumMapping = value.value;
                if (enumMapping is String) return enumMapping;
              } catch (_) {
                // Legacy custom getters may throw; fall back to the enum name.
              }
              return EnumName(value).name;
            })()
                .toLowerCase() ==
            enumName) {
          throwing = value;
          break;
        }
      }
    }
    keys.add('throwing');

    if (map['nullableMapping'] != null) {
      final enumName = (map['nullableMapping'] as String).toLowerCase();
      for (final value in NullableMappingEnum.values) {
        if ((() {
              try {
                // Explicit Object? also supports non-String declared getter types.
                // ignore: omit_local_variable_types
                final Object? enumMapping = value.value;
                if (enumMapping is String) return enumMapping;
              } catch (_) {
                // Legacy custom getters may throw; fall back to the enum name.
              }
              return EnumName(value).name;
            })()
                .toLowerCase() ==
            enumName) {
          nullableMapping = value;
          break;
        }
      }
    }
    keys.add('nullableMapping');

    if (map['plain'] != null) {
      final enumName = (map['plain'] as String).toLowerCase();
      for (final value in FixtureEnum.values) {
        if (EnumName(value).name.toLowerCase() == enumName) {
          plain = value;
          break;
        }
      }
    }
    keys.add('plain');

    if (map['optional'] != null) {
      final enumName = (map['optional'] as String).toLowerCase();
      for (final value in FixtureEnum.values) {
        if (EnumName(value).name.toLowerCase() == enumName) {
          optional = value;
          break;
        }
      }
    }
    keys.add('optional');

    if (map['mapped'] != null) {
      final enumName = (map['mapped'] as String).toLowerCase();
      for (final value in MappedEnum.values) {
        if ((() {
              try {
                // Explicit Object? also supports non-String declared getter types.
                // ignore: omit_local_variable_types
                final Object? enumMapping = value.value;
                if (enumMapping is String) return enumMapping;
              } catch (_) {
                // Legacy custom getters may throw; fall back to the enum name.
              }
              return EnumName(value).name;
            })()
                .toLowerCase() ==
            enumName) {
          mapped = value;
          break;
        }
      }
    }
    keys.add('mapped');

    if (map['enhanced'] != null) {
      final enumName = (map['enhanced'] as String).toLowerCase();
      for (final value in EnhancedEnum.values) {
        if ((() {
              try {
                // Explicit Object? also supports non-String declared getter types.
                // ignore: omit_local_variable_types
                final Object? enumMapping = value.value;
                if (enumMapping is String) return enumMapping;
              } catch (_) {
                // Legacy custom getters may throw; fall back to the enum name.
              }
              return EnumName(value).name;
            })()
                .toLowerCase() ==
            enumName) {
          enhanced = value;
          break;
        }
      }
    }
    keys.add('enhanced');

    if (map['mixed'] != null) {
      final enumName = (map['mixed'] as String).toLowerCase();
      for (final value in MixedMappingEnum.values) {
        if ((() {
              try {
                // Explicit Object? also supports non-String declared getter types.
                // ignore: omit_local_variable_types
                final Object? enumMapping = value.value;
                if (enumMapping is String) return enumMapping;
              } catch (_) {
                // Legacy custom getters may throw; fall back to the enum name.
              }
              return EnumName(value).name;
            })()
                .toLowerCase() ==
            enumName) {
          mixed = value;
          break;
        }
      }
    }
    keys.add('mixed');

    return keys;
  }

  Set<String> get keys {
    final result = <String>{};
    result.add('staticMapping');
    result.add('interfaceMapping');
    result.add('shadowedName');
    result.add('enumName');
    result.add('unannotated');
    result.add('throwing');
    result.add('nullableMapping');
    result.add('plain');
    result.add('optional');
    result.add('mapped');
    result.add('enhanced');
    result.add('mixed');
    return result;
  }

  Set<String> compare(EnumFixture other) {
    final result = <String>{};
    if (deletedAt != other.deletedAt) {
      result.add('deletedAt');
    }

    if (staticMapping != other.staticMapping) {
      result.add('staticMapping');
    }

    if (interfaceMapping != other.interfaceMapping) {
      result.add('interfaceMapping');
    }

    if (shadowedName != other.shadowedName) {
      result.add('shadowedName');
    }

    if (enumName != other.enumName) {
      result.add('enumName');
    }

    if (unannotated != other.unannotated) {
      result.add('unannotated');
    }

    if (throwing != other.throwing) {
      result.add('throwing');
    }

    if (nullableMapping != other.nullableMapping) {
      result.add('nullableMapping');
    }

    if (plain != other.plain) {
      result.add('plain');
    }

    if (optional != other.optional) {
      result.add('optional');
    }

    if (mapped != other.mapped) {
      result.add('mapped');
    }

    if (enhanced != other.enhanced) {
      result.add('enhanced');
    }

    if (mixed != other.mixed) {
      result.add('mixed');
    }

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
}

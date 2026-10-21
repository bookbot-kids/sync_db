// Frozen output of the pre-migration generator (HEAD), with only the
// extension and converter names changed for side-by-side runtime comparison.
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enum_fixture.dart';

// **************************************************************************
// Model2Generator
// **************************************************************************

// EnumFixture model generator
extension $LegacyEnumFixture on EnumFixture {
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

    map['staticMapping'] = LegacyEnumToString.convertToString(staticMapping);
    map['interfaceMapping'] =
        LegacyEnumToString.convertToString(interfaceMapping);
    map['shadowedName'] = LegacyEnumToString.convertToString(shadowedName);
    map['enumName'] = LegacyEnumToString.convertToString(enumName);
    map['unannotated'] = LegacyEnumToString.convertToString(unannotated);
    map['throwing'] = LegacyEnumToString.convertToString(throwing);
    map['nullableMapping'] =
        LegacyEnumToString.convertToString(nullableMapping);
    map['plain'] = LegacyEnumToString.convertToString(plain);
    if (optional != null) {
      map['optional'] = LegacyEnumToString.convertToString(optional);
    }
    map['mapped'] = LegacyEnumToString.convertToString(mapped);
    map['enhanced'] = LegacyEnumToString.convertToString(enhanced);
    map['mixed'] = LegacyEnumToString.convertToString(mixed);
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
      final value = LegacyEnumToString.fromString(
          StaticMappingEnum.values, map['staticMapping']);
      if (value != null) {
        staticMapping = value;
      }
    }
    keys.add('staticMapping');

    if (map['interfaceMapping'] != null) {
      final value = LegacyEnumToString.fromString(
          InterfaceMappingEnum.values, map['interfaceMapping']);
      if (value != null) {
        interfaceMapping = value;
      }
    }
    keys.add('interfaceMapping');

    if (map['shadowedName'] != null) {
      final value = LegacyEnumToString.fromString(
          ShadowedNameEnum.values, map['shadowedName']);
      if (value != null) {
        shadowedName = value;
      }
    }
    keys.add('shadowedName');

    if (map['enumName'] != null) {
      final value =
          LegacyEnumToString.fromString(FixtureEnum.values, map['enumName']);
      if (value != null) {
        enumName = value;
      }
    }
    keys.add('enumName');

    if (map['unannotated'] != null) {
      final value =
          LegacyEnumToString.fromString(FixtureEnum.values, map['unannotated']);
      if (value != null) {
        unannotated = value;
      }
    }
    keys.add('unannotated');

    if (map['throwing'] != null) {
      final value =
          LegacyEnumToString.fromString(GetterEnum.values, map['throwing']);
      if (value != null) {
        throwing = value;
      }
    }
    keys.add('throwing');

    if (map['nullableMapping'] != null) {
      final value = LegacyEnumToString.fromString(
          NullableMappingEnum.values, map['nullableMapping']);
      if (value != null) {
        nullableMapping = value;
      }
    }
    keys.add('nullableMapping');

    if (map['plain'] != null) {
      final value =
          LegacyEnumToString.fromString(FixtureEnum.values, map['plain']);
      if (value != null) {
        plain = value;
      }
    }
    keys.add('plain');

    if (map['optional'] != null) {
      final value =
          LegacyEnumToString.fromString(FixtureEnum.values, map['optional']);
      if (value != null) {
        optional = value;
      }
    }
    keys.add('optional');

    if (map['mapped'] != null) {
      final value =
          LegacyEnumToString.fromString(MappedEnum.values, map['mapped']);
      if (value != null) {
        mapped = value;
      }
    }
    keys.add('mapped');

    if (map['enhanced'] != null) {
      final value =
          LegacyEnumToString.fromString(EnhancedEnum.values, map['enhanced']);
      if (value != null) {
        enhanced = value;
      }
    }
    keys.add('enhanced');

    if (map['mixed'] != null) {
      final value =
          LegacyEnumToString.fromString(MixedMappingEnum.values, map['mixed']);
      if (value != null) {
        mixed = value;
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

import 'package:sync_db/sync_db.dart';

import '../support/legacy_enum_converter.dart';

part 'enum_fixture.g.dart';
part 'enum_fixture.legacy.dart';

enum FixtureEnum { first, mixedCase, UPPER, under_score, caseName, CASENAME }

enum MappedEnum {
  first('wire-first'),
  empty(''),
  duplicate('WIRE-FIRST'),
  second('WiRe.Second');

  const MappedEnum(this.value);
  final String value;
}

enum EnhancedEnum {
  first(1),
  second(2);

  const EnhancedEnum(this.value);
  final int value;
}

enum MixedMappingEnum {
  first('custom'),
  second(2),
  third(null);

  const MixedMappingEnum(this.value);
  final Object? value;
}

enum InterfaceMappingEnum {
  first('interface-custom'),
  second('second');

  const InterfaceMappingEnum(this.value);
  final Comparable<String> value;
}

enum ShadowedNameEnum {
  first,
  second;

  String get name => 'not-the-wire-name';
}

enum StaticMappingEnum {
  first,
  second;

  static String get value => 'not-instance-mapping';
}

enum GetterEnum {
  first,
  second;

  String get value => throw StateError('no mapping');
}

enum NullableMappingEnum {
  first('nullable-custom'),
  second(null);

  const NullableMappingEnum(this.value);
  final String? value;
}

// Abstract models exercise the actual generator without needing an Isar DB.
abstract class EnumFixture extends Model {
  StaticMappingEnum staticMapping = StaticMappingEnum.first;
  InterfaceMappingEnum interfaceMapping = InterfaceMappingEnum.first;
  ShadowedNameEnum shadowedName = ShadowedNameEnum.first;
  FixtureEnum enumName = FixtureEnum.first;
  FixtureEnum? unannotated = FixtureEnum.first;
  GetterEnum throwing = GetterEnum.first;
  NullableMappingEnum nullableMapping = NullableMappingEnum.first;
  FixtureEnum plain = FixtureEnum.first;
  @ModelNullable()
  FixtureEnum? optional;
  MappedEnum mapped = MappedEnum.first;
  EnhancedEnum enhanced = EnhancedEnum.first;
  MixedMappingEnum mixed = MixedMappingEnum.first;
}

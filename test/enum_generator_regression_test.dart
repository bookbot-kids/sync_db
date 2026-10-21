import 'package:flutter_test/flutter_test.dart';
import 'models/enum_fixture.dart';

class _Fixture extends EnumFixture {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const fields = [
    'plain',
    'optional',
    'mapped',
    'enhanced',
    'mixed',
    'throwing',
    'nullableMapping',
    'interfaceMapping',
    'shadowedName',
    'unannotated',
    'enumName',
    'staticMapping'
  ];
  final values = <String, List<Enum>>{
    'plain': FixtureEnum.values,
    'optional': FixtureEnum.values,
    'mapped': MappedEnum.values,
    'enhanced': EnhancedEnum.values,
    'mixed': MixedMappingEnum.values,
    'throwing': GetterEnum.values,
    'nullableMapping': NullableMappingEnum.values,
    'interfaceMapping': InterfaceMappingEnum.values,
    'shadowedName': ShadowedNameEnum.values,
    'unannotated': FixtureEnum.values,
    'enumName': FixtureEnum.values,
    'staticMapping': StaticMappingEnum.values,
  };

  for (final field in fields) {
    group('generated $field', () {
      for (final value in values[field]!) {
        test('wire name and case variants for $value', () async {
          final original = _Fixture();
          switch (field) {
            case 'staticMapping':
              original.staticMapping = value as StaticMappingEnum;
            case 'throwing':
              original.throwing = value as GetterEnum;
            case 'nullableMapping':
              original.nullableMapping = value as NullableMappingEnum;
            case 'interfaceMapping':
              original.interfaceMapping = value as InterfaceMappingEnum;
            case 'shadowedName':
              original.shadowedName = value as ShadowedNameEnum;
            case 'unannotated':
              original.unannotated = value as FixtureEnum;
            case 'enumName':
              original.enumName = value as FixtureEnum;
            case 'plain':
              original.plain = value as FixtureEnum;
            case 'optional':
              original.optional = value as FixtureEnum;
            case 'mapped':
              original.mapped = value as MappedEnum;
            case 'enhanced':
              original.enhanced = value as EnhancedEnum;
            case 'mixed':
              original.mixed = value as MixedMappingEnum;
          }
          final oldMap = $LegacyEnumFixture(original).map;
          final newMap = $EnumFixture(original).map;
          expect(newMap, oldMap);
          final wireName = oldMap[field] as String;
          for (final input in {
            wireName,
            wireName.toLowerCase(),
            wireName.toUpperCase(),
            wireName
                .split('')
                .indexed
                .map((pair) => pair.$1.isEven
                    ? pair.$2.toUpperCase()
                    : pair.$2.toLowerCase())
                .join(),
          }) {
            final before = _Fixture();
            final after = _Fixture();
            final oldKeys =
                await $LegacyEnumFixture(before).setMap({field: input});
            final newKeys = await $EnumFixture(after).setMap({field: input});
            expect($EnumFixture(after).map, $LegacyEnumFixture(before).map,
                reason: '$field: $input');
            expect(newKeys, oldKeys);
          }
        });
      }

      for (final input in <Object?>[
        null,
        '',
        'unknown',
        ' first',
        'first ',
        'FixtureEnum.first',
        'mixed Case',
        '\nfirst',
        'FIRST\n',
      ]) {
        test('invalid or null input ${input.runtimeType}: "$input"', () async {
          final before = _Fixture()..optional = FixtureEnum.mixedCase;
          final after = _Fixture()..optional = FixtureEnum.mixedCase;
          final oldKeys =
              await $LegacyEnumFixture(before).setMap({field: input});
          final newKeys = await $EnumFixture(after).setMap({field: input});
          expect($EnumFixture(after).map, $LegacyEnumFixture(before).map);
          expect(newKeys, oldKeys);
        });
      }

      for (final input in <Object>[0, 1.5, true, [], {}, FixtureEnum.first]) {
        test('rejects dynamic ${input.runtimeType}', () async {
          final before = _Fixture();
          final after = _Fixture();
          await expectLater($LegacyEnumFixture(before).setMap({field: input}),
              throwsA(isA<TypeError>()));
          await expectLater($EnumFixture(after).setMap({field: input}),
              throwsA(isA<TypeError>()));
          expect($EnumFixture(after).map, $LegacyEnumFixture(before).map);
        });
      }
    });
  }

  test('missing keys preserve enum fields and return the same key set',
      () async {
    final before = _Fixture()..optional = FixtureEnum.UPPER;
    final after = _Fixture()..optional = FixtureEnum.UPPER;
    expect(await $EnumFixture(after).setMap({}),
        await $LegacyEnumFixture(before).setMap({}));
    expect($EnumFixture(after).map, $LegacyEnumFixture(before).map);
    expect($EnumFixture(after).keys, $LegacyEnumFixture(before).keys);
  });

  test('nullable field omits null and does not clear on incoming null',
      () async {
    final model = _Fixture();
    expect($EnumFixture(model).map.containsKey('optional'), isFalse);
    expect($EnumFixture(model).map, $LegacyEnumFixture(model).map);
    model.optional = FixtureEnum.UPPER;
    await $EnumFixture(model).setMap({'optional': null});
    expect(model.optional, FixtureEnum.UPPER);
  });

  test('unannotated nullable enum rejects null during serialization', () {
    final model = _Fixture()..unannotated = null;
    expect(() => $LegacyEnumFixture(model).map, throwsA(anything));
    expect(() => $EnumFixture(model).map, throwsA(anything));
  });

  test('case collisions preserve first-match semantics', () async {
    final model = _Fixture();
    await $EnumFixture(model).setMap({'plain': 'CASENAME'});
    expect(model.plain, FixtureEnum.caseName);
  });

  test('custom wire value accepts mapping, not enum identifier', () async {
    final model = _Fixture();
    await $EnumFixture(model).setMap({'mapped': 'second'});
    expect(model.mapped, MappedEnum.first);
    await $EnumFixture(model).setMap({'mapped': 'WIRE.SECOND'});
    expect(model.mapped, MappedEnum.second);
    expect($EnumFixture(model).map['mapped'], 'WiRe.Second');
  });
}

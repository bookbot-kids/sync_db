// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'class.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetClassRoomCollection on Isar {
  IsarCollection<ClassRoom> get classRooms => this.collection();
}

const ClassRoomSchema = CollectionSchema(
  name: r'ClassRoom',
  id: 2717467172829419821,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'deletedAt': PropertySchema(
      id: 1,
      name: r'deletedAt',
      type: IsarType.dateTime,
    ),
    r'hasListeners': PropertySchema(
      id: 2,
      name: r'hasListeners',
      type: IsarType.bool,
    ),
    r'id': PropertySchema(
      id: 3,
      name: r'id',
      type: IsarType.string,
    ),
    r'level': PropertySchema(
      id: 4,
      name: r'level',
      type: IsarType.long,
    ),
    r'metadata': PropertySchema(
      id: 5,
      name: r'metadata',
      type: IsarType.string,
    ),
    r'name': PropertySchema(
      id: 6,
      name: r'name',
      type: IsarType.string,
    ),
    r'partition': PropertySchema(
      id: 7,
      name: r'partition',
      type: IsarType.string,
    ),
    r'readingBookIds': PropertySchema(
      id: 8,
      name: r'readingBookIds',
      type: IsarType.stringList,
    ),
    r'rewards': PropertySchema(
      id: 9,
      name: r'rewards',
      type: IsarType.objectList,
      target: r'ClassReward',
    ),
    r'syncStatus': PropertySchema(
      id: 10,
      name: r'syncStatus',
      type: IsarType.byte,
      enumMap: _ClassRoomsyncStatusEnumValueMap,
    ),
    r'tableName': PropertySchema(
      id: 11,
      name: r'tableName',
      type: IsarType.string,
    ),
    r'teacherId': PropertySchema(
      id: 12,
      name: r'teacherId',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 13,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _classRoomEstimateSize,
  serialize: _classRoomSerialize,
  deserialize: _classRoomDeserialize,
  deserializeProp: _classRoomDeserializeProp,
  idName: r'localId',
  indexes: {
    r'id': IndexSchema(
      id: -3268401673993471357,
      name: r'id',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'id',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {r'ClassReward': ClassRewardSchema},
  getId: _classRoomGetId,
  getLinks: _classRoomGetLinks,
  attach: _classRoomAttach,
  version: '3.1.0+1',
);

int _classRoomEstimateSize(
  ClassRoom object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.id;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.metadata.length * 3;
  bytesCount += 3 + object.name.length * 3;
  {
    final value = object.partition;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.readingBookIds.length * 3;
  {
    for (var i = 0; i < object.readingBookIds.length; i++) {
      final value = object.readingBookIds[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.rewards.length * 3;
  {
    final offsets = allOffsets[ClassReward]!;
    for (var i = 0; i < object.rewards.length; i++) {
      final value = object.rewards[i];
      bytesCount += ClassRewardSchema.estimateSize(value, offsets, allOffsets);
    }
  }
  bytesCount += 3 + object.tableName.length * 3;
  bytesCount += 3 + object.teacherId.length * 3;
  return bytesCount;
}

void _classRoomSerialize(
  ClassRoom object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeDateTime(offsets[1], object.deletedAt);
  writer.writeBool(offsets[2], object.hasListeners);
  writer.writeString(offsets[3], object.id);
  writer.writeLong(offsets[4], object.level);
  writer.writeString(offsets[5], object.metadata);
  writer.writeString(offsets[6], object.name);
  writer.writeString(offsets[7], object.partition);
  writer.writeStringList(offsets[8], object.readingBookIds);
  writer.writeObjectList<ClassReward>(
    offsets[9],
    allOffsets,
    ClassRewardSchema.serialize,
    object.rewards,
  );
  writer.writeByte(offsets[10], object.syncStatus.index);
  writer.writeString(offsets[11], object.tableName);
  writer.writeString(offsets[12], object.teacherId);
  writer.writeDateTime(offsets[13], object.updatedAt);
}

ClassRoom _classRoomDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ClassRoom();
  object.createdAt = reader.readDateTimeOrNull(offsets[0]);
  object.deletedAt = reader.readDateTimeOrNull(offsets[1]);
  object.id = reader.readStringOrNull(offsets[3]);
  object.level = reader.readLong(offsets[4]);
  object.localId = id;
  object.metadata = reader.readString(offsets[5]);
  object.name = reader.readString(offsets[6]);
  object.partition = reader.readStringOrNull(offsets[7]);
  object.readingBookIds = reader.readStringList(offsets[8]) ?? [];
  object.rewards = reader.readObjectList<ClassReward>(
        offsets[9],
        ClassRewardSchema.deserialize,
        allOffsets,
        ClassReward(),
      ) ??
      [];
  object.syncStatus =
      _ClassRoomsyncStatusValueEnumMap[reader.readByteOrNull(offsets[10])] ??
          SyncStatus.created;
  object.teacherId = reader.readString(offsets[12]);
  object.updatedAt = reader.readDateTimeOrNull(offsets[13]);
  return object;
}

P _classRoomDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 1:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readStringList(offset) ?? []) as P;
    case 9:
      return (reader.readObjectList<ClassReward>(
            offset,
            ClassRewardSchema.deserialize,
            allOffsets,
            ClassReward(),
          ) ??
          []) as P;
    case 10:
      return (_ClassRoomsyncStatusValueEnumMap[reader.readByteOrNull(offset)] ??
          SyncStatus.created) as P;
    case 11:
      return (reader.readString(offset)) as P;
    case 12:
      return (reader.readString(offset)) as P;
    case 13:
      return (reader.readDateTimeOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _ClassRoomsyncStatusEnumValueMap = {
  'created': 0,
  'updated': 1,
  'synced': 2,
  'none': 3,
};
const _ClassRoomsyncStatusValueEnumMap = {
  0: SyncStatus.created,
  1: SyncStatus.updated,
  2: SyncStatus.synced,
  3: SyncStatus.none,
};

Id _classRoomGetId(ClassRoom object) {
  return object.localId;
}

List<IsarLinkBase<dynamic>> _classRoomGetLinks(ClassRoom object) {
  return [];
}

void _classRoomAttach(IsarCollection<dynamic> col, Id id, ClassRoom object) {
  object.localId = id;
}

extension ClassRoomByIndex on IsarCollection<ClassRoom> {
  Future<ClassRoom?> getById(String? id) {
    return getByIndex(r'id', [id]);
  }

  ClassRoom? getByIdSync(String? id) {
    return getByIndexSync(r'id', [id]);
  }

  Future<bool> deleteById(String? id) {
    return deleteByIndex(r'id', [id]);
  }

  bool deleteByIdSync(String? id) {
    return deleteByIndexSync(r'id', [id]);
  }

  Future<List<ClassRoom?>> getAllById(List<String?> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndex(r'id', values);
  }

  List<ClassRoom?> getAllByIdSync(List<String?> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'id', values);
  }

  Future<int> deleteAllById(List<String?> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'id', values);
  }

  int deleteAllByIdSync(List<String?> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'id', values);
  }

  Future<Id> putById(ClassRoom object) {
    return putByIndex(r'id', object);
  }

  Id putByIdSync(ClassRoom object, {bool saveLinks = true}) {
    return putByIndexSync(r'id', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllById(List<ClassRoom> objects) {
    return putAllByIndex(r'id', objects);
  }

  List<Id> putAllByIdSync(List<ClassRoom> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'id', objects, saveLinks: saveLinks);
  }
}

extension ClassRoomQueryWhereSort
    on QueryBuilder<ClassRoom, ClassRoom, QWhere> {
  QueryBuilder<ClassRoom, ClassRoom, QAfterWhere> anyLocalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ClassRoomQueryWhere
    on QueryBuilder<ClassRoom, ClassRoom, QWhereClause> {
  QueryBuilder<ClassRoom, ClassRoom, QAfterWhereClause> localIdEqualTo(
      Id localId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: localId,
        upper: localId,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterWhereClause> localIdNotEqualTo(
      Id localId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: localId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: localId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: localId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: localId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterWhereClause> localIdGreaterThan(
      Id localId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: localId, includeLower: include),
      );
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterWhereClause> localIdLessThan(
      Id localId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: localId, includeUpper: include),
      );
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterWhereClause> localIdBetween(
    Id lowerLocalId,
    Id upperLocalId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerLocalId,
        includeLower: includeLower,
        upper: upperLocalId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterWhereClause> idIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'id',
        value: [null],
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterWhereClause> idIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'id',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterWhereClause> idEqualTo(String? id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'id',
        value: [id],
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterWhereClause> idNotEqualTo(
      String? id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [],
              upper: [id],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [id],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [id],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [],
              upper: [id],
              includeUpper: false,
            ));
      }
    });
  }
}

extension ClassRoomQueryFilter
    on QueryBuilder<ClassRoom, ClassRoom, QFilterCondition> {
  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> createdAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'createdAt',
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition>
      createdAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'createdAt',
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> createdAtEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> createdAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> createdAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> deletedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'deletedAt',
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition>
      deletedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'deletedAt',
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> deletedAtEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deletedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition>
      deletedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'deletedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> deletedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'deletedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> deletedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'deletedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> hasListenersEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hasListeners',
        value: value,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> idIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> idIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> idEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> idGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> idLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> idBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> idStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> idEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> idContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> idMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'id',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> levelEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'level',
        value: value,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> levelGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'level',
        value: value,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> levelLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'level',
        value: value,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> levelBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'level',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> localIdEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localId',
        value: value,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> localIdGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'localId',
        value: value,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> localIdLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'localId',
        value: value,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> localIdBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'localId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> metadataEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'metadata',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> metadataGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'metadata',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> metadataLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'metadata',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> metadataBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'metadata',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> metadataStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'metadata',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> metadataEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'metadata',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> metadataContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'metadata',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> metadataMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'metadata',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> metadataIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'metadata',
        value: '',
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition>
      metadataIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'metadata',
        value: '',
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> nameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> nameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> partitionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'partition',
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition>
      partitionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'partition',
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> partitionEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'partition',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition>
      partitionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'partition',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> partitionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'partition',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> partitionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'partition',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> partitionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'partition',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> partitionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'partition',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> partitionContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'partition',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> partitionMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'partition',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> partitionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'partition',
        value: '',
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition>
      partitionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'partition',
        value: '',
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition>
      readingBookIdsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'readingBookIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition>
      readingBookIdsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'readingBookIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition>
      readingBookIdsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'readingBookIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition>
      readingBookIdsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'readingBookIds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition>
      readingBookIdsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'readingBookIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition>
      readingBookIdsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'readingBookIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition>
      readingBookIdsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'readingBookIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition>
      readingBookIdsElementMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'readingBookIds',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition>
      readingBookIdsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'readingBookIds',
        value: '',
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition>
      readingBookIdsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'readingBookIds',
        value: '',
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition>
      readingBookIdsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'readingBookIds',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition>
      readingBookIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'readingBookIds',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition>
      readingBookIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'readingBookIds',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition>
      readingBookIdsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'readingBookIds',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition>
      readingBookIdsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'readingBookIds',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition>
      readingBookIdsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'readingBookIds',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition>
      rewardsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'rewards',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> rewardsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'rewards',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition>
      rewardsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'rewards',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition>
      rewardsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'rewards',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition>
      rewardsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'rewards',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition>
      rewardsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'rewards',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> syncStatusEqualTo(
      SyncStatus value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncStatus',
        value: value,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition>
      syncStatusGreaterThan(
    SyncStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'syncStatus',
        value: value,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> syncStatusLessThan(
    SyncStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'syncStatus',
        value: value,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> syncStatusBetween(
    SyncStatus lower,
    SyncStatus upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'syncStatus',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> tableNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tableName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition>
      tableNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tableName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> tableNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tableName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> tableNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tableName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> tableNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'tableName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> tableNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'tableName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> tableNameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'tableName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> tableNameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'tableName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> tableNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tableName',
        value: '',
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition>
      tableNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'tableName',
        value: '',
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> teacherIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'teacherId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition>
      teacherIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'teacherId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> teacherIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'teacherId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> teacherIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'teacherId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> teacherIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'teacherId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> teacherIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'teacherId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> teacherIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'teacherId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> teacherIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'teacherId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> teacherIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'teacherId',
        value: '',
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition>
      teacherIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'teacherId',
        value: '',
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> updatedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'updatedAt',
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition>
      updatedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'updatedAt',
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> updatedAtEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> updatedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> updatedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ClassRoomQueryObject
    on QueryBuilder<ClassRoom, ClassRoom, QFilterCondition> {
  QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> rewardsElement(
      FilterQuery<ClassReward> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'rewards');
    });
  }
}

extension ClassRoomQueryLinks
    on QueryBuilder<ClassRoom, ClassRoom, QFilterCondition> {}

extension ClassRoomQuerySortBy on QueryBuilder<ClassRoom, ClassRoom, QSortBy> {
  QueryBuilder<ClassRoom, ClassRoom, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterSortBy> sortByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterSortBy> sortByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterSortBy> sortByHasListeners() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasListeners', Sort.asc);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterSortBy> sortByHasListenersDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasListeners', Sort.desc);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterSortBy> sortByLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'level', Sort.asc);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterSortBy> sortByLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'level', Sort.desc);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterSortBy> sortByMetadata() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadata', Sort.asc);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterSortBy> sortByMetadataDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadata', Sort.desc);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterSortBy> sortByPartition() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partition', Sort.asc);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterSortBy> sortByPartitionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partition', Sort.desc);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterSortBy> sortBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterSortBy> sortBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterSortBy> sortByTableName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tableName', Sort.asc);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterSortBy> sortByTableNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tableName', Sort.desc);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterSortBy> sortByTeacherId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'teacherId', Sort.asc);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterSortBy> sortByTeacherIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'teacherId', Sort.desc);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension ClassRoomQuerySortThenBy
    on QueryBuilder<ClassRoom, ClassRoom, QSortThenBy> {
  QueryBuilder<ClassRoom, ClassRoom, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterSortBy> thenByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterSortBy> thenByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterSortBy> thenByHasListeners() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasListeners', Sort.asc);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterSortBy> thenByHasListenersDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasListeners', Sort.desc);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterSortBy> thenByLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'level', Sort.asc);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterSortBy> thenByLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'level', Sort.desc);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterSortBy> thenByLocalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localId', Sort.asc);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterSortBy> thenByLocalIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localId', Sort.desc);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterSortBy> thenByMetadata() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadata', Sort.asc);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterSortBy> thenByMetadataDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadata', Sort.desc);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterSortBy> thenByPartition() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partition', Sort.asc);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterSortBy> thenByPartitionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partition', Sort.desc);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterSortBy> thenBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterSortBy> thenBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterSortBy> thenByTableName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tableName', Sort.asc);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterSortBy> thenByTableNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tableName', Sort.desc);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterSortBy> thenByTeacherId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'teacherId', Sort.asc);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterSortBy> thenByTeacherIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'teacherId', Sort.desc);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension ClassRoomQueryWhereDistinct
    on QueryBuilder<ClassRoom, ClassRoom, QDistinct> {
  QueryBuilder<ClassRoom, ClassRoom, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QDistinct> distinctByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deletedAt');
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QDistinct> distinctByHasListeners() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hasListeners');
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QDistinct> distinctById(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'id', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QDistinct> distinctByLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'level');
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QDistinct> distinctByMetadata(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'metadata', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QDistinct> distinctByPartition(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'partition', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QDistinct> distinctByReadingBookIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'readingBookIds');
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QDistinct> distinctBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncStatus');
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QDistinct> distinctByTableName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tableName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QDistinct> distinctByTeacherId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'teacherId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ClassRoom, ClassRoom, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension ClassRoomQueryProperty
    on QueryBuilder<ClassRoom, ClassRoom, QQueryProperty> {
  QueryBuilder<ClassRoom, int, QQueryOperations> localIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localId');
    });
  }

  QueryBuilder<ClassRoom, DateTime?, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<ClassRoom, DateTime?, QQueryOperations> deletedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deletedAt');
    });
  }

  QueryBuilder<ClassRoom, bool, QQueryOperations> hasListenersProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hasListeners');
    });
  }

  QueryBuilder<ClassRoom, String?, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ClassRoom, int, QQueryOperations> levelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'level');
    });
  }

  QueryBuilder<ClassRoom, String, QQueryOperations> metadataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'metadata');
    });
  }

  QueryBuilder<ClassRoom, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<ClassRoom, String?, QQueryOperations> partitionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'partition');
    });
  }

  QueryBuilder<ClassRoom, List<String>, QQueryOperations>
      readingBookIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'readingBookIds');
    });
  }

  QueryBuilder<ClassRoom, List<ClassReward>, QQueryOperations>
      rewardsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rewards');
    });
  }

  QueryBuilder<ClassRoom, SyncStatus, QQueryOperations> syncStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncStatus');
    });
  }

  QueryBuilder<ClassRoom, String, QQueryOperations> tableNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tableName');
    });
  }

  QueryBuilder<ClassRoom, String, QQueryOperations> teacherIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'teacherId');
    });
  }

  QueryBuilder<ClassRoom, DateTime?, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const ClassRewardSchema = Schema(
  name: r'ClassReward',
  id: -3136041855463881631,
  properties: {
    r'enabled': PropertySchema(
      id: 0,
      name: r'enabled',
      type: IsarType.bool,
    ),
    r'hashCode': PropertySchema(
      id: 1,
      name: r'hashCode',
      type: IsarType.long,
    ),
    r'name': PropertySchema(
      id: 2,
      name: r'name',
      type: IsarType.string,
    ),
    r'token': PropertySchema(
      id: 3,
      name: r'token',
      type: IsarType.long,
    )
  },
  estimateSize: _classRewardEstimateSize,
  serialize: _classRewardSerialize,
  deserialize: _classRewardDeserialize,
  deserializeProp: _classRewardDeserializeProp,
);

int _classRewardEstimateSize(
  ClassReward object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.name.length * 3;
  return bytesCount;
}

void _classRewardSerialize(
  ClassReward object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.enabled);
  writer.writeLong(offsets[1], object.hashCode);
  writer.writeString(offsets[2], object.name);
  writer.writeLong(offsets[3], object.token);
}

ClassReward _classRewardDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ClassReward();
  object.enabled = reader.readBool(offsets[0]);
  object.name = reader.readString(offsets[2]);
  object.token = reader.readLong(offsets[3]);
  return object;
}

P _classRewardDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension ClassRewardQueryFilter
    on QueryBuilder<ClassReward, ClassReward, QFilterCondition> {
  QueryBuilder<ClassReward, ClassReward, QAfterFilterCondition> enabledEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'enabled',
        value: value,
      ));
    });
  }

  QueryBuilder<ClassReward, ClassReward, QAfterFilterCondition> hashCodeEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hashCode',
        value: value,
      ));
    });
  }

  QueryBuilder<ClassReward, ClassReward, QAfterFilterCondition>
      hashCodeGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'hashCode',
        value: value,
      ));
    });
  }

  QueryBuilder<ClassReward, ClassReward, QAfterFilterCondition>
      hashCodeLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'hashCode',
        value: value,
      ));
    });
  }

  QueryBuilder<ClassReward, ClassReward, QAfterFilterCondition> hashCodeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'hashCode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ClassReward, ClassReward, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassReward, ClassReward, QAfterFilterCondition> nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassReward, ClassReward, QAfterFilterCondition> nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassReward, ClassReward, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassReward, ClassReward, QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassReward, ClassReward, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassReward, ClassReward, QAfterFilterCondition> nameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassReward, ClassReward, QAfterFilterCondition> nameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClassReward, ClassReward, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<ClassReward, ClassReward, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<ClassReward, ClassReward, QAfterFilterCondition> tokenEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'token',
        value: value,
      ));
    });
  }

  QueryBuilder<ClassReward, ClassReward, QAfterFilterCondition>
      tokenGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'token',
        value: value,
      ));
    });
  }

  QueryBuilder<ClassReward, ClassReward, QAfterFilterCondition> tokenLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'token',
        value: value,
      ));
    });
  }

  QueryBuilder<ClassReward, ClassReward, QAfterFilterCondition> tokenBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'token',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ClassRewardQueryObject
    on QueryBuilder<ClassReward, ClassReward, QFilterCondition> {}

// **************************************************************************
// Model2Generator
// **************************************************************************

// ClassRoom model generator
extension $ClassRoom on ClassRoom {
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

    map['name'] = name;
    map['teacherId'] = teacherId;
    map['readingBookIds'] = readingBookIds.toSet().toList();
    map['level'] = level;
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

    if (map['name'] != null) name = map['name'];
    keys.add('name');

    if (map['teacherId'] != null) teacherId = map['teacherId'];
    keys.add('teacherId');

    readingBookIds = Set<String>.from(
            (map['readingBookIds'] as List?)?.whereNotNull() ?? <String>[])
        .toList();
    keys.add('readingBookIds');

    if (map['level'] != null) level = map['level'];
    keys.add('level');

    return keys;
  }

  /// Save record and sync to service
  Future<void> save(
      {bool syncToService = true,
      bool runInTransaction = true,
      bool initialize = true}) async {
    final callback = () async {
      if (initialize) {
        await init();
      }

      if (syncToService && syncStatus == SyncStatus.updated) {
        final other = await find(id, filterDeletedAt: false);
        if (other != null) {
          final diff = compare(other);
          if (diff.isNotEmpty) {
            var recordLog = await ServiceRecord().findBy(id, tableName);
            recordLog ??= ServiceRecord();
            recordLog.id = id;
            recordLog.name = tableName;
            recordLog.appendFields(diff);
            await recordLog.save(runInTransaction: false);
          }
        }
      }
      await Sync.shared.db.local.classRooms.put(this);
    };

    if (runInTransaction) {
      await Sync.shared.db.local.writeTxn(() async {
        await callback();
      });

      if (syncToService) {
        // ignore: unawaited_futures
        sync();
      }
    } else {
      await callback();
      if (syncToService) {
        // ignore: unawaited_futures
        sync();
      }
    }
  }

  /// Get all records
  static Future<List<ClassRoom>> all({bool filterDeletedAt = true}) {
    final collection = Sync.shared.db.local.classRooms;
    return filterDeletedAt
        ? collection.filter().getAll()
        : collection.where().findAll();
  }

  /// Find record by id
  static Future<ClassRoom?> find(String? id,
      {bool filterDeletedAt = true}) async {
    final filter = await Sync.shared.db.local.classRooms.filter().idEqualTo(id);
    return filterDeletedAt ? filter.getFirst() : filter.findFirst();
  }

  /// List records by sync status
  static Future<List<ClassRoom>> queryStatus(SyncStatus status,
      {bool filterDeletedAt = true}) async {
    final filter = await Sync.shared.db.local.classRooms
        .filter()
        .syncStatusEqualTo(status);
    return filterDeletedAt ? filter.getAll() : filter.findAll();
  }

  /// delete and sync record
  Future<void> delete({bool syncToService = true}) async {
    deletedAt = await NetworkTime.shared.now;
    await save(syncToService: syncToService);
  }

  /// delete local record without syncing
  Future<void> deleteLocal() async {
    if (id != null) {
      await db.writeTxn(() async {
        await db.classRooms.delete(localId);
      });
    }
  }

  /// Clear all records and reset the auto increment value
  Future<void> clear() {
    return db.classRooms.clear();
  }

  Set<String> compare(ClassRoom other) {
    final result = <String>{};
    if (deletedAt != other.deletedAt) {
      result.add('deletedAt');
    }

    if (name != other.name) {
      result.add('name');
    }

    if (teacherId != other.teacherId) {
      result.add('teacherId');
    }

    if (!DeepCollectionEquality()
        .equals(readingBookIds, other.readingBookIds)) {
      result.add('readingBookIds');
    }

    if (!DeepCollectionEquality().equals(rewards, other.rewards)) {
      result.add('rewards');
    }

    if (level != other.level) {
      result.add('level');
    }

    final list = <String>[];
    final remap = remapFields();
    for (final item in result) {
      if (remap.containsKey(item)) {
        list.addAll(remap[item]!);
      } else {
        list.add(item);
      }
    }
    return list.toSet();
  }

  /// Export all data into json
  Future<List<Map<String, dynamic>>> exportJson(
      {Function(Uint8List)? callback}) async {
    final where = Sync.shared.db.local.classRooms.where();
    if (callback != null) {
      await where.exportJsonRaw(callback);
      return [];
    }

    return where.exportJson();
  }

  /// Import json into this collection
  Future<void> importJson(dynamic jsonData) async {
    if (jsonData is Uint8List) {
      await Sync.shared.db.local.classRooms.importJsonRaw(jsonData);
    } else if (jsonData is List<Map<String, dynamic>>) {
      await Sync.shared.db.local.classRooms.importJson(jsonData);
    } else {
      throw UnsupportedError('Json type is not supported');
    }
  }
}

extension ClassRoomQAfterFilterCondition
    on QueryBuilder<ClassRoom, ClassRoom, QAfterFilterCondition> {
  Future<List<ClassRoom>> getAll() async {
    return deletedAtIsNull().findAll();
  }

  Future<ClassRoom?> getFirst() async {
    return deletedAtIsNull().findFirst();
  }
}

extension ClassRoomQFilterCondition
    on QueryBuilder<ClassRoom, ClassRoom, QFilterCondition> {
  Future<List<ClassRoom>> getAll() async {
    return deletedAtIsNull().findAll();
  }

  Future<ClassRoom?> getFirst() async {
    return deletedAtIsNull().findFirst();
  }
}

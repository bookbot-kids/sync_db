// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetProgressCollection on Isar {
  IsarCollection<Progress> get progress => this.collection();
}

const ProgressSchema = CollectionSchema(
  name: r'Progress',
  id: 4416052739984182258,
  properties: {
    r'accuracies': PropertySchema(
      id: 0,
      name: r'accuracies',
      type: IsarType.doubleList,
    ),
    r'accuracy': PropertySchema(
      id: 1,
      name: r'accuracy',
      type: IsarType.double,
    ),
    r'bookId': PropertySchema(
      id: 2,
      name: r'bookId',
      type: IsarType.string,
    ),
    r'bookLanguage': PropertySchema(
      id: 3,
      name: r'bookLanguage',
      type: IsarType.string,
      enumMap: _ProgressbookLanguageEnumValueMap,
    ),
    r'completedAt': PropertySchema(
      id: 4,
      name: r'completedAt',
      type: IsarType.long,
    ),
    r'correct': PropertySchema(
      id: 5,
      name: r'correct',
      type: IsarType.boolList,
    ),
    r'correctWords': PropertySchema(
      id: 6,
      name: r'correctWords',
      type: IsarType.objectList,
      target: r'ProgressCorrectWords',
    ),
    r'createdAt': PropertySchema(
      id: 7,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'currentPage': PropertySchema(
      id: 8,
      name: r'currentPage',
      type: IsarType.long,
    ),
    r'deletedAt': PropertySchema(
      id: 9,
      name: r'deletedAt',
      type: IsarType.dateTime,
    ),
    r'fluencies': PropertySchema(
      id: 10,
      name: r'fluencies',
      type: IsarType.doubleList,
    ),
    r'fluency': PropertySchema(
      id: 11,
      name: r'fluency',
      type: IsarType.double,
    ),
    r'hasListeners': PropertySchema(
      id: 12,
      name: r'hasListeners',
      type: IsarType.bool,
    ),
    r'id': PropertySchema(
      id: 13,
      name: r'id',
      type: IsarType.string,
    ),
    r'incorrectWords': PropertySchema(
      id: 14,
      name: r'incorrectWords',
      type: IsarType.objectList,
      target: r'ProgressCorrectWords',
    ),
    r'level': PropertySchema(
      id: 15,
      name: r'level',
      type: IsarType.long,
    ),
    r'markers': PropertySchema(
      id: 16,
      name: r'markers',
      type: IsarType.stringList,
    ),
    r'metadata': PropertySchema(
      id: 17,
      name: r'metadata',
      type: IsarType.string,
    ),
    r'pageReadCount': PropertySchema(
      id: 18,
      name: r'pageReadCount',
      type: IsarType.long,
    ),
    r'partition': PropertySchema(
      id: 19,
      name: r'partition',
      type: IsarType.string,
    ),
    r'profileId': PropertySchema(
      id: 20,
      name: r'profileId',
      type: IsarType.string,
    ),
    r'progress': PropertySchema(
      id: 21,
      name: r'progress',
      type: IsarType.doubleList,
    ),
    r'rating': PropertySchema(
      id: 22,
      name: r'rating',
      type: IsarType.long,
    ),
    r'readPracticeWords': PropertySchema(
      id: 23,
      name: r'readPracticeWords',
      type: IsarType.stringList,
    ),
    r'readToMeTime': PropertySchema(
      id: 24,
      name: r'readToMeTime',
      type: IsarType.long,
    ),
    r'readWords': PropertySchema(
      id: 25,
      name: r'readWords',
      type: IsarType.stringList,
    ),
    r'readingTime': PropertySchema(
      id: 26,
      name: r'readingTime',
      type: IsarType.long,
    ),
    r'syncStatus': PropertySchema(
      id: 27,
      name: r'syncStatus',
      type: IsarType.byte,
      enumMap: _ProgresssyncStatusEnumValueMap,
    ),
    r'tableName': PropertySchema(
      id: 28,
      name: r'tableName',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 29,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'viewingTime': PropertySchema(
      id: 30,
      name: r'viewingTime',
      type: IsarType.long,
    )
  },
  estimateSize: _progressEstimateSize,
  serialize: _progressSerialize,
  deserialize: _progressDeserialize,
  deserializeProp: _progressDeserializeProp,
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
  embeddedSchemas: {r'ProgressCorrectWords': ProgressCorrectWordsSchema},
  getId: _progressGetId,
  getLinks: _progressGetLinks,
  attach: _progressAttach,
  version: '3.1.8',
);

int _progressEstimateSize(
  Progress object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.accuracies.length * 8;
  {
    final value = object.bookId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.bookLanguage.name.length * 3;
  bytesCount += 3 + object.correct.length;
  bytesCount += 3 + object.correctWords.length * 3;
  {
    final offsets = allOffsets[ProgressCorrectWords]!;
    for (var i = 0; i < object.correctWords.length; i++) {
      final value = object.correctWords[i];
      bytesCount +=
          ProgressCorrectWordsSchema.estimateSize(value, offsets, allOffsets);
    }
  }
  bytesCount += 3 + object.fluencies.length * 8;
  {
    final value = object.id;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.incorrectWords.length * 3;
  {
    final offsets = allOffsets[ProgressCorrectWords]!;
    for (var i = 0; i < object.incorrectWords.length; i++) {
      final value = object.incorrectWords[i];
      bytesCount +=
          ProgressCorrectWordsSchema.estimateSize(value, offsets, allOffsets);
    }
  }
  bytesCount += 3 + object.markers.length * 3;
  {
    for (var i = 0; i < object.markers.length; i++) {
      final value = object.markers[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.metadata.length * 3;
  {
    final value = object.partition;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.profileId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.progress.length * 8;
  bytesCount += 3 + object.readPracticeWords.length * 3;
  {
    for (var i = 0; i < object.readPracticeWords.length; i++) {
      final value = object.readPracticeWords[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.readWords.length * 3;
  {
    for (var i = 0; i < object.readWords.length; i++) {
      final value = object.readWords[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.tableName.length * 3;
  return bytesCount;
}

void _progressSerialize(
  Progress object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDoubleList(offsets[0], object.accuracies);
  writer.writeDouble(offsets[1], object.accuracy);
  writer.writeString(offsets[2], object.bookId);
  writer.writeString(offsets[3], object.bookLanguage.name);
  writer.writeLong(offsets[4], object.completedAt);
  writer.writeBoolList(offsets[5], object.correct);
  writer.writeObjectList<ProgressCorrectWords>(
    offsets[6],
    allOffsets,
    ProgressCorrectWordsSchema.serialize,
    object.correctWords,
  );
  writer.writeDateTime(offsets[7], object.createdAt);
  writer.writeLong(offsets[8], object.currentPage);
  writer.writeDateTime(offsets[9], object.deletedAt);
  writer.writeDoubleList(offsets[10], object.fluencies);
  writer.writeDouble(offsets[11], object.fluency);
  writer.writeBool(offsets[12], object.hasListeners);
  writer.writeString(offsets[13], object.id);
  writer.writeObjectList<ProgressCorrectWords>(
    offsets[14],
    allOffsets,
    ProgressCorrectWordsSchema.serialize,
    object.incorrectWords,
  );
  writer.writeLong(offsets[15], object.level);
  writer.writeStringList(offsets[16], object.markers);
  writer.writeString(offsets[17], object.metadata);
  writer.writeLong(offsets[18], object.pageReadCount);
  writer.writeString(offsets[19], object.partition);
  writer.writeString(offsets[20], object.profileId);
  writer.writeDoubleList(offsets[21], object.progress);
  writer.writeLong(offsets[22], object.rating);
  writer.writeStringList(offsets[23], object.readPracticeWords);
  writer.writeLong(offsets[24], object.readToMeTime);
  writer.writeStringList(offsets[25], object.readWords);
  writer.writeLong(offsets[26], object.readingTime);
  writer.writeByte(offsets[27], object.syncStatus.index);
  writer.writeString(offsets[28], object.tableName);
  writer.writeDateTime(offsets[29], object.updatedAt);
  writer.writeLong(offsets[30], object.viewingTime);
}

Progress _progressDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Progress();
  object.accuracies = reader.readDoubleList(offsets[0]) ?? [];
  object.accuracy = reader.readDouble(offsets[1]);
  object.bookId = reader.readStringOrNull(offsets[2]);
  object.bookLanguage =
      _ProgressbookLanguageValueEnumMap[reader.readStringOrNull(offsets[3])] ??
          LibraryLanguage.en;
  object.completedAt = reader.readLongOrNull(offsets[4]);
  object.correct = reader.readBoolList(offsets[5]) ?? [];
  object.correctWords = reader.readObjectList<ProgressCorrectWords>(
        offsets[6],
        ProgressCorrectWordsSchema.deserialize,
        allOffsets,
        ProgressCorrectWords(),
      ) ??
      [];
  object.createdAt = reader.readDateTimeOrNull(offsets[7]);
  object.currentPage = reader.readLong(offsets[8]);
  object.deletedAt = reader.readDateTimeOrNull(offsets[9]);
  object.fluencies = reader.readDoubleList(offsets[10]) ?? [];
  object.fluency = reader.readDouble(offsets[11]);
  object.id = reader.readStringOrNull(offsets[13]);
  object.incorrectWords = reader.readObjectList<ProgressCorrectWords>(
        offsets[14],
        ProgressCorrectWordsSchema.deserialize,
        allOffsets,
        ProgressCorrectWords(),
      ) ??
      [];
  object.level = reader.readLong(offsets[15]);
  object.localId = id;
  object.markers = reader.readStringList(offsets[16]) ?? [];
  object.metadata = reader.readString(offsets[17]);
  object.pageReadCount = reader.readLong(offsets[18]);
  object.partition = reader.readStringOrNull(offsets[19]);
  object.profileId = reader.readStringOrNull(offsets[20]);
  object.progress = reader.readDoubleList(offsets[21]) ?? [];
  object.rating = reader.readLong(offsets[22]);
  object.readPracticeWords = reader.readStringList(offsets[23]) ?? [];
  object.readToMeTime = reader.readLong(offsets[24]);
  object.readWords = reader.readStringList(offsets[25]) ?? [];
  object.readingTime = reader.readLong(offsets[26]);
  object.syncStatus =
      _ProgresssyncStatusValueEnumMap[reader.readByteOrNull(offsets[27])] ??
          SyncStatus.created;
  object.updatedAt = reader.readDateTimeOrNull(offsets[29]);
  object.viewingTime = reader.readLong(offsets[30]);
  return object;
}

P _progressDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDoubleList(offset) ?? []) as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (_ProgressbookLanguageValueEnumMap[
              reader.readStringOrNull(offset)] ??
          LibraryLanguage.en) as P;
    case 4:
      return (reader.readLongOrNull(offset)) as P;
    case 5:
      return (reader.readBoolList(offset) ?? []) as P;
    case 6:
      return (reader.readObjectList<ProgressCorrectWords>(
            offset,
            ProgressCorrectWordsSchema.deserialize,
            allOffsets,
            ProgressCorrectWords(),
          ) ??
          []) as P;
    case 7:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 10:
      return (reader.readDoubleList(offset) ?? []) as P;
    case 11:
      return (reader.readDouble(offset)) as P;
    case 12:
      return (reader.readBool(offset)) as P;
    case 13:
      return (reader.readStringOrNull(offset)) as P;
    case 14:
      return (reader.readObjectList<ProgressCorrectWords>(
            offset,
            ProgressCorrectWordsSchema.deserialize,
            allOffsets,
            ProgressCorrectWords(),
          ) ??
          []) as P;
    case 15:
      return (reader.readLong(offset)) as P;
    case 16:
      return (reader.readStringList(offset) ?? []) as P;
    case 17:
      return (reader.readString(offset)) as P;
    case 18:
      return (reader.readLong(offset)) as P;
    case 19:
      return (reader.readStringOrNull(offset)) as P;
    case 20:
      return (reader.readStringOrNull(offset)) as P;
    case 21:
      return (reader.readDoubleList(offset) ?? []) as P;
    case 22:
      return (reader.readLong(offset)) as P;
    case 23:
      return (reader.readStringList(offset) ?? []) as P;
    case 24:
      return (reader.readLong(offset)) as P;
    case 25:
      return (reader.readStringList(offset) ?? []) as P;
    case 26:
      return (reader.readLong(offset)) as P;
    case 27:
      return (_ProgresssyncStatusValueEnumMap[reader.readByteOrNull(offset)] ??
          SyncStatus.created) as P;
    case 28:
      return (reader.readString(offset)) as P;
    case 29:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 30:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _ProgressbookLanguageEnumValueMap = {
  r'en': r'en',
  r'id': r'id',
  r'sw': r'sw',
};
const _ProgressbookLanguageValueEnumMap = {
  r'en': LibraryLanguage.en,
  r'id': LibraryLanguage.id,
  r'sw': LibraryLanguage.sw,
};
const _ProgresssyncStatusEnumValueMap = {
  'created': 0,
  'updated': 1,
  'synced': 2,
  'none': 3,
};
const _ProgresssyncStatusValueEnumMap = {
  0: SyncStatus.created,
  1: SyncStatus.updated,
  2: SyncStatus.synced,
  3: SyncStatus.none,
};

Id _progressGetId(Progress object) {
  return object.localId;
}

List<IsarLinkBase<dynamic>> _progressGetLinks(Progress object) {
  return [];
}

void _progressAttach(IsarCollection<dynamic> col, Id id, Progress object) {
  object.localId = id;
}

extension ProgressByIndex on IsarCollection<Progress> {
  Future<Progress?> getById(String? id) {
    return getByIndex(r'id', [id]);
  }

  Progress? getByIdSync(String? id) {
    return getByIndexSync(r'id', [id]);
  }

  Future<bool> deleteById(String? id) {
    return deleteByIndex(r'id', [id]);
  }

  bool deleteByIdSync(String? id) {
    return deleteByIndexSync(r'id', [id]);
  }

  Future<List<Progress?>> getAllById(List<String?> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndex(r'id', values);
  }

  List<Progress?> getAllByIdSync(List<String?> idValues) {
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

  Future<Id> putById(Progress object) {
    return putByIndex(r'id', object);
  }

  Id putByIdSync(Progress object, {bool saveLinks = true}) {
    return putByIndexSync(r'id', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllById(List<Progress> objects) {
    return putAllByIndex(r'id', objects);
  }

  List<Id> putAllByIdSync(List<Progress> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'id', objects, saveLinks: saveLinks);
  }
}

extension ProgressQueryWhereSort on QueryBuilder<Progress, Progress, QWhere> {
  QueryBuilder<Progress, Progress, QAfterWhere> anyLocalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ProgressQueryWhere on QueryBuilder<Progress, Progress, QWhereClause> {
  QueryBuilder<Progress, Progress, QAfterWhereClause> localIdEqualTo(
      Id localId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: localId,
        upper: localId,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterWhereClause> localIdNotEqualTo(
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

  QueryBuilder<Progress, Progress, QAfterWhereClause> localIdGreaterThan(
      Id localId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: localId, includeLower: include),
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterWhereClause> localIdLessThan(
      Id localId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: localId, includeUpper: include),
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterWhereClause> localIdBetween(
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

  QueryBuilder<Progress, Progress, QAfterWhereClause> idIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'id',
        value: [null],
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterWhereClause> idIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'id',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterWhereClause> idEqualTo(String? id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'id',
        value: [id],
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterWhereClause> idNotEqualTo(String? id) {
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

extension ProgressQueryFilter
    on QueryBuilder<Progress, Progress, QFilterCondition> {
  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      accuraciesElementEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'accuracies',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      accuraciesElementGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'accuracies',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      accuraciesElementLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'accuracies',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      accuraciesElementBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'accuracies',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      accuraciesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'accuracies',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> accuraciesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'accuracies',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      accuraciesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'accuracies',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      accuraciesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'accuracies',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      accuraciesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'accuracies',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      accuraciesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'accuracies',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> accuracyEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'accuracy',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> accuracyGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'accuracy',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> accuracyLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'accuracy',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> accuracyBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'accuracy',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> bookIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'bookId',
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> bookIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'bookId',
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> bookIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bookId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> bookIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bookId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> bookIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bookId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> bookIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bookId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> bookIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'bookId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> bookIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'bookId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> bookIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'bookId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> bookIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'bookId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> bookIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bookId',
        value: '',
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> bookIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'bookId',
        value: '',
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> bookLanguageEqualTo(
    LibraryLanguage value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bookLanguage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      bookLanguageGreaterThan(
    LibraryLanguage value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bookLanguage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> bookLanguageLessThan(
    LibraryLanguage value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bookLanguage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> bookLanguageBetween(
    LibraryLanguage lower,
    LibraryLanguage upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bookLanguage',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      bookLanguageStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'bookLanguage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> bookLanguageEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'bookLanguage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> bookLanguageContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'bookLanguage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> bookLanguageMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'bookLanguage',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      bookLanguageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bookLanguage',
        value: '',
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      bookLanguageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'bookLanguage',
        value: '',
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> completedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'completedAt',
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      completedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'completedAt',
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> completedAtEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'completedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      completedAtGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'completedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> completedAtLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'completedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> completedAtBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'completedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> correctElementEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'correct',
        value: value,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> correctLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'correct',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> correctIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'correct',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> correctIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'correct',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> correctLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'correct',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      correctLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'correct',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> correctLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'correct',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      correctWordsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'correctWords',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      correctWordsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'correctWords',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      correctWordsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'correctWords',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      correctWordsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'correctWords',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      correctWordsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'correctWords',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      correctWordsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'correctWords',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> createdAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'createdAt',
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> createdAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'createdAt',
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> createdAtEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> createdAtGreaterThan(
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

  QueryBuilder<Progress, Progress, QAfterFilterCondition> createdAtLessThan(
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

  QueryBuilder<Progress, Progress, QAfterFilterCondition> createdAtBetween(
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

  QueryBuilder<Progress, Progress, QAfterFilterCondition> currentPageEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currentPage',
        value: value,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      currentPageGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'currentPage',
        value: value,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> currentPageLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'currentPage',
        value: value,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> currentPageBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'currentPage',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> deletedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'deletedAt',
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> deletedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'deletedAt',
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> deletedAtEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deletedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> deletedAtGreaterThan(
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

  QueryBuilder<Progress, Progress, QAfterFilterCondition> deletedAtLessThan(
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

  QueryBuilder<Progress, Progress, QAfterFilterCondition> deletedAtBetween(
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

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      fluenciesElementEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fluencies',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      fluenciesElementGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fluencies',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      fluenciesElementLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fluencies',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      fluenciesElementBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fluencies',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      fluenciesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'fluencies',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> fluenciesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'fluencies',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      fluenciesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'fluencies',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      fluenciesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'fluencies',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      fluenciesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'fluencies',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      fluenciesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'fluencies',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> fluencyEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fluency',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> fluencyGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fluency',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> fluencyLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fluency',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> fluencyBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fluency',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> hasListenersEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hasListeners',
        value: value,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> idIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> idIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> idEqualTo(
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

  QueryBuilder<Progress, Progress, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<Progress, Progress, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<Progress, Progress, QAfterFilterCondition> idBetween(
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

  QueryBuilder<Progress, Progress, QAfterFilterCondition> idStartsWith(
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

  QueryBuilder<Progress, Progress, QAfterFilterCondition> idEndsWith(
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

  QueryBuilder<Progress, Progress, QAfterFilterCondition> idContains(
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

  QueryBuilder<Progress, Progress, QAfterFilterCondition> idMatches(
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

  QueryBuilder<Progress, Progress, QAfterFilterCondition> idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      incorrectWordsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'incorrectWords',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      incorrectWordsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'incorrectWords',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      incorrectWordsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'incorrectWords',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      incorrectWordsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'incorrectWords',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      incorrectWordsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'incorrectWords',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      incorrectWordsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'incorrectWords',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> levelEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'level',
        value: value,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> levelGreaterThan(
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

  QueryBuilder<Progress, Progress, QAfterFilterCondition> levelLessThan(
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

  QueryBuilder<Progress, Progress, QAfterFilterCondition> levelBetween(
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

  QueryBuilder<Progress, Progress, QAfterFilterCondition> localIdEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localId',
        value: value,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> localIdGreaterThan(
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

  QueryBuilder<Progress, Progress, QAfterFilterCondition> localIdLessThan(
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

  QueryBuilder<Progress, Progress, QAfterFilterCondition> localIdBetween(
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

  QueryBuilder<Progress, Progress, QAfterFilterCondition> markersElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'markers',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      markersElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'markers',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      markersElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'markers',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> markersElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'markers',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      markersElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'markers',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      markersElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'markers',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      markersElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'markers',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> markersElementMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'markers',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      markersElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'markers',
        value: '',
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      markersElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'markers',
        value: '',
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> markersLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'markers',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> markersIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'markers',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> markersIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'markers',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> markersLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'markers',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      markersLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'markers',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> markersLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'markers',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> metadataEqualTo(
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

  QueryBuilder<Progress, Progress, QAfterFilterCondition> metadataGreaterThan(
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

  QueryBuilder<Progress, Progress, QAfterFilterCondition> metadataLessThan(
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

  QueryBuilder<Progress, Progress, QAfterFilterCondition> metadataBetween(
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

  QueryBuilder<Progress, Progress, QAfterFilterCondition> metadataStartsWith(
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

  QueryBuilder<Progress, Progress, QAfterFilterCondition> metadataEndsWith(
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

  QueryBuilder<Progress, Progress, QAfterFilterCondition> metadataContains(
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

  QueryBuilder<Progress, Progress, QAfterFilterCondition> metadataMatches(
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

  QueryBuilder<Progress, Progress, QAfterFilterCondition> metadataIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'metadata',
        value: '',
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> metadataIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'metadata',
        value: '',
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> pageReadCountEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pageReadCount',
        value: value,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      pageReadCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'pageReadCount',
        value: value,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> pageReadCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'pageReadCount',
        value: value,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> pageReadCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'pageReadCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> partitionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'partition',
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> partitionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'partition',
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> partitionEqualTo(
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

  QueryBuilder<Progress, Progress, QAfterFilterCondition> partitionGreaterThan(
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

  QueryBuilder<Progress, Progress, QAfterFilterCondition> partitionLessThan(
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

  QueryBuilder<Progress, Progress, QAfterFilterCondition> partitionBetween(
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

  QueryBuilder<Progress, Progress, QAfterFilterCondition> partitionStartsWith(
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

  QueryBuilder<Progress, Progress, QAfterFilterCondition> partitionEndsWith(
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

  QueryBuilder<Progress, Progress, QAfterFilterCondition> partitionContains(
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

  QueryBuilder<Progress, Progress, QAfterFilterCondition> partitionMatches(
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

  QueryBuilder<Progress, Progress, QAfterFilterCondition> partitionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'partition',
        value: '',
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      partitionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'partition',
        value: '',
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> profileIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'profileId',
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> profileIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'profileId',
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> profileIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'profileId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> profileIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'profileId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> profileIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'profileId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> profileIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'profileId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> profileIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'profileId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> profileIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'profileId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> profileIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'profileId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> profileIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'profileId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> profileIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'profileId',
        value: '',
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      profileIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'profileId',
        value: '',
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      progressElementEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'progress',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      progressElementGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'progress',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      progressElementLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'progress',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      progressElementBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'progress',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> progressLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'progress',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> progressIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'progress',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> progressIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'progress',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      progressLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'progress',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      progressLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'progress',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> progressLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'progress',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> ratingEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rating',
        value: value,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> ratingGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rating',
        value: value,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> ratingLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rating',
        value: value,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> ratingBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rating',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      readPracticeWordsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'readPracticeWords',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      readPracticeWordsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'readPracticeWords',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      readPracticeWordsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'readPracticeWords',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      readPracticeWordsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'readPracticeWords',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      readPracticeWordsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'readPracticeWords',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      readPracticeWordsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'readPracticeWords',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      readPracticeWordsElementContains(String value,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'readPracticeWords',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      readPracticeWordsElementMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'readPracticeWords',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      readPracticeWordsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'readPracticeWords',
        value: '',
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      readPracticeWordsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'readPracticeWords',
        value: '',
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      readPracticeWordsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'readPracticeWords',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      readPracticeWordsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'readPracticeWords',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      readPracticeWordsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'readPracticeWords',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      readPracticeWordsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'readPracticeWords',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      readPracticeWordsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'readPracticeWords',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      readPracticeWordsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'readPracticeWords',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> readToMeTimeEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'readToMeTime',
        value: value,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      readToMeTimeGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'readToMeTime',
        value: value,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> readToMeTimeLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'readToMeTime',
        value: value,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> readToMeTimeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'readToMeTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      readWordsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'readWords',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      readWordsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'readWords',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      readWordsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'readWords',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      readWordsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'readWords',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      readWordsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'readWords',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      readWordsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'readWords',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      readWordsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'readWords',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      readWordsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'readWords',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      readWordsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'readWords',
        value: '',
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      readWordsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'readWords',
        value: '',
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      readWordsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'readWords',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> readWordsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'readWords',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      readWordsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'readWords',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      readWordsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'readWords',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      readWordsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'readWords',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      readWordsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'readWords',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> readingTimeEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'readingTime',
        value: value,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      readingTimeGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'readingTime',
        value: value,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> readingTimeLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'readingTime',
        value: value,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> readingTimeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'readingTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> syncStatusEqualTo(
      SyncStatus value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncStatus',
        value: value,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> syncStatusGreaterThan(
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

  QueryBuilder<Progress, Progress, QAfterFilterCondition> syncStatusLessThan(
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

  QueryBuilder<Progress, Progress, QAfterFilterCondition> syncStatusBetween(
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

  QueryBuilder<Progress, Progress, QAfterFilterCondition> tableNameEqualTo(
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

  QueryBuilder<Progress, Progress, QAfterFilterCondition> tableNameGreaterThan(
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

  QueryBuilder<Progress, Progress, QAfterFilterCondition> tableNameLessThan(
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

  QueryBuilder<Progress, Progress, QAfterFilterCondition> tableNameBetween(
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

  QueryBuilder<Progress, Progress, QAfterFilterCondition> tableNameStartsWith(
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

  QueryBuilder<Progress, Progress, QAfterFilterCondition> tableNameEndsWith(
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

  QueryBuilder<Progress, Progress, QAfterFilterCondition> tableNameContains(
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

  QueryBuilder<Progress, Progress, QAfterFilterCondition> tableNameMatches(
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

  QueryBuilder<Progress, Progress, QAfterFilterCondition> tableNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tableName',
        value: '',
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      tableNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'tableName',
        value: '',
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> updatedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'updatedAt',
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> updatedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'updatedAt',
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> updatedAtEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> updatedAtGreaterThan(
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

  QueryBuilder<Progress, Progress, QAfterFilterCondition> updatedAtLessThan(
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

  QueryBuilder<Progress, Progress, QAfterFilterCondition> updatedAtBetween(
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

  QueryBuilder<Progress, Progress, QAfterFilterCondition> viewingTimeEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'viewingTime',
        value: value,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition>
      viewingTimeGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'viewingTime',
        value: value,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> viewingTimeLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'viewingTime',
        value: value,
      ));
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> viewingTimeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'viewingTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ProgressQueryObject
    on QueryBuilder<Progress, Progress, QFilterCondition> {
  QueryBuilder<Progress, Progress, QAfterFilterCondition> correctWordsElement(
      FilterQuery<ProgressCorrectWords> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'correctWords');
    });
  }

  QueryBuilder<Progress, Progress, QAfterFilterCondition> incorrectWordsElement(
      FilterQuery<ProgressCorrectWords> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'incorrectWords');
    });
  }
}

extension ProgressQueryLinks
    on QueryBuilder<Progress, Progress, QFilterCondition> {}

extension ProgressQuerySortBy on QueryBuilder<Progress, Progress, QSortBy> {
  QueryBuilder<Progress, Progress, QAfterSortBy> sortByAccuracy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accuracy', Sort.asc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> sortByAccuracyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accuracy', Sort.desc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> sortByBookId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bookId', Sort.asc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> sortByBookIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bookId', Sort.desc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> sortByBookLanguage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bookLanguage', Sort.asc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> sortByBookLanguageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bookLanguage', Sort.desc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> sortByCompletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.asc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> sortByCompletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.desc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> sortByCurrentPage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentPage', Sort.asc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> sortByCurrentPageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentPage', Sort.desc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> sortByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> sortByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> sortByFluency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fluency', Sort.asc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> sortByFluencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fluency', Sort.desc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> sortByHasListeners() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasListeners', Sort.asc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> sortByHasListenersDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasListeners', Sort.desc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> sortByLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'level', Sort.asc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> sortByLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'level', Sort.desc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> sortByMetadata() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadata', Sort.asc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> sortByMetadataDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadata', Sort.desc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> sortByPageReadCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pageReadCount', Sort.asc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> sortByPageReadCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pageReadCount', Sort.desc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> sortByPartition() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partition', Sort.asc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> sortByPartitionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partition', Sort.desc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> sortByProfileId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profileId', Sort.asc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> sortByProfileIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profileId', Sort.desc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> sortByRating() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rating', Sort.asc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> sortByRatingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rating', Sort.desc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> sortByReadToMeTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'readToMeTime', Sort.asc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> sortByReadToMeTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'readToMeTime', Sort.desc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> sortByReadingTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'readingTime', Sort.asc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> sortByReadingTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'readingTime', Sort.desc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> sortBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> sortBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> sortByTableName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tableName', Sort.asc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> sortByTableNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tableName', Sort.desc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> sortByViewingTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'viewingTime', Sort.asc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> sortByViewingTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'viewingTime', Sort.desc);
    });
  }
}

extension ProgressQuerySortThenBy
    on QueryBuilder<Progress, Progress, QSortThenBy> {
  QueryBuilder<Progress, Progress, QAfterSortBy> thenByAccuracy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accuracy', Sort.asc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> thenByAccuracyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accuracy', Sort.desc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> thenByBookId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bookId', Sort.asc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> thenByBookIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bookId', Sort.desc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> thenByBookLanguage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bookLanguage', Sort.asc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> thenByBookLanguageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bookLanguage', Sort.desc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> thenByCompletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.asc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> thenByCompletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.desc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> thenByCurrentPage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentPage', Sort.asc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> thenByCurrentPageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentPage', Sort.desc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> thenByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> thenByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> thenByFluency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fluency', Sort.asc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> thenByFluencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fluency', Sort.desc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> thenByHasListeners() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasListeners', Sort.asc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> thenByHasListenersDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasListeners', Sort.desc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> thenByLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'level', Sort.asc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> thenByLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'level', Sort.desc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> thenByLocalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localId', Sort.asc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> thenByLocalIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localId', Sort.desc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> thenByMetadata() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadata', Sort.asc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> thenByMetadataDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadata', Sort.desc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> thenByPageReadCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pageReadCount', Sort.asc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> thenByPageReadCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pageReadCount', Sort.desc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> thenByPartition() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partition', Sort.asc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> thenByPartitionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partition', Sort.desc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> thenByProfileId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profileId', Sort.asc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> thenByProfileIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profileId', Sort.desc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> thenByRating() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rating', Sort.asc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> thenByRatingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rating', Sort.desc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> thenByReadToMeTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'readToMeTime', Sort.asc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> thenByReadToMeTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'readToMeTime', Sort.desc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> thenByReadingTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'readingTime', Sort.asc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> thenByReadingTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'readingTime', Sort.desc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> thenBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> thenBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> thenByTableName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tableName', Sort.asc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> thenByTableNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tableName', Sort.desc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> thenByViewingTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'viewingTime', Sort.asc);
    });
  }

  QueryBuilder<Progress, Progress, QAfterSortBy> thenByViewingTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'viewingTime', Sort.desc);
    });
  }
}

extension ProgressQueryWhereDistinct
    on QueryBuilder<Progress, Progress, QDistinct> {
  QueryBuilder<Progress, Progress, QDistinct> distinctByAccuracies() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'accuracies');
    });
  }

  QueryBuilder<Progress, Progress, QDistinct> distinctByAccuracy() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'accuracy');
    });
  }

  QueryBuilder<Progress, Progress, QDistinct> distinctByBookId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bookId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Progress, Progress, QDistinct> distinctByBookLanguage(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bookLanguage', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Progress, Progress, QDistinct> distinctByCompletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'completedAt');
    });
  }

  QueryBuilder<Progress, Progress, QDistinct> distinctByCorrect() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'correct');
    });
  }

  QueryBuilder<Progress, Progress, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<Progress, Progress, QDistinct> distinctByCurrentPage() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currentPage');
    });
  }

  QueryBuilder<Progress, Progress, QDistinct> distinctByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deletedAt');
    });
  }

  QueryBuilder<Progress, Progress, QDistinct> distinctByFluencies() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fluencies');
    });
  }

  QueryBuilder<Progress, Progress, QDistinct> distinctByFluency() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fluency');
    });
  }

  QueryBuilder<Progress, Progress, QDistinct> distinctByHasListeners() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hasListeners');
    });
  }

  QueryBuilder<Progress, Progress, QDistinct> distinctById(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'id', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Progress, Progress, QDistinct> distinctByLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'level');
    });
  }

  QueryBuilder<Progress, Progress, QDistinct> distinctByMarkers() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'markers');
    });
  }

  QueryBuilder<Progress, Progress, QDistinct> distinctByMetadata(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'metadata', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Progress, Progress, QDistinct> distinctByPageReadCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pageReadCount');
    });
  }

  QueryBuilder<Progress, Progress, QDistinct> distinctByPartition(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'partition', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Progress, Progress, QDistinct> distinctByProfileId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'profileId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Progress, Progress, QDistinct> distinctByProgress() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'progress');
    });
  }

  QueryBuilder<Progress, Progress, QDistinct> distinctByRating() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rating');
    });
  }

  QueryBuilder<Progress, Progress, QDistinct> distinctByReadPracticeWords() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'readPracticeWords');
    });
  }

  QueryBuilder<Progress, Progress, QDistinct> distinctByReadToMeTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'readToMeTime');
    });
  }

  QueryBuilder<Progress, Progress, QDistinct> distinctByReadWords() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'readWords');
    });
  }

  QueryBuilder<Progress, Progress, QDistinct> distinctByReadingTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'readingTime');
    });
  }

  QueryBuilder<Progress, Progress, QDistinct> distinctBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncStatus');
    });
  }

  QueryBuilder<Progress, Progress, QDistinct> distinctByTableName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tableName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Progress, Progress, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<Progress, Progress, QDistinct> distinctByViewingTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'viewingTime');
    });
  }
}

extension ProgressQueryProperty
    on QueryBuilder<Progress, Progress, QQueryProperty> {
  QueryBuilder<Progress, int, QQueryOperations> localIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localId');
    });
  }

  QueryBuilder<Progress, List<double>, QQueryOperations> accuraciesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'accuracies');
    });
  }

  QueryBuilder<Progress, double, QQueryOperations> accuracyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'accuracy');
    });
  }

  QueryBuilder<Progress, String?, QQueryOperations> bookIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bookId');
    });
  }

  QueryBuilder<Progress, LibraryLanguage, QQueryOperations>
      bookLanguageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bookLanguage');
    });
  }

  QueryBuilder<Progress, int?, QQueryOperations> completedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'completedAt');
    });
  }

  QueryBuilder<Progress, List<bool>, QQueryOperations> correctProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'correct');
    });
  }

  QueryBuilder<Progress, List<ProgressCorrectWords>, QQueryOperations>
      correctWordsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'correctWords');
    });
  }

  QueryBuilder<Progress, DateTime?, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<Progress, int, QQueryOperations> currentPageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currentPage');
    });
  }

  QueryBuilder<Progress, DateTime?, QQueryOperations> deletedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deletedAt');
    });
  }

  QueryBuilder<Progress, List<double>, QQueryOperations> fluenciesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fluencies');
    });
  }

  QueryBuilder<Progress, double, QQueryOperations> fluencyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fluency');
    });
  }

  QueryBuilder<Progress, bool, QQueryOperations> hasListenersProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hasListeners');
    });
  }

  QueryBuilder<Progress, String?, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Progress, List<ProgressCorrectWords>, QQueryOperations>
      incorrectWordsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'incorrectWords');
    });
  }

  QueryBuilder<Progress, int, QQueryOperations> levelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'level');
    });
  }

  QueryBuilder<Progress, List<String>, QQueryOperations> markersProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'markers');
    });
  }

  QueryBuilder<Progress, String, QQueryOperations> metadataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'metadata');
    });
  }

  QueryBuilder<Progress, int, QQueryOperations> pageReadCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pageReadCount');
    });
  }

  QueryBuilder<Progress, String?, QQueryOperations> partitionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'partition');
    });
  }

  QueryBuilder<Progress, String?, QQueryOperations> profileIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'profileId');
    });
  }

  QueryBuilder<Progress, List<double>, QQueryOperations> progressProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'progress');
    });
  }

  QueryBuilder<Progress, int, QQueryOperations> ratingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rating');
    });
  }

  QueryBuilder<Progress, List<String>, QQueryOperations>
      readPracticeWordsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'readPracticeWords');
    });
  }

  QueryBuilder<Progress, int, QQueryOperations> readToMeTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'readToMeTime');
    });
  }

  QueryBuilder<Progress, List<String>, QQueryOperations> readWordsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'readWords');
    });
  }

  QueryBuilder<Progress, int, QQueryOperations> readingTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'readingTime');
    });
  }

  QueryBuilder<Progress, SyncStatus, QQueryOperations> syncStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncStatus');
    });
  }

  QueryBuilder<Progress, String, QQueryOperations> tableNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tableName');
    });
  }

  QueryBuilder<Progress, DateTime?, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<Progress, int, QQueryOperations> viewingTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'viewingTime');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const ProgressCorrectWordsSchema = Schema(
  name: r'ProgressCorrectWords',
  id: 5689098693382831636,
  properties: {
    r'correct': PropertySchema(
      id: 0,
      name: r'correct',
      type: IsarType.bool,
    ),
    r'hashCode': PropertySchema(
      id: 1,
      name: r'hashCode',
      type: IsarType.long,
    ),
    r'word': PropertySchema(
      id: 2,
      name: r'word',
      type: IsarType.string,
    )
  },
  estimateSize: _progressCorrectWordsEstimateSize,
  serialize: _progressCorrectWordsSerialize,
  deserialize: _progressCorrectWordsDeserialize,
  deserializeProp: _progressCorrectWordsDeserializeProp,
);

int _progressCorrectWordsEstimateSize(
  ProgressCorrectWords object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.word.length * 3;
  return bytesCount;
}

void _progressCorrectWordsSerialize(
  ProgressCorrectWords object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.correct);
  writer.writeLong(offsets[1], object.hashCode);
  writer.writeString(offsets[2], object.word);
}

ProgressCorrectWords _progressCorrectWordsDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ProgressCorrectWords();
  object.correct = reader.readBool(offsets[0]);
  object.word = reader.readString(offsets[2]);
  return object;
}

P _progressCorrectWordsDeserializeProp<P>(
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
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension ProgressCorrectWordsQueryFilter on QueryBuilder<ProgressCorrectWords,
    ProgressCorrectWords, QFilterCondition> {
  QueryBuilder<ProgressCorrectWords, ProgressCorrectWords,
      QAfterFilterCondition> correctEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'correct',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressCorrectWords, ProgressCorrectWords,
      QAfterFilterCondition> hashCodeEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hashCode',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressCorrectWords, ProgressCorrectWords,
      QAfterFilterCondition> hashCodeGreaterThan(
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

  QueryBuilder<ProgressCorrectWords, ProgressCorrectWords,
      QAfterFilterCondition> hashCodeLessThan(
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

  QueryBuilder<ProgressCorrectWords, ProgressCorrectWords,
      QAfterFilterCondition> hashCodeBetween(
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

  QueryBuilder<ProgressCorrectWords, ProgressCorrectWords,
      QAfterFilterCondition> wordEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'word',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressCorrectWords, ProgressCorrectWords,
      QAfterFilterCondition> wordGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'word',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressCorrectWords, ProgressCorrectWords,
      QAfterFilterCondition> wordLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'word',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressCorrectWords, ProgressCorrectWords,
      QAfterFilterCondition> wordBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'word',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressCorrectWords, ProgressCorrectWords,
      QAfterFilterCondition> wordStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'word',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressCorrectWords, ProgressCorrectWords,
      QAfterFilterCondition> wordEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'word',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressCorrectWords, ProgressCorrectWords,
          QAfterFilterCondition>
      wordContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'word',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressCorrectWords, ProgressCorrectWords,
          QAfterFilterCondition>
      wordMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'word',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressCorrectWords, ProgressCorrectWords,
      QAfterFilterCondition> wordIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'word',
        value: '',
      ));
    });
  }

  QueryBuilder<ProgressCorrectWords, ProgressCorrectWords,
      QAfterFilterCondition> wordIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'word',
        value: '',
      ));
    });
  }
}

extension ProgressCorrectWordsQueryObject on QueryBuilder<ProgressCorrectWords,
    ProgressCorrectWords, QFilterCondition> {}

// **************************************************************************
// Model2Generator
// **************************************************************************

// Progress model generator
extension $Progress on Progress {
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

    map['profileId'] = profileId;
    map['bookId'] = bookId;
    map['currentPage'] = currentPage;
    map['rating'] = rating;
    map['bookLanguage'] = EnumToString.convertToString(bookLanguage);
    map['progress'] = progress;
    map['correct'] = correct;
    map['fluency'] = fluency;
    map['accuracy'] = accuracy;
    map['accuracies'] = accuracies;
    map['fluencies'] = fluencies;
    map['level'] = level;
    map['pageReadCount'] = pageReadCount;
    map['readToMeTime'] = readToMeTime;
    map['readingTime'] = readingTime;
    map['viewingTime'] = viewingTime;
    map['completedAt'] = completedAt;
    map['markers'] = markers;
    map['readWords'] = readWords.toSet().toList();
    map['readPracticeWords'] = readPracticeWords.toSet().toList();
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

    if (map['profileId'] != null) {
      profileId = map['profileId'];
    }
    keys.add('profileId');

    if (map['bookId'] != null) {
      bookId = map['bookId'];
    }
    keys.add('bookId');

    if (map['currentPage'] != null) {
      currentPage = map['currentPage'].toInt();
    }
    keys.add('currentPage');

    if (map['rating'] != null) {
      rating = map['rating'].toInt();
    }
    keys.add('rating');

    if (map['bookLanguage'] != null) {
      final value =
          EnumToString.fromString(LibraryLanguage.values, map['bookLanguage']);
      if (value != null) {
        bookLanguage = value;
      }
    }
    keys.add('bookLanguage');

    progress = List<double>.from(
        map['progress']?.map((e) => e.toDouble()).toList() ?? <double>[]);
    keys.add('progress');

    correct = List<bool>.from((map['correct'] as List?)?.nonNulls ?? <bool>[]);
    keys.add('correct');

    if (map['fluency'] != null) {
      fluency =
          map['fluency'] is int ? map['fluency'].toDouble() : map['fluency'];
    }
    keys.add('fluency');

    if (map['accuracy'] != null) {
      accuracy =
          map['accuracy'] is int ? map['accuracy'].toDouble() : map['accuracy'];
    }
    keys.add('accuracy');

    accuracies = List<double>.from(
        map['accuracies']?.map((e) => e.toDouble()).toList() ?? <double>[]);
    keys.add('accuracies');

    fluencies = List<double>.from(
        map['fluencies']?.map((e) => e.toDouble()).toList() ?? <double>[]);
    keys.add('fluencies');

    if (map['level'] != null) {
      level = map['level'].toInt();
    }
    keys.add('level');

    if (map['pageReadCount'] != null) {
      pageReadCount = map['pageReadCount'].toInt();
    }
    keys.add('pageReadCount');

    if (map['readToMeTime'] != null) {
      readToMeTime = map['readToMeTime'].toInt();
    }
    keys.add('readToMeTime');

    if (map['readingTime'] != null) {
      readingTime = map['readingTime'].toInt();
    }
    keys.add('readingTime');

    if (map['viewingTime'] != null) {
      viewingTime = map['viewingTime'].toInt();
    }
    keys.add('viewingTime');

    if (map['completedAt'] != null) {
      completedAt = map['completedAt'].toInt();
    }
    keys.add('completedAt');

    markers =
        List<String>.from((map['markers'] as List?)?.nonNulls ?? <String>[]);
    keys.add('markers');

    readWords =
        Set<String>.from((map['readWords'] as List?)?.nonNulls ?? <String>[])
            .toList();
    keys.add('readWords');

    readPracticeWords = Set<String>.from(
            (map['readPracticeWords'] as List?)?.nonNulls ?? <String>[])
        .toList();
    keys.add('readPracticeWords');

    return keys;
  }

  Set<String> get keys {
    final result = <String>{};
    result.add('profileId');
    result.add('bookId');
    result.add('currentPage');
    result.add('rating');
    result.add('bookLanguage');
    result.add('progress');
    result.add('correct');
    result.add('fluency');
    result.add('accuracy');
    result.add('accuracies');
    result.add('fluencies');
    result.add('level');
    result.add('pageReadCount');
    result.add('readToMeTime');
    result.add('readingTime');
    result.add('viewingTime');
    result.add('completedAt');
    result.add('markers');
    result.add('readWords');
    result.add('readPracticeWords');
    return result;
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

      await saveInternal(() async {
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
        await Sync.shared.db.local.progress.put(this);
      });
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
  static Future<List<Progress>> all({bool filterDeletedAt = true}) {
    final collection = Sync.shared.db.local.progress;
    return filterDeletedAt
        ? collection.filter().getAll()
        : collection.where().findAll();
  }

  /// Find record by id
  static Future<Progress?> find(String? id,
      {bool filterDeletedAt = true}) async {
    final filter = await Sync.shared.db.local.progress.filter().idEqualTo(id);
    return filterDeletedAt ? filter.getFirst() : filter.findFirst();
  }

  /// List records by sync status
  static Future<List<Progress>> queryStatus(SyncStatus status,
      {bool filterDeletedAt = true}) async {
    final filter =
        await Sync.shared.db.local.progress.filter().syncStatusEqualTo(status);
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
        await db.progress.delete(localId);
      });
    }
  }

  /// Clear all records and reset the auto increment value
  Future<void> clear() {
    return db.progress.clear();
  }

  Set<String> compare(Progress other) {
    final result = <String>{};
    if (deletedAt != other.deletedAt) {
      result.add('deletedAt');
    }

    if (profileId != other.profileId) {
      result.add('profileId');
    }

    if (bookId != other.bookId) {
      result.add('bookId');
    }

    if (currentPage != other.currentPage) {
      result.add('currentPage');
    }

    if (rating != other.rating) {
      result.add('rating');
    }

    if (bookLanguage != other.bookLanguage) {
      result.add('bookLanguage');
    }

    if (!DeepCollectionEquality().equals(progress, other.progress)) {
      result.add('progress');
    }

    if (!DeepCollectionEquality().equals(correct, other.correct)) {
      result.add('correct');
    }

    if (fluency != other.fluency) {
      result.add('fluency');
    }

    if (accuracy != other.accuracy) {
      result.add('accuracy');
    }

    if (!DeepCollectionEquality().equals(accuracies, other.accuracies)) {
      result.add('accuracies');
    }

    if (!DeepCollectionEquality().equals(fluencies, other.fluencies)) {
      result.add('fluencies');
    }

    if (level != other.level) {
      result.add('level');
    }

    if (pageReadCount != other.pageReadCount) {
      result.add('pageReadCount');
    }

    if (!DeepCollectionEquality().equals(correctWords, other.correctWords)) {
      result.add('correctWords');
    }

    if (!DeepCollectionEquality()
        .equals(incorrectWords, other.incorrectWords)) {
      result.add('incorrectWords');
    }

    if (readToMeTime != other.readToMeTime) {
      result.add('readToMeTime');
    }

    if (readingTime != other.readingTime) {
      result.add('readingTime');
    }

    if (viewingTime != other.viewingTime) {
      result.add('viewingTime');
    }

    if (completedAt != other.completedAt) {
      result.add('completedAt');
    }

    if (!DeepCollectionEquality().equals(markers, other.markers)) {
      result.add('markers');
    }

    if (!DeepCollectionEquality().equals(readWords, other.readWords)) {
      result.add('readWords');
    }

    if (!DeepCollectionEquality()
        .equals(readPracticeWords, other.readPracticeWords)) {
      result.add('readPracticeWords');
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
    final where = Sync.shared.db.local.progress.where();
    if (callback != null) {
      await where.exportJsonRaw(callback);
      return [];
    }

    return where.exportJson();
  }

  /// Import json into this collection
  Future<void> importJson(dynamic jsonData) async {
    if (jsonData is Uint8List) {
      await Sync.shared.db.local.progress.importJsonRaw(jsonData);
    } else if (jsonData is List<Map<String, dynamic>>) {
      await Sync.shared.db.local.progress.importJson(jsonData);
    } else {
      throw UnsupportedError('Json type is not supported');
    }
  }
}

extension ProgressQAfterFilterCondition
    on QueryBuilder<Progress, Progress, QAfterFilterCondition> {
  Future<List<Progress>> getAll() async {
    return deletedAtIsNull().findAll();
  }

  Future<Progress?> getFirst() async {
    return deletedAtIsNull().findFirst();
  }
}

extension ProgressQFilterCondition
    on QueryBuilder<Progress, Progress, QFilterCondition> {
  Future<List<Progress>> getAll() async {
    return deletedAtIsNull().findAll();
  }

  Future<Progress?> getFirst() async {
    return deletedAtIsNull().findFirst();
  }
}

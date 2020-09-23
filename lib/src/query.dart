import 'package:intl/intl.dart';
import 'abstract.dart';

/// Based on https://guides.rubyonrails.org/active_record_querying.html
class Query {
  Query(this.tableName);

  bool caseSensitive = false;
  dynamic condition;
  Database database;
  String filterOperator = 'and';
  int index;
  Function instantiateModel;
  bool isMatches; // is search text mode
  String ordering;
  int resultLimit;
  String tableName;

  /// Sets the condition on the query and other optionals
  /// The condition can only be a Null, String or Map of field and equality value
  ///
  /// *String query*: `Query(table).where('column <= 3')`
  ///
  /// *Accepted operators*: `<`, `<=`, `=`, `>`, `>=`, `[matches]`, `is`, `not`
  ///
  /// *Map query*: `Query(table).where({"column1" : 3, "column2": "a"})`
  /// The `filterOperator` must be `and` or `or`
  /// It's equals: `column1 = 3 {filterOperator} column2 = "a"`
  ///
  Query where(
      [dynamic condition,
      Database database,
      Function instantiateModel,
      String filterOperator,
      bool isMatches]) {
    if (condition is String || condition is Map || condition == null) {
      if (filterOperator != null &&
          filterOperator.toLowerCase() != 'and' &&
          filterOperator.toLowerCase() != 'or') {
        throw QueryException();
      }

      _set(instantiateModel, database);
      this.condition = condition;
      if (filterOperator != null) {
        this.filterOperator = filterOperator;
      }

      this.isMatches = isMatches;

      return this;
    }
    throw QueryException();
  }

  /// Sets the sort order on the query and other optionals
  Query order([String order, Database database, Function instantiateModel]) {
    _set(instantiateModel, database);
    ordering = order;
    return this;
  }

  /// Set the limit on the number of results
  Query limit([int limit, Database database, Function instantiateModel]) {
    _set(instantiateModel, database);
    resultLimit = limit;
    return this;
  }

  /// Start the first result at the offset
  Query offset([int index, Database database, Function instantiateModel]) {
    _set(instantiateModel, database);
    this.index = index;
    return this;
  }

  /// Set the query is matched
  Query matches(
      [bool isMatches,
      bool caseSensitive,
      Database database,
      Function instantiateModel]) {
    _set(instantiateModel, database);
    this.isMatches = isMatches;
    this.caseSensitive = caseSensitive;
    return this;
  }

  /// Loads the query results into a List
  Future<List> load({listenable = true}) {
    return database.query(this, listenable: listenable);
  }

  /// Sets instantiateModel function and database
  void _set(Function instantiateModel, Database database) {
    if (instantiateModel != null) {
      this.instantiateModel = instantiateModel;
    }
    if (database != null) {
      this.database = database;
    }
  }
}

class QueryException implements Exception {
  @override
  String toString() =>
      Intl.message('Query was incorrectly constructed.', name: 'queryFailure');
}

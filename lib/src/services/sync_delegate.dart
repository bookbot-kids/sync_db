/// The external sync delegate
/// Client app uses this one to inject data with the same format into database
abstract class SyncDelegate {
  /// Sync read data for a table.
  /// The `token` param can be null.
  /// Return a list of records (must not be null)
  /// Make sure the data list is correct format
  Future<List> syncRead(String? token);

  /// The sync table name
  String get tableName;
}

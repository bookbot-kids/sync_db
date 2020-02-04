import "abstract.dart";
import "query.dart";
import "robust_http.dart";

class CosmosSync extends Sync {
  static CosmosSync shared;
  HTTP http;
  Database _database;
  User _user;
  
  Map<String, DateTime> _tableReadLock = {};
  Map<String, DateTime> _tableWriteLock = {};

  /// Configure the Cosmos DB, which in this case is the DB url
  /// This will require the `databaseAccount` name, and database id `dbId` in the config map
  static Future<void> config(Map config) {
    shared = CosmosSync();
    shared.http = HTTP('https://${config["databaseAccount"]}.documents.azure.com/dbs/${config["dbId"]}/');
  }

  /// SyncAll will run the sync across the complete database.
  /// Cosmos has a resource token structure so it knows which tables have read or write sync.
  Future<void> syncAll() async {
    final resourceTokens = await _user.resourceTokens();
    final keys = resourceTokens.keys;

    // Loop through tables to read sync
    for (final tableName in keys) {
      await syncRead(tableName);
    }

    // Loop through tables to write sync
    for (final tableName in keys) {
      if (resourceTokens[tableName]["permissionMode"] == "All") {
        await syncWrite(tableName);
      }
    }
  }

  /// Read sync this table if it is not locked.
  Future<void> syncRead(String table) async {
    // Check if table is locked and return if it is
    if (_tableWriteLock[table] != null && _tableWriteLock[table].isAfter(DateTime.now())) {
      return;
    }

    // Lock this specific table for reading
    _tableWriteLock[table] = DateTime.now().add(Duration(minutes: 1));

    // Get the last record change timestamp on server side
    final query = Query().order("_ts desc").limit(1);
    final record = _database.query(query)[0];
    String select;
    if (record == null || (record != null && record["_ts"] == null)) {
      select = "SELECT * FROM $table";
    }
    else {
      select = "SELECT * FROM $table WHERE _ts > ${record["_ts"]}";
    }
    final parameters = {"query": select};



    // Get updated records from last _ts timestamp as a map
    // Compare who has the newer _ts or updated_at (if status is _updated), and use that
    // Save complete cosmos document into sembast
  }

  /// Write sync this table if it has permission and is not locked.
  Future<void> syncWrite(String table) async {
    // Check if table is locked and return if it is
    if (_tableReadLock[table] != null && _tableReadLock[table].isAfter(DateTime.now())) {
      return;
    }
    // Check if we have write permission on table
    final resourceTokens = await _user.resourceTokens();
    if (resourceTokens[table]["permissionMode"] != "All") {
      return;
    }

    // Lock this specific table for reading
    _tableReadLock[table] = DateTime.now().add(Duration(minutes: 1));

    // Get created records and save to Cosmos DB
    var query = Query().where({"_status": "createdAt"}).order("createdAt asc");
    var records = _database.query<Map>(query);

    for (final record in records) {

    }

    // Get records that have been updated and update Cosmos
    query = Query().where({"_status": "updatedAt"}).order("updatedAt asc");
    records = _database.query<Map>(query);

    for (final record in records) {

    }




    // Get models marked created/updated
    // Get record if updated and compare record to save (for time being - until we add notifications)
    // Save record
    // see if there are any new updated records after this to upload
  }
}

String tellMe() => "something";
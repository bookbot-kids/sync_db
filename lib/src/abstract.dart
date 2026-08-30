import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sync_db/sync_db.dart';

const statusKey = '_status';
const idKey = 'id';
const updatedKey = 'updatedAt';
const createdKey = 'createdAt';
const deletedKey = 'deletedAt';
const partitionKey = 'partition';

abstract class UserSession {
  /// set login token. In azure b2c, it's id token
  Future<void> setToken(String token, {bool waitingRefresh = false});

  Future<String?> get token;

  /// Get new token
  Future<void> refresh({bool forceRefreshToken = false, String? userId});

  /// provide list of table with read/write permission
  Future<List<ServicePoint>> servicePoints();

  /// provide permission for a table
  Future<List<ServicePoint>> servicePointsForTable(String table);

  Future<bool> hasSignedIn();

  /// user role
  String? get role;

  /// get email
  String? get email;

  /// sign out user & clear all private keys
  Future<void> signout({bool notify = true});

  /// provide storage token to upload/download file
  Future<String?> get storageToken;

  /// delete user
  Future<void> deleteUser(String email);

  /// The tables to request resource tokens for.
  ///
  /// An entry may carry a qualifier - `Book:bookbot` - which asks the token
  /// service for a permission scoped to that partition. Use this when the
  /// qualifier is only known at runtime (a profile's reading framework, for
  /// example) rather than at construction.
  ///
  /// Returns true when the list actually changed, so the caller can decide
  /// whether a [refresh] is needed.
  bool setTablesToSync(List<String> tables) => false;

  /// Current tables (with qualifiers) being synced.
  List<String> get tablesToSync => const [];
}

class Notifier<T> extends ChangeNotifier {
  T _value;
  StackTrace? _sourceTrace;
  Notifier(this._value);

  StackTrace? get sourceTrace => _sourceTrace;

  T get value => _value;

  set value(T value) {
    _value = value;
    refresh();
  }

  // Only update value without call [notifyListeners]
  void updateValue(T value) {
    _value = value;
  }

  void refresh() {
    if (kDebugMode) {
      _sourceTrace = StackTrace.current;
    }

    notifyListeners();
  }
}

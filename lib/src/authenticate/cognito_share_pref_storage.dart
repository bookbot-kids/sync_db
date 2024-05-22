import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:amazon_cognito_identity_dart_2/cognito.dart' as cognito;

/// Cognito shared preference storage, uses to store session keys
class SharedPreferenceStorage extends cognito.CognitoStorage {
  SharedPreferenceStorage(this._prefs);

  final SharedPreferences? _prefs;

  @override
  Future<void> clear() async {
    await _prefs!.clear();
  }

  @override
  Future getItem(String key) async {
    String? item;
    try {
      var value = _prefs!.getString(key);
      if (value != null) {
        item = json.decode(value);
      }
    } catch (e) {
      return null;
    }
    return item;
  }

  @override
  Future removeItem(String key) async {
    final item = await getItem(key);
    if (item != null) {
      await _prefs!.remove(key);
      return item;
    }
    return null;
  }

  @override
  Future setItem(String key, value) async {
    await _prefs!.setString(key, json.encode(value));
    return getItem(key);
  }
}

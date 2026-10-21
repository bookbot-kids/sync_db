// Frozen default-mode behavior from enum_to_string 2.2.1, used only as the
// before-change oracle. Kept local so tests do not retain the removed dependency.
class LegacyEnumToString {
  static String convertToString(dynamic item) {
    assert(item != null);
    final split = item.toString().split('.');
    assert(split.length > 1 && split[0] == item.runtimeType.toString());
    try {
      final dynamic mapping = item.value;
      if (mapping is String) return mapping;
    } catch (_) {
      // The old package ignored absent or throwing custom getters.
    }
    return item.toString().split('.')[1];
  }

  static final Map<String, Map<dynamic, String>> _cache = {};

  static T? fromString<T>(List<T> values, String name) {
    try {
      final cacheKey = '${T.toString()}:false';
      if (!_cache.containsKey(cacheKey)) {
        _cache[cacheKey] = {};
        for (final value in values) {
          _cache[cacheKey]![value] = convertToString(value).toLowerCase();
        }
      }
      for (final entry in _cache[cacheKey]!.entries) {
        if (entry.value == name.toLowerCase()) return entry.key as T;
      }
      return null;
    } on StateError {
      return null;
    }
  }
}

/// Finds an enum by its Dart name, ignoring case.
/// Returns null for unknown names.
T? parseEnum<T extends Enum>(Iterable<T> values, String name) {
  final normalizedName = name.toLowerCase();
  for (final value in values) {
    if (value.name.toLowerCase() == normalizedName) return value;
  }
  return null;
}

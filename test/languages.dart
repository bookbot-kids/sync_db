import 'package:enum_to_string/enum_to_string.dart';

enum Language {
  us,
  gb,
  au,
  es,
  ar,
  vi,
  zh,
  id,
}

extension $Language on Language {
  String get name => EnumToString.convertToString(this);
  static Language fromString(String? value,
      {Language defaultLanguage = Language.us}) {
    if (value?.isNotEmpty == true) {
      return EnumToString.fromString(Language.values, value!) ??
          defaultLanguage;
    }

    return defaultLanguage;
  }
}

Language languageStringToEnum(String language) {
  final languageEnum = EnumToString.fromString(Language.values, language);
  if (languageEnum == null) {
    throw Exception("Unknown language $language");
  }
  return languageEnum;
}

class LanguageGroups {
  static final _groups = {
    "en": [Language.us, Language.gb, Language.au],
    "vi": [Language.vi],
    "es": [Language.es],
    "zh": [Language.zh],
    "ar": [Language.ar],
    "id": [Language.id]
  };

  static List<String> get groups => _groups.keys.toList();

  static List<Language> get english => _groups["en"] ?? [];

  ///
  /// Return the Language(s) belonging to [group]
  ///
  static List<Language> languages(String group) => _groups[group] ?? [];

  ///
  /// Return the group to which [language] belongs.
  ///
  static String group(Language language) {
    return _groups.keys.firstWhere(
        (element) => _groups[element]?.contains(language) == true,
        orElse: () => '');
  }
}

enum LibraryLanguage { en, id }

extension $LibraryLanguage on LibraryLanguage {
  String get name => EnumToString.convertToString(this);
  static LibraryLanguage fromString(String? value,
      {LibraryLanguage defaultLanguage = LibraryLanguage.en}) {
    if (value?.isNotEmpty == true) {
      return EnumToString.fromString(LibraryLanguage.values, value!) ??
          defaultLanguage;
    }

    return defaultLanguage;
  }
}

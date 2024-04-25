class StringUtils {
  static bool isNotNullOrEmpty(String s) => !isNullOrEmpty(s);
  static bool isNullOrEmpty(String s) => (s == null || s.isEmpty) ? true : false;

  static bool equalsIgnoreCase(String a, String b) => a?.toLowerCase() == b?.toLowerCase();
}

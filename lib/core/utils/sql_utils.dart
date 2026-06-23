/// Utilitas deteksi jenis perintah SQL (presentation/domain agnostic).
abstract final class SqlUtils {
  static final _selectPattern = RegExp(r'^\s*select\b', caseSensitive: false);
  static final _dangerousPattern = RegExp(
    r'\b(delete|drop|update|insert|alter|truncate)\b',
    caseSensitive: false,
  );
  static final _complexQueryPattern = RegExp(
    r'\b(join|union|intersect|except|cross)\b',
    caseSensitive: false,
  );
  static final _fromTablePattern = RegExp(
    r'\bfrom\s+([`"\[])?(\w+)\1',
    caseSensitive: false,
  );

  static bool isSelectQuery(String sql) => _selectPattern.hasMatch(sql);

  static bool containsDangerousKeyword(String sql) =>
      _dangerousPattern.hasMatch(sql);

  static bool requiresConfirmation(String sql) =>
      !isSelectQuery(sql) || containsDangerousKeyword(sql);

  /// Apakah query terlalu kompleks untuk auto-select tabel (JOIN, subquery, dll.).
  static bool isComplexSelectQuery(String sql) {
    final trimmed = sql.trim();
    if (!isSelectQuery(trimmed)) return true;
    if (_complexQueryPattern.hasMatch(trimmed)) return true;
    final withoutStrings = trimmed.replaceAll(RegExp(r"'[^']*'"), '');
    if (RegExp(r'\(\s*select\b', caseSensitive: false).hasMatch(withoutStrings)) {
      return true;
    }
    final fromMatches = _fromTablePattern.allMatches(withoutStrings).length;
    return fromMatches != 1;
  }

  /// Ekstrak nama tabel tunggal dari klausa FROM pada SELECT sederhana.
  static String? extractSimpleFromTable(String sql) {
    if (isComplexSelectQuery(sql)) return null;
    final match = _fromTablePattern.firstMatch(sql.trim());
    return match?.group(2);
  }
}

/// Utilitas deteksi jenis perintah SQL (presentation/domain agnostic).
abstract final class DbLensSqlUtils {
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

  /// Buang spasi dan `;` di ujung. Query dibungkus `SELECT * FROM (...)`
  /// untuk pagination/count, jadi `;` penutup akan membuatnya invalid.
  static String stripTrailingSemicolons(String sql) =>
      sql.replaceFirst(RegExp(r'[\s;]+$'), '');

  /// SELECT, read-only WITH/PRAGMA/EXPLAIN — dijalankan lewat jalur query
  /// berpaginasi, bukan [executeStatement].
  static bool isSelectQuery(String sql) {
    final trimmed = sql.trim();
    if (trimmed.isEmpty) return false;

    if (RegExp(r'^\s*select\b', caseSensitive: false).hasMatch(trimmed)) {
      return true;
    }
    if (RegExp(r'^\s*explain\b', caseSensitive: false).hasMatch(trimmed)) {
      return true;
    }
    if (RegExp(r'^\s*pragma\b', caseSensitive: false).hasMatch(trimmed)) {
      return _isReadOnlyPragma(trimmed);
    }
    if (RegExp(r'^\s*with\b', caseSensitive: false).hasMatch(trimmed)) {
      return _isReadOnlyWithQuery(trimmed);
    }
    return false;
  }

  static String _stripSqlStrings(String sql) =>
      sql.replaceAll(RegExp(r"'[^']*'"), '');

  /// PRAGMA dengan assignment (`PRAGMA foo = bar`) bersifat mutating.
  static bool _isReadOnlyPragma(String sql) {
    final normalized = _stripSqlStrings(sql).trim();
    return !RegExp(
      r'^\s*pragma\s+\w+\s*=',
      caseSensitive: false,
    ).hasMatch(normalized);
  }

  /// WITH hanya read-only jika statement utama setelah CTE adalah SELECT.
  /// Kalau tidak bisa dipastikan, treat sebagai non-select (butuh konfirmasi).
  static bool _isReadOnlyWithQuery(String sql) {
    final normalized = _stripSqlStrings(sql).trim();

    if (RegExp(
      r'^\s*with\b[\s\S]*\)\s*(delete|update|insert|replace)\b',
      caseSensitive: false,
    ).hasMatch(normalized)) {
      return false;
    }

    if (RegExp(
      r'^\s*with\b[\s\S]*\)\s*select\b',
      caseSensitive: false,
    ).hasMatch(normalized)) {
      return true;
    }

    return false;
  }

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
    if (RegExp(r'\(\s*select\b', caseSensitive: false)
        .hasMatch(withoutStrings)) {
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

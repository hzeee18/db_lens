/// Utilitas deteksi jenis perintah SQL (presentation/domain agnostic).
abstract final class SqlUtils {
  static final _selectPattern = RegExp(r'^\s*select\b', caseSensitive: false);
  static final _dangerousPattern = RegExp(
    r'\b(delete|drop|update|insert|alter|truncate)\b',
    caseSensitive: false,
  );

  static bool isSelectQuery(String sql) => _selectPattern.hasMatch(sql);

  static bool containsDangerousKeyword(String sql) =>
      _dangerousPattern.hasMatch(sql);

  static bool requiresConfirmation(String sql) =>
      !isSelectQuery(sql) || containsDangerousKeyword(sql);
}

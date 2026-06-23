import 'dart:convert';

/// Utilitas untuk menyiapkan data baris sebagai JSON yang dapat dibaca.
abstract final class JsonViewUtils {
  static const _encoder = JsonEncoder.withIndent('  ');

  /// Siapkan baris untuk tampilan JSON — hapus kolom internal dan parse string JSON.
  static Map<String, Object?> prepareRow(Map<String, Object?> row) {
    final cleaned = Map<String, Object?>.from(row)..remove('_rowid_');
    return cleaned.map(
      (key, value) => MapEntry(key, normalizeValue(value)),
    );
  }

  /// Encode baris sebagai pretty-printed JSON.
  static String encodePretty(Map<String, Object?> row) {
    return _encoder.convert(prepareRow(row));
  }

  /// Encode daftar baris sebagai pretty-printed JSON array.
  static String encodePrettyArray(List<Map<String, Object?>> rows) {
    final prepared = rows.map(prepareRow).toList();
    return _encoder.convert(prepared);
  }

  /// Normalisasi nilai — deteksi dan parse string yang berisi JSON.
  static Object? normalizeValue(Object? value) {
    if (value is String && looksLikeJson(value)) {
      try {
        final decoded = jsonDecode(value);
        return normalizeValue(decoded);
      } catch (_) {
        return value;
      }
    }
    if (value is Map) {
      return value.map(
        (key, val) => MapEntry(key.toString(), normalizeValue(val)),
      );
    }
    if (value is List) {
      return value.map(normalizeValue).toList();
    }
    return value;
  }

  static bool looksLikeJson(String value) {
    final trimmed = value.trim();
    if (trimmed.length < 2) return false;
    final first = trimmed[0];
    final last = trimmed[trimmed.length - 1];
    return (first == '{' && last == '}') || (first == '[' && last == ']');
  }

  /// Parse teks JSON hasil edit menjadi map baris.
  static Map<String, Object?> parseRowJson(String source) {
    final decoded = jsonDecode(source.trim());
    if (decoded is! Map) {
      throw const FormatException('JSON must be an object');
    }
    return _mapFromDynamic(decoded);
  }

  static Map<String, Object?> _mapFromDynamic(Map<dynamic, dynamic> map) {
    return map.map(
      (key, value) => MapEntry(key.toString(), _valueFromDynamic(value)),
    );
  }

  static Object? _valueFromDynamic(Object? value) {
    if (value is Map) return _mapFromDynamic(value);
    if (value is List) {
      return value.map(_valueFromDynamic).toList();
    }
    return value;
  }
}

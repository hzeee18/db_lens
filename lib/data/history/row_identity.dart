import 'dart:convert';

/// Utilitas membangun kunci identitas stabil untuk satu baris.
abstract final class RowIdentity {
  static String of(Map<String, dynamic> row, List<String> identityColumns) {
    if (identityColumns.isEmpty) {
      final cleaned = Map<String, dynamic>.from(row)..remove('_rowid_');
      return jsonEncode(cleaned);
    }

    final identity = <String, dynamic>{
      for (final column in identityColumns) column: row[column],
    };
    return jsonEncode(identity);
  }
}
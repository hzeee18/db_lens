import 'package:flutter/material.dart';

import '../theme/db_lens_theme.dart';

/// Utilitas format, warna, pencarian, dan sort baris di UI.
abstract final class RowUtils {
  static Color valueColor(Object? value, [DbLensTheme? theme]) {
    final t = theme ?? DbLensTheme();
    if (value == null) return t.syntaxNull;
    if (value is bool) return t.syntaxBool;
    if (value is num) return t.syntaxNumber;
    if (value is String || value is List<String>) return t.syntaxString;
    return t.syntaxDefault;
  }

  static String formatValue(Object? value) {
    if (value == null) return 'null';
    if (value is bool) return value.toString();
    if (value is String) return '"$value"';
    if (value is List<String>) return '[${value.map((e) => '"$e"').join(', ')}]';
    return value.toString();
  }

  static String normalizeValue(Object? value) {
    if (value == null) return 'null';
    if (value is String) return value;
    return value.toString();
  }

  static int compareValues(Object? a, Object? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    if (a is num && b is num) return a.compareTo(b);
    if (a is bool && b is bool) return a == b ? 0 : (a ? 1 : -1);
    return normalizeValue(a).toLowerCase().compareTo(
          normalizeValue(b).toLowerCase(),
        );
  }

  static List<Map<String, Object?>> applySearchAndSort({
    required List<Map<String, Object?>> rows,
    required List<String> columns,
    required String searchText,
    required String? sortColumn,
    required bool sortAscending,
  }) {
    var result = List<Map<String, Object?>>.from(rows);
    final query = searchText.trim().toLowerCase();

    if (query.isNotEmpty) {
      result = result.where((row) {
        return columns.any((column) {
          final value = normalizeValue(row[column]).toLowerCase();
          return value.contains(query);
        });
      }).toList();
    }

    if (sortColumn != null) {
      result.sort((a, b) {
        final comparison = compareValues(a[sortColumn], b[sortColumn]);
        return sortAscending ? comparison : -comparison;
      });
    }

    return result;
  }

  static List<String> filterItems(List<String> items, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((item) => item.toLowerCase().contains(q)).toList();
  }
}

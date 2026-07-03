import 'package:flutter/material.dart';

import '../theme/db_lens_theme.dart';

/// Hook untuk render nilai sel kustom (mis. BLOB gambar, epoch timestamp).
///
/// Default: [DbLensValueFormat.format]/[DbLensValueFormat.color] dipakai
/// oleh [DbLensTableView]/[DbLensListView] bila [DbLensValueRenderer] tidak
/// diisi. Konsumen bisa menimpanya tanpa fork widget:
///
/// ```dart
/// DbLensTableView(
///   rows: rows,
///   columns: columns,
///   valueRenderer: (context, value, theme) {
///     if (value is int && value > 1e12) return Text(formatEpoch(value));
///     return Text(DbLensValueFormat.format(value));
///   },
/// )
/// ```
typedef DbLensValueRenderer = Widget Function(
  BuildContext context,
  Object? value,
  DbLensTheme theme,
);

/// Format & warna default untuk nilai sel — dipakai sebagai fallback oleh
/// widget presentasi, dan bisa dipanggil langsung oleh konsumen yang
/// membangun tampilan data sendiri (mis. grid/console kustom).
abstract final class DbLensValueFormat {
  static Color color(Object? value, DbLensTheme theme) {
    if (value == null) return theme.syntaxNull;
    if (value is bool) return theme.syntaxBool;
    if (value is num) return theme.syntaxNumber;
    if (value is String || value is List<String>) return theme.syntaxString;
    return theme.syntaxDefault;
  }

  static String format(Object? value) {
    if (value == null) return 'null';
    if (value is bool) return value.toString();
    if (value is String) return '"$value"';
    if (value is List<String>) {
      return '[${value.map((e) => '"$e"').join(', ')}]';
    }
    return value.toString();
  }
}

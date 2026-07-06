import 'package:flutter/material.dart';

import '../utils/json_view_utils.dart';

/// Satu format ekspor baris (JSON, CSV, dll.) yang bisa ditawarkan lewat
/// toolbar/query console. Bawaan cuma JSON ([dbLensJsonExport]) — format
/// lain (CSV, TSV, dst.) bisa ditambahkan konsumen tanpa menyentuh source
/// `db_lens`:
///
/// ```dart
/// const csvExport = DbLensExportFormat(
///   label: 'CSV',
///   icon: Icons.file_copy_outlined,
///   serialize: toCsv,
/// );
/// ```
class DbLensExportFormat {
  const DbLensExportFormat({
    required this.label,
    required this.icon,
    required this.serialize,
  });

  final String label;
  final IconData icon;
  final String Function(List<Map<String, Object?>> rows) serialize;
}

/// Format ekspor JSON bawaan (pretty-printed, kolom internal disembunyikan).
const dbLensJsonExport = DbLensExportFormat(
  label: 'JSON',
  icon: Icons.data_object_outlined,
  serialize: _encodeJson,
);

String _encodeJson(List<Map<String, Object?>> rows) =>
    DbLensJsonUtils.encodePrettyArray(rows);

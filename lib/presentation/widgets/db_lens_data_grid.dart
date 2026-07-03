import 'package:flutter/material.dart';

import '../hooks/db_lens_value_renderer.dart';
import '../theme/db_lens_theme.dart';

/// Primitive grid murni — hitung lebar kolom, render header + body dengan
/// scroll horizontal+vertikal. Tidak tahu apa itu controller, tidak
/// melakukan side effect apa pun (copy/edit) sendiri — cuma memanggil
/// callback yang diberikan.
///
/// Dipakai langsung untuk tampilan seperti konsol SQL kustom, atau lewat
/// preset [DbLensTableView] untuk tampilan browse standar (kolom index +
/// sort header).
///
/// Catatan: butuh parent dengan tinggi terbatas (mis. `Expanded` di dalam
/// `Column`), sama seperti `ListView` biasa.
class DbLensDataGrid extends StatelessWidget {
  const DbLensDataGrid({
    super.key,
    required this.rows,
    required this.columns,
    this.columnWidths,
    this.minColumnWidth = 90,
    this.maxColumnWidth = 260,
    this.headerBuilder,
    this.cellBuilder,
    this.onCellTap,
    this.onCellLongPress,
    this.leadingWidth,
    this.leadingHeaderBuilder,
    this.leadingBuilder,
  });

  final List<Map<String, Object?>> rows;
  final List<String> columns;

  /// Lebar per kolom. Kalau null, dihitung otomatis dari isi kolom.
  final Map<String, double>? columnWidths;
  final double minColumnWidth;
  final double maxColumnWidth;

  final Widget Function(BuildContext context, String column)? headerBuilder;
  final Widget Function(
    BuildContext context,
    String column,
    Object? value,
    Map<String, Object?> row,
  )? cellBuilder;
  final void Function(String column, Map<String, Object?> row)? onCellTap;
  final void Function(String column, Map<String, Object?> row)?
      onCellLongPress;

  /// Kolom tambahan di paling kiri (mis. nomor baris) — opsional.
  final double? leadingWidth;
  final Widget Function(BuildContext context)? leadingHeaderBuilder;
  final Widget Function(BuildContext context, int rowIndex,
      Map<String, Object?> row)? leadingBuilder;

  static Map<String, double> computeWidths(
    List<String> columns,
    List<Map<String, Object?>> rows, {
    double minWidth = 90,
    double maxWidth = 260,
  }) {
    const charWidth = 7.5;
    final widths = <String, double>{};
    for (final col in columns) {
      var w = col.length * charWidth + 40;
      for (final row in rows.take(60)) {
        final text = DbLensValueFormat.format(row[col]);
        final vw = text.length * charWidth + 28;
        if (vw > w) w = vw;
      }
      widths[col] = w.clamp(minWidth, maxWidth);
    }
    return widths;
  }

  @override
  Widget build(BuildContext context) {
    final theme = DbLensThemeScope.of(context);
    final widths = columnWidths ??
        computeWidths(columns, rows,
            minWidth: minColumnWidth, maxWidth: maxColumnWidth);
    final leading = leadingWidth ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth =
            widths.values.fold<double>(0, (sum, w) => sum + w) + leading;
        final tableWidth =
            contentWidth > constraints.maxWidth ? contentWidth : constraints.maxWidth;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderRow(context, theme, widths),
                Expanded(
                  child: ListView.builder(
                    itemCount: rows.length,
                    itemBuilder: (context, index) =>
                        _buildRow(context, theme, rows[index], index, widths),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderRow(
    BuildContext context,
    DbLensTheme theme,
    Map<String, double> widths,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(bottom: BorderSide(color: theme.border, width: 1.5)),
      ),
      child: Row(
        children: [
          if (leadingWidth != null)
            SizedBox(
              width: leadingWidth,
              child: leadingHeaderBuilder?.call(context) ?? const SizedBox(),
            ),
          for (final column in columns)
            SizedBox(
              width: widths[column],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: headerBuilder?.call(context, column) ??
                    Text(
                      column,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    DbLensTheme theme,
    Map<String, Object?> row,
    int index,
    Map<String, double> widths,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: index.isEven ? theme.bg : theme.surface,
        border: Border(bottom: BorderSide(color: theme.border, width: 0.5)),
      ),
      child: Row(
        children: [
          if (leadingWidth != null)
            SizedBox(
              width: leadingWidth,
              child: leadingBuilder?.call(context, index, row) ??
                  const SizedBox(),
            ),
          for (final column in columns)
            SizedBox(
              width: widths[column],
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onCellTap == null ? null : () => onCellTap!(column, row),
                onLongPress: onCellLongPress == null
                    ? null
                    : () => onCellLongPress!(column, row),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  child: cellBuilder?.call(context, column, row[column], row) ??
                      Text(
                        DbLensValueFormat.format(row[column]),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: DbLensValueFormat.color(row[column], theme),
                          fontSize: 12.5,
                          fontStyle: row[column] == null
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

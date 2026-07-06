import 'package:flutter/material.dart';

import '../theme/db_lens_theme.dart';
import 'db_lens_data_grid.dart';

/// Preset [DbLensDataGrid] untuk tampilan tabel browse standar — kolom
/// nomor baris + header yang bisa di-tap untuk sort.
///
/// Murni presentational: menerima data + callback, tidak menerima
/// controller apa pun.
class DbLensTableView extends StatelessWidget {
  const DbLensTableView({
    super.key,
    required this.rows,
    required this.columns,
    this.rowNumberStart = 1,
    this.sortColumn,
    this.sortAscending = true,
    this.onSort,
    this.onRowTap,
    this.onCellLongPress,
    this.onIndexLongPress,
  });

  final List<Map<String, Object?>> rows;
  final List<String> columns;
  final int rowNumberStart;
  final String? sortColumn;
  final bool sortAscending;
  final ValueChanged<String>? onSort;
  final void Function(Map<String, Object?> row)? onRowTap;
  final void Function(String column, Map<String, Object?> row)?
      onCellLongPress;
  final void Function(Map<String, Object?> row)? onIndexLongPress;

  static const double _indexWidth = 44;

  @override
  Widget build(BuildContext context) {
    final theme = DbLensThemeScope.of(context);

    return DbLensDataGrid(
      rows: rows,
      columns: columns,
      leadingWidth: _indexWidth,
      leadingHeaderBuilder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Text(
          '#',
          style: TextStyle(
            color: theme.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      leadingBuilder: (context, index, row) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onRowTap == null ? null : () => onRowTap!(row),
        onLongPress:
            onIndexLongPress == null ? null : () => onIndexLongPress!(row),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Text(
            '${rowNumberStart + index}',
            style: TextStyle(color: theme.textMuted, fontSize: 11.5),
          ),
        ),
      ),
      headerBuilder: (context, column) {
        final isActive = sortColumn == column;
        final indicator = !isActive ? '' : (sortAscending ? ' ↑' : ' ↓');
        return InkWell(
          onTap: onSort == null ? null : () => onSort!(column),
          child: Text(
            '$column$indicator',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isActive ? theme.textPrimary : theme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
      onCellTap: onRowTap == null ? null : (_, row) => onRowTap!(row),
      onCellLongPress: onCellLongPress,
    );
  }
}

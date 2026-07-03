import 'package:flutter/material.dart';

import '../hooks/db_lens_value_renderer.dart';
import '../theme/db_lens_theme.dart';

/// Tampilan baris sebagai kartu yang bisa di-expand — preview beberapa
/// kolom pertama, tap untuk lihat semua field, long-press field untuk edit
/// (kalau [canEditColumn] mengizinkan).
///
/// Murni presentational: menerima data + callback, tidak menerima
/// controller apa pun.
class DbLensListView extends StatelessWidget {
  const DbLensListView({
    super.key,
    required this.rows,
    required this.columns,
    this.rowNumberStart = 1,
    this.previewColumnCount = 2,
    this.canEditColumn,
    this.onEditCell,
    this.onCopyRow,
    this.valueRenderer,
    this.padding = const EdgeInsets.all(12),
  });

  final List<Map<String, Object?>> rows;
  final List<String> columns;
  final int rowNumberStart;
  final int previewColumnCount;
  final bool Function(String column)? canEditColumn;
  final void Function(String column, Object? currentValue, Map<String, Object?> row)?
      onEditCell;
  final void Function(Map<String, Object?> row)? onCopyRow;
  final DbLensValueRenderer? valueRenderer;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _DbLensListCard(
        row: rows[index],
        columns: columns,
        rowNum: rowNumberStart + index,
        previewColumnCount: previewColumnCount,
        canEditColumn: canEditColumn,
        onEditCell: onEditCell,
        onCopyRow: onCopyRow,
        valueRenderer: valueRenderer,
      ),
    );
  }
}

class _DbLensListCard extends StatefulWidget {
  const _DbLensListCard({
    required this.row,
    required this.columns,
    required this.rowNum,
    required this.previewColumnCount,
    this.canEditColumn,
    this.onEditCell,
    this.onCopyRow,
    this.valueRenderer,
  });

  final Map<String, Object?> row;
  final List<String> columns;
  final int rowNum;
  final int previewColumnCount;
  final bool Function(String column)? canEditColumn;
  final void Function(String column, Object? currentValue, Map<String, Object?> row)?
      onEditCell;
  final void Function(Map<String, Object?> row)? onCopyRow;
  final DbLensValueRenderer? valueRenderer;

  @override
  State<_DbLensListCard> createState() => _DbLensListCardState();
}

class _DbLensListCardState extends State<_DbLensListCard> {
  bool _expanded = false;

  Widget _renderValue(BuildContext context, Object? value, DbLensTheme theme) {
    if (widget.valueRenderer != null) return widget.valueRenderer!(context, value, theme);
    return Text(
      DbLensValueFormat.format(value),
      style: TextStyle(
        color: DbLensValueFormat.color(value, theme),
        fontSize: DbLensTheme.dataFontSize,
        fontStyle: value == null ? FontStyle.italic : FontStyle.normal,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = DbLensThemeScope.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, theme),
            if (_expanded) ...[
              Divider(height: 1, color: theme.border),
              _buildFields(context, theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, DbLensTheme theme) {
    return InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.accentSoft,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                '#${widget.rowNum}',
                style: TextStyle(
                  color: theme.accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: _buildPreview(context, theme)),
            if (widget.onCopyRow != null)
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: Icon(Icons.copy_rounded, size: 15, color: theme.textMuted),
                onPressed: () => widget.onCopyRow!(widget.row),
                tooltip: 'Copy as JSON',
              ),
            Icon(
              _expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: theme.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context, DbLensTheme theme) {
    final previewCols = widget.columns.take(widget.previewColumnCount).toList();
    if (previewCols.isEmpty) {
      return Text('(empty)', style: TextStyle(color: theme.textMuted, fontSize: 12));
    }
    return Row(
      children: previewCols.map((col) {
        return Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(col, style: TextStyle(color: theme.textMuted, fontSize: 10)),
              _renderValue(context, widget.row[col], theme),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFields(BuildContext context, DbLensTheme theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        children: widget.columns.map((col) {
          final value = widget.row[col];
          final editable = widget.canEditColumn?.call(col) ?? false;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: GestureDetector(
              onLongPress: editable
                  ? () => widget.onEditCell?.call(col, value, widget.row)
                  : null,
              behavior: HitTestBehavior.opaque,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            col,
                            style: TextStyle(
                              color: theme.textMuted,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (editable)
                          Padding(
                            padding: const EdgeInsets.only(left: 2),
                            child: Icon(Icons.edit_rounded, size: 9, color: theme.accent),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: _renderValue(context, value, theme)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/db_lens_controller.dart';
import '../hooks/db_lens_value_renderer.dart';
import '../theme/db_lens_theme.dart';
import '../utils/db_lens_cell_edit.dart';
import '../utils/db_lens_snackbar.dart';
import '../utils/db_lens_row_id_utils.dart';

/// Expandable row cards — preview columns, copy JSON, search highlight, edit.
///
/// When [onEditCell] is omitted, [DbLensCellEdit.run] is used automatically
/// (via [onSaveCell], [controller], or nearest [DbLensControllerScope]).
class DbLensListView extends StatelessWidget {
  const DbLensListView({
    super.key,
    required this.rows,
    required this.columns,
    this.rowNumberStart = 1,
    this.previewColumnCount = 2,
    this.searchQuery = '',
    this.canEditColumn,
    this.onEditCell,
    this.onSaveCell,
    this.controller,
    this.isSQLite,
    this.onCopyRow,
    this.valueRenderer,
    this.padding = const EdgeInsets.all(12),
  });

  final List<Map<String, Object?>> rows;
  final List<String> columns;
  final int rowNumberStart;
  final int previewColumnCount;
  final String searchQuery;
  final bool Function(String column)? canEditColumn;
  final Future<void> Function(String column, Object? currentValue, Map<String, Object?> row)?
      onEditCell;
  final Future<bool> Function(String column, Object? newValue, Map<String, Object?> row)?
      onSaveCell;
  final DbLensController? controller;
  final bool? isSQLite;
  final void Function(Map<String, Object?> row)? onCopyRow;
  final DbLensValueRenderer? valueRenderer;
  final EdgeInsets padding;

  /// Default edit handler — dialog + save via controller or [onSaveCell].
  static Future<void> defaultEditCell(
    BuildContext context, {
    required String column,
    required Object? currentValue,
    required Map<String, Object?> row,
    Future<bool> Function(String column, Object? newValue, Map<String, Object?> row)? onSave,
    DbLensController? controller,
    bool? isSQLite,
  }) {
    return DbLensCellEdit.run(
      context,
      column: column,
      currentValue: currentValue,
      row: row,
      onSave: onSave,
      controller: controller,
      isSQLite: isSQLite,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _RowCard(
        row: rows[index],
        columns: columns,
        rowNum: rowNumberStart + index,
        previewColumnCount: previewColumnCount,
        searchQuery: searchQuery,
        canEditColumn: canEditColumn,
        onEditCell: onEditCell,
        onSaveCell: onSaveCell,
        controller: controller,
        isSQLite: isSQLite,
        onCopyRow: onCopyRow,
        valueRenderer: valueRenderer,
      ),
    );
  }
}

class _RowCard extends StatefulWidget {
  const _RowCard({
    required this.row,
    required this.columns,
    required this.rowNum,
    required this.previewColumnCount,
    required this.searchQuery,
    this.canEditColumn,
    this.onEditCell,
    this.onSaveCell,
    this.controller,
    this.isSQLite,
    this.onCopyRow,
    this.valueRenderer,
  });

  final Map<String, Object?> row;
  final List<String> columns;
  final int rowNum;
  final int previewColumnCount;
  final String searchQuery;
  final bool Function(String column)? canEditColumn;
  final Future<void> Function(String column, Object? currentValue, Map<String, Object?> row)?
      onEditCell;
  final Future<bool> Function(String column, Object? newValue, Map<String, Object?> row)?
      onSaveCell;
  final DbLensController? controller;
  final bool? isSQLite;
  final void Function(Map<String, Object?> row)? onCopyRow;
  final DbLensValueRenderer? valueRenderer;

  @override
  State<_RowCard> createState() => _RowCardState();
}

class _RowCardState extends State<_RowCard> {
  bool _expanded = false;

  Future<void> _editCell(BuildContext context, String column, Object? value) async {
    if (widget.onEditCell != null) {
      await widget.onEditCell!(column, value, widget.row);
      return;
    }

    await DbLensCellEdit.run(
      context,
      column: column,
      currentValue: value,
      row: widget.row,
      onSave: widget.onSaveCell,
      controller: widget.controller,
      isSQLite: widget.isSQLite,
    );
  }

  void _copyJson(BuildContext context) {
    if (widget.onCopyRow != null) {
      widget.onCopyRow!(widget.row);
      return;
    }

    final exportRow = Map<String, Object?>.from(
      withoutRowIdEntry(Map<String, dynamic>.from(widget.row)),
    );
    Clipboard.setData(
      ClipboardData(text: const JsonEncoder.withIndent('  ').convert(exportRow)),
    );
    showDbLensSnack(context, 'Copied as JSON');
  }

  TextStyle _valueStyle(DbLensTheme theme, Object? value, {double? fontSize, FontWeight? weight}) {
    return TextStyle(
      color: DbLensValueFormat.color(value, theme),
      fontSize: fontSize ?? DbLensTheme.dataFontSize,
      fontWeight: weight,
      height: 1.4,
      fontStyle: value == null ? FontStyle.italic : FontStyle.normal,
    );
  }

  Widget _renderPreviewValue(BuildContext context, Object? value, DbLensTheme theme) {
    if (widget.valueRenderer != null) {
      return widget.valueRenderer!(context, value, theme);
    }
    return Text(
      DbLensValueFormat.format(value),
      style: _valueStyle(theme, value, fontSize: 12, weight: FontWeight.w500),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _renderFieldValue(BuildContext context, Object? value, DbLensTheme theme, {required bool isMatch}) {
    if (widget.valueRenderer != null) {
      return widget.valueRenderer!(context, value, theme);
    }

    final child = SelectableText(
      DbLensValueFormat.format(value),
      style: _valueStyle(theme, value, fontSize: 12),
    );

    if (!isMatch) return child;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: theme.accentSoft,
        borderRadius: BorderRadius.circular(4),
      ),
      child: child,
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
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
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
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: Icon(Icons.copy_rounded, size: 15, color: theme.textMuted),
              onPressed: () => _copyJson(context),
              tooltip: 'Copy as JSON',
            ),
            Icon(
              _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
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
        final value = widget.row[col];
        return Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(col, style: TextStyle(color: theme.textMuted, fontSize: 10)),
              _renderPreviewValue(context, value, theme),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFields(BuildContext context, DbLensTheme theme) {
    final q = widget.searchQuery.toLowerCase();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        children: widget.columns.map((col) {
          final value = widget.row[col];
          final isMatch = q.isNotEmpty && (value?.toString().toLowerCase().contains(q) ?? false);
          final editable = widget.canEditColumn?.call(col) ?? false;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
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
                Expanded(
                  child: GestureDetector(
                    onLongPress: editable ? () => _editCell(context, col, value) : null,
                    child: _renderFieldValue(context, value, theme, isMatch: isMatch),
                  ),
                ),
                if (editable)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: InkWell(
                      onTap: () => _editCell(context, col, value),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: theme.surface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: theme.border),
                        ),
                        child: Icon(Icons.edit_rounded, size: 12, color: theme.accent),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

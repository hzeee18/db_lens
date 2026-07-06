import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/history_entry_entity.dart';
import '../theme/db_lens_theme.dart';
import '../utils/db_lens_snackbar.dart';
import '../utils/history_diff_utils.dart';
import 'db_lens_json_view.dart';

/// Single history entry — diff or raw JSON, with copy.
///
/// Use [showAsSheet] for a modal, or embed directly in a `Scaffold`.
class DbLensHistoryEntryView extends StatefulWidget {
  const DbLensHistoryEntryView({super.key, required this.entry, this.theme});

  final HistoryEntry entry;
  final DbLensTheme? theme;

  static Future<void> showAsSheet(
    BuildContext context, {
    required HistoryEntry entry,
    DbLensTheme? theme,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => DecoratedBox(
        decoration: BoxDecoration(
          color: (theme ?? DbLensThemeScope.of(context)).bg,
          borderRadius: const BorderRadius.vertical(top: DbLensTheme.sheetRadius),
        ),
        child: DbLensHistoryEntryView(entry: entry, theme: theme),
      ),
    );
  }

  @override
  State<DbLensHistoryEntryView> createState() => _DbLensHistoryEntryViewState();
}

class _DbLensHistoryEntryViewState extends State<DbLensHistoryEntryView> {
  bool _jsonView = false;

  IconData _iconFor(HistoryChangeType type) {
    return switch (type) {
      HistoryChangeType.insert => Icons.add_circle_outline,
      HistoryChangeType.update => Icons.edit_outlined,
      HistoryChangeType.delete => Icons.remove_circle_outline,
    };
  }

  Color _colorFor(HistoryChangeType type, DbLensTheme theme) {
    return switch (type) {
      HistoryChangeType.insert => theme.diffAdded,
      HistoryChangeType.update => theme.diffChanged,
      HistoryChangeType.delete => theme.diffRemoved,
    };
  }

  String _prettyJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      return raw;
    }
  }

  String _copyableJsonText() {
    final entry = widget.entry;
    final before = entry.beforeJson;
    final after = entry.afterJson;

    return switch (entry.changeType) {
      HistoryChangeType.insert => after != null ? _prettyJson(after) : '',
      HistoryChangeType.delete => before != null ? _prettyJson(before) : '',
      HistoryChangeType.update => () {
          final parts = <String>[];
          if (before != null) parts.add('Before:\n${_prettyJson(before)}');
          if (after != null) parts.add('After:\n${_prettyJson(after)}');
          return parts.join('\n\n');
        }(),
    };
  }

  void _copyJson(BuildContext context) {
    final text = _copyableJsonText();
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    showDbLensSnack(context, 'JSON copied');
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final theme = widget.theme ?? DbLensThemeScope.of(context);
    final before = entry.beforeJson;
    final after = entry.afterJson;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
          child: Row(
            children: [
              Icon(_iconFor(entry.changeType), size: 18, color: _colorFor(entry.changeType, theme)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${entry.collection} · ${entry.changeType.name}',
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Copy JSON',
                onPressed: _copyableJsonText().isEmpty ? null : () => _copyJson(context),
                icon: Icon(Icons.content_copy, size: 20, color: theme.accent),
              ),
              IconButton(
                tooltip: _jsonView ? 'Show diff' : 'Show raw JSON',
                onPressed: () => setState(() => _jsonView = !_jsonView),
                icon: Icon(
                  _jsonView ? Icons.difference_outlined : Icons.data_object_outlined,
                  size: 20,
                  color: theme.accent,
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: theme.border),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _jsonView
                ? _buildJsonView(theme, before, after)
                : DbLensHistoryDiffView(entry: entry, theme: theme),
          ),
        ),
      ],
    );
  }

  Widget _buildJsonView(DbLensTheme theme, String? before, String? after) {
    final entry = widget.entry;
    final isSingleSnapshot =
        entry.changeType == HistoryChangeType.insert || entry.changeType == HistoryChangeType.delete;

    if (isSingleSnapshot) {
      final raw = entry.changeType == HistoryChangeType.insert ? after : before;
      if (raw == null) {
        return Text('No data available', style: TextStyle(color: theme.textMuted, fontSize: 12));
      }
      return DbLensJsonSyntaxText(json: _prettyJson(raw), theme: theme);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (before != null) ...[
          Text('Before', style: TextStyle(color: theme.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DbLensJsonSyntaxText(json: _prettyJson(before), theme: theme),
          const SizedBox(height: 16),
        ],
        if (after != null) ...[
          Text('After', style: TextStyle(color: theme.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DbLensJsonSyntaxText(json: _prettyJson(after), theme: theme),
        ],
      ],
    );
  }
}

/// Field-level diff for one [HistoryEntry].
///
/// Insert/delete: single value column. Update: side-by-side before/after.
class DbLensHistoryDiffView extends StatelessWidget {
  const DbLensHistoryDiffView({super.key, required this.entry, required this.theme});

  final HistoryEntry entry;
  final DbLensTheme theme;

  bool get _isSingleColumn =>
      entry.changeType == HistoryChangeType.insert || entry.changeType == HistoryChangeType.delete;

  @override
  Widget build(BuildContext context) {
    final fields = DbLensHistoryDiffUtils.compute(
      beforeJson: entry.beforeJson,
      afterJson: entry.afterJson,
      changedColumns: entry.changedColumns,
    );

    if (fields.isEmpty) {
      return Text('No field data available', style: TextStyle(color: theme.textMuted, fontSize: 12));
    }

    if (_isSingleColumn) {
      return _buildSingleColumnView(fields);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLegend(),
        const SizedBox(height: 12),
        _buildDualColumnHeaders(),
        Divider(height: 16, color: theme.border),
        for (final field in fields) _buildDualColumnRow(field),
      ],
    );
  }

  Widget _buildSingleColumnView(List<DbLensDiffField> fields) {
    final rowColor = switch (entry.changeType) {
      HistoryChangeType.insert => theme.diffAdded.withValues(alpha: 0.08),
      HistoryChangeType.delete => theme.diffRemoved.withValues(alpha: 0.08),
      HistoryChangeType.update => Colors.transparent,
    };
    final barColor = switch (entry.changeType) {
      HistoryChangeType.insert => theme.diffAdded,
      HistoryChangeType.delete => theme.diffRemoved,
      HistoryChangeType.update => Colors.transparent,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSingleColumnHeaders(),
        Divider(height: 16, color: theme.border),
        for (final field in fields)
          Container(
            decoration: BoxDecoration(
              color: rowColor,
              border: Border(left: BorderSide(color: barColor, width: 2)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            margin: const EdgeInsets.only(bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    field.key,
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: SelectableText(
                    _format(_valueForSingleColumn(field)),
                    style: TextStyle(
                      color: theme.textSecondary,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Object? _valueForSingleColumn(DbLensDiffField field) {
    return entry.changeType == HistoryChangeType.insert ? field.afterValue : field.beforeValue;
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        _legendDot(theme.diffAdded, 'Added'),
        _legendDot(theme.diffChanged, 'Changed'),
        _legendDot(theme.diffRemoved, 'Removed'),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: theme.textMuted, fontSize: 11)),
      ],
    );
  }

  Widget _buildSingleColumnHeaders() {
    final style = TextStyle(
      color: theme.textMuted,
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
    );
    return Row(
      children: [
        Expanded(flex: 3, child: Text('Field', style: style)),
        Expanded(flex: 5, child: Text('Value', style: style)),
      ],
    );
  }

  Widget _buildDualColumnHeaders() {
    final style = TextStyle(
      color: theme.textMuted,
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
    );
    return Row(
      children: [
        Expanded(flex: 3, child: Text('Field', style: style)),
        Expanded(flex: 4, child: Text('Before', style: style)),
        Expanded(flex: 4, child: Text('After', style: style)),
      ],
    );
  }

  Widget _buildDualColumnRow(DbLensDiffField field) {
    final rowColor = switch (field.kind) {
      DbLensDiffKind.added => theme.diffAdded.withValues(alpha: 0.08),
      DbLensDiffKind.removed => theme.diffRemoved.withValues(alpha: 0.08),
      DbLensDiffKind.changed => theme.diffChanged.withValues(alpha: 0.08),
      DbLensDiffKind.unchanged => Colors.transparent,
    };
    final barColor = switch (field.kind) {
      DbLensDiffKind.added => theme.diffAdded,
      DbLensDiffKind.removed => theme.diffRemoved,
      DbLensDiffKind.changed => theme.diffChanged,
      DbLensDiffKind.unchanged => Colors.transparent,
    };

    return Container(
      decoration: BoxDecoration(
        color: rowColor,
        border: Border(left: BorderSide(color: barColor, width: 2)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      margin: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              field.key,
              style: TextStyle(color: theme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(flex: 4, child: _valueText(field.beforeValue, show: field.kind != DbLensDiffKind.added)),
          Expanded(flex: 4, child: _valueText(field.afterValue, show: field.kind != DbLensDiffKind.removed)),
        ],
      ),
    );
  }

  Widget _valueText(Object? value, {required bool show}) {
    if (!show) {
      return Text('—', style: TextStyle(color: theme.textMuted, fontSize: 12));
    }
    return SelectableText(
      _format(value),
      style: TextStyle(
        color: theme.textSecondary,
        fontSize: 12,
        height: 1.35,
        fontStyle: value == null ? FontStyle.italic : FontStyle.normal,
      ),
    );
  }

  String _format(Object? value) {
    if (value == null) return 'null';
    if (value is String) return value;
    return value.toString();
  }
}

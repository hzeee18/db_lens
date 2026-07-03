import 'dart:convert';

import 'package:flutter/material.dart';

import '../../domain/entities/history_entry_entity.dart';
import '../controllers/db_lens_history_controller.dart';
import '../theme/db_lens_theme.dart';
import '../widgets/db_lens_panel_widgets.dart';
import '../widgets/db_lens_row_json_sheet.dart';

/// Bottom sheet riwayat perubahan data per source.
class DbLensHistorySheet extends StatefulWidget {
  const DbLensHistorySheet({
    super.key,
    required this.controller,
    required this.theme,
    required this.sourceName,
  });

  final DbLensHistoryController controller;
  final DbLensTheme theme;
  final String sourceName;

  static Future<void> show(
    BuildContext context, {
    required DbLensHistoryController controller,
    required DbLensTheme theme,
    required String sourceName,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => DbLensHistorySheet(
        controller: controller,
        theme: theme,
        sourceName: sourceName,
      ),
    );
  }

  @override
  State<DbLensHistorySheet> createState() => _DbLensHistorySheetState();
}

class _DbLensHistorySheetState extends State<DbLensHistorySheet> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    widget.controller.startListening();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    widget.controller.stopListening();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear history'),
        content: const Text(
          'Hapus semua riwayat perubahan untuk source ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.controller.clear();
    }
  }

  void _showEntryDetail(HistoryEntry entry) {
    final before = entry.beforeJson;
    final after = entry.afterJson;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: widget.theme.bg,
            borderRadius:
                const BorderRadius.vertical(top: DbLensTheme.sheetRadius),
            border: Border(
              top: BorderSide(color: widget.theme.border),
              left: BorderSide(color: widget.theme.border),
              right: BorderSide(color: widget.theme.border),
            ),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.75,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
                  child: Row(
                    children: [
                      Icon(
                        _iconFor(entry.changeType),
                        size: 18,
                        color: _colorFor(entry.changeType),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${entry.collection} · ${entry.changeType.name}',
                          style: TextStyle(
                            color: widget.theme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close,
                          size: 20,
                          color: widget.theme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (before != null) ...[
                          Text(
                            'Before',
                            style: TextStyle(
                              color: widget.theme.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DbLensJsonSyntaxText(
                            json: _prettyJson(before),
                            theme: widget.theme,
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (after != null) ...[
                          Text(
                            'After',
                            style: TextStyle(
                              color: widget.theme.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DbLensJsonSyntaxText(
                            json: _prettyJson(after),
                            theme: widget.theme,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _prettyJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.75;
    final c = widget.controller;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: widget.theme.bg,
        borderRadius:
            const BorderRadius.vertical(top: DbLensTheme.sheetRadius),
        border: Border(
          top: BorderSide(color: widget.theme.border),
          left: BorderSide(color: widget.theme.border),
          right: BorderSide(color: widget.theme.border),
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHandle(),
            _buildHeader(context),
            const Divider(height: 1),
            Flexible(child: _buildBody(c)),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 10, bottom: 4),
        width: 32,
        height: 3,
        decoration: BoxDecoration(
          color: widget.theme.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 12),
      child: Row(
        children: [
          Icon(Icons.history, size: 18, color: widget.theme.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Change History',
                  style: TextStyle(
                    color: widget.theme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  widget.sourceName,
                  style: TextStyle(
                    color: widget.theme.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (!widget.controller.isEmpty)
            TextButton(
              onPressed: _confirmClear,
              child: const Text('Clear'),
            ),
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, size: 20, color: widget.theme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(DbLensHistoryController c) {
    if (c.loading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: CircularProgressIndicator(color: widget.theme.accent),
        ),
      );
    }

    if (c.isEmpty) {
      return DbLensEmptyPlaceholder(
        icon: Icons.history_toggle_off,
        title: 'No changes yet',
        subtitle: 'Perubahan data akan muncul di sini setelah terdeteksi.',
        theme: widget.theme,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: c.entries.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        indent: 56,
        color: widget.theme.border,
      ),
      itemBuilder: (context, index) {
        final entry = c.entries[index];
        return ListTile(
          onTap: () => _showEntryDetail(entry),
          leading: Icon(
            _iconFor(entry.changeType),
            color: _colorFor(entry.changeType),
          ),
          title: Text(
            entry.collection,
            style: TextStyle(
              color: widget.theme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            '${entry.changeType.name} · ${entry.rowKey}',
            style: TextStyle(color: widget.theme.textMuted, fontSize: 12),
          ),
          trailing: Text(
            _formatTime(entry.createdAt),
            style: TextStyle(color: widget.theme.textMuted, fontSize: 11),
          ),
        );
      },
    );
  }

  IconData _iconFor(HistoryChangeType type) {
    return switch (type) {
      HistoryChangeType.insert => Icons.add_circle_outline,
      HistoryChangeType.update => Icons.edit_outlined,
      HistoryChangeType.delete => Icons.remove_circle_outline,
    };
  }

  Color _colorFor(HistoryChangeType type) {
    return switch (type) {
      HistoryChangeType.insert => Colors.greenAccent.shade400,
      HistoryChangeType.update => widget.theme.accent,
      HistoryChangeType.delete => Colors.redAccent.shade200,
    };
  }

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final s = time.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

import 'package:flutter/material.dart';

import '../controllers/db_lens_controller.dart';
import '../scope/db_lens_controller_scope.dart';
import '../theme/db_lens_theme.dart';

/// Hook untuk mengganti dialog konfirmasi query bawaan (dipanggil sebelum
/// menjalankan statement non-SELECT). Kembalikan `true` untuk lanjut.
typedef DbLensQueryConfirmBuilder = Future<bool?> Function(
  BuildContext context,
  String sql,
);

/// Editor SQL mentah — expand/collapse, jalankan (dengan konfirmasi untuk
/// statement non-SELECT), tampilkan error/info hasil eksekusi.
class DbLensQueryEditor extends StatefulWidget {
  const DbLensQueryEditor({
    super.key,
    this.controller,
    this.hintText = 'SELECT * FROM users LIMIT 20',
    this.confirmBuilder,
  });

  final DbLensController? controller;
  final String hintText;
  final DbLensQueryConfirmBuilder? confirmBuilder;

  @override
  State<DbLensQueryEditor> createState() => _DbLensQueryEditorState();
}

class _DbLensQueryEditorState extends State<DbLensQueryEditor> {
  final _queryController = TextEditingController();

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  DbLensController _controllerOf(BuildContext context) =>
      widget.controller ?? DbLensControllerScope.of(context);

  Future<bool?> _defaultConfirm(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm query'),
        content: const Text(
          '⚠️ This query may modify or delete data. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Run'),
          ),
        ],
      ),
    );
  }

  Future<void> _run(DbLensController c) async {
    final sql = _queryController.text.trim();
    c.query.setText(sql);
    if (sql.isNotEmpty && await c.query.shouldConfirm()) {
      FocusManager.instance.primaryFocus?.unfocus();
      if (!mounted) return;
      bool? confirmed;
      if (widget.confirmBuilder != null) {
        confirmed = await widget.confirmBuilder!(context, sql);
      } else {
        confirmed = await _defaultConfirm(context);
      }
      if (confirmed != true) return;
    }
    await c.runQuery();
  }

  void _clear(DbLensController c) {
    if (c.query.queryMode) {
      c.restoreTableView();
      return;
    }
    _queryController.clear();
    c.query.clearText();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controllerOf(context);
    final theme = DbLensThemeScope.of(context);

    return AnimatedBuilder(
      animation: c.query,
      builder: (context, _) {
        final canClear =
            c.query.queryMode || _queryController.text.trim().isNotEmpty;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.code_rounded, size: 16, color: theme.textMuted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Raw SQL Query',
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: c.query.toggleExpanded,
                      child: Text(c.query.queryExpanded ? 'Collapse' : 'Expand'),
                    ),
                  ],
                ),
                if (c.query.queryExpanded || canClear) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _queryController,
                    minLines: 2,
                    maxLines: 6,
                    onChanged: (_) => setState(() {}),
                    decoration: theme
                        .fieldDecoration(hintText: widget.hintText, fillColor: theme.bg)
                        .copyWith(contentPadding: const EdgeInsets.all(12)),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    runSpacing: 8,
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'SELECT runs directly. Non-SELECT queries require confirmation.',
                        style: TextStyle(color: theme.textMuted, fontSize: 11),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (canClear)
                            TextButton(
                              onPressed:
                                  c.query.runningQuery ? null : () => _clear(c),
                              child: const Text('Clear query'),
                            ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed:
                                c.query.runningQuery ? null : () => _run(c),
                            icon: c.query.runningQuery
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.play_arrow_rounded, size: 18),
                            label: Text(c.query.runningQuery ? 'Running' : 'Run'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (c.query.queryError != null)
                    _buildMessage(
                      theme,
                      c.query.queryError!,
                      icon: Icons.error_outline,
                      color: Colors.redAccent,
                    )
                  else if (c.query.queryInfoMessage != null)
                    _buildMessage(
                      theme,
                      c.query.queryInfoMessage!,
                      icon: Icons.info_outline,
                      color: theme.accent,
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessage(
    DbLensTheme theme,
    String message, {
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: theme.textSecondary, fontSize: 12, height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

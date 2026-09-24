import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/sql_utils.dart';
import '../../db_lens_facade.dart';
import '../controllers/db_lens_query_history_controller.dart';
import '../theme/db_lens_theme.dart';
import '../theme/db_lens_theme_data.dart';
import '../utils/db_lens_snackbar.dart';
import 'db_lens_data_grid.dart';
import 'db_lens_query_editor.dart';
import 'db_lens_query_history_list.dart';

/// Halaman konsol SQL penuh — editor gelap, riwayat, grid hasil, salin CSV/JSON.
///
/// Berdiri sendiri lewat [DbLens.runRawQuery] / [DbLens.executeStatement]
/// (tanpa [DbLensController]). Bungkus dengan [DbLensThemeScope].
///
/// ```dart
/// DbLensQueryConsole.push(
///   context,
///   source: 'Main DB',
///   tableNames: ['users', 'orders'],
/// );
/// ```
class DbLensQueryConsole extends StatefulWidget {
  const DbLensQueryConsole({
    super.key,
    required this.source,
    this.tableNames = const [],
    this.historyController,
    this.confirmBuilder,
    this.onBack,
  });

  /// sourceId atau sourceName.
  final String source;
  final List<String> tableNames;
  final DbLensQueryHistoryController? historyController;
  final DbLensQueryConfirmBuilder? confirmBuilder;
  final VoidCallback? onBack;

  static Future<T?> push<T>(
    BuildContext context, {
    required String source,
    List<String> tableNames = const [],
    DbLensQueryHistoryController? historyController,
    DbLensQueryConfirmBuilder? confirmBuilder,
  }) {
    final theme = DbLensTheme(DbLensThemeData.fromMaterialTheme(Theme.of(context)));
    return Navigator.of(context).push<T>(
      MaterialPageRoute(
        builder: (context) => DbLensThemeScope(
          theme: theme,
          child: DbLensQueryConsole(
            source: source,
            tableNames: tableNames,
            historyController: historyController,
            confirmBuilder: confirmBuilder,
            onBack: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }

  @override
  State<DbLensQueryConsole> createState() => _DbLensQueryConsoleState();
}

class _DbLensQueryConsoleState extends State<DbLensQueryConsole> {
  static const _editorBg = Color(0xFF1A1D23);
  static const _editorFg = Color(0xFFCDD6F4);
  static const _editorSubtle = Color(0xFF6B7280);
  static const _editorBorder = Color(0xFF2D3142);
  static const _editorAccent = Color(0xFF4D9DE0);
  static const _editorGreen = Color(0xFF4EC9B0);

  final _queryCtrl = TextEditingController();
  late final DbLensQueryHistoryController _history;
  late final bool _ownsHistory;

  bool _running = false;
  bool _hasResult = false;
  List<Map<String, Object?>> _rows = [];
  List<String> _cols = [];
  Map<String, double> _colWidths = {};
  String? _error;
  String? _info;
  bool _editorExpanded = true;

  @override
  void initState() {
    super.initState();
    _ownsHistory = widget.historyController == null;
    _history = widget.historyController ?? DbLensQueryHistoryController();
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    if (_ownsHistory) _history.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final sql = _queryCtrl.text.trim();
    if (sql.isEmpty) return;
    FocusManager.instance.primaryFocus?.unfocus();

    if (DbLensSqlUtils.isSelectQuery(sql)) {
      setState(() {
        _running = true;
        _error = null;
        _info = null;
        _hasResult = false;
      });
      try {
        final sw = Stopwatch()..start();
        final rawRows = await DbLens.runRawQuery(widget.source, sql);
        sw.stop();
        final ms = sw.elapsedMilliseconds;
        if (!mounted) return;
        final cols = rawRows.isNotEmpty
            ? rawRows.first.keys.where((k) => k != '_rowid_').toList()
            : <String>[];
        final rows = rawRows
            .map((r) => r.map((k, v) => MapEntry(k, v as Object?)))
            .toList();
        final infoText =
            '${rows.length} row${rows.length == 1 ? '' : 's'} · ${ms}ms';
        setState(() {
          _rows = rows;
          _cols = cols;
          _colWidths = DbLensDataGrid.computeWidths(
            _cols,
            _rows,
            minWidth: 80,
            maxWidth: 240,
          );
          _info = infoText;
          _hasResult = true;
          _running = false;
        });
        _history.record(sql, info: infoText, isError: false);
      } catch (e) {
        if (!mounted) return;
        final msg = e.toString();
        setState(() {
          _error = msg;
          _hasResult = false;
          _running = false;
        });
        _history.record(sql, info: msg, isError: true);
      }
    } else {
      final confirmed = await _confirmMutation(sql);
      if (confirmed != true || !mounted) return;
      setState(() {
        _running = true;
        _error = null;
      });
      try {
        await DbLens.executeStatement(widget.source, sql);
        if (!mounted) return;
        setState(() => _running = false);
        _history.record(sql, info: 'Berhasil dijalankan', isError: false);
        showDbLensSnack(context, 'Statement berhasil dijalankan');
      } catch (e) {
        if (!mounted) return;
        final msg = e.toString();
        setState(() {
          _error = msg;
          _running = false;
        });
        _history.record(sql, info: msg, isError: true);
      }
    }
  }

  Future<bool?> _confirmMutation(String sql) async {
    if (widget.confirmBuilder != null) {
      return widget.confirmBuilder!(context, sql);
    }
    final theme = DbLensThemeScope.of(context);
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.bg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'Konfirmasi Eksekusi',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: theme.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '⚠️ Statement ini akan mengubah atau menghapus data. Tidak bisa di-undo.',
              style: TextStyle(
                color: theme.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _editorBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                sql,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: _editorFg,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: TextStyle(color: theme.textMuted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Jalankan'),
          ),
        ],
      ),
    );
  }

  void _clearAll() {
    setState(() {
      _queryCtrl.clear();
      _hasResult = false;
      _rows = [];
      _cols = [];
      _colWidths = {};
      _error = null;
      _info = null;
    });
  }

  void _showHistory() {
    if (_history.isEmpty) return;
    final theme = DbLensThemeScope.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
              child: Row(
                children: [
                  Icon(Icons.history_rounded, size: 16, color: theme.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Riwayat Query',
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                    color: theme.textMuted,
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: theme.border),
            Expanded(
              child: DbLensQueryHistoryList(
                controller: _history,
                onSelect: (sql) {
                  _queryCtrl.text = sql;
                  setState(() {});
                  Navigator.pop(ctx);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyAsJson() {
    Clipboard.setData(
      ClipboardData(
        text: const JsonEncoder.withIndent('  ').convert(_rows),
      ),
    );
    showDbLensSnack(context, 'Disalin sebagai JSON');
  }

  void _copyAsCsv() {
    final header = _cols.join(',');
    final body = _rows.map((r) {
      return _cols.map((c) {
        final v = r[c]?.toString() ?? '';
        return v.contains(',') || v.contains('"')
            ? '"${v.replaceAll('"', '""')}"'
            : v;
      }).join(',');
    }).join('\n');
    Clipboard.setData(ClipboardData(text: '$header\n$body'));
    showDbLensSnack(context, 'Disalin sebagai CSV');
  }

  @override
  Widget build(BuildContext context) {
    final theme = DbLensThemeScope.of(context);
    return Scaffold(
      backgroundColor: theme.bg,
      appBar: _buildAppBar(theme),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildEditorPanel(),
          Expanded(child: _buildResultsPanel(theme)),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(DbLensTheme theme) {
    return AppBar(
      backgroundColor: _editorBg,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      iconTheme: const IconThemeData(color: _editorFg),
      leading: widget.onBack != null
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: widget.onBack,
            )
          : null,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Query Console',
            style: TextStyle(
              color: _editorFg,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            widget.source,
            style: const TextStyle(color: _editorSubtle, fontSize: 11),
          ),
        ],
      ),
      actions: [
        if (!_history.isEmpty)
          IconButton(
            icon: const Icon(Icons.history_rounded,
                color: _editorSubtle, size: 20),
            onPressed: _showHistory,
            tooltip: 'Riwayat',
          ),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded,
              color: _editorSubtle, size: 20),
          onPressed: _clearAll,
          tooltip: 'Bersihkan',
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: _editorBorder),
      ),
    );
  }

  Widget _buildEditorPanel() {
    final tables = widget.tableNames;
    final firstTable = tables.isNotEmpty ? tables.first : 'table_name';

    return ColoredBox(
      color: _editorBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 12, 6),
            child: Row(
              children: [
                const Icon(Icons.terminal_rounded,
                    size: 13, color: _editorAccent),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'SQL EDITOR',
                    style: TextStyle(
                      color: _editorSubtle,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () =>
                      setState(() => _editorExpanded = !_editorExpanded),
                  child: Icon(
                    _editorExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: _editorSubtle,
                  ),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child:
                _editorExpanded ? _buildEditorBody(firstTable) : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorBody(String firstTable) {
    final theme = DbLensThemeScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: TextField(
            controller: _queryCtrl,
            minLines: 3,
            maxLines: 8,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: _editorFg,
              height: 1.65,
            ),
            cursorColor: theme.accent,
            decoration: InputDecoration(
              hintText:
                  '-- Ketik SQL di sini\nSELECT * FROM $firstTable LIMIT 20',
              hintStyle: TextStyle(
                fontFamily: 'monospace',
                color: _editorSubtle,
                fontSize: 12,
                height: 1.65,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        if (widget.tableNames.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                const Text(
                  'Tables:',
                  style: TextStyle(
                    color: _editorSubtle,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 10),
                for (final t in widget.tableNames)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => _insertTableName(t),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF252836),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF3D4460)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.table_rows_outlined,
                                size: 10, color: _editorAccent),
                            const SizedBox(width: 5),
                            Text(
                              t,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                color: _editorFg,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: _editorBorder)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 8, 12, 10),
          child: Row(
            children: [
              if (_info != null && !_running) ...[
                const Icon(Icons.check_circle_outline,
                    size: 13, color: _editorGreen),
                const SizedBox(width: 6),
                Text(
                  _info!,
                  style: const TextStyle(
                    color: _editorGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const Spacer(),
              if (_queryCtrl.text.isNotEmpty) ...[
                GestureDetector(
                  onTap: () {
                    _queryCtrl.clear();
                    setState(() {});
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      'Hapus',
                      style: TextStyle(
                        color: _editorSubtle,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              FilledButton.icon(
                onPressed: _running ? null : _run,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.accent,
                  disabledBackgroundColor:
                      theme.accent.withValues(alpha: 0.4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: _running
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.play_arrow_rounded,
                        size: 16, color: Colors.white),
                label: Text(
                  _running ? 'Running...' : 'Run',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _insertTableName(String t) {
    final text = _queryCtrl.text;
    final sel = _queryCtrl.selection;
    final start = sel.start < 0 ? text.length : sel.start;
    final end = sel.end < 0 ? text.length : sel.end;
    final newText = text.replaceRange(start, end, t);
    _queryCtrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + t.length),
    );
    setState(() {});
  }

  Widget _buildResultsPanel(DbLensTheme theme) {
    if (_running) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: theme.accent,
              strokeWidth: 2.5,
            ),
            const SizedBox(height: 14),
            Text(
              'Menjalankan query...',
              style: TextStyle(color: theme.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.error_outline, size: 16, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Text(
                    'Query Error',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SelectableText(
                _error!,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_hasResult) return _buildIdleState();

    if (_rows.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 44, color: theme.textMuted),
            const SizedBox(height: 10),
            Text(
              'Query berhasil — tidak ada data',
              style: TextStyle(color: theme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildResultBanner(theme),
        Expanded(
          child: DbLensDataGrid(
            rows: _rows,
            columns: _cols,
            columnWidths: _colWidths,
            onCellLongPress: (column, row) {
              Clipboard.setData(
                ClipboardData(text: row[column]?.toString() ?? 'null'),
              );
              showDbLensSnack(context, 'Nilai disalin');
            },
          ),
        ),
      ],
    );
  }

  Widget _buildIdleState() {
    final theme = DbLensThemeScope.of(context);
    final tables = widget.tableNames;
    final examples = [
      if (tables.isNotEmpty) 'SELECT * FROM ${tables.first} LIMIT 20',
      if (tables.length >= 2)
        'SELECT a.*, b.*\nFROM ${tables[0]} a\nJOIN ${tables[1]} b ON a.id = b.id',
      if (tables.isNotEmpty) 'PRAGMA table_info(${tables.first})',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: theme.accentSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.terminal_rounded, size: 32, color: theme.accent),
          ),
          const SizedBox(height: 16),
          Text(
            'Tulis SQL dan tekan Run',
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Supports SELECT, JOIN, INSERT, UPDATE, DELETE, PRAGMA, dan lainnya.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.textMuted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          if (examples.isNotEmpty) ...[
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Contoh query:',
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            for (final sql in examples)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () {
                    _queryCtrl.text = sql;
                    if (!_editorExpanded) {
                      setState(() => _editorExpanded = true);
                    } else {
                      setState(() {});
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _editorBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _editorBorder),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            sql,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              color: _editorFg,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.north_west_rounded,
                            size: 14, color: _editorSubtle),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultBanner(DbLensTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(bottom: BorderSide(color: theme.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: theme.diffAdded,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _info ?? '${_rows.length} rows',
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.accentSoft,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${_cols.length} col',
              style: TextStyle(
                color: theme.accent,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          _CopyButton(
            label: 'CSV',
            icon: Icons.file_copy_outlined,
            onTap: _copyAsCsv,
            theme: theme,
          ),
          const SizedBox(width: 12),
          _CopyButton(
            label: 'JSON',
            icon: Icons.data_object_outlined,
            onTap: _copyAsJson,
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.theme,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final DbLensTheme theme;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: theme.textMuted),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: theme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

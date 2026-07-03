import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/models/db_lens_config.dart';
import '../../db_lens_facade.dart';
import '../controllers/db_lens_controller.dart';
import '../theme/db_lens_theme.dart';
import '../utils/db_lens_row_id_utils.dart';
import '../utils/db_lens_snackbar.dart';
import '../utils/json_view_utils.dart';
import '../utils/row_utils.dart';
import '../widgets/db_lens_chip.dart';
import '../widgets/db_lens_history_sheet.dart';
import '../widgets/db_lens_panel_widgets.dart';
import '../widgets/db_lens_row_json_sheet.dart';

enum _DbLensDataView { table, list, json }

/// Panel inspeksi database — hanya berinteraksi dengan [DbLensController].
class DbLensPanel extends StatefulWidget {
  const DbLensPanel({
    super.key,
    this.config = const DbLensConfig(),
    this.controller,
  });

  final DbLensConfig config;

  /// Jika diisi, panel memakai controller ini dan TIDAK men-dispose-nya
  /// (lifecycle jadi tanggung jawab caller). Caller harus memanggil
  /// [DbLensController.initialize] sebelum widget dipasang.
  ///
  /// Jika null, panel membuat controller sendiri seperti sebelumnya.
  final DbLensController? controller;

  @override
  State<DbLensPanel> createState() => _DbLensPanelState();
}

class _DbLensPanelState extends State<DbLensPanel> {
  late final DbLensController _controller;
  late final bool _ownsController;
  bool _isClosing = false;
  _DbLensDataView _dataView = _DbLensDataView.table;

  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _queryController = TextEditingController();

  DbLensTheme get _theme => DbLensThemeScope.of(context);

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ??
        DbLens.createController(config: widget.config);
    _controller.addListener(_onControllerChanged);
    if (_ownsController) {
      _controller.initialize();
    } else {
      assert(
        _controller.isInitialized,
        'Controller passed to DbLensPanel must be initialized before mounting. '
        'Call controller.initialize() first.',
      );
    }
  }

  void _onControllerChanged() {
    if (!mounted) return;
    if (_controller.lastError != null) {
      _showSnackBar(_controller.lastError!, isError: true);
      _controller.lastError = null;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    if (_ownsController) {
      _controller.dispose();
    }
    _sheetController.dispose();
    _searchController.dispose();
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _closePanel() async {
    if (_isClosing || !mounted) return;
    _isClosing = true;
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      final navigator = Navigator.of(context);
      if (navigator.canPop()) navigator.pop();
    } finally {
      _isClosing = false;
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    showDbLensSnack(context, message, isError: isError);
  }

  Future<void> _confirmAndRunQuery() async {
    final sql = _queryController.text.trim();
    _controller.setQueryText(sql);
    if (sql.isNotEmpty && await _controller.shouldConfirmQuery()) {
      FocusManager.instance.primaryFocus?.unfocus();
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
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
      if (confirmed != true) return;
    }
    await _controller.runQuery();
  }

  void _setDataView(_DbLensDataView view) {
    setState(() => _dataView = view);
  }

  Future<void> _copyAllAsJson() async {
    final json = await _controller.copyAllAsJson();
    if (!mounted || json == null) return;
    await Clipboard.setData(ClipboardData(text: json));
    _showSnackBar('Copied all rows as JSON');
  }

  Future<void> _showEditCellDialog({
    required String column,
    required Object? currentValue,
    required Map<String, Object?> row,
  }) async {
    if (!_controller.canEditCells) return;

    final result = await showDialog<Object?>(
      context: context,
      builder: (context) => _EditCellDialog(
        column: column,
        currentValue: currentValue,
        theme: _theme,
      ),
    );

    if (!mounted || result == _EditCellDialog.cancelled) return;

    final success = await _controller.updateCellValue(
      column: column,
      newValue: result,
      row: row,
    );
    if (success && mounted) {
      _showSnackBar('Cell updated');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _closePanel();
      },
      child: DraggableScrollableSheet(
        controller: _sheetController,
        initialChildSize: DbLensTheme.initialChildSize,
        minChildSize: DbLensTheme.minChildSize,
        maxChildSize: DbLensTheme.maxChildSize,
        builder: (context, scrollController) {
          return AnimatedBuilder(
            animation: _sheetController,
            builder: (context, _) {
              final sheetSize = _sheetController.isAttached
                  ? _sheetController.size
                  : DbLensTheme.initialChildSize;
              return DbLensUnfocusTap(
                onTapOutside: () =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                child: DecoratedBox(
                  decoration: _theme.sheetDecoration(size: sheetSize),
                  child: CustomScrollView(
                    controller: scrollController,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    slivers: [
                      SliverToBoxAdapter(child: _buildTopSection(c)),
                      if (!c.hasSources)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildEmptyState(),
                        )
                      else
                        ..._buildDataSlivers(c),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTopSection(DbLensController c) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _theme.bg,
        borderRadius: const BorderRadius.vertical(top: DbLensTheme.sheetRadius),
        border: Border(bottom: BorderSide(color: _theme.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DbLensDragHandleBar(
            controller: _sheetController,
            minSize: DbLensTheme.minChildSize,
            maxSize: DbLensTheme.maxChildSize,
            dismissThreshold: DbLensTheme.dismissThreshold,
            onDismiss: _closePanel,
            theme: _theme,
          ),
          _buildHeader(c),
          if (c.hasSources) ...[
            Divider(height: 1, thickness: 1, color: _theme.border),
            _buildSelectorSection(c),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(DbLensController c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Close',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: _closePanel,
            style: IconButton.styleFrom(
              backgroundColor: _theme.accentSoft,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
                side: BorderSide(
                  color: _theme.accent.withValues(alpha: 0.25),
                ),
              ),
            ),
            icon: Icon(Icons.close_rounded, size: 15, color: _theme.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DB Lens',
                  style: TextStyle(
                    color: _theme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                    height: 1.2,
                  ),
                ),
                Text(
                  'Database inspector',
                  style: TextStyle(
                    color: _theme.textMuted,
                    fontSize: 11,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          if (c.selectedSourceId != null)
            IconButton(
              tooltip: 'History',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: () => _showHistorySheet(c),
              style: IconButton.styleFrom(
                backgroundColor: _theme.accentSoft,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                  side: BorderSide(
                    color: _theme.accent.withValues(alpha: 0.25),
                  ),
                ),
              ),
              icon: Icon(Icons.history, size: 15, color: _theme.accent),
            ),
          if (c.selectedSourceId != null) const SizedBox(width: 6),
          if (c.selectedCollection != null || c.queryMode)
            _buildRowCountBadge(c),
        ],
      ),
    );
  }

  Widget _buildRowCountBadge(DbLensController c) {
    return DbLensChip(
      label: '${c.activeRowCount} rows',
      foreground: _theme.textSecondary,
      background: _theme.surface,
      borderColor: _theme.border,
      borderRadius: 6,
    );
  }

  Widget _buildSelectorSection(DbLensController c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DbLensSelectorField(
            icon: Icons.dns_outlined,
            label: 'Source',
            items: c.filteredSourceNames,
            selected: c.selectedSourceName,
            searchText: c.sourceSearchText,
            onSearchChanged: _controller.setSourceSearchText,
            searchHint: 'Search sources…',
            theme: _theme,
            onSelected: (name) {
              final source = c.sources.firstWhere((s) => s.name == name);
              _controller.selectSource(source.id);
            },
          ),
          if (c.collections.isNotEmpty) ...[
            const SizedBox(height: 10),
            DbLensSelectorField(
              icon: Icons.table_rows_outlined,
              label: 'Collection',
              items: c.filteredCollections,
              selected: c.selectedCollection,
              searchText: c.collectionSearchText,
              onSearchChanged: _controller.setCollectionSearchText,
              searchHint: 'Search collections…',
              theme: _theme,
              onSelected: _controller.selectCollection,
            ),
          ],
          if (c.selectedSourceId != null && c.supportsRawSql) ...[
            const SizedBox(height: 10),
            _buildQuerySection(c),
          ],
          if (c.selectedSourceId != null &&
              (c.selectedCollection != null || c.queryMode)) ...[
            const SizedBox(height: 12),
            _buildSearchField(c),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchField(DbLensController c) {
    return TextField(
      controller: _searchController,
      onChanged: _controller.setSearchText,
      enabled: c.activeRows.isNotEmpty || c.queryMode,
      decoration: _theme.fieldDecoration(
        hintText: 'Search rows across all columns',
        prefixIcon: const Icon(Icons.search, size: 18),
        suffixIcon: c.searchText.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  _searchController.clear();
                  _controller.clearSearch();
                },
                icon: const Icon(Icons.close, size: 18),
              ),
      ),
    );
  }

  Widget _buildQuerySection(DbLensController c) {
    final canClear = c.queryMode || _queryController.text.trim().isNotEmpty;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _theme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _theme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.code_rounded, size: 16, color: _theme.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Raw SQL Query',
                    style: TextStyle(
                      color: _theme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _controller.toggleQueryExpanded,
                  child: Text(c.queryExpanded ? 'Collapse' : 'Expand'),
                ),
              ],
            ),
            if (c.queryExpanded || canClear) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _queryController,
                minLines: 2,
                maxLines: 6,
                onChanged: (_) => setState(() {}),
                decoration: _theme
                    .fieldDecoration(
                      hintText: 'SELECT * FROM users LIMIT 20',
                      fillColor: _theme.bg,
                    )
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
                    style: TextStyle(color: _theme.textMuted, fontSize: 11),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (canClear)
                        TextButton(
                          onPressed: c.runningQuery
                              ? null
                              : () {
                                  if (c.queryMode) {
                                    _controller.restoreTableView();
                                    return;
                                  }
                                  _queryController.clear();
                                  _controller.clearQueryInput();
                                },
                          child: const Text('Clear query'),
                        ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: c.runningQuery ? null : _confirmAndRunQuery,
                        icon: c.runningQuery
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.play_arrow_rounded, size: 18),
                        label: Text(c.runningQuery ? 'Running' : 'Run'),
                      ),
                    ],
                  ),
                ],
              ),
              if (c.queryError != null)
                _buildQueryMessage(
                  c.queryError!,
                  icon: Icons.error_outline,
                  color: Colors.redAccent,
                )
              else if (c.queryInfoMessage != null)
                _buildQueryMessage(
                  c.queryInfoMessage!,
                  icon: Icons.info_outline,
                  color: _theme.accent,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQueryMessage(
    String message, {
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _theme.bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _theme.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: _theme.textSecondary,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDataSlivers(DbLensController c) {
    final columns = c.activeColumns;
    final visibleRows = c.visibleRows(columns: columns);

    if (c.loading) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: ColoredBox(
            color: _theme.bg,
            child: DbLensLoadingIndicator(theme: _theme),
          ),
        ),
      ];
    }

    if (c.selectedCollection == null && !c.queryMode) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: ColoredBox(
            color: _theme.bg,
            child: DbLensEmptyPlaceholder(
              icon: Icons.table_chart_outlined,
              title: 'Select a collection',
              subtitle: 'Pick a source and collection above to inspect rows',
              theme: _theme,
            ),
          ),
        ),
      ];
    }

    if (c.activeRows.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: ColoredBox(
            color: _theme.bg,
            child: DbLensEmptyPlaceholder(
              icon: c.queryMode
                  ? Icons.search_off_outlined
                  : Icons.inbox_outlined,
              title: c.queryMode
                  ? (c.queryInfoMessage ?? 'No rows returned')
                  : 'Collection is empty',
              subtitle: c.queryMode
                  ? 'Run another query or clear query to return to the table view'
                  : 'No rows found in "${c.selectedCollection}"',
              theme: _theme,
            ),
          ),
        ),
      ];
    }

    if (visibleRows.isEmpty && c.hasActiveSearch) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: ColoredBox(
            color: _theme.bg,
            child: DbLensEmptyPlaceholder(
              icon: Icons.search_off_outlined,
              title: 'No results for "${c.searchText.trim()}"',
              subtitle: 'Try a different keyword or clear the search field',
              theme: _theme,
            ),
          ),
        ),
      ];
    }

    return [
      if (c.queryMode && c.queryCustomResult)
        SliverToBoxAdapter(child: _buildCustomQueryBanner(c)),
      SliverToBoxAdapter(
        child: _buildTableToolbar(c, visibleRows.length),
      ),
      SliverToBoxAdapter(
        child: ColoredBox(
          color: _theme.bg,
          child: Stack(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: switch (_dataView) {
                  _DbLensDataView.json => _buildJsonArrayView(visibleRows),
                  _DbLensDataView.list => _buildListView(c, visibleRows, columns),
                  _DbLensDataView.table => SingleChildScrollView(
                      key: const ValueKey('table-view'),
                      scrollDirection: Axis.horizontal,
                      primary: false,
                      child: _buildDataTable(c, visibleRows, columns),
                    ),
                },
              ),
              if (c.isPageTransition)
                Positioned.fill(
                  child: DbLensTablePageSkeleton(theme: _theme),
                ),
              if (c.copyingJson)
                Positioned.fill(
                  child: ColoredBox(
                    color: _theme.bg.withValues(alpha: 0.7),
                    child: DbLensLoadingIndicator(theme: _theme),
                  ),
                ),
            ],
          ),
        ),
      ),
      SliverToBoxAdapter(child: _buildPagination(c)),
    ];
  }

  Widget _buildListView(
    DbLensController c,
    List<Map<String, Object?>> rows,
    List<String> columns,
  ) {
    return Padding(
      key: const ValueKey('list-view'),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          for (final entry in rows.asMap().entries)
            _buildListCard(
              c,
              entry.value,
              columns,
              (c.pagination?.rangeStart ?? 1) + entry.key,
            ),
        ],
      ),
    );
  }

  Widget _buildListCard(
    DbLensController c,
    Map<String, Object?> row,
    List<String> columns,
    int rowNum,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _theme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _theme.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _showRowJsonView(row, rowNum: rowNum),
        onLongPress: () => _copyRow(row),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '#$rowNum',
                style: TextStyle(
                  color: _theme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 6),
              for (final col in columns)
                if (col != kDbLensRowIdColumn) _buildListField(c, col, row),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListField(
    DbLensController c,
    String col,
    Map<String, Object?> row,
  ) {
    final value = row[col];
    final formatted = DbLensRowUtils.formatValue(value);
    final editable = c.canEditCells;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: GestureDetector(
        onLongPress: editable
            ? () => _showEditCellDialog(
                  column: col,
                  currentValue: value,
                  row: row,
                )
            : null,
        behavior: HitTestBehavior.opaque,
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$col: ',
                style: TextStyle(
                  color: _theme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(
                text: formatted,
                style: TextStyle(
                  color: DbLensRowUtils.valueColor(value, _theme),
                  fontSize: DbLensTheme.dataFontSize,
                  fontStyle: value == null ? FontStyle.italic : FontStyle.normal,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJsonArrayView(List<Map<String, Object?>> rows) {
    return Padding(
      key: const ValueKey('json-view'),
      padding: const EdgeInsets.all(16),
      child: SelectableText(
        DbLensJsonUtils.encodePrettyArray(rows),
        style: TextStyle(
          fontSize: DbLensTheme.dataFontSize,
          height: 1.5,
          color: _theme.textPrimary,
          overflow: TextOverflow.clip,
        ),
      ),
    );
  }

  Widget _buildCustomQueryBanner(DbLensController c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: DbLensChip(
        icon: Icons.query_stats,
        label: 'Custom query result — collection not switched',
        foreground: _theme.accent,
        background: _theme.accentSoft,
        borderColor: _theme.accent.withValues(alpha: 0.25),
        borderRadius: 8,
        expandWidth: true,
      ),
    );
  }

  Widget _buildTableToolbar(
    DbLensController c,
    int visibleCount,
  ) {
    final pagination = c.pagination;
    final statusText = c.queryMode
        ? '$visibleCount of ${c.activeRowCount}'
        : pagination != null && pagination.totalRows > 0
            ? '${pagination.rangeStart}–${pagination.rangeEnd} of ${pagination.totalRows}'
            : '0 rows';

    final hintText = switch (_dataView) {
      _DbLensDataView.json => 'Current page as JSON · copy button copies all rows',
      _DbLensDataView.list => c.canEditCells
          ? 'Tap card to view JSON · long-press a field to edit'
          : 'Tap card to view JSON · long-press card to copy',
      _DbLensDataView.table => c.canEditCells
          ? 'Tap row to view JSON · long-press cell to edit'
          : 'Tap row to view JSON · long-press index to copy',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _theme.surface,
        border: Border(bottom: BorderSide(color: _theme.border)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 13, color: _theme.textMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              hintText,
              style: TextStyle(color: _theme.textMuted, fontSize: 11),
            ),
          ),
          Text(
            statusText,
            style: TextStyle(
              color: _theme.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 4),
          _buildViewToggleButton(
            icon: Icons.table_rows_outlined,
            tooltip: 'Table view',
            view: _DbLensDataView.table,
          ),
          _buildViewToggleButton(
            icon: Icons.view_agenda_outlined,
            tooltip: 'List view',
            view: _DbLensDataView.list,
          ),
          _buildViewToggleButton(
            icon: Icons.data_object_outlined,
            tooltip: 'JSON view',
            view: _DbLensDataView.json,
          ),
          IconButton(
            tooltip: 'Copy all as JSON',
            onPressed: c.canCopyJson && !c.copyingJson ? _copyAllAsJson : null,
            visualDensity: VisualDensity.compact,
            icon: c.copyingJson
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _theme.accent,
                    ),
                  )
                : Icon(Icons.content_copy, size: 18, color: _theme.accent),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: c.canRefresh ? _controller.refresh : null,
            visualDensity: VisualDensity.compact,
            icon: c.refreshing
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _theme.accent,
                    ),
                  )
                : const Icon(Icons.refresh_rounded, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggleButton({
    required IconData icon,
    required String tooltip,
    required _DbLensDataView view,
  }) {
    final isActive = _dataView == view;
    return IconButton(
      tooltip: tooltip,
      onPressed: () => _setDataView(view),
      visualDensity: VisualDensity.compact,
      icon: Icon(
        icon,
        size: 18,
        color: isActive ? _theme.accent : _theme.textMuted,
      ),
    );
  }

  Widget _buildDataTable(
    DbLensController c,
    List<Map<String, Object?>> rows,
    List<String> columns,
  ) {
    return Table(
      defaultColumnWidth: const IntrinsicColumnWidth(),
      border: TableBorder(
        horizontalInside: BorderSide(color: _theme.border),
        verticalInside: BorderSide(color: _theme.border),
      ),
      children: [
        TableRow(
          decoration: BoxDecoration(color: _theme.surface),
          children: [
            _buildIndexHeaderCell(),
            ...columns.map((col) => _buildHeaderCell(c, col)),
          ],
        ),
        ...rows.asMap().entries.map((entry) {
          final index = entry.key;
          final row = entry.value;
          final rowNum = (c.pagination?.rangeStart ?? 1) + index;
          return TableRow(
            decoration: BoxDecoration(
              color: index.isEven ? _theme.bg : _theme.surface,
            ),
            children: [
              _buildIndexCell(rowNum, row),
              ...columns.map((col) {
                final value = row[col];
                final formatted = DbLensRowUtils.formatValue(value);
                final display = formatted.length > 48
                    ? '${formatted.substring(0, 48)}…'
                    : formatted;
                return _buildDataCell(
                  display: display,
                  value: value,
                  column: col,
                  row: row,
                  rowNum: rowNum,
                  editable: c.canEditCells && col != kDbLensRowIdColumn,
                );
              }),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildIndexHeaderCell() {
    return SizedBox(
      width: DbLensTheme.indexColWidth,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: DbLensTheme.cellPaddingV,
        ),
        child: Text(
          '#',
          style: TextStyle(
            color: _theme.textMuted.withValues(alpha: 0.9),
            fontSize: DbLensTheme.headerFontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(DbLensController c, String label) {
    final isActive = c.sortColumn == label;
    final indicator = !isActive ? '' : (c.sortAscending ? ' ↑' : ' ↓');

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DbLensTheme.cellPaddingH,
        vertical: DbLensTheme.cellPaddingV,
      ),
      child: InkWell(
        onTap: () => _controller.toggleSort(label),
        borderRadius: BorderRadius.circular(6),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: DbLensTheme.cellMinWidth),
          child: Text(
            '$label$indicator',
            style: TextStyle(
              color: isActive ? _theme.textPrimary : _theme.textSecondary,
              fontSize: DbLensTheme.headerFontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }

  void _showRowJsonView(Map<String, Object?> row, {int? rowNum}) {
    DbLensRowJsonSheet.show(
      context,
      row: row,
      theme: _theme,
      rowNum: rowNum,
      canEdit: _controller.canEditCells,
      onCopied: () => _showSnackBar('Copied as JSON'),
      onSave: (updated) => _controller.updateRowFromJson(row, updated),
      onSaved: () => _showSnackBar('Row updated'),
    );
  }

  Future<void> _showHistorySheet(DbLensController c) async {
    final sourceId = c.selectedSourceId;
    if (sourceId == null) return;

    final historyController = DbLens.createHistoryController();
    await historyController.loadFor(sourceId);

    if (!mounted) {
      historyController.dispose();
      return;
    }

    await DbLensHistorySheet.show(
      context,
      controller: historyController,
      theme: _theme,
      sourceName: c.selectedSourceName ?? sourceId,
    );

    historyController.dispose();
  }

  Widget _buildIndexCell(int rowNum, Map<String, Object?> row) {
    return GestureDetector(
      onTap: () => _showRowJsonView(row, rowNum: rowNum),
      onLongPress: () => _copyRow(row),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: DbLensTheme.indexColWidth,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: DbLensTheme.cellPaddingV,
          ),
          child: Text(
            '$rowNum',
            style: TextStyle(
              color: _theme.textMuted.withValues(alpha: 0.85),
              fontSize: DbLensTheme.dataFontSize - 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataCell({
    required String display,
    required Object? value,
    required String column,
    required Map<String, Object?> row,
    required int rowNum,
    required bool editable,
  }) {
    final isNull = value == null;
    return GestureDetector(
      onTap: () => _showRowJsonView(row, rowNum: rowNum),
      onLongPress: editable
          ? () => _showEditCellDialog(
                column: column,
                currentValue: value,
                row: row,
              )
          : () => _copyRow(row),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DbLensTheme.cellPaddingH,
          vertical: DbLensTheme.cellPaddingV,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: DbLensTheme.cellMinWidth),
          child: Text(
            display,
            style: TextStyle(
              color: DbLensRowUtils.valueColor(value, _theme),
              fontSize: DbLensTheme.dataFontSize,
              fontStyle: isNull ? FontStyle.italic : FontStyle.normal,
              height: 1.35,
            ),
          ),
        ),
      ),
    );
  }

  void _copyRow(Map<String, Object?> row) {
    final exportRow = Map<String, Object?>.from(
      withoutRowIdEntry(Map<String, dynamic>.from(row)),
    );
    Clipboard.setData(ClipboardData(text: jsonEncode(exportRow)));
    _showSnackBar('Copied as JSON');
  }

  Widget _buildEmptyState() {
    return ColoredBox(
      color: _theme.bg,
      child: DbLensEmptyPlaceholder(
        icon: Icons.storage_outlined,
        title: 'No sources registered',
        subtitle: "Call DbLens.register('Name', db) before opening the panel",
        theme: _theme,
      ),
    );
  }

  Widget _buildPagination(DbLensController c) {
    final pagination = c.pagination;

    if (pagination != null) {
      return DbLensPaginationBar(
        page: pagination.page,
        totalPages: pagination.totalPages,
        rangeStart: pagination.rangeStart,
        rangeEnd: pagination.rangeEnd,
        totalRows: pagination.totalRows,
        canGoPrevious: pagination.canGoPrevious,
        canGoNext: pagination.canGoNext,
        isLoading: pagination.isLoading,
        theme: _theme,
        onPrevious: () => pagination.previousPage(),
        onNext: () => pagination.nextPage(),
        onJumpToPage: (page) => pagination.jumpToPage(page),
      );
    }

    final totalRows = c.activeRowCount;
    return DbLensPaginationBar(
      page: 0,
      totalPages: 1,
      rangeStart: totalRows == 0 ? 0 : 1,
      rangeEnd: totalRows,
      totalRows: totalRows,
      canGoPrevious: false,
      canGoNext: false,
      isLoading: false,
      theme: _theme,
      onPrevious: () {},
      onNext: () {},
    );
  }
}

class _EditCellDialog extends StatefulWidget {
  const _EditCellDialog({
    required this.column,
    required this.currentValue,
    required this.theme,
  });

  static const cancelled = Object();

  final String column;
  final Object? currentValue;
  final DbLensTheme theme;

  @override
  State<_EditCellDialog> createState() => _EditCellDialogState();
}

class _EditCellDialogState extends State<_EditCellDialog> {
  late final TextEditingController _textController;
  late bool _boolValue;

  @override
  void initState() {
    super.initState();
    _boolValue =
        widget.currentValue is bool ? widget.currentValue! as bool : false;
    _textController = TextEditingController(
      text: widget.currentValue?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Object? _parseValue() {
    final value = widget.currentValue;
    if (value is bool) return _boolValue;
    if (value is int) return int.tryParse(_textController.text.trim());
    if (value is double) return double.tryParse(_textController.text.trim());
    if (value is num) {
      final parsed = num.tryParse(_textController.text.trim());
      return parsed;
    }
    if (value == null && _textController.text.trim().toLowerCase() == 'null') {
      return null;
    }
    return _textController.text;
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.currentValue;
    final isBool = value is bool;

    return AlertDialog(
      title: Text('Edit ${widget.column}'),
      content: isBool
          ? SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Value'),
              value: _boolValue,
              onChanged: (v) => setState(() => _boolValue = v),
            )
          : TextField(
              controller: _textController,
              autofocus: true,
              keyboardType: value is num
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
              decoration: InputDecoration(
                labelText: 'New value',
                border: widget.theme.outlineBorder(),
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, _EditCellDialog.cancelled),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _parseValue()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/models/db_lens_config.dart';
import '../../db_lens_facade.dart';
import '../controllers/db_lens_controller.dart';
import '../theme/db_lens_theme.dart';
import '../utils/row_utils.dart';
import '../widgets/db_lens_panel_widgets.dart';

/// Panel inspeksi database — hanya berinteraksi dengan [DbLensController].
class DbLensPanel extends StatefulWidget {
  const DbLensPanel({super.key, this.config = const DbLensConfig()});

  final DbLensConfig config;

  @override
  State<DbLensPanel> createState() => _DbLensPanelState();
}

class _DbLensPanelState extends State<DbLensPanel> {
  late final DbLensController _controller;
  bool _isClosing = false;

  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _queryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = DbLens.createController(config: widget.config);
    _controller.addListener(_onControllerChanged);
    _controller.initialize();
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
    _controller.dispose();
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? Colors.redAccent : DbLensTheme.accent,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: DbLensTheme.textPrimary),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: DbLensTheme.bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: DbLensTheme.border),
        ),
      ),
    );
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
          final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
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
                  decoration: DbLensTheme.sheetDecoration(size: sheetSize),
                  child: Padding(
                    padding: EdgeInsets.only(bottom: bottomInset),
                    child: CustomScrollView(
                      controller: scrollController,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      slivers: [
                        SliverToBoxAdapter(child: _buildTopSection(c)),
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: !c.hasSources
                              ? _buildEmptyState()
                              : _buildBody(c),
                        ),
                      ],
                    ),
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
      decoration: const BoxDecoration(
        color: DbLensTheme.bg,
        borderRadius: BorderRadius.vertical(top: DbLensTheme.sheetRadius),
        border: Border(bottom: BorderSide(color: DbLensTheme.border)),
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
          ),
          _buildHeader(c),
          if (c.hasSources) ...[
            const Divider(height: 1, thickness: 1, color: DbLensTheme.border),
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
              backgroundColor: DbLensTheme.accentSoft,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
                side: BorderSide(
                  color: DbLensTheme.accent.withValues(alpha: 0.25),
                ),
              ),
            ),
            icon: const Icon(Icons.close_rounded, size: 15, color: DbLensTheme.accent),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DB Lens',
                  style: TextStyle(
                    color: DbLensTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                    height: 1.2,
                  ),
                ),
                Text(
                  'Database inspector',
                  style: TextStyle(
                    color: DbLensTheme.textMuted,
                    fontSize: 11,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          if (c.selectedCollection != null) _buildRowCountBadge(c),
        ],
      ),
    );
  }

  Widget _buildRowCountBadge(DbLensController c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: DbLensTheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: DbLensTheme.border),
      ),
      child: Text(
        '${c.activeRowCount} rows',
        style: const TextStyle(
          color: DbLensTheme.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          fontFamily: 'monospace',
          letterSpacing: -0.2,
        ),
      ),
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
            items: c.sourceNames,
            selected: c.selectedSourceName,
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
              items: c.collections,
              selected: c.selectedCollection,
              onSelected: _controller.selectCollection,
            ),
          ],
          if (c.selectedSourceId != null) ...[
            const SizedBox(height: 12),
            _buildSearchField(c),
            if (c.supportsRawSql) ...[
              const SizedBox(height: 10),
              _buildQuerySection(c),
            ],
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
      decoration: DbLensTheme.fieldDecoration(
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
        color: DbLensTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DbLensTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.code_rounded, size: 16, color: DbLensTheme.textMuted),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Raw SQL Query',
                    style: TextStyle(
                      color: DbLensTheme.textPrimary,
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
                decoration: DbLensTheme.fieldDecoration(
                  hintText: 'SELECT * FROM users LIMIT 20',
                  fillColor: DbLensTheme.bg,
                ).copyWith(contentPadding: const EdgeInsets.all(12)),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                runSpacing: 8,
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'SELECT runs directly. Non-SELECT queries require confirmation.',
                    style: TextStyle(color: DbLensTheme.textMuted, fontSize: 11),
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
                  color: DbLensTheme.accent,
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
          color: DbLensTheme.bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: DbLensTheme.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: DbLensTheme.textSecondary,
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

  Widget _buildBody(DbLensController c) {
    final columns = c.activeColumns;
    final visibleRows = c.visibleRows(columns: columns);

    if (c.loading) {
      return const ColoredBox(color: DbLensTheme.bg, child: DbLensLoadingIndicator());
    }

    if (c.selectedCollection == null && !c.queryMode) {
      return const ColoredBox(
        color: DbLensTheme.bg,
        child: DbLensEmptyPlaceholder(
          icon: Icons.table_chart_outlined,
          title: 'Select a collection',
          subtitle: 'Pick a source and collection above to inspect rows',
        ),
      );
    }

    if (c.activeRows.isEmpty) {
      return ColoredBox(
        color: DbLensTheme.bg,
        child: DbLensEmptyPlaceholder(
          icon: c.queryMode ? Icons.search_off_outlined : Icons.inbox_outlined,
          title: c.queryMode
              ? (c.queryInfoMessage ?? 'No rows returned')
              : 'Collection is empty',
          subtitle: c.queryMode
              ? 'Run another query or clear query to return to the table view'
              : 'No rows found in "${c.selectedCollection}"',
        ),
      );
    }

    if (visibleRows.isEmpty && c.hasActiveSearch) {
      return ColoredBox(
        color: DbLensTheme.bg,
        child: DbLensEmptyPlaceholder(
          icon: Icons.search_off_outlined,
          title: 'No results for "${c.searchText.trim()}"',
          subtitle: 'Try a different keyword or clear the search field',
        ),
      );
    }

    return ColoredBox(
      color: DbLensTheme.bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTableToolbar(c, visibleRows.length),
          Expanded(
            child: Stack(
              children: [
                Scrollbar(
                  child: SingleChildScrollView(
                    primary: false,
                    physics: const ClampingScrollPhysics(),
                    child: SingleChildScrollView(
                      primary: false,
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      child: _buildDataTable(c, visibleRows, columns),
                    ),
                  ),
                ),
                if (c.isPageTransition)
                  const Positioned.fill(
                    child: DbLensTablePageSkeleton(
                      rowCount: 6,
                      columnCount: 5,
                    ),
                  ),
              ],
            ),
          ),
          _buildPagination(c),
        ],
      ),
    );
  }

  Widget _buildTableToolbar(DbLensController c, int visibleCount) {
    final pagination = c.pagination;
    final statusText = c.queryMode
        ? '$visibleCount of ${c.activeRowCount}'
        : pagination != null && pagination.totalRows > 0
            ? '${pagination.rangeStart}–${pagination.rangeEnd} of ${pagination.totalRows}'
            : '0 rows';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: DbLensTheme.surface,
        border: Border(bottom: BorderSide(color: DbLensTheme.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 13, color: DbLensTheme.textMuted),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              'Long-press any cell to copy row as JSON',
              style: TextStyle(color: DbLensTheme.textMuted, fontSize: 11),
            ),
          ),
          Text(
            statusText,
            style: const TextStyle(
              color: DbLensTheme.textSecondary,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Refresh',
            onPressed: c.canRefresh ? _controller.refresh : null,
            visualDensity: VisualDensity.compact,
            icon: c.refreshing
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: DbLensTheme.accent,
                    ),
                  )
                : const Icon(Icons.refresh_rounded, size: 18),
          ),
        ],
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
      border: const TableBorder(
        horizontalInside: BorderSide(color: DbLensTheme.border),
        verticalInside: BorderSide(color: DbLensTheme.border),
      ),
      children: [
        TableRow(
          decoration: const BoxDecoration(color: DbLensTheme.surface),
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
              color: index.isEven ? DbLensTheme.bg : DbLensTheme.surface,
            ),
            children: [
              _buildIndexCell(rowNum, row),
              ...columns.map((col) {
                final value = row[col];
                final formatted = RowUtils.formatValue(value);
                final display = formatted.length > 48
                    ? '${formatted.substring(0, 48)}…'
                    : formatted;
                return _buildDataCell(display, value, row);
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
            color: DbLensTheme.textMuted.withValues(alpha: 0.9),
            fontSize: DbLensTheme.headerFontSize,
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
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
              color: isActive ? DbLensTheme.textPrimary : DbLensTheme.textSecondary,
              fontSize: DbLensTheme.headerFontSize,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIndexCell(int rowNum, Map<String, Object?> row) {
    return GestureDetector(
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
              color: DbLensTheme.textMuted.withValues(alpha: 0.85),
              fontSize: DbLensTheme.dataFontSize - 1,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataCell(
    String display,
    Object? value,
    Map<String, Object?> row,
  ) {
    final isNull = value == null;
    return GestureDetector(
      onLongPress: () => _copyRow(row),
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
              color: RowUtils.valueColor(value),
              fontSize: DbLensTheme.dataFontSize,
              fontFamily: 'monospace',
              fontStyle: isNull ? FontStyle.italic : FontStyle.normal,
              height: 1.35,
            ),
          ),
        ),
      ),
    );
  }

  void _copyRow(Map<String, Object?> row) {
    Clipboard.setData(ClipboardData(text: jsonEncode(row)));
    _showSnackBar('Copied as JSON');
  }

  Widget _buildEmptyState() {
    return const ColoredBox(
      color: DbLensTheme.bg,
      child: DbLensEmptyPlaceholder(
        icon: Icons.storage_outlined,
        title: 'No sources registered',
        subtitle: "Call DbLens.register('Name', db) before opening the panel",
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
      onPrevious: () {},
      onNext: () {},
    );
  }
}

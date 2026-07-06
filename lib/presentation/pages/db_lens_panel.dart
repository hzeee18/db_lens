import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/models/db_lens_config.dart';
import '../../db_lens_facade.dart';
import '../controllers/db_lens_controller.dart';
import '../hooks/db_lens_cell_editor_builder.dart';
import '../scope/db_lens_controller_scope.dart';
import '../state/db_lens_pagination.dart';
import '../theme/db_lens_theme.dart';
import '../utils/db_lens_row_id_utils.dart';
import '../utils/db_lens_snackbar.dart';
import '../widgets/db_lens_cell_editor.dart';
import '../widgets/db_lens_chip.dart';
import '../widgets/db_lens_collection_list.dart';
import '../widgets/db_lens_empty_state.dart';
import '../widgets/db_lens_history_sheet.dart';
import '../widgets/db_lens_json_view.dart';
import '../widgets/db_lens_list_view.dart';
import '../widgets/db_lens_loading_view.dart';
import '../widgets/db_lens_pagination_bar.dart';
import '../widgets/db_lens_panel_widgets.dart';
import '../widgets/db_lens_query_editor.dart';
import '../widgets/db_lens_row_json_sheet.dart';
import '../widgets/db_lens_search_bar.dart';
import '../widgets/db_lens_source_list.dart';
import '../widgets/db_lens_table_view.dart';
import '../widgets/db_lens_toolbar.dart';

enum _DbLensDataView { table, list, json }

/// Panel inspeksi database bawaan — disusun dari widget-widget publik yang
/// sama yang tersedia untuk custom UI (lihat [DbLensSourceList],
/// [DbLensToolbar], [DbLensTableView], dst.). Bukan implementasi paralel.
class DbLensPanel extends StatelessWidget {
  const DbLensPanel({
    super.key,
    this.config = const DbLensConfig(),
    this.controller,
  });

  final DbLensConfig config;

  /// Jika diisi, panel memakai controller ini dan TIDAK men-dispose-nya.
  /// Caller harus memanggil [DbLensController.initialize] sebelum widget
  /// dipasang. Jika null, panel membuat dan mengelola controller sendiri.
  final DbLensController? controller;

  @override
  Widget build(BuildContext context) {
    return DbLensControllerScope(
      controller: controller,
      config: config,
      child: const _DbLensPanelSheet(),
    );
  }
}

class _DbLensPanelSheet extends StatefulWidget {
  const _DbLensPanelSheet();

  @override
  State<_DbLensPanelSheet> createState() => _DbLensPanelSheetState();
}

class _DbLensPanelSheetState extends State<_DbLensPanelSheet> {
  bool _isClosing = false;
  _DbLensDataView _dataView = _DbLensDataView.table;
  DbLensController? _listenedController;

  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  final TextEditingController _searchController = TextEditingController();

  DbLensTheme get _theme => DbLensThemeScope.of(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final c = DbLensControllerScope.of(context);
    if (!identical(_listenedController, c)) {
      _listenedController?.removeListener(_onControllerChanged);
      c.addListener(_onControllerChanged);
      _listenedController = c;
    }
  }

  @override
  void dispose() {
    _listenedController?.removeListener(_onControllerChanged);
    _sheetController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    final c = _listenedController;
    if (c != null && c.lastError != null) {
      _showSnackBar(c.lastError!, isError: true);
      c.lastError = null;
    }
    setState(() {});
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

  void _setDataView(_DbLensDataView view) => setState(() => _dataView = view);

  Future<void> _showEditCellDialog({
    required String column,
    required Object? currentValue,
    required Map<String, Object?> row,
  }) async {
    final c = DbLensControllerScope.of(context);
    if (!c.canEditCells) return;

    Object? result;
    try {
      result = await DbLensCellEditor.show(context, column, currentValue);
    } on DbLensCellEditCancelled {
      return;
    }

    if (!mounted) return;
    final success = await c.updateCellValue(column: column, newValue: result, row: row);
    if (success && mounted) _showSnackBar('Cell updated');
  }

  void _showRowJsonView(Map<String, Object?> row, {int? rowNum}) {
    final c = DbLensControllerScope.of(context);
    DbLensRowJsonSheet.show(
      context,
      row: row,
      theme: _theme,
      rowNum: rowNum,
      canEdit: c.canEditCells,
      onCopied: () => _showSnackBar('Copied as JSON'),
      onSave: (updated) => c.updateRowFromJson(row, updated),
      onSaved: () => _showSnackBar('Row updated'),
    );
  }

  void _copyRow(Map<String, Object?> row) {
    final exportRow = Map<String, Object?>.from(
      withoutRowIdEntry(Map<String, dynamic>.from(row)),
    );
    Clipboard.setData(ClipboardData(text: jsonEncode(exportRow)));
    _showSnackBar('Copied as JSON');
  }

  Future<void> _showHistorySheet(DbLensController c) async {
    final sourceId = c.source.selectedSourceId;
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
      sourceName: c.source.selectedSourceName ?? sourceId,
      theme: _theme,
    );
    historyController.dispose();
  }

  DbLensPaginationController<Map<String, Object?>>? _activePagination(DbLensController c) =>
      c.query.queryMode ? c.query.pagination : c.table.pagination;

  @override
  Widget build(BuildContext context) {
    final c = DbLensControllerScope.of(context);

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
              final sheetSize =
                  _sheetController.isAttached ? _sheetController.size : DbLensTheme.initialChildSize;
              return DbLensUnfocusTap(
                onTapOutside: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: DecoratedBox(
                  decoration: _theme.sheetDecoration(size: sheetSize),
                  child: CustomScrollView(
                    controller: scrollController,
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    slivers: [
                      SliverToBoxAdapter(child: _buildTopSection(c)),
                      if (!c.source.hasSources)
                        SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState())
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
          if (c.source.hasSources) ...[
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
                side: BorderSide(color: _theme.accent.withValues(alpha: 0.25)),
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
                  style: TextStyle(color: _theme.textMuted, fontSize: 11, height: 1.2),
                ),
              ],
            ),
          ),
          if (c.source.selectedSourceId != null)
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
                  side: BorderSide(color: _theme.accent.withValues(alpha: 0.25)),
                ),
              ),
              icon: Icon(Icons.history, size: 15, color: _theme.accent),
            ),
          if (c.source.selectedSourceId != null) const SizedBox(width: 6),
          if (c.source.selectedCollection != null || c.query.queryMode)
            DbLensChip(
              label: '${c.activeRowCount} rows',
              foreground: _theme.textSecondary,
              background: _theme.surface,
              borderColor: _theme.border,
              borderRadius: 6,
            ),
        ],
      ),
    );
  }

  Widget _buildSelectorSection(DbLensController c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DbLensSourceList(),
          if (c.source.collections.isNotEmpty) ...[
            const SizedBox(height: 10),
            const DbLensCollectionList(),
          ],
          if (c.source.selectedSourceId != null && c.source.supportsRawSql) ...[
            const SizedBox(height: 10),
            const DbLensQueryEditor(),
          ],
          if (c.source.selectedSourceId != null &&
              (c.source.selectedCollection != null || c.query.queryMode)) ...[
            const SizedBox(height: 12),
            DbLensSearchBar(
              controller: _searchController,
              hintText: 'Search rows across all columns',
              onChanged: c.table.setSearchText,
              onClear: c.table.clearSearch,
              showClear: c.table.searchText.isNotEmpty,
              padding: EdgeInsets.zero,
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildDataSlivers(DbLensController c) {
    final columns = c.activeColumns;
    final visibleRows = c.visibleRows(columns: columns);

    if (c.table.loading) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: ColoredBox(color: _theme.bg, child: DbLensLoadingView(theme: _theme)),
        ),
      ];
    }

    if (c.source.selectedCollection == null && !c.query.queryMode) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: ColoredBox(
            color: _theme.bg,
            child: DbLensEmptyState(
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
            child: DbLensEmptyState(
              icon: c.query.queryMode ? Icons.search_off_outlined : Icons.inbox_outlined,
              title: c.query.queryMode
                  ? (c.query.queryInfoMessage ?? 'No rows returned')
                  : 'Collection is empty',
              subtitle: c.query.queryMode
                  ? 'Run another query or clear query to return to the table view'
                  : 'No rows found in "${c.source.selectedCollection}"',
              theme: _theme,
            ),
          ),
        ),
      ];
    }

    if (visibleRows.isEmpty && c.table.hasActiveSearch) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: ColoredBox(
            color: _theme.bg,
            child: DbLensEmptyState(
              icon: Icons.search_off_outlined,
              title: 'No results for "${c.table.searchText.trim()}"',
              subtitle: 'Try a different keyword or clear the search field',
              theme: _theme,
            ),
          ),
        ),
      ];
    }

    return [
      if (c.query.queryMode && c.query.queryCustomResult)
        SliverToBoxAdapter(child: _buildCustomQueryBanner()),
      SliverToBoxAdapter(child: _buildToolbar(c, visibleRows.length)),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 420,
          child: ColoredBox(
            color: _theme.bg,
            child: Stack(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: switch (_dataView) {
                    _DbLensDataView.json =>
                      DbLensJsonView(key: const ValueKey('json-view'), rows: visibleRows),
                    _DbLensDataView.list => DbLensListView(
                        key: const ValueKey('list-view'),
                        rows: visibleRows,
                        columns: columns,
                        rowNumberStart: (c.table.pagination?.rangeStart ?? 1),
                        canEditColumn: (col) => c.canEditCells && col != kDbLensRowIdColumn,
                        onEditCell: (col, value, row) =>
                            _showEditCellDialog(column: col, currentValue: value, row: row),
                        onCopyRow: _copyRow,
                      ),
                    _DbLensDataView.table => DbLensTableView(
                        key: const ValueKey('table-view'),
                        rows: visibleRows,
                        columns: columns,
                        rowNumberStart: (c.table.pagination?.rangeStart ?? 1),
                        sortColumn: c.table.sortColumn,
                        sortAscending: c.table.sortAscending,
                        onSort: c.table.toggleSort,
                        onRowTap: (row) => _showRowJsonView(row),
                        onIndexLongPress: _copyRow,
                        onCellLongPress: (col, row) {
                          if (c.canEditCells && col != kDbLensRowIdColumn) {
                            _showEditCellDialog(
                              column: col,
                              currentValue: row[col],
                              row: row,
                            );
                          } else {
                            _copyRow(row);
                          }
                        },
                      ),
                  },
                ),
                if (_isPageTransition(c))
                  Positioned.fill(child: DbLensTablePageSkeleton(theme: _theme)),
                if (c.copyingJson)
                  Positioned.fill(
                    child: ColoredBox(
                      color: _theme.bg.withValues(alpha: 0.7),
                      child: DbLensLoadingView(theme: _theme),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      SliverToBoxAdapter(child: _buildPagination(c)),
    ];
  }

  bool _isPageTransition(DbLensController c) {
    final pagination = _activePagination(c);
    return pagination != null && pagination.isLoading && !pagination.isInitialLoad;
  }

  Widget _buildCustomQueryBanner() {
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

  Widget _buildToolbar(DbLensController c, int visibleCount) {
    final pagination = _activePagination(c);
    final statusText = c.query.queryMode
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

    return DbLensToolbar(
      status: Row(
        children: [
          Expanded(
            child: Text(hintText, style: TextStyle(color: _theme.textMuted, fontSize: 11)),
          ),
          Text(statusText, style: TextStyle(color: _theme.textSecondary, fontSize: 11)),
        ],
      ),
      actions: [
        for (final view in _DbLensDataView.values) _buildViewToggleButton(view),
        DbLensCopyJsonAction(onCopied: (_) => _showSnackBar('Copied all rows as JSON')),
        const DbLensRefreshAction(),
      ],
    );
  }

  Widget _buildViewToggleButton(_DbLensDataView view) {
    final icon = switch (view) {
      _DbLensDataView.table => Icons.table_rows_outlined,
      _DbLensDataView.list => Icons.view_agenda_outlined,
      _DbLensDataView.json => Icons.data_object_outlined,
    };
    final tooltip = switch (view) {
      _DbLensDataView.table => 'Table view',
      _DbLensDataView.list => 'List view',
      _DbLensDataView.json => 'JSON view',
    };
    final isActive = _dataView == view;
    return IconButton(
      tooltip: tooltip,
      onPressed: () => _setDataView(view),
      visualDensity: VisualDensity.compact,
      icon: Icon(icon, size: 18, color: isActive ? _theme.accent : _theme.textMuted),
    );
  }

  Widget _buildEmptyState() {
    return ColoredBox(
      color: _theme.bg,
      child: DbLensEmptyState(
        icon: Icons.storage_outlined,
        title: 'No sources registered',
        subtitle: "Call DbLens.register('Name', db) before opening the panel",
        theme: _theme,
      ),
    );
  }

  Widget _buildPagination(DbLensController c) {
    final pagination = _activePagination(c);

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
        onPrevious: pagination.previousPage,
        onNext: pagination.nextPage,
        onJumpToPage: pagination.jumpToPage,
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

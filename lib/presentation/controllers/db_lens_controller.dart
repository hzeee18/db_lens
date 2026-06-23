import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/enums/source_type.dart';
import '../../core/models/db_lens_config.dart';
import '../../domain/entities/source_entity.dart';
import '../../domain/repositories/lens_repository.dart';
import '../../domain/usecases/execute_statement_use_case.dart';
import '../../domain/usecases/get_all_rows_use_case.dart';
import '../../domain/usecases/get_collections_use_case.dart';
import '../../domain/usecases/get_columns_use_case.dart';
import '../../domain/usecases/get_row_count_use_case.dart';
import '../../domain/usecases/get_rows_use_case.dart';
import '../../domain/usecases/get_sources_use_case.dart';
import '../../domain/usecases/run_raw_query_count_use_case.dart';
import '../../domain/usecases/run_raw_query_paged_use_case.dart';
import '../../domain/usecases/update_cell_use_case.dart';
import '../state/db_lens_pagination.dart';
import '../../core/utils/sql_utils.dart';
import '../state/db_lens_panel_models.dart';
import '../utils/json_view_utils.dart';
import '../utils/row_utils.dart';

/// Controller presentasi — satu-satunya jembatan UI ke domain layer.
///
/// Mengelola sumber terpilih, koleksi, pagination, loading, dan query SQL.
class DbLensController extends ChangeNotifier {
  DbLensController({
    required GetSourcesUseCase getSources,
    required GetCollectionsUseCase getCollections,
    required GetRowsUseCase getRows,
    required GetRowCountUseCase getRowCount,
    required GetColumnsUseCase getColumns,
    required RunRawQueryPagedUseCase runRawQueryPaged,
    required RunRawQueryCountUseCase runRawQueryCount,
    required ExecuteStatementUseCase executeStatement,
    required UpdateCellUseCase updateCell,
    required GetAllRowsUseCase getAllRows,
    required LensRepository repository,
    this.config = const DbLensConfig(),
  })  : _getSources = getSources,
        _getCollections = getCollections,
        _getRows = getRows,
        _getRowCount = getRowCount,
        _getColumns = getColumns,
        _runRawQueryPaged = runRawQueryPaged,
        _runRawQueryCount = runRawQueryCount,
        _executeStatement = executeStatement,
        _updateCell = updateCell,
        _getAllRows = getAllRows,
        _repository = repository;

  final GetSourcesUseCase _getSources;
  final GetCollectionsUseCase _getCollections;
  final GetRowsUseCase _getRows;
  final GetRowCountUseCase _getRowCount;
  final GetColumnsUseCase _getColumns;
  final RunRawQueryPagedUseCase _runRawQueryPaged;
  final RunRawQueryCountUseCase _runRawQueryCount;
  final ExecuteStatementUseCase _executeStatement;
  final UpdateCellUseCase _updateCell;
  final GetAllRowsUseCase _getAllRows;
  final LensRepository _repository;

  final DbLensConfig config;

  // ── Observable state ──────────────────────────────────────────────────────

  List<SourceEntity> sources = [];
  String? selectedSourceId;
  String? selectedCollection;
  List<String> collections = [];

  List<String> columns = [];
  String? columnsTable;

  List<String> queryColumns = [];
  DbLensTableViewCache? tableViewCache;

  bool loading = false;
  bool refreshing = false;
  bool runningQuery = false;
  bool queryMode = false;
  bool queryExpanded = false;
  bool queryCustomResult = false;
  bool exporting = false;

  String searchText = '';
  String sourceSearchText = '';
  String collectionSearchText = '';
  String? sortColumn;
  bool sortAscending = true;
  String? queryError;
  String? queryInfoMessage;
  String? lastError;

  DbLensPaginationController<Map<String, Object?>>? pagination;
  String? paginationCollection;

  // ── Derived getters ───────────────────────────────────────────────────────

  bool get hasSources => sources.isNotEmpty;

  List<String> get sourceNames => sources.map((s) => s.name).toList();

  List<String> get filteredSourceNames =>
      RowUtils.filterItems(sourceNames, sourceSearchText);

  List<String> get filteredCollections =>
      RowUtils.filterItems(collections, collectionSearchText);

  String? get selectedSourceName {
    if (selectedSourceId == null) return null;
    for (final source in sources) {
      if (source.id == selectedSourceId) return source.name;
    }
    return null;
  }

  SourceType? get selectedSourceType =>
      selectedSourceId != null
          ? _repository.getSourceType(selectedSourceId!)
          : null;

  bool get canCopyJson =>
      !exporting &&
      !loading &&
      (queryMode
          ? activeRows.isNotEmpty || activeRowCount > 0
          : selectedCollection != null);

  bool get canEditCells =>
      !queryMode && !queryCustomResult && selectedCollection != null;

  List<Map<String, Object?>> get activeRows => pagination?.rows ?? const [];

  List<String> get activeColumns {
    final cols = queryMode ? queryColumns : columns;
    return cols.where((c) => c != '_rowid_').toList();
  }

  List<String> get displayColumns => activeColumns;

  int get activeRowCount => pagination?.totalRows ?? 0;

  bool get hasActiveSearch => searchText.trim().isNotEmpty;

  bool get supportsRawSql =>
      selectedSourceId != null && _repository.supportsRawSql(selectedSourceId!);

  bool get canRefresh {
    if (loading || runningQuery || exporting) return false;
    if (queryMode) return queryText.trim().isNotEmpty;
    if (selectedCollection == null) return false;
    return !(pagination?.isLoading ?? false);
  }

  bool get isPageTransition =>
      !queryMode &&
      pagination != null &&
      pagination!.isLoading &&
      !pagination!.isInitialLoad;

  String queryText = '';

  List<Map<String, Object?>> visibleRows({
    required List<String> columns,
  }) {
    return RowUtils.applySearchAndSort(
      rows: activeRows,
      columns: columns,
      searchText: searchText,
      sortColumn: sortColumn,
      sortAscending: sortAscending,
    );
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    sources = await _getSources();
    if (sources.isNotEmpty) {
      selectedSourceId = sources.first.id;
      await loadCollections(selectedSourceId!);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposePagination();
    super.dispose();
  }

  // ── Source & collection ───────────────────────────────────────────────────

  Future<void> selectSource(String sourceId) async {
    selectedSourceId = sourceId;
    sourceSearchText = '';
    collectionSearchText = '';
    notifyListeners();
    await loadCollections(sourceId);
  }

  Future<void> loadCollections(String sourceId) async {
    loading = true;
    lastError = null;
    notifyListeners();
    try {
      final result = await _getCollections(sourceId);
      collections = result.map((c) => c.name).toList();
      selectedCollection = null;
      _resetTableViewState();
      _resetQueryState();
      _resetSearchAndSort();
      loading = false;
      notifyListeners();
    } catch (error) {
      loading = false;
      lastError = 'Failed to load collections: $error';
      notifyListeners();
    }
  }

  Future<void> selectCollection(String collection) async {
    selectedCollection = collection;
    collectionSearchText = '';
    notifyListeners();
    await loadCollection(collection);
  }

  Future<void> loadCollection(String collection, {bool showLoading = true}) async {
    if (selectedSourceId == null) return;

    _ensureTablePagination(collection);

    final collectionChanged = columnsTable != collection;

    if (showLoading && (pagination!.isInitialLoad || collectionChanged)) {
      loading = true;
      notifyListeners();
    }

    try {
      if (collectionChanged || columns.isEmpty) {
        columns = await _getColumns(selectedSourceId!, collection);
        columnsTable = collection;
        notifyListeners();
      }

      await pagination!.loadPage(0);
      _resetQueryState();
      _resetSearchAndSort();
      loading = false;
      notifyListeners();
    } catch (error) {
      loading = false;
      lastError = 'Failed to load rows: $error';
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (!canRefresh) return;
    if (queryMode && queryText.trim().isNotEmpty) {
      await runQuery(fromRefresh: true);
      return;
    }
    final collection = selectedCollection;
    if (collection == null || selectedSourceId == null) return;
    try {
      _ensureTablePagination(collection);
      refreshing = true;
      notifyListeners();
      await pagination!.refresh();
      refreshing = false;
      notifyListeners();
    } catch (error) {
      refreshing = false;
      lastError = 'Failed to refresh: $error';
      notifyListeners();
    }
  }

  // ── Search & sort ─────────────────────────────────────────────────────────

  void setSearchText(String value) {
    searchText = value;
    notifyListeners();
  }

  void setSourceSearchText(String value) {
    sourceSearchText = value;
    notifyListeners();
  }

  void setCollectionSearchText(String value) {
    collectionSearchText = value;
    notifyListeners();
  }

  void clearSearch() {
    searchText = '';
    notifyListeners();
  }

  void toggleSort(String column) {
    if (sortColumn != column) {
      sortColumn = column;
      sortAscending = true;
    } else if (sortAscending) {
      sortAscending = false;
    } else {
      sortColumn = null;
      sortAscending = true;
    }
    notifyListeners();
  }

  void toggleQueryExpanded() {
    queryExpanded = !queryExpanded;
    notifyListeners();
  }

  void setQueryText(String value) {
    queryText = value;
    notifyListeners();
  }

  void clearQueryInput() {
    queryText = '';
    queryError = null;
    queryInfoMessage = null;
    notifyListeners();
  }

  void restoreTableView() {
    final cache = tableViewCache;
    final collection = selectedCollection;
    if (cache != null) {
      columns = List<String>.from(cache.columns);
      columnsTable = cache.columnsTable;
    }
    _resetQueryState();
    _resetSearchAndSort();
    if (collection != null) _ensureTablePagination(collection);
    notifyListeners();
  }

  // ── Cell edit ─────────────────────────────────────────────────────────────

  Future<bool> updateCellValue({
    required String column,
    required Object? newValue,
    required Map<String, Object?> row,
  }) async {
    final sourceId = selectedSourceId;
    final collection = selectedCollection;
    if (sourceId == null || collection == null || !canEditCells) return false;

    try {
      await _updateCell(sourceId, collection, column, newValue, row);
      await refresh();
      return true;
    } catch (error) {
      lastError = 'Failed to update cell: $error';
      notifyListeners();
      return false;
    }
  }

  /// Perbarui baris dari map JSON hasil edit. Mengembalikan pesan error atau null jika sukses.
  Future<String?> updateRowFromJson(
    Map<String, Object?> originalRow,
    Map<String, Object?> updatedRow,
  ) async {
    final sourceId = selectedSourceId;
    final collection = selectedCollection;
    if (sourceId == null || collection == null || !canEditCells) {
      return 'Editing is not available in this view.';
    }

    final original = Map<String, Object?>.from(originalRow);
    final originalDisplay = JsonViewUtils.prepareRow(original);
    final updated = Map<String, Object?>.from(updatedRow)..remove('_rowid_');

    final validationError = _validateRowUpdate(original, updated);
    if (validationError != null) return validationError;

    final changedColumns = <String>[];
    for (final key in originalDisplay.keys) {
      if (!updated.containsKey(key)) continue;
      if (!_valuesEqual(originalDisplay[key], updated[key])) {
        changedColumns.add(key);
      }
    }

    if (changedColumns.isEmpty) return null;

    try {
      for (final column in changedColumns) {
        await _updateCell(
          sourceId,
          collection,
          column,
          updated[column],
          original,
        );
      }
      await refresh();
      return null;
    } catch (error) {
      return 'Failed to update row: $error';
    }
  }

  String? _validateRowUpdate(
    Map<String, Object?> original,
    Map<String, Object?> updated,
  ) {
    if (selectedSourceType == SourceType.sharedPreferences) {
      return _validateSharedPreferencesRowUpdate(original, updated);
    }
    return null;
  }

  String? _validateSharedPreferencesRowUpdate(
    Map<String, Object?> original,
    Map<String, Object?> updated,
  ) {
    final expectedType = original['type'] as String?;
    if (expectedType == null) return null;

    if (updated.containsKey('type') &&
        updated['type']?.toString() != original['type']?.toString()) {
      return 'Cannot change the type field (expected "$expectedType").';
    }

    if (updated.containsKey('key') && updated['key'] is! String) {
      return 'Key must be a string.';
    }

    if (updated.containsKey('value')) {
      final newValue = updated['value'];
      if (!_valueMatchesPrefType(newValue, expectedType)) {
        return 'Value must remain $expectedType '
            '(got ${_describeValueType(newValue)}).';
      }
    }

    return null;
  }

  bool _valueMatchesPrefType(Object? value, String type) {
    switch (type) {
      case 'bool':
        return value is bool;
      case 'int':
        return value is int;
      case 'double':
        return value is double || value is int;
      case 'String':
        return value is String;
      case 'StringList':
        return value is List && value.every((e) => e is String);
      default:
        return true;
    }
  }

  String _describeValueType(Object? value) {
    if (value == null) return 'null';
    if (value is List) return 'List';
    return value.runtimeType.toString();
  }

  bool _valuesEqual(Object? a, Object? b) {
    if (a is List && b is List) {
      return a.length == b.length &&
          List.generate(a.length, (i) => _valuesEqual(a[i], b[i]))
              .every((e) => e);
    }
    return a == b;
  }

  // ── Export & JSON view ────────────────────────────────────────────────────

  /// Ambil semua baris aktif tanpa pagination (untuk JSON view & export).
  Future<List<Map<String, Object?>>> allRows() => _fetchAllActiveRows();

  Future<List<Map<String, Object?>>> _fetchAllActiveRows() async {
    final sourceId = selectedSourceId;
    if (sourceId == null) return [];

    if (queryMode && queryText.trim().isNotEmpty) {
      final total = await _runRawQueryCount(sourceId, queryText.trim());
      if (total == 0) return [];
      return _runRawQueryPaged(
        sourceId,
        queryText.trim(),
        limit: total,
        offset: 0,
      );
    }

    final collection = selectedCollection;
    if (collection == null) return [];
    return _getAllRows(sourceId, collection);
  }

  Future<String?> copyAllAsJson() async {
    if (!canCopyJson) return null;
    exporting = true;
    notifyListeners();
    try {
      final rows = await _fetchAllActiveRows();
      final exportRows = rows
          .map((row) => Map<String, Object?>.from(row)..remove('_rowid_'))
          .toList();
      exporting = false;
      notifyListeners();
      return jsonEncode(exportRows);
    } catch (error) {
      exporting = false;
      lastError = 'Failed to copy JSON: $error';
      notifyListeners();
      return null;
    }
  }

  // ── Query ─────────────────────────────────────────────────────────────────

  Future<bool> shouldConfirmQuery() =>
      Future.value(SqlUtils.requiresConfirmation(queryText.trim()));

  Future<void> runQuery({bool fromRefresh = false}) async {
    final sourceId = selectedSourceId;
    final sql = queryText.trim();
    if (sourceId == null) return;

    if (sql.isEmpty) {
      queryError = 'Query cannot be empty.';
      notifyListeners();
      return;
    }

    if (!supportsRawSql) {
      queryError = 'Raw SQL is not supported for this source.';
      notifyListeners();
      return;
    }

    if (SqlUtils.isSelectQuery(sql)) {
      _cacheTableViewForQuery();

      final detectedTable = SqlUtils.extractSimpleFromTable(sql);
      final tableExists = detectedTable != null &&
          collections.any(
            (c) => c.toLowerCase() == detectedTable.toLowerCase(),
          );
      queryCustomResult = !tableExists;

      if (tableExists) {
        selectedCollection = collections.firstWhere(
          (c) => c.toLowerCase() == detectedTable.toLowerCase(),
        );
      }

      late List<String> derivedColumns;
      try {
        final peek = await _runRawQueryPaged(
          sourceId,
          sql,
          limit: 1,
          offset: 0,
        );
        derivedColumns = peek.isNotEmpty ? peek.first.keys.toList() : [];
      } catch (error) {
        queryError = error.toString();
        notifyListeners();
        return;
      }

      fromRefresh ? refreshing = true : runningQuery = true;
      queryExpanded = true;
      queryError = null;
      queryInfoMessage = null;
      queryColumns = derivedColumns;
      queryMode = true;
      _resetSearchAndSort();
      notifyListeners();

      _ensureQueryPagination(sourceId, sql);
      await pagination!.loadPage(0);
      runningQuery = false;
      refreshing = false;
      notifyListeners();
      return;
    }

    fromRefresh ? refreshing = true : runningQuery = true;
    queryExpanded = true;
    queryError = null;
    queryInfoMessage = null;
    _resetSearchAndSort();
    notifyListeners();

    try {
      await _executeStatement(sourceId, sql);
      await _refreshTableSnapshot();
      _cacheTableViewForQuery();
      queryColumns = [];
      queryMode = true;
      queryCustomResult = true;
      queryInfoMessage = 'Query executed successfully. No rows returned.';
      runningQuery = false;
      refreshing = false;
      notifyListeners();
    } catch (error) {
      runningQuery = false;
      refreshing = false;
      queryError = error.toString();
      notifyListeners();
    }
  }

  // ── Pagination helpers ────────────────────────────────────────────────────

  void _onPaginationChanged() {
    if (pagination == null) return;
    loading = pagination!.isInitialLoad && pagination!.isLoading;
    refreshing = !pagination!.isInitialLoad && pagination!.isLoading;
    notifyListeners();
  }

  void _disposePagination() {
    pagination?.removeListener(_onPaginationChanged);
    pagination?.dispose();
    pagination = null;
    paginationCollection = null;
  }

  void _ensureTablePagination(String collection) {
    if (paginationCollection == collection && pagination != null) return;

    _disposePagination();
    paginationCollection = collection;

    final sourceId = selectedSourceId!;
    late final DbLensPaginationController<Map<String, Object?>> ctrl;
    ctrl = DbLensPaginationController<Map<String, Object?>>(
      pageSize: config.pageSize,
      enablePrefetch: config.enablePrefetch,
      fetchPage: ({
        required int page,
        required int pageSize,
        required int offset,
        required bool refreshTotal,
      }) async {
        final entities = await _getRows(sourceId, collection, pageSize, offset);
        final rows = entities.map((e) => e.data).toList();
        final totalRows = refreshTotal
            ? await _getRowCount(sourceId, collection)
            : ctrl.totalRows;
        return DbLensPageData(rows: rows, totalRows: totalRows, page: page);
      },
    )..addListener(_onPaginationChanged);
    pagination = ctrl;
  }

  void _ensureQueryPagination(String sourceId, String sql) {
    _disposePagination();

    late final DbLensPaginationController<Map<String, Object?>> ctrl;
    ctrl = DbLensPaginationController<Map<String, Object?>>(
      pageSize: config.pageSize,
      enablePrefetch: config.enablePrefetch,
      fetchPage: ({
        required int page,
        required int pageSize,
        required int offset,
        required bool refreshTotal,
      }) async {
        final rows = await _runRawQueryPaged(
          sourceId,
          sql,
          limit: pageSize,
          offset: offset,
        );
        final totalRows = refreshTotal
            ? await _runRawQueryCount(sourceId, sql)
            : ctrl.totalRows;
        return DbLensPageData(rows: rows, totalRows: totalRows, page: page);
      },
    )..addListener(_onPaginationChanged);
    pagination = ctrl;
  }

  Future<void> _refreshTableSnapshot() async {
    final collection = selectedCollection;
    if (selectedSourceId == null || collection == null) return;
    _ensureTablePagination(collection);
    await pagination!.refresh();
  }

  // ── Private reset helpers ─────────────────────────────────────────────────

  void _resetSearchAndSort() {
    searchText = '';
    sortColumn = null;
    sortAscending = true;
  }

  void _resetQueryState() {
    queryMode = false;
    queryCustomResult = false;
    queryColumns = [];
    queryError = null;
    queryInfoMessage = null;
    queryExpanded = false;
    queryText = '';
  }

  void _resetTableViewState() {
    columns = [];
    columnsTable = null;
    tableViewCache = null;
    _disposePagination();
  }

  void _cacheTableViewForQuery() {
    tableViewCache = DbLensTableViewCache(
      columns: List<String>.from(columns),
      columnsTable: columnsTable,
    );
  }
}

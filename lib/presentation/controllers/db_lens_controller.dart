import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/models/db_lens_config.dart';
import '../../domain/repositories/lens_repository.dart';
import '../state/db_lens_panel_models.dart';
import '../utils/db_lens_row_id_utils.dart';
import '../utils/row_utils.dart';
import 'db_lens_browse_controller.dart';
import 'db_lens_edit_controller.dart';
import 'db_lens_query_controller.dart';
import 'db_lens_query_history_controller.dart';
import 'db_lens_source_controller.dart';
import 'db_lens_table_controller.dart';

/// Facade headless yang menggabungkan controller kecil ([source], [table],
/// [query], [queryHistory], [edit], [browse]).
///
/// Dipakai penuh lewat [DbLensPanel]/[DbLens.open], atau dibongkar untuk
/// UI custom lewat [DbLensControllerScope] — ambil sub-controller yang
/// relevan saja, tidak wajib depend ke semuanya.
class DbLensController extends ChangeNotifier {
  DbLensController({
    required LensRepository repository,
    this.config = const DbLensConfig(),
  })  : _repository = repository,
        source = DbLensSourceController(repository: repository),
        table = DbLensTableController(repository: repository, config: config),
        query = DbLensQueryController(repository: repository, config: config),
        queryHistory = DbLensQueryHistoryController(),
        edit = DbLensEditController(repository: repository),
        browse = DbLensBrowseController(repository: repository) {
    _merged = Listenable.merge(
      [source, table, query, queryHistory, edit, browse],
    )..addListener(notifyListeners);
  }

  final LensRepository _repository;
  final DbLensConfig config;
  late final Listenable _merged;

  final DbLensSourceController source;
  final DbLensTableController table;
  final DbLensQueryController query;
  final DbLensQueryHistoryController queryHistory;
  final DbLensEditController edit;
  final DbLensBrowseController browse;

  bool _initialized = false;
  bool copyingJson = false;
  String? _copyError;

  /// Apakah [initialize] sudah pernah dipanggil dan selesai.
  bool get isInitialized => _initialized;

  /// Error terbaru dari salah satu sub-controller (untuk ditampilkan sekali
  /// lewat snackbar lalu di-clear). Set null untuk clear semuanya.
  String? get lastError =>
      source.lastError ??
      table.lastError ??
      edit.lastError ??
      browse.lastError ??
      _copyError;

  set lastError(String? value) {
    source.lastError = value;
    table.lastError = value;
    edit.lastError = value;
    browse.lastError = value;
    _copyError = value;
  }

  Future<void> initialize() async {
    await source.initialize();
    if (source.selectedSourceId != null && source.selectedCollection != null) {
      await table.bindTo(source.selectedSourceId!, source.selectedCollection!);
    }
    _initialized = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _merged.removeListener(notifyListeners);
    source.dispose();
    table.dispose();
    query.dispose();
    queryHistory.dispose();
    edit.dispose();
    browse.dispose();
    super.dispose();
  }

  // ── Source & collection ───────────────────────────────────────────────────

  Future<void> selectSource(String sourceId) async {
    query.exit();
    table.reset();
    await source.selectSource(sourceId);
  }

  Future<void> selectCollection(String collection) async {
    query.exit();
    source.selectCollection(collection);
    if (source.selectedSourceId != null) {
      await table.bindTo(source.selectedSourceId!, collection);
    }
  }

  Future<List<BrowseSourceSnapshot>> loadBrowseSnapshot() =>
      browse.load().then((_) => browse.snapshot);

  Future<void> refreshBrowse() => browse.refresh();

  // ── Active view (table atau hasil query, mana yang sedang aktif) ───────────

  List<Map<String, Object?>> get activeRows =>
      query.queryMode ? query.rows : table.rows;

  List<String> get activeColumns => query.queryMode
      ? withoutRowIdColumn(query.queryColumns)
      : table.activeColumns;

  int get activeRowCount => query.queryMode ? query.rowCount : table.rowCount;

  List<Map<String, Object?>> visibleRows({required List<String> columns}) {
    final rows = query.queryMode ? query.rows : table.rows;
    return DbLensRowUtils.applySearchAndSort(
      rows: rows,
      columns: columns,
      searchText: table.searchText,
      sortColumn: table.sortColumn,
      sortAscending: table.sortAscending,
    );
  }

  bool get canRefresh {
    if (copyingJson) return false;
    if (query.queryMode) {
      return query.queryText.trim().isNotEmpty && !query.runningQuery;
    }
    return source.selectedCollection != null && table.canRefresh;
  }

  Future<void> refresh() async {
    if (!canRefresh) return;
    if (query.queryMode) {
      await runQuery(fromRefresh: true);
    } else {
      await table.refresh();
    }
  }

  // ── Query ─────────────────────────────────────────────────────────────────

  Future<void> runQuery({bool fromRefresh = false}) async {
    final sourceId = source.selectedSourceId;
    if (sourceId == null) return;
    await query.run(sourceId: sourceId, fromRefresh: fromRefresh);
    final sql = query.queryText.trim();
    if (sql.isNotEmpty) {
      queryHistory.record(
        sql,
        isError: query.queryError != null,
        info: query.queryError ?? query.queryInfoMessage,
        table: source.selectedCollection,
      );
    }
  }

  void restoreTableView() => query.exit();

  // ── Edit ──────────────────────────────────────────────────────────────────

  bool get canEditCells =>
      !query.queryMode && source.selectedCollection != null;

  Future<bool> updateCellValue({
    required String column,
    required Object? newValue,
    required Map<String, Object?> row,
  }) async {
    final sourceId = source.selectedSourceId;
    final collection = source.selectedCollection;
    if (sourceId == null || collection == null || !canEditCells) return false;

    final ok = await edit.updateCell(
      sourceId: sourceId,
      collection: collection,
      column: column,
      newValue: newValue,
      row: row,
    );
    if (ok) await table.refresh();
    return ok;
  }

  bool get canDeleteRows {
    final sourceId = source.selectedSourceId;
    return canEditCells &&
        sourceId != null &&
        _repository.supportsRowDelete(sourceId);
  }

  Future<String?> deleteRow(Map<String, Object?> row) async {
    final sourceId = source.selectedSourceId;
    final collection = source.selectedCollection;
    if (sourceId == null || collection == null || !canDeleteRows) {
      return 'Deleting is not available in this view.';
    }

    final error = await edit.deleteRow(
      sourceId: sourceId,
      collection: collection,
      row: row,
    );
    if (error == null) await table.refresh();
    return error;
  }

  Future<String?> updateRowFromJson(
    Map<String, Object?> originalRow,
    Map<String, Object?> updatedRow,
  ) async {
    final sourceId = source.selectedSourceId;
    final collection = source.selectedCollection;
    if (sourceId == null || collection == null || !canEditCells) {
      return 'Editing is not available in this view.';
    }

    final error = await edit.updateRowFromJson(
      sourceId: sourceId,
      collection: collection,
      originalRow: originalRow,
      updatedRow: updatedRow,
    );
    if (error == null) await table.refresh();
    return error;
  }

  // ── Copy JSON ─────────────────────────────────────────────────────────────

  bool get canCopyJson =>
      !copyingJson &&
      !table.loading &&
      !query.runningQuery &&
      (query.queryMode
          ? activeRows.isNotEmpty || activeRowCount > 0
          : source.selectedCollection != null);

  Future<List<Map<String, Object?>>> _fetchAllActiveRows() async {
    final sourceId = source.selectedSourceId;
    if (sourceId == null) return [];

    if (query.queryMode && query.queryText.trim().isNotEmpty) {
      final sql = query.queryText.trim();
      final total = await _repository.runRawQueryCount(sourceId, sql);
      if (total == 0) return [];
      return _repository.runRawQueryPaged(sourceId, sql,
          limit: total, offset: 0);
    }

    final collection = source.selectedCollection;
    if (collection == null) return [];
    return _repository.getAllRows(sourceId, collection);
  }

  Future<String?> copyAllAsJson() async {
    if (!canCopyJson) return null;
    copyingJson = true;
    notifyListeners();
    try {
      final rows = await _fetchAllActiveRows();
      final exportRows = rows
          .map(
            (row) => Map<String, Object?>.from(
              withoutRowIdEntry(Map<String, dynamic>.from(row)),
            ),
          )
          .toList();
      copyingJson = false;
      notifyListeners();
      return jsonEncode(exportRows);
    } catch (error) {
      copyingJson = false;
      _copyError = 'Failed to copy JSON: $error';
      notifyListeners();
      return null;
    }
  }
}

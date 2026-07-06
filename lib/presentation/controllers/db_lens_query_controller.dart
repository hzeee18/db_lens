import 'package:flutter/foundation.dart';

import '../../core/models/db_lens_config.dart';
import '../../core/utils/sql_utils.dart';
import '../../domain/repositories/lens_repository.dart';
import '../state/db_lens_pagination.dart';

/// Mengelola mode raw-SQL: teks query, eksekusi, dan hasil (jika SELECT).
class DbLensQueryController extends ChangeNotifier {
  DbLensQueryController({
    required LensRepository repository,
    this.config = const DbLensConfig(),
  }) : _repository = repository;

  final LensRepository _repository;
  final DbLensConfig config;

  bool queryMode = false;
  bool queryExpanded = false;
  bool queryCustomResult = false;
  bool runningQuery = false;
  bool refreshing = false;
  String queryText = '';
  List<String> queryColumns = [];
  String? queryError;
  String? queryInfoMessage;

  DbLensPaginationController<Map<String, Object?>>? pagination;

  List<Map<String, Object?>> get rows => pagination?.rows ?? const [];

  int get rowCount => pagination?.totalRows ?? 0;

  Future<bool> shouldConfirm() =>
      Future.value(DbLensSqlUtils.requiresConfirmation(queryText.trim()));

  void setText(String value) {
    queryText = value;
    notifyListeners();
  }

  void toggleExpanded() {
    queryExpanded = !queryExpanded;
    notifyListeners();
  }

  void clearText() {
    queryText = '';
    queryError = null;
    queryInfoMessage = null;
    notifyListeners();
  }

  Future<void> run({required String sourceId, bool fromRefresh = false}) async {
    final sql = queryText.trim();
    if (sql.isEmpty) {
      queryError = 'Query cannot be empty.';
      notifyListeners();
      return;
    }

    if (!_repository.supportsRawSql(sourceId)) {
      queryError = 'Raw SQL is not supported for this source.';
      notifyListeners();
      return;
    }

    if (DbLensSqlUtils.isSelectQuery(sql)) {
      await _runSelect(sourceId, sql, fromRefresh: fromRefresh);
      return;
    }

    await _runStatement(sourceId, sql, fromRefresh: fromRefresh);
  }

  Future<void> _runSelect(
    String sourceId,
    String sql, {
    required bool fromRefresh,
  }) async {
    late List<String> derivedColumns;
    try {
      final peek =
          await _repository.runRawQueryPaged(sourceId, sql, limit: 1, offset: 0);
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
    queryCustomResult = false;
    queryMode = true;
    notifyListeners();

    _ensurePagination(sourceId, sql);
    await pagination!.loadPage(0);
    runningQuery = false;
    refreshing = false;
    notifyListeners();
  }

  Future<void> _runStatement(
    String sourceId,
    String sql, {
    required bool fromRefresh,
  }) async {
    fromRefresh ? refreshing = true : runningQuery = true;
    queryExpanded = true;
    queryError = null;
    queryInfoMessage = null;
    notifyListeners();

    try {
      await _repository.executeStatement(sourceId, sql);
      queryColumns = [];
      queryMode = true;
      queryCustomResult = true;
      queryInfoMessage = 'Query executed successfully. No rows returned.';
      _disposePagination();
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

  /// Keluar dari mode query, kembali ke tampilan tabel biasa.
  void exit() {
    queryMode = false;
    queryCustomResult = false;
    queryColumns = [];
    queryError = null;
    queryInfoMessage = null;
    queryExpanded = false;
    queryText = '';
    _disposePagination();
    notifyListeners();
  }

  void _ensurePagination(String sourceId, String sql) {
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
        final rows = await _repository.runRawQueryPaged(
          sourceId,
          sql,
          limit: pageSize,
          offset: offset,
        );
        final totalRows = refreshTotal
            ? await _repository.runRawQueryCount(sourceId, sql)
            : ctrl.totalRows;
        return DbLensPageData(rows: rows, totalRows: totalRows, page: page);
      },
    )..addListener(_onPaginationChanged);
    pagination = ctrl;
  }

  void _onPaginationChanged() => notifyListeners();

  void _disposePagination() {
    pagination?.removeListener(_onPaginationChanged);
    pagination?.dispose();
    pagination = null;
  }

  @override
  void dispose() {
    _disposePagination();
    super.dispose();
  }
}

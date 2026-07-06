import 'package:flutter/foundation.dart';

import '../../core/models/db_lens_config.dart';
import '../../domain/repositories/lens_repository.dart';
import '../state/db_lens_pagination.dart';
import '../utils/db_lens_row_id_utils.dart';
import '../utils/row_utils.dart';

/// Mengelola pagination, kolom, pencarian, dan sort untuk satu koleksi
/// (mode "browse" — bukan hasil query mentah, lihat [DbLensQueryController]).
class DbLensTableController extends ChangeNotifier {
  DbLensTableController({
    required LensRepository repository,
    this.config = const DbLensConfig(),
  }) : _repository = repository;

  final LensRepository _repository;
  final DbLensConfig config;

  DbLensPaginationController<Map<String, Object?>>? pagination;
  String? _boundSourceId;
  String? _boundCollection;

  List<String> columns = [];
  String? columnsTable;
  bool loading = false;
  bool refreshing = false;
  String searchText = '';
  String? sortColumn;
  bool sortAscending = true;
  String? lastError;

  List<Map<String, Object?>> get rows => pagination?.rows ?? const [];

  List<String> get activeColumns => withoutRowIdColumn(columns);

  int get rowCount => pagination?.totalRows ?? 0;

  bool get hasActiveSearch => searchText.trim().isNotEmpty;

  bool get isPageTransition =>
      pagination != null &&
      pagination!.isLoading &&
      !pagination!.isInitialLoad;

  bool get canRefresh =>
      !loading && !refreshing && !(pagination?.isLoading ?? false);

  List<Map<String, Object?>> visibleRows({required List<String> columns}) {
    return DbLensRowUtils.applySearchAndSort(
      rows: rows,
      columns: columns,
      searchText: searchText,
      sortColumn: sortColumn,
      sortAscending: sortAscending,
    );
  }

  /// Ikat controller ke [sourceId]/[collection] — memuat kolom (jika ganti)
  /// dan halaman pertama.
  Future<void> bindTo(String sourceId, String collection) async {
    final changed = _boundSourceId != sourceId || _boundCollection != collection;
    if (changed) {
      _disposePagination();
      _boundSourceId = sourceId;
      _boundCollection = collection;
      _ensurePagination(sourceId, collection);
    }

    final firstLoad = pagination!.isInitialLoad;
    if (firstLoad || changed) {
      loading = true;
      notifyListeners();
    }

    try {
      if (changed || columns.isEmpty) {
        columns = await _repository.getColumns(sourceId, collection);
        columnsTable = collection;
      }
      await pagination!.loadPage(0);
      searchText = '';
      sortColumn = null;
      sortAscending = true;
      loading = false;
      notifyListeners();
    } catch (error) {
      loading = false;
      lastError = 'Failed to load rows: $error';
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (pagination == null) return;
    try {
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

  void setSearchText(String value) {
    searchText = value;
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

  /// Lepas ikatan ke koleksi manapun (dipanggil saat pindah source/koleksi).
  void reset() {
    _boundSourceId = null;
    _boundCollection = null;
    columns = [];
    columnsTable = null;
    searchText = '';
    sortColumn = null;
    sortAscending = true;
    _disposePagination();
    notifyListeners();
  }

  void _ensurePagination(String sourceId, String collection) {
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
        final entities =
            await _repository.getRows(sourceId, collection, pageSize, offset);
        final rows = entities.map((e) => e.data).toList();
        final totalRows = refreshTotal
            ? await _repository.getRowCount(sourceId, collection)
            : ctrl.totalRows;
        return DbLensPageData(rows: rows, totalRows: totalRows, page: page);
      },
    )..addListener(_onPaginationChanged);
    pagination = ctrl;
  }

  void _onPaginationChanged() {
    notifyListeners();
  }

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

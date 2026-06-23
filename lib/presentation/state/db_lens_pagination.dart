import 'package:flutter/foundation.dart';

import '../../core/models/db_lens_config.dart';

/// Hasil satu halaman dari sumber data (mis. SQLite LIMIT/OFFSET).
class DbLensPageData<T> {
  const DbLensPageData({
    required this.rows,
    required this.totalRows,
    required this.page,
  });

  final List<T> rows;
  final int totalRows;

  /// Halaman berbasis 0.
  final int page;
}

/// Signature fetcher: [page] dan [offset] berbasis 0.
typedef DbLensPageFetcher<T> = Future<DbLensPageData<T>> Function({
  required int page,
  required int pageSize,
  required int offset,
  required bool refreshTotal,
});

/// Controller pagination terpisah dari UI.
///
/// Fitur:
/// - LIMIT + OFFSET via [fetchPage]
/// - Guard double-fetch (loading + stale request id)
/// - Skip reload jika halaman sama
/// - Prefetch halaman berikutnya (opsional)
/// - [syncWithoutFetch] untuk restore snapshot tanpa query
class DbLensPaginationController<T> extends ChangeNotifier {
  DbLensPaginationController({
    required DbLensPageFetcher<T> fetchPage,
    int pageSize = DbLensConfig.defaultPageSize,
    bool enablePrefetch = true,
  })  : _fetchPage = fetchPage,
        _pageSize = pageSize,
        _enablePrefetch = enablePrefetch;

  final DbLensPageFetcher<T> _fetchPage;
  final int _pageSize;
  final bool _enablePrefetch;

  int _page = 0;
  int _totalRows = 0;
  List<T> _rows = [];
  bool _isLoading = false;
  bool _isInitialLoad = true;
  int _requestId = 0;
  int _prefetchRequestId = 0;
  final Map<int, List<T>> _prefetchCache = {};

  // ── Public state ──────────────────────────────────────────────────────────

  int get page => _page;
  int get pageSize => _pageSize;
  int get totalRows => _totalRows;
  List<T> get rows => _rows;
  bool get isLoading => _isLoading;
  bool get isInitialLoad => _isInitialLoad;

  int get totalPages =>
      _totalRows == 0 ? 1 : (_totalRows / _pageSize).ceil();

  int get rangeStart => _totalRows == 0 ? 0 : _page * _pageSize + 1;

  int get rangeEnd {
    if (_totalRows == 0) return 0;
    final end = (_page + 1) * _pageSize;
    return end > _totalRows ? _totalRows : end;
  }

  bool get canGoPrevious => _page > 0;
  bool get canGoNext => _page < totalPages - 1;
  bool get hasMultiplePages => _totalRows > _pageSize;

  // ── Navigation ────────────────────────────────────────────────────────────

  Future<void> loadPage(int page, {bool force = false}) async {
    if (page < 0) return;
    if (!force && page == _page && _rows.isNotEmpty && !_isLoading) {
      return;
    }

    if (_prefetchCache.containsKey(page)) {
      final cachedRows = _prefetchCache.remove(page)!;
      _requestId++;
      _prefetchRequestId++;
      _applyPage(page: page, rows: cachedRows, totalRows: _totalRows);
      _prefetchNextPage();
      return;
    }

    final requestId = ++_requestId;
    _isLoading = true;
    notifyListeners();

    try {
      final refreshTotal = force || page == 0 || _totalRows == 0;
      final result = await _fetchPage(
        page: page,
        pageSize: _pageSize,
        offset: page * _pageSize,
        refreshTotal: refreshTotal,
      );

      if (requestId != _requestId) return;

      _page = result.page;
      _rows = result.rows;
      _totalRows = result.totalRows;
      _isInitialLoad = false;
    } finally {
      if (requestId == _requestId) {
        _isLoading = false;
        _isInitialLoad = false;
        notifyListeners();
        _prefetchNextPage();
      }
    }
  }

  Future<void> nextPage() => loadPage(_page + 1);

  Future<void> previousPage() => loadPage(_page - 1);

  Future<void> jumpToPage(int page) => loadPage(page);

  /// Reload halaman aktif dan refresh total row count.
  Future<void> refresh() => loadPage(_page, force: true);

  /// Restore state dari cache (mis. kembali dari query mode) tanpa fetch.
  void syncWithoutFetch({
    required int page,
    required List<T> rows,
    required int totalRows,
  }) {
    _cancelInFlightRequests();
    _page = page;
    _rows = rows;
    _totalRows = totalRows;
    _isLoading = false;
    _isInitialLoad = false;
    notifyListeners();
  }

  void reset() {
    _cancelInFlightRequests();
    _page = 0;
    _totalRows = 0;
    _rows = [];
    _isLoading = false;
    _isInitialLoad = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelInFlightRequests();
    super.dispose();
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  void _cancelInFlightRequests() {
    _requestId++;
    _prefetchRequestId++;
    _prefetchCache.clear();
    _isLoading = false;
  }

  void _applyPage({
    required int page,
    required List<T> rows,
    required int totalRows,
  }) {
    _page = page;
    _rows = rows;
    _totalRows = totalRows;
    _isInitialLoad = false;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _prefetchNextPage() async {
    if (!_enablePrefetch || _isLoading) return;

    final nextPage = _page + 1;
    if (nextPage >= totalPages || _prefetchCache.containsKey(nextPage)) {
      return;
    }

    final prefetchId = ++_prefetchRequestId;
    final anchorPage = _page;

    try {
      final result = await _fetchPage(
        page: nextPage,
        pageSize: _pageSize,
        offset: nextPage * _pageSize,
        refreshTotal: false,
      );

      if (prefetchId != _prefetchRequestId || anchorPage != _page) return;

      _prefetchCache[nextPage] = result.rows;
    } catch (_) {
      // Prefetch gagal — diabaikan, navigasi berikutnya akan fetch normal.
    }
  }
}

// ── Infinite scroll (alternatif) ────────────────────────────────────────────

/// Controller infinite scroll untuk [ListView.builder].
///
/// Cocok jika Anda lebih suka scroll daripada tombol halaman.
class DbLensInfiniteScrollController<T> extends ChangeNotifier {
  DbLensInfiniteScrollController({
    required DbLensPageFetcher<T> fetchPage,
    int pageSize = DbLensConfig.defaultPageSize,
  })  : _fetchPage = fetchPage,
        _pageSize = pageSize;

  final DbLensPageFetcher<T> _fetchPage;
  final int _pageSize;

  final List<T> _items = [];
  int _totalRows = 0;
  int _nextPage = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  int _requestId = 0;

  List<T> get items => List.unmodifiable(_items);
  int get totalRows => _totalRows;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;

  Future<void> loadInitial() async {
    reset();
    await loadMore();
  }

  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;

    final requestId = ++_requestId;
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _fetchPage(
        page: _nextPage,
        pageSize: _pageSize,
        offset: _nextPage * _pageSize,
        refreshTotal: _nextPage == 0,
      );

      if (requestId != _requestId) return;

      _totalRows = result.totalRows;
      _items.addAll(result.rows);
      _nextPage++;
      _hasMore = _items.length < _totalRows;
    } finally {
      if (requestId == _requestId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void reset() {
    _requestId++;
    _items.clear();
    _totalRows = 0;
    _nextPage = 0;
    _isLoading = false;
    _hasMore = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _requestId++;
    super.dispose();
  }
}

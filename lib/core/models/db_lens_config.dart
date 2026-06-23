/// Konfigurasi panel DbLens (pagination, prefetch, dll.).
class DbLensConfig {
  static const int defaultPageSize = 10;
  static const int maxPageSize = 500;

  const DbLensConfig({
    this.pageSize = defaultPageSize,
    this.enablePrefetch = true,
  }) : assert(
          pageSize >= 1 && pageSize <= maxPageSize,
          'pageSize must be between 1 and $maxPageSize',
        );

  /// Jumlah baris per halaman (1–[maxPageSize]).
  final int pageSize;

  /// Prefetch halaman berikutnya di background.
  final bool enablePrefetch;
}

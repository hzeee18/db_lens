import '../enums/db_lens_presentation_mode.dart';

/// Konfigurasi panel DbLens (pagination, prefetch, dll.).
class DbLensConfig {
  static const int defaultPageSize = 10;
  static const int maxPageSize = 500;
  static const Duration defaultHistoryPollInterval = Duration(seconds: 5);

  const DbLensConfig({
    this.pageSize = defaultPageSize,
    this.enablePrefetch = true,
    this.enableHistory = true,
    this.historyPollInterval = defaultHistoryPollInterval,
    this.presentationMode = DbLensPresentationMode.bottomSheet,
    this.fullscreenDialog = true,
    this.allowInRelease = false,
  }) : assert(
          pageSize >= 1 && pageSize <= maxPageSize,
          'pageSize must be between 1 and $maxPageSize',
        );

  /// Jumlah baris per halaman (1–[maxPageSize]).
  final int pageSize;

  /// Prefetch halaman berikutnya di background.
  final bool enablePrefetch;

  /// Aktifkan pelacakan riwayat perubahan data (nonaktif di release build).
  final bool enableHistory;

  /// Interval polling untuk deteksi perubahan data.
  final Duration historyPollInterval;

  /// Mode presentasi default saat dipanggil lewat [DbLens.open].
  final DbLensPresentationMode presentationMode;

  /// Only used when [presentationMode] is [DbLensPresentationMode.fullPage].
  final bool fullscreenDialog;

  /// Izinkan [DbLens.open] di release build (mis. build QA). Default `false`.
  final bool allowInRelease;
}

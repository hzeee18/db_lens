import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'core/enums/db_lens_presentation_mode.dart';
import 'core/models/db_lens_config.dart';
import 'data/datasources/lens_datasource.dart';
import 'data/history/history_data_source.dart';
import 'data/history/history_database.dart';
import 'data/history/history_repository_impl.dart';
import 'data/registry/db_lens_registry.dart';
import 'data/repositories/lens_repository_impl.dart';
import 'domain/repositories/lens_repository.dart';
import 'presentation/controllers/db_lens_controller.dart';
import 'presentation/controllers/db_lens_history_controller.dart';
import 'presentation/pages/db_lens_panel.dart';
import 'presentation/theme/db_lens_theme.dart';
import 'presentation/theme/db_lens_theme_data.dart';

/// Main entry point for DbLens.
///
/// Tiga konsep inti:
/// 1. Register data source — `DbLens.register(...)`.
/// 2. Buat controller headless — `DbLens.createController()` (opsional,
///    dipakai kalau menyusun UI sendiri lewat `DbLensControllerScope`).
/// 3. Compose widget — `DbLens.open()`/`DbLens.buildPanel()` untuk UI
///    bawaan, atau susun widget dari `package:db_lens/db_lens.dart` sendiri.
class DbLens {
  DbLens._();

  static final HistoryDataSource _historyDataSource =
      HistoryDataSource(HistoryDatabase.instance);

  static final HistoryRepositoryImpl _historyRepository =
      HistoryRepositoryImpl(_historyDataSource);

  static final DbLensRegistry _registry = DbLensRegistry(
    historyDataSource: kReleaseMode ? null : _historyDataSource,
    historyRepository: kReleaseMode ? null : _historyRepository,
    pollInterval: DbLensConfig.defaultHistoryPollInterval,
    enableHistory: !kReleaseMode,
  );

  static final LensRepository _repository = LensRepositoryImpl(_registry);

  // ── 1. Register data source ─────────────────────────────────────────────

  /// Register a sqflite [database] with a display [name].
  static void register(String name, Database database) {
    _registry.registerSQLite(name: name, database: database);
  }

  /// Register SharedPreferences as a data source.
  static void registerSharedPreferences(
    String name,
    SharedPreferences preferences,
  ) {
    _registry.registerSharedPreferences(name: name, preferences: preferences);
  }

  /// Register a custom [LensDataSource] (source).
  static void registerSource(LensDataSource source) {
    _registry.registerSource(source);
  }

  /// Remove a source by [sourceId].
  static void unregisterSource(String sourceId) {
    _registry.removeSource(sourceId);
  }

  // ── Direct data access (untuk UI custom tanpa controller) ────────────────

  /// Registry global — akses langsung ke semua [LensDataSource] terdaftar
  /// (mis. `DbLens.registry.getSources()`) untuk menyusun UI sendiri.
  static DbLensRegistry get registry => _registry;

  /// Jalankan SELECT arbitrer pada sumber SQL. [source] boleh sourceId atau
  /// sourceName. Melempar [UnsupportedError] untuk sumber non-SQL.
  static Future<List<Map<String, dynamic>>> runRawQuery(
    String source,
    String sql,
  ) {
    return _repository.runRawQuery(_resolveSourceId(source), sql);
  }

  /// Eksekusi perintah non-SELECT (INSERT/UPDATE/DELETE/DDL) pada sumber SQL.
  /// [source] boleh sourceId atau sourceName.
  static Future<void> executeStatement(String source, String sql) {
    return _repository.executeStatement(_resolveSourceId(source), sql);
  }

  /// Terima sourceId maupun sourceName; kembalikan sourceId yang terdaftar.
  static String _resolveSourceId(String sourceIdOrName) {
    if (_registry.getSource(sourceIdOrName) != null) return sourceIdOrName;
    for (final source in _registry.getSources()) {
      if (source.sourceName == sourceIdOrName) return source.sourceId;
    }
    return sourceIdOrName;
  }

  // ── 2. Create controller ────────────────────────────────────────────────

  /// Buat controller headless untuk UI custom (lewat [DbLensControllerScope])
  /// atau untuk dipakai bersama [buildPanel].
  static DbLensController createController({DbLensConfig? config}) {
    return DbLensController(
      repository: _repository,
      config: config ?? const DbLensConfig(),
    );
  }

  /// Buat controller untuk riwayat perubahan data satu source (dipakai
  /// lewat [DbLensHistoryPanel]/[DbLensHistorySheet]).
  static DbLensHistoryController createHistoryController() {
    return DbLensHistoryController(
      historyRepository: _historyRepository,
      isTrackingEnabled: () => _registry.enableHistory,
      configureTracking: ({bool? enabled}) =>
          _registry.configureHistory(enabled: enabled),
    );
  }

  /// Konfigurasi pelacakan riwayat perubahan data. Tidak berjalan di release
  /// build ([kReleaseMode]).
  static void configureHistory({bool? enabled, Duration? pollInterval}) {
    if (kReleaseMode) return;
    _registry.configureHistory(enabled: enabled, pollInterval: pollInterval);
  }

  // ── 3. Compose widget ───────────────────────────────────────────────────

  /// Open the built-in DbLens panel. Tidak berjalan di release build.
  static Future<void> open(
    BuildContext context, {
    DbLensConfig? config,
    DbLensThemeData? theme,
  }) async {
    if (kReleaseMode) return;

    final panelConfig = config ?? const DbLensConfig();
    final panelTheme = DbLensTheme(theme);

    switch (panelConfig.presentationMode) {
      case DbLensPresentationMode.fullPage:
        await Navigator.of(context).push(
          MaterialPageRoute(
            fullscreenDialog: panelConfig.fullscreenDialog,
            builder: (_) => DbLensThemeScope(
              theme: panelTheme,
              child: Scaffold(
                backgroundColor: Colors.transparent,
                body: DbLensPanel(config: panelConfig),
              ),
            ),
          ),
        );
        return;
      case DbLensPresentationMode.bottomSheet:
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          barrierColor: Colors.black54,
          enableDrag: false,
          useSafeArea: true,
          builder: (_) => DbLensThemeScope(
            theme: panelTheme,
            child: DbLensPanel(config: panelConfig),
          ),
        );
        return;
    }
  }

  /// Widget inspector yang bisa di-embed di widget tree konsumen (mis. tab
  /// debug/QA aplikasi sendiri) — tanpa navigasi.
  static Widget buildPanel({
    DbLensConfig? config,
    DbLensThemeData? theme,
    DbLensController? controller,
  }) {
    if (kReleaseMode) return const SizedBox.shrink();

    final panelConfig = config ?? const DbLensConfig();

    return DbLensThemeScope(
      theme: DbLensTheme(theme),
      child: DbLensPanel(config: panelConfig, controller: controller),
    );
  }
}

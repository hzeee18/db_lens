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
import 'domain/usecases/clear_history_use_case.dart';
import 'domain/usecases/execute_statement_use_case.dart';
import 'domain/usecases/get_all_rows_use_case.dart';
import 'domain/usecases/get_collections_use_case.dart';
import 'domain/usecases/get_columns_use_case.dart';
import 'domain/usecases/get_history_use_case.dart';
import 'domain/usecases/get_row_count_use_case.dart';
import 'domain/usecases/get_rows_use_case.dart';
import 'domain/usecases/get_sources_use_case.dart';
import 'domain/usecases/run_raw_query_count_use_case.dart';
import 'domain/usecases/run_raw_query_paged_use_case.dart';
import 'domain/usecases/update_cell_use_case.dart';
import 'presentation/controllers/db_lens_controller.dart';
import 'presentation/controllers/db_lens_history_controller.dart';
import 'presentation/pages/db_lens_custom_host.dart';
import 'presentation/pages/db_lens_panel.dart';
import 'presentation/theme/db_lens_theme.dart';
import 'presentation/theme/db_lens_theme_data.dart';

/// Main entry point for DbLens.
///
/// Usage:
/// ```dart
/// DbLens.register('Main DB', db);
/// DbLens.open(context);
/// ```
class DbLens {
  DbLens._();

  static final HistoryDataSource _historyDataSource =
      HistoryDataSource(HistoryDatabase.instance);

  static final HistoryRepositoryImpl _historyRepository =
      HistoryRepositoryImpl(_historyDataSource);

  static final DbLensRegistry registry = DbLensRegistry(
    historyDataSource: kReleaseMode ? null : _historyDataSource,
    historyRepository: kReleaseMode ? null : _historyRepository,
    pollInterval: DbLensConfig.defaultHistoryPollInterval,
    enableHistory: !kReleaseMode,
  );

  static final LensRepository _repository = LensRepositoryImpl(registry);

  static final GetSourcesUseCase _getSources =
      GetSourcesUseCase(_repository);
  static final GetCollectionsUseCase _getCollections =
      GetCollectionsUseCase(_repository);
  static final GetRowsUseCase _getRows = GetRowsUseCase(_repository);
  static final GetRowCountUseCase _getRowCount =
      GetRowCountUseCase(_repository);
  static final GetColumnsUseCase _getColumns =
      GetColumnsUseCase(_repository);
  static final RunRawQueryPagedUseCase _runRawQueryPaged =
      RunRawQueryPagedUseCase(_repository);
  static final RunRawQueryCountUseCase _runRawQueryCount =
      RunRawQueryCountUseCase(_repository);
  static final ExecuteStatementUseCase _executeStatement =
      ExecuteStatementUseCase(_repository);
  static final UpdateCellUseCase _updateCell =
      UpdateCellUseCase(_repository);
  static final GetAllRowsUseCase _getAllRows =
      GetAllRowsUseCase(_repository);
  static final GetHistoryUseCase _getHistory =
      GetHistoryUseCase(_historyRepository);
  static final ClearHistoryUseCase _clearHistory =
      ClearHistoryUseCase(_historyRepository);

  /// Register a sqflite [database] with a display [name].
  static void register(String name, Database database) {
    registry.registerSQLite(name: name, database: database);
  }

  /// Register SharedPreferences as a data source.
  static void registerSharedPreferences(
    String name,
    SharedPreferences preferences,
  ) {
    registry.registerSharedPreferences(name: name, preferences: preferences);
  }

  /// Register a custom [LensDataSource] (source).
  static void registerSource(LensDataSource source) {
    registry.registerSource(source);
  }

  /// Unregister a source by [name] (legacy alias).
  static void unregister(String name) {
    registry.removeSource(name);
  }

  /// Remove a source by [sourceId].
  static void unregisterSource(String sourceId) {
    registry.removeSource(sourceId);
  }

  /// All registered source display names (backward compatible).
  static List<String> get databaseNames =>
      registry.getSources().map((s) => s.sourceName).toList();

  /// Get a registered sqflite database by [name] (legacy API).
  static Database? getDatabase(String name) =>
      registry.getSqliteDatabase(name);

  /// Membuat controller untuk panel (dipakai internal / testing).
  static DbLensController createController({DbLensConfig? config}) {
    final panelConfig = config ?? const DbLensConfig();
    return DbLensController(
      getSources: _getSources,
      getCollections: _getCollections,
      getRows: _getRows,
      getRowCount: _getRowCount,
      getColumns: _getColumns,
      runRawQueryPaged: _runRawQueryPaged,
      runRawQueryCount: _runRawQueryCount,
      executeStatement: _executeStatement,
      updateCell: _updateCell,
      getAllRows: _getAllRows,
      repository: _repository,
      config: panelConfig,
    );
  }

  /// Membuat controller untuk sheet riwayat perubahan data.
  static DbLensHistoryController createHistoryController() {
    return DbLensHistoryController(
      getHistory: _getHistory,
      clearHistory: _clearHistory,
      historyRepository: _historyRepository,
    );
  }

  /// Konfigurasi pelacakan riwayat perubahan data.
  static void configureHistory({
    bool? enabled,
    Duration? pollInterval,
  }) {
    if (kReleaseMode) return;
    registry.configureHistory(
      enabled: enabled,
      pollInterval: pollInterval,
    );
  }

  /// Open the DbLens panel.
  ///
  /// Tidak berjalan di release build ([kReleaseMode]).
  static Future<void> open(
    BuildContext context, {
    DbLensConfig? config,
    DbLensThemeData? theme,
    DbLensPresentationMode? mode,
  }) async {
    if (kReleaseMode) return;

    final panelConfig = config ?? const DbLensConfig();
    final effectiveMode = mode ?? panelConfig.presentationMode;

    switch (effectiveMode) {
      case DbLensPresentationMode.fullPage:
        await openPage(
          context,
          config: panelConfig,
          theme: theme,
          fullscreenDialog: panelConfig.fullscreenDialog,
        );
        return;
      case DbLensPresentationMode.embedded:
        assert(
          false,
          'DbLensPresentationMode.embedded tidak bisa dipakai lewat DbLens.open(). '
          'Gunakan DbLens.buildPanel() dan tempatkan widget-nya sendiri.',
        );
        return;
      case DbLensPresentationMode.bottomSheet:
        final panelTheme = DbLensTheme(theme);
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

  /// Buka inspector sebagai halaman penuh via [Navigator.push].
  static Future<void> openPage(
    BuildContext context, {
    DbLensConfig? config,
    DbLensThemeData? theme,
    bool fullscreenDialog = true,
  }) async {
    if (kReleaseMode) return;

    final panelConfig = config ?? const DbLensConfig();
    final panelTheme = DbLensTheme(theme);

    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: fullscreenDialog,
        builder: (_) => DbLensThemeScope(
          theme: panelTheme,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: DbLensPanel(config: panelConfig),
          ),
        ),
      ),
    );
  }

  /// Widget inspector yang bisa di-embed di widget tree konsumen.
  static Widget buildPanel({
    DbLensConfig? config,
    DbLensThemeData? theme,
    DbLensController? controller,
  }) {
    if (kReleaseMode) return const SizedBox.shrink();

    final panelConfig = config ?? const DbLensConfig();
    final panelTheme = DbLensTheme(theme);

    return DbLensThemeScope(
      theme: panelTheme,
      child: DbLensPanel(
        config: panelConfig,
        controller: controller,
      ),
    );
  }

  /// Buka shell UI custom sepenuhnya dengan [DbLensController] headless.
  static Future<void> openCustom(
    BuildContext context, {
    required Widget Function(BuildContext context, DbLensController controller)
        builder,
    DbLensConfig? config,
    DbLensThemeData? theme,
  }) async {
    if (kReleaseMode) return;

    final panelConfig = config ?? const DbLensConfig();

    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: panelConfig.fullscreenDialog,
        builder: (_) => DbLensCustomHost(
          builder: builder,
          config: panelConfig,
          theme: theme,
        ),
      ),
    );
  }

  /// Fetch all table names from a registered database (legacy API).
  static Future<List<String>> getTables(String dbName) async {
    final collections = await _getCollections(dbName);
    return collections.map((c) => c.name).toList();
  }

  /// Fetch rows from [table] with pagination (legacy API).
  static Future<List<Map<String, Object?>>> getRows(
    String dbName,
    String table, {
    int limit = DbLensConfig.defaultPageSize,
    int offset = 0,
  }) async {
    final rows = await _getRows(dbName, table, limit, offset);
    return rows.map((r) => r.data).toList();
  }

  /// Fetch total row count (legacy API).
  static Future<int> getRowCount(String dbName, String table) =>
      _getRowCount(dbName, table);

  /// Get column names (legacy API).
  static Future<List<String>> getColumns(String dbName, String table) =>
      _getColumns(dbName, table);

  /// Run a raw SELECT query (legacy API).
  static Future<List<Map<String, Object?>>> runRawQuery(
    String dbName,
    String sql,
  ) async {
    return _runRawQueryPaged(dbName, sql, limit: 0x7fffffff, offset: 0);
  }

  /// Run a paginated raw SELECT query (legacy API).
  static Future<List<Map<String, Object?>>> runRawQueryPaged(
    String dbName,
    String sql, {
    required int limit,
    required int offset,
  }) =>
      _runRawQueryPaged(dbName, sql, limit: limit, offset: offset);

  /// Total row count of a raw SELECT (legacy API).
  static Future<int> runRawQueryCount(String dbName, String sql) =>
      _runRawQueryCount(dbName, sql);

  /// Execute a non-SELECT statement (legacy API).
  static Future<void> executeStatement(String dbName, String sql) =>
      _executeStatement(dbName, sql);
}

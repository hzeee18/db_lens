import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../datasources/lens_datasource.dart';
import '../datasources/shared_preferences/shared_preferences_data_source.dart';
import '../datasources/sqlite/sqlite_data_source.dart';
import '../history/collection_change_tracker.dart';
import '../history/history_data_source.dart';
import '../history/history_repository_impl.dart';

/// Registry global untuk semua [LensDataSource] yang terdaftar.
class DbLensRegistry {
  DbLensRegistry({
    HistoryDataSource? historyDataSource,
    HistoryRepositoryImpl? historyRepository,
    Duration pollInterval = const Duration(seconds: 5),
    bool enableHistory = false,
  })  : _historyDataSource = historyDataSource,
        _historyRepository = historyRepository,
        _pollInterval = pollInterval,
        _enableHistory = enableHistory;

  final HistoryDataSource? _historyDataSource;
  final HistoryRepositoryImpl? _historyRepository;
  Duration _pollInterval;
  bool _enableHistory;

  final Map<String, LensDataSource> _sources = {};
  final Map<String, CollectionChangeTracker> _trackers = {};

  Duration get pollInterval => _pollInterval;
  bool get enableHistory => _enableHistory;

  /// Semua sumber data terdaftar.
  List<LensDataSource> getSources() => _sources.values.toList();

  LensDataSource? getSource(String sourceId) => _sources[sourceId];

  /// Daftarkan sumber SQLite dari instance [Database] sqflite.
  void registerSQLite({
    required String name,
    required Database database,
    String? id,
  }) {
    final sourceId = id ?? name;
    _sources[sourceId] = SqliteDataSource(
      sourceId: sourceId,
      sourceName: name,
      database: database,
    );
    _startTracking(_sources[sourceId]!);
  }

  /// Daftarkan sumber SharedPreferences.
  void registerSharedPreferences({
    required String name,
    required SharedPreferences preferences,
    String? id,
  }) {
    final sourceId = id ?? name;
    _sources[sourceId] = SharedPreferencesDataSource(
      sourceId: sourceId,
      sourceName: name,
      preferences: preferences,
    );
    _startTracking(_sources[sourceId]!);
  }

  /// Daftarkan sumber kustom (Hive, Isar, ObjectBox, dll.).
  void registerSource(LensDataSource source) {
    _sources[source.sourceId] = source;
    _startTracking(source);
  }

  /// Hapus sumber berdasarkan [sourceId].
  void removeSource(String sourceId) {
    _trackers.remove(sourceId)?.stop();
    _sources.remove(sourceId);
  }

  /// Ubah konfigurasi history dan restart tracker yang sedang berjalan.
  void configureHistory({
    bool? enabled,
    Duration? pollInterval,
  }) {
    if (enabled != null) {
      _enableHistory = enabled;
    }
    if (pollInterval != null) {
      _pollInterval = pollInterval;
    }

    if (!_enableHistory || _historyDataSource == null) {
      for (final tracker in _trackers.values) {
        tracker.stop();
      }
      _trackers.clear();
      return;
    }

    final sources = Map<String, LensDataSource>.from(_sources);
    for (final tracker in _trackers.values) {
      tracker.stop();
    }
    _trackers.clear();
    for (final source in sources.values) {
      _startTracking(source);
    }
  }

  void _startTracking(LensDataSource source) {
    if (!_enableHistory || _historyDataSource == null) return;

    _trackers.remove(source.sourceId)?.stop();
    final tracker = CollectionChangeTracker(
      source: source,
      historyDataSource: _historyDataSource!,
      historyRepository: _historyRepository,
      pollInterval: _pollInterval,
    );
    _trackers[source.sourceId] = tracker;
    tracker.start();
  }

  /// Ambil database sqflite mentah untuk backward compatibility.
  Database? getSqliteDatabase(String sourceId) {
    final source = _sources[sourceId];
    if (source is SqliteDataSource) {
      return source.database;
    }
    return null;
  }
}

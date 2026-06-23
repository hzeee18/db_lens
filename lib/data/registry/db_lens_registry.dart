import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../datasources/lens_datasource.dart';
import '../datasources/shared_preferences/shared_preferences_data_source.dart';
import '../datasources/sqlite/sqlite_data_source.dart';

/// Registry global untuk semua [LensDataSource] yang terdaftar.
class DbLensRegistry {
  final Map<String, LensDataSource> _sources = {};

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
  }

  /// Daftarkan sumber kustom (Hive, Isar, ObjectBox, dll.).
  void registerSource(LensDataSource source) {
    _sources[source.sourceId] = source;
  }

  /// Hapus sumber berdasarkan [sourceId].
  void removeSource(String sourceId) {
    _sources.remove(sourceId);
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

import 'package:sqflite/sqflite.dart';

import '../../../core/enums/source_type.dart';
import '../../../core/utils/parse_utils.dart';
import '../sqlite/sql_queryable_data_source.dart';

/// Implementasi [LensDataSource] untuk database SQLite (sqflite).
class SqliteDataSource implements SqlQueryableDataSource {
  SqliteDataSource({
    required String sourceId,
    required String sourceName,
    required Database database,
  })  : _sourceId = sourceId,
        _sourceName = sourceName,
        _database = database;

  final String _sourceId;
  final String _sourceName;
  final Database _database;

  /// Instance sqflite mentah (hanya untuk integrasi legacy).
  Database get database => _database;

  @override
  String get sourceId => _sourceId;

  @override
  String get sourceName => _sourceName;

  @override
  SourceType get sourceType => SourceType.sqlite;

  @override
  Future<List<String>> collections() async {
    final result = await _database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
    );
    return result.map((row) => row['name'] as String).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> rows(
    String collection,
    int limit,
    int offset,
  ) async {
    final result = await _database.rawQuery(
      'SELECT * FROM $collection LIMIT $limit OFFSET $offset',
    );
    return result.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  @override
  Future<int> count(String collection) async {
    final result = await _database.rawQuery(
      'SELECT COUNT(*) as count FROM $collection',
    );
    return ParseUtils.asInt(result.first['count']);
  }

  @override
  Future<List<String>> columnNames(String collection) async {
    final result = await _database.rawQuery('PRAGMA table_info($collection)');
    return result.map((row) => row['name'] as String).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> rawQuery(String sql) async {
    final result = await _database.rawQuery(sql);
    return result.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> rawQueryPaged(
    String sql, {
    required int limit,
    required int offset,
  }) async {
    final result = await _database.rawQuery(
      'SELECT * FROM ($sql) LIMIT $limit OFFSET $offset',
    );
    return result.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  @override
  Future<int> rawQueryCount(String sql) async {
    final result = await _database.rawQuery(
      'SELECT COUNT(*) as count FROM ($sql)',
    );
    return ParseUtils.asInt(result.first['count']);
  }

  @override
  Future<void> execute(String sql) async {
    await _database.execute(sql);
  }
}

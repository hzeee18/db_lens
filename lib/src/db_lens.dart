import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'db_lens_panel.dart';

/// Main entry point for DbLens.
///
/// Usage:
/// ```dart
/// // Register your database
/// DbLens.register('Main DB', db);
///
/// // Open the panel manually
/// DbLens.open(context);
/// ```
class DbLens {
  DbLens._();

  static final Map<String, Database> _databases = {};

  /// Register a sqflite [database] with a display [name].
  static void register(String name, Database database) {
    _databases[name] = database;
  }

  /// Unregister a database by [name].
  static void unregister(String name) {
    _databases.remove(name);
  }

  /// All registered database names.
  static List<String> get databaseNames => _databases.keys.toList();

  /// Get a registered database by [name].
  static Database? getDatabase(String name) => _databases[name];

  /// Open the DbLens panel.
  static void open(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DbLensPanel(),
    );
  }

  /// Fetch all table names from a registered database.
  static Future<List<String>> getTables(String dbName) async {
    final db = _databases[dbName];
    if (db == null) return [];
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
    );
    return result.map((r) => r['name'] as String).toList();
  }

  /// Fetch rows from [table] in database [dbName] with pagination.
  static Future<List<Map<String, Object?>>> getRows(
    String dbName,
    String table, {
    int limit = 50,
    int offset = 0,
  }) async {
    final db = _databases[dbName];
    if (db == null) return [];
    return db.rawQuery('SELECT * FROM $table LIMIT $limit OFFSET $offset');
  }

  /// Fetch total row count from [table] in database [dbName].
  static Future<int> getRowCount(String dbName, String table) async {
    final db = _databases[dbName];
    if (db == null) return 0;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $table');
    return (result.first['count'] as int?) ?? 0;
  }

  /// Get column names for [table] in database [dbName].
  static Future<List<String>> getColumns(String dbName, String table) async {
    final db = _databases[dbName];
    if (db == null) return [];
    final result = await db.rawQuery('PRAGMA table_info($table)');
    return result.map((r) => r['name'] as String).toList();
  }
}

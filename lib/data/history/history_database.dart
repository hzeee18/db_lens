import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Database sqflite privat milik db_lens untuk menyimpan riwayat perubahan.
class HistoryDatabase {
  HistoryDatabase._();

  static final HistoryDatabase instance = HistoryDatabase._();

  Database? _db;

  Future<Database> get database async {
    final existing = _db;
    if (existing != null) return existing;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'db_lens_history.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE history_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            source_id TEXT NOT NULL,
            source_name TEXT NOT NULL,
            collection TEXT NOT NULL,
            change_type TEXT NOT NULL,
            row_key TEXT NOT NULL,
            before_json TEXT,
            after_json TEXT,
            changed_columns TEXT,
            created_at_ms INTEGER NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_history_source_id ON history_entries(source_id)',
        );
        await db.execute(
          'CREATE INDEX idx_history_source_collection '
          'ON history_entries(source_id, collection)',
        );
        await db.execute(
          'CREATE INDEX idx_history_created_at ON history_entries(created_at_ms)',
        );
      },
    );
  }

  @visibleForTesting
  Future<void> closeForTesting() async {
    await _db?.close();
    _db = null;
  }
}

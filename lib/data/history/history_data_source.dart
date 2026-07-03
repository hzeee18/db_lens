import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../domain/entities/history_entry_entity.dart';
import 'history_database.dart';

/// CRUD langsung ke tabel [history_entries].
class HistoryDataSource {
  HistoryDataSource(this._database);

  final HistoryDatabase _database;

  Future<Database> get _db => _database.database;

  Future<void> insertEntries(List<HistoryEntry> entries) async {
    if (entries.isEmpty) return;

    final db = await _db;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final entry in entries) {
        batch.insert('history_entries', _toMap(entry));
      }
      await batch.commit(noResult: true);
    });
  }

  Future<List<HistoryEntry>> getForSource(
    String sourceId, {
    int? limit,
  }) async {
    final db = await _db;
    final rows = await db.query(
      'history_entries',
      where: 'source_id = ?',
      whereArgs: [sourceId],
      orderBy: 'created_at_ms DESC',
      limit: limit,
    );
    return rows.map(_fromMap).toList();
  }

  Future<void> clearForSource(String sourceId) async {
    final db = await _db;
    await db.delete(
      'history_entries',
      where: 'source_id = ?',
      whereArgs: [sourceId],
    );
  }

  Future<void> clearAll() async {
    final db = await _db;
    await db.delete('history_entries');
  }

  Map<String, Object?> _toMap(HistoryEntry entry) {
    return {
      if (entry.id != null) 'id': entry.id,
      'source_id': entry.sourceId,
      'source_name': entry.sourceName,
      'collection': entry.collection,
      'change_type': entry.changeType.name,
      'row_key': entry.rowKey,
      'before_json': entry.beforeJson,
      'after_json': entry.afterJson,
      'changed_columns': entry.changedColumns == null
          ? null
          : jsonEncode(entry.changedColumns),
      'created_at_ms': entry.createdAt.millisecondsSinceEpoch,
    };
  }

  HistoryEntry _fromMap(Map<String, Object?> row) {
    final changedColumnsRaw = row['changed_columns'] as String?;
    List<String>? changedColumns;
    if (changedColumnsRaw != null) {
      final decoded = jsonDecode(changedColumnsRaw);
      if (decoded is List) {
        changedColumns = decoded.map((e) => e.toString()).toList();
      }
    }

    return HistoryEntry(
      id: row['id'] as int?,
      sourceId: row['source_id'] as String,
      sourceName: row['source_name'] as String,
      collection: row['collection'] as String,
      changeType: HistoryChangeType.fromString(row['change_type'] as String),
      rowKey: row['row_key'] as String,
      beforeJson: row['before_json'] as String?,
      afterJson: row['after_json'] as String?,
      changedColumns: changedColumns,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row['created_at_ms'] as int,
      ),
    );
  }
}

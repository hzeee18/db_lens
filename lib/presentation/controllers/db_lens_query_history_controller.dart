import 'package:flutter/foundation.dart';

/// Satu entri riwayat eksekusi query — beda konsep dari [HistoryEntry]
/// (yang melacak perubahan baris). Ini melacak perintah SQL yang pernah
/// dijalankan konsumen lewat [DbLensQueryController].
class DbLensQueryHistoryEntry {
  const DbLensQueryHistoryEntry({
    required this.sql,
    required this.isError,
    required this.createdAt,
    this.info,
    this.table,
  });

  final String sql;
  final bool isError;
  final String? info;
  final String? table;
  final DateTime createdAt;
}

/// Riwayat query yang pernah dijalankan pada sesi ini (in-memory, tidak
/// dipersist). Dipisah dari [DbLensQueryController] supaya bisa dipakai
/// ulang tanpa terikat ke satu tampilan query editor tertentu.
class DbLensQueryHistoryController extends ChangeNotifier {
  DbLensQueryHistoryController({this.maxEntries = 40});

  final int maxEntries;

  final List<DbLensQueryHistoryEntry> _entries = [];

  List<DbLensQueryHistoryEntry> get entries => List.unmodifiable(_entries);

  bool get isEmpty => _entries.isEmpty;

  void record(String sql, {required bool isError, String? info, String? table}) {
    if (sql.trim().isEmpty) return;
    _entries.insert(
      0,
      DbLensQueryHistoryEntry(
        sql: sql,
        isError: isError,
        info: info,
        table: table,
        createdAt: DateTime.now(),
      ),
    );
    while (_entries.length > maxEntries) {
      _entries.removeLast();
    }
    notifyListeners();
  }

  void clear() {
    _entries.clear();
    notifyListeners();
  }
}

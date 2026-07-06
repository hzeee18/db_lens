import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';

import '../../domain/entities/history_entry_entity.dart';
import '../datasources/lens_datasource.dart';
import 'history_data_source.dart';
import 'history_repository_impl.dart';
import 'row_identity.dart';

/// Memantau perubahan data per source lewat polling + diffing snapshot.
class CollectionChangeTracker {
  CollectionChangeTracker({
    required LensDataSource source,
    required HistoryDataSource historyDataSource,
    HistoryRepositoryImpl? historyRepository,
    Duration pollInterval = const Duration(seconds: 5),
  })  : _source = source,
        _historyDataSource = historyDataSource,
        _historyRepository = historyRepository,
        _pollInterval = pollInterval;

  final LensDataSource _source;
  final HistoryDataSource _historyDataSource;
  final HistoryRepositoryImpl? _historyRepository;
  final Duration _pollInterval;

  Timer? _timer;
  bool _polling = false;
  bool _seeded = false;
  bool _seeding = false;
  Future<void>? _seedInFlight;

  /// collection -> identityKey -> row snapshot
  final Map<String, Map<String, Map<String, dynamic>>> _lastSnapshot = {};

  /// Kolom identitas per collection (cache).
  final Map<String, List<String>> _identityColumnsCache = {};

  void start() {
    _timer?.cancel();
    unawaited(_seedBaseline());
    _timer = Timer.periodic(_pollInterval, (_) => unawaited(_poll()));
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Jalankan satu siklus polling (untuk unit test).
  @visibleForTesting
  Future<void> pollNow() => _poll();

  /// Seed baseline tanpa menulis riwayat (untuk unit test).
  @visibleForTesting
  Future<void> seedNow() => _seedBaseline();

  Future<void> _seedBaseline() async {
    if (_seeded) return;
    if (_seeding) {
      await _seedInFlight;
      return;
    }

    _seeding = true;
    final future = _runSeedBaseline();
    _seedInFlight = future;
    try {
      await future;
    } finally {
      _seeding = false;
      if (identical(_seedInFlight, future)) {
        _seedInFlight = null;
      }
    }
  }

  Future<void> _runSeedBaseline() async {
    try {
      final collections = await _source.collections();
      for (final collection in collections) {
        if (_isInternalCollection(collection)) continue;
        await _refreshSnapshot(collection);
      }
      _seeded = true;
    } catch (_) {
      // Abaikan error seed — tick berikutnya akan mencoba lagi.
    }
  }

  Future<void> _poll() async {
    if (_polling) return;
    _polling = true;
    try {
      if (!_seeded) {
        await _seedBaseline();
        return;
      }

      final collections = await _source.collections();
      for (final collection in collections) {
        if (_isInternalCollection(collection)) continue;
        await _diffCollection(collection);
      }

      // Hapus snapshot collection yang sudah tidak ada.
      final removedCollections = _lastSnapshot.keys
          .where(
            (name) =>
                !collections.contains(name) || _isInternalCollection(name),
          )
          .toList();
      for (final name in removedCollections) {
        _lastSnapshot.remove(name);
        _identityColumnsCache.remove(name);
      }
    } catch (_) {
      // Abaikan error polling — coba lagi di tick berikutnya.
    } finally {
      _polling = false;
    }
  }

  Future<void> _refreshSnapshot(String collection) async {
    final identityColumns = await _identityColumnsFor(collection);
    final rows = await _source.allRows(collection);
    final snapshot = <String, Map<String, dynamic>>{};
    for (final row in rows) {
      final key = RowIdentity.of(row, identityColumns);
      snapshot[key] = row;
    }
    _lastSnapshot[collection] = snapshot;
  }

  Future<void> _diffCollection(String collection) async {
    final identityColumns = await _identityColumnsFor(collection);
    final rows = await _source.allRows(collection);
    final newSnapshot = <String, Map<String, dynamic>>{};
    for (final row in rows) {
      final key = RowIdentity.of(row, identityColumns);
      newSnapshot[key] = row;
    }

    final oldSnapshot = _lastSnapshot[collection] ?? {};
    final entries = <HistoryEntry>[];
    final now = DateTime.now();

    for (final entry in newSnapshot.entries) {
      final key = entry.key;
      final newRow = entry.value;
      final oldRow = oldSnapshot[key];
      if (oldRow == null) {
        entries.add(_insertEntry(collection, key, newRow, now));
      } else if (_rowJson(oldRow) != _rowJson(newRow)) {
        entries.add(_updateEntry(collection, key, oldRow, newRow, now));
      }
    }

    for (final key in oldSnapshot.keys) {
      if (!newSnapshot.containsKey(key)) {
        entries.add(_deleteEntry(collection, key, oldSnapshot[key]!, now));
      }
    }

    if (entries.isNotEmpty) {
      await _historyDataSource.insertEntries(entries);
      _historyRepository?.notifyChanged();
    }

    _lastSnapshot[collection] = newSnapshot;
  }

  Future<List<String>> _identityColumnsFor(String collection) async {
    final cached = _identityColumnsCache[collection];
    if (cached != null) return cached;
    final columns = await _source.identityColumns(collection);
    _identityColumnsCache[collection] = columns;
    return columns;
  }

  HistoryEntry _insertEntry(
    String collection,
    String rowKey,
    Map<String, dynamic> row,
    DateTime createdAt,
  ) {
    return HistoryEntry(
      sourceId: _source.sourceId,
      sourceName: _source.sourceName,
      collection: collection,
      changeType: HistoryChangeType.insert,
      rowKey: rowKey,
      afterJson: _rowJson(row),
      createdAt: createdAt,
    );
  }

  HistoryEntry _updateEntry(
    String collection,
    String rowKey,
    Map<String, dynamic> before,
    Map<String, dynamic> after,
    DateTime createdAt,
  ) {
    final changedColumns = <String>[];
    final allKeys = {...before.keys, ...after.keys};
    for (final key in allKeys) {
      if (key == '_rowid_') continue;
      if (_valueJson(before[key]) != _valueJson(after[key])) {
        changedColumns.add(key);
      }
    }

    return HistoryEntry(
      sourceId: _source.sourceId,
      sourceName: _source.sourceName,
      collection: collection,
      changeType: HistoryChangeType.update,
      rowKey: rowKey,
      beforeJson: _rowJson(before),
      afterJson: _rowJson(after),
      changedColumns: changedColumns.isEmpty ? null : changedColumns,
      createdAt: createdAt,
    );
  }

  HistoryEntry _deleteEntry(
    String collection,
    String rowKey,
    Map<String, dynamic> row,
    DateTime createdAt,
  ) {
    return HistoryEntry(
      sourceId: _source.sourceId,
      sourceName: _source.sourceName,
      collection: collection,
      changeType: HistoryChangeType.delete,
      rowKey: rowKey,
      beforeJson: _rowJson(row),
      createdAt: createdAt,
    );
  }

  String _rowJson(Map<String, dynamic> row) {
    final cleaned = Map<String, dynamic>.from(row)..remove('_rowid_');
    return jsonEncode(cleaned);
  }

  String _valueJson(Object? value) => jsonEncode(value);

  bool _isInternalCollection(String collection) {
    return collection.startsWith('sqlite_');
  }
}

import 'dart:async';

import '../../domain/entities/history_entry_entity.dart';
import '../../domain/repositories/history_repository.dart';
import 'history_data_source.dart';

/// Implementasi [HistoryRepository] berbasis sqflite privat.
class HistoryRepositoryImpl implements HistoryRepository {
  HistoryRepositoryImpl(this._dataSource);

  final HistoryDataSource _dataSource;
  final StreamController<void> _changedController =
      StreamController<void>.broadcast();

  @override
  Stream<void> get onChanged => _changedController.stream;

  @override
  Future<List<HistoryEntry>> getHistory(String sourceId, {int? limit}) {
    return _dataSource.getForSource(sourceId, limit: limit);
  }

  @override
  Future<void> clearHistory(String sourceId) async {
    await _dataSource.clearForSource(sourceId);
    _changedController.add(null);
  }

  @override
  Future<void> clearAllHistory() async {
    await _dataSource.clearAll();
    _changedController.add(null);
  }

  /// Dipanggil oleh tracker setelah menulis entri baru.
  void notifyChanged() {
    if (!_changedController.isClosed) {
      _changedController.add(null);
    }
  }

  void dispose() {
    _changedController.close();
  }
}

import '../entities/history_entry_entity.dart';

/// Kontrak akses riwayat perubahan data per source.
abstract class HistoryRepository {
  Future<List<HistoryEntry>> getHistory(String sourceId, {int? limit});

  Future<void> clearHistory(String sourceId);

  Future<void> clearAllHistory();

  /// Dipancarkan saat tracker menulis entri baru atau riwayat dihapus.
  Stream<void> get onChanged;
}

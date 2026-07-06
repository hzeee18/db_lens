/// Jenis perubahan data yang terdeteksi oleh history tracker.
enum HistoryChangeType {
  insert,
  update,
  delete;

  static HistoryChangeType fromString(String value) {
    return HistoryChangeType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => throw ArgumentError('Unknown change type: $value'),
    );
  }
}

/// Satu entri riwayat perubahan baris di collection.
class HistoryEntry {
  const HistoryEntry({
    this.id,
    required this.sourceId,
    required this.sourceName,
    required this.collection,
    required this.changeType,
    required this.rowKey,
    this.beforeJson,
    this.afterJson,
    this.changedColumns,
    required this.createdAt,
  });

  final int? id;
  final String sourceId;
  final String sourceName;
  final String collection;
  final HistoryChangeType changeType;
  final String rowKey;
  final String? beforeJson;
  final String? afterJson;
  final List<String>? changedColumns;
  final DateTime createdAt;
}

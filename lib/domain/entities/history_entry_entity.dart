/// Change type detected by the history tracker.
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

/// One persisted row-change history entry.
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

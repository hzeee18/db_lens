import 'dart:convert';

/// Field diff kind between before/after snapshots.
enum DbLensDiffKind { added, removed, changed, unchanged }

/// One field diff result.
class DbLensDiffField {
  const DbLensDiffField({
    required this.key,
    required this.beforeValue,
    required this.afterValue,
    required this.kind,
  });

  final String key;
  final Object? beforeValue;
  final Object? afterValue;
  final DbLensDiffKind kind;
}

/// Computes field-level diffs from history entry JSON snapshots.
class DbLensHistoryDiffUtils {
  const DbLensHistoryDiffUtils._();

  static List<DbLensDiffField> compute({
    String? beforeJson,
    String? afterJson,
    List<String>? changedColumns,
  }) {
    final before = _tryParse(beforeJson);
    final after = _tryParse(afterJson);
    final keys = <String>{...before.keys, ...after.keys}.toList()..sort();
    final changedSet = changedColumns?.toSet();

    return keys.map((key) {
      final hasBefore = before.containsKey(key);
      final hasAfter = after.containsKey(key);

      final DbLensDiffKind kind;
      if (hasBefore && !hasAfter) {
        kind = DbLensDiffKind.removed;
      } else if (!hasBefore && hasAfter) {
        kind = DbLensDiffKind.added;
      } else if (changedSet != null) {
        kind = changedSet.contains(key)
            ? DbLensDiffKind.changed
            : DbLensDiffKind.unchanged;
      } else {
        kind = jsonEncode(before[key]) != jsonEncode(after[key])
            ? DbLensDiffKind.changed
            : DbLensDiffKind.unchanged;
      }

      return DbLensDiffField(
        key: key,
        beforeValue: before[key],
        afterValue: after[key],
        kind: kind,
      );
    }).toList();
  }

  static Map<String, dynamic> _tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } catch (_) {
      return const {};
    }
  }
}

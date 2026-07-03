import 'package:flutter/material.dart';

import '../controllers/db_lens_query_history_controller.dart';
import '../theme/db_lens_theme.dart';
import 'db_lens_empty_state.dart';

/// Daftar riwayat query yang pernah dijalankan pada sesi ini — tap untuk
/// memakai ulang SQL-nya (lewat [onSelect]).
class DbLensQueryHistoryList extends StatelessWidget {
  const DbLensQueryHistoryList({
    super.key,
    required this.controller,
    this.table,
    this.onSelect,
  });

  final DbLensQueryHistoryController controller;

  /// Bila diisi, hanya entri yang dijalankan pada konteks tabel ini yang
  /// ditampilkan. `null` menampilkan semua riwayat.
  final String? table;
  final ValueChanged<String>? onSelect;

  List<DbLensQueryHistoryEntry> _visibleEntries() {
    if (table == null) return controller.entries;
    return controller.entries.where((e) => e.table == table).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = DbLensThemeScope.of(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final entries = _visibleEntries();

        if (entries.isEmpty) {
          return DbLensEmptyState(
            icon: Icons.history_toggle_off,
            title: table == null ? 'Belum ada query' : 'Belum ada query untuk tabel ini',
            subtitle: table == null
                ? 'Query yang dijalankan akan muncul di sini.'
                : 'Query yang dijalankan pada "$table" akan muncul di sini.',
            theme: theme,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: entries.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final entry = entries[index];
            return InkWell(
              onTap: onSelect == null ? null : () => onSelect!(entry.sql),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: entry.isError
                        ? Colors.redAccent.withValues(alpha: 0.3)
                        : theme.border,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.sql,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: theme.textPrimary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          entry.isError ? Icons.error_outline : Icons.check_circle_outline,
                          size: 12,
                          color: entry.isError ? Colors.redAccent : theme.diffAdded,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            entry.info ?? '',
                            style: TextStyle(
                              color: entry.isError ? Colors.redAccent : theme.textMuted,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (onSelect != null)
                          Text(
                            'Pakai',
                            style: TextStyle(
                              color: theme.accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

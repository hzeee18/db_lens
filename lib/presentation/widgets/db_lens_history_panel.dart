import 'package:flutter/material.dart';

import '../../domain/entities/history_entry_entity.dart';
import '../controllers/db_lens_history_controller.dart';
import '../theme/db_lens_theme.dart';
import 'db_lens_empty_state.dart';
import 'db_lens_history_entry_view.dart';

/// Konten riwayat perubahan data — search, toggle tracking, list entri.
///
/// Widget biasa, TIDAK terikat ke bottom sheet — bisa ditempel di
/// `Scaffold` biasa, tab, atau dibungkus modal lewat [DbLensHistorySheet].
/// (Sebelumnya konten ini terkunci privat di dalam sheet, sehingga
/// konsumen yang butuh tampilan full-page terpaksa menulis ulang total.)
class DbLensHistoryPanel extends StatefulWidget {
  const DbLensHistoryPanel({
    super.key,
    required this.controller,
    this.sourceName,
    this.onEntryTap,
    this.showHeader = true,
  });

  final DbLensHistoryController controller;
  final String? sourceName;
  final void Function(BuildContext context, HistoryEntry entry)? onEntryTap;
  final bool showHeader;

  @override
  State<DbLensHistoryPanel> createState() => _DbLensHistoryPanelState();
}

class _DbLensHistoryPanelState extends State<DbLensHistoryPanel> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    widget.controller.startListening();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    widget.controller.stopListening();
    _searchController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear history'),
        content: const Text('Hapus semua riwayat perubahan untuk source ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) await widget.controller.clear();
  }

  void _openEntry(BuildContext context, HistoryEntry entry) {
    if (widget.onEntryTap != null) {
      widget.onEntryTap!(context, entry);
      return;
    }
    DbLensHistoryEntryView.showAsSheet(context, entry: entry);
  }

  @override
  Widget build(BuildContext context) {
    final theme = DbLensThemeScope.of(context);
    final c = widget.controller;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showHeader) _buildHeader(context, theme, c),
        if (!c.isEmpty) _buildSearchField(theme, c),
        Divider(height: 1, color: theme.border),
        Expanded(child: _buildBody(theme, c)),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, DbLensTheme theme, DbLensHistoryController c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 12),
      child: Row(
        children: [
          Icon(Icons.history, size: 18, color: theme.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Change History',
                  style: TextStyle(color: theme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                ),
                if (widget.sourceName != null)
                  Text(widget.sourceName!, style: TextStyle(color: theme.textMuted, fontSize: 11)),
              ],
            ),
          ),
          if (c.canToggleTracking) _buildTrackingToggle(theme, c),
          if (!c.isEmpty)
            TextButton(onPressed: () => _confirmClear(context), child: const Text('Clear')),
        ],
      ),
    );
  }

  Widget _buildTrackingToggle(DbLensTheme theme, DbLensHistoryController c) {
    final enabled = c.trackingEnabled;
    return Tooltip(
      message: enabled ? 'Pause tracking' : 'Resume tracking',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Track', style: TextStyle(color: theme.textMuted, fontSize: 11)),
          Transform.scale(
            scale: 0.75,
            child: Switch(
              value: enabled,
              activeThumbColor: theme.accent,
              onChanged: c.setTrackingEnabled,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(DbLensTheme theme, DbLensHistoryController c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: TextField(
        controller: _searchController,
        onChanged: c.setSearchText,
        decoration: theme.fieldDecoration(
          hintText: 'Search by table or row...',
          prefixIcon: const Icon(Icons.search, size: 18),
          suffixIcon: c.searchText.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  onPressed: () {
                    _searchController.clear();
                    c.setSearchText('');
                  },
                  icon: const Icon(Icons.close, size: 16),
                ),
        ),
      ),
    );
  }

  Widget _buildBody(DbLensTheme theme, DbLensHistoryController c) {
    if (c.loading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: CircularProgressIndicator(color: theme.accent),
        ),
      );
    }

    if (c.isEmpty) {
      return DbLensEmptyState(
        icon: Icons.history_toggle_off,
        title: 'No changes yet',
        subtitle: 'Perubahan data akan muncul di sini setelah terdeteksi.',
        theme: theme,
      );
    }

    final filtered = c.filteredEntries;
    if (filtered.isEmpty) {
      return DbLensEmptyState(
        icon: Icons.search_off_outlined,
        title: 'No results for "${c.searchText.trim()}"',
        subtitle: 'Try a different table or row name',
        theme: theme,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => Divider(height: 1, indent: 56, color: theme.border),
      itemBuilder: (context, index) {
        final entry = filtered[index];
        return ListTile(
          onTap: () => _openEntry(context, entry),
          leading: Icon(_iconFor(entry.changeType), color: _colorFor(entry.changeType, theme)),
          title: Text(
            entry.collection,
            style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            '${entry.changeType.name} · ${entry.rowKey}',
            style: TextStyle(color: theme.textMuted, fontSize: 12),
          ),
          trailing: Text(_formatTime(entry.createdAt), style: TextStyle(color: theme.textMuted, fontSize: 11)),
        );
      },
    );
  }

  IconData _iconFor(HistoryChangeType type) {
    return switch (type) {
      HistoryChangeType.insert => Icons.add_circle_outline,
      HistoryChangeType.update => Icons.edit_outlined,
      HistoryChangeType.delete => Icons.remove_circle_outline,
    };
  }

  Color _colorFor(HistoryChangeType type, DbLensTheme theme) {
    return switch (type) {
      HistoryChangeType.insert => theme.diffAdded,
      HistoryChangeType.update => theme.diffChanged,
      HistoryChangeType.delete => theme.diffRemoved,
    };
  }

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final s = time.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

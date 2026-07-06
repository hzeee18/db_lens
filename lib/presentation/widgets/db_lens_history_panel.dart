import 'package:flutter/material.dart';

import '../../domain/entities/history_entry_entity.dart';
import '../controllers/db_lens_history_controller.dart';
import '../theme/db_lens_theme.dart';
import 'db_lens_empty_state.dart';
import 'db_lens_history_entry_view.dart';

/// History entry list. Search/filter panels open from [DbLensHistoryHeader].
///
/// Pass [table] to scope entries to one collection.
class DbLensHistoryPanel extends StatefulWidget {
  const DbLensHistoryPanel({
    super.key,
    required this.controller,
    this.table,
    this.onEntryTap,
  });

  final DbLensHistoryController controller;

  /// Scope entries to this collection only.
  final String? table;

  final void Function(BuildContext context, HistoryEntry entry)? onEntryTap;

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
    _searchController.text = widget.controller.searchText;
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

  List<HistoryEntry> _visibleEntries(DbLensHistoryController c) {
    final entries = c.filteredEntries;
    final table = widget.table;
    if (table == null) return entries;
    return entries.where((e) => e.collection == table).toList();
  }

  bool _hasEntriesForScope(DbLensHistoryController c) {
    final table = widget.table;
    if (table == null) return !c.isEmpty;
    return c.entries.any((e) => e.collection == table);
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
    final hasScopeData = _hasEntriesForScope(c);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasScopeData && c.searchExpanded) _buildSearchField(theme, c),
        if (hasScopeData && c.filtersExpanded) _buildFilters(theme, c),
        Divider(height: 1, color: theme.border),
        Expanded(child: _buildBody(theme, c)),
      ],
    );
  }

  Widget _buildSearchField(DbLensTheme theme, DbLensHistoryController c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        onChanged: c.setSearchText,
        decoration: theme.fieldDecoration(
          hintText: 'Search by row...',
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

  Widget _buildFilters(DbLensTheme theme, DbLensHistoryController c) {
    final tables = c.availableTables;
    final showTablePicker = widget.table == null && tables.length > 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showTablePicker)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DropdownButtonFormField<String?>(
                value: c.tableFilter,
                isExpanded: true,
                decoration: theme.fieldDecoration(
                  hintText: 'All tables',
                  prefixIcon: const Icon(Icons.table_chart_outlined, size: 18),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All tables'),
                  ),
                  for (final table in tables)
                    DropdownMenuItem<String?>(
                      value: table,
                      child: Text(table),
                    ),
                ],
                onChanged: c.setTableFilter,
              ),
            ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final type in HistoryChangeType.values)
                FilterChip(
                  label: Text(type.name),
                  selected: c.changeTypeFilter.contains(type),
                  onSelected: (_) => c.toggleChangeTypeFilter(type),
                  selectedColor: _colorFor(type, theme).withValues(alpha: 0.2),
                  checkmarkColor: _colorFor(type, theme),
                  labelStyle: TextStyle(
                    color: c.changeTypeFilter.contains(type)
                        ? _colorFor(type, theme)
                        : theme.textSecondary,
                    fontSize: 12,
                  ),
                  side: BorderSide(color: theme.border),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ],
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

    if (!_hasEntriesForScope(c)) {
      final table = widget.table;
      return DbLensEmptyState(
        icon: Icons.history_toggle_off,
        title: table != null ? 'No changes for "$table"' : 'No changes yet',
        subtitle: table != null
            ? 'No changes recorded for this table yet.'
            : 'Changes appear here once tracking detects them.',
        theme: theme,
      );
    }

    final filtered = _visibleEntries(c);
    if (filtered.isEmpty) {
      return DbLensEmptyState(
        icon: Icons.search_off_outlined,
        title: c.hasActiveFilters ? 'No matching changes' : 'No results',
        subtitle: c.hasActiveFilters
            ? 'Try a different table, change type, or search term'
            : 'Try a different row name',
        theme: theme,
      );
    }

    final showCollection = widget.table == null;

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
            showCollection ? entry.collection : entry.rowKey,
            style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            showCollection
                ? '${entry.changeType.name} · ${entry.rowKey}'
                : entry.changeType.name,
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

import 'package:db_lens/db_lens.dart';
import 'package:flutter/material.dart';

/// Demo custom UI headless via [DbLensInspectorScope] — browse home + detail
/// route memakai controller yang sama.
class CustomUiScreen extends StatelessWidget {
  const CustomUiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom UI (DbLensInspectorScope)')),
      body: DbLensInspectorScope(
        theme: DbLensThemeData.fromMaterialTheme(Theme.of(context)),
        builder: (context, controller) =>
            _BrowseHome(controller: controller),
      ),
    );
  }
}

class _BrowseHome extends StatefulWidget {
  const _BrowseHome({required this.controller});

  final DbLensController controller;

  @override
  State<_BrowseHome> createState() => _BrowseHomeState();
}

class _BrowseHomeState extends State<_BrowseHome> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.controller.loadBrowseSnapshot();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openCollection({
    required String sourceId,
    required String collection,
  }) async {
    final controller = widget.controller;
    await controller.selectSource(sourceId);
    await controller.selectCollection(collection);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _CollectionDetailScreen(controller: controller),
      ),
    );
    if (!mounted) return;
    await controller.refreshBrowse();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    if (controller.browseLoading && !controller.hasBrowseSnapshot) {
      return const Center(child: CircularProgressIndicator());
    }

    final snapshot = controller.filteredBrowseSnapshot;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 4, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search sources & collections...',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: controller.setBrowseSearchText,
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: controller.browseRefreshing
                    ? null
                    : controller.refreshBrowse,
                icon: controller.browseRefreshing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        if (controller.lastError != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              controller.lastError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        Expanded(
          child: snapshot.isEmpty
              ? const Center(child: Text('No sources or collections'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: snapshot.length,
                  itemBuilder: (context, sourceIndex) {
                    final sourceSnapshot = snapshot[sourceIndex];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.dns_outlined),
                            title: Text(sourceSnapshot.sourceName),
                            subtitle: Text(
                              '${sourceSnapshot.collections.length} collections · '
                              '${sourceSnapshot.totalRowCount} rows',
                            ),
                          ),
                          const Divider(height: 1),
                          for (final collection
                              in sourceSnapshot.collections)
                            ListTile(
                              dense: true,
                              title: Text(collection.name),
                              trailing: Text('${collection.rowCount}'),
                              onTap: () => _openCollection(
                                sourceId: sourceSnapshot.sourceId,
                                collection: collection.name,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _CollectionDetailScreen extends StatefulWidget {
  const _CollectionDetailScreen({required this.controller});

  final DbLensController controller;

  @override
  State<_CollectionDetailScreen> createState() =>
      _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<_CollectionDetailScreen> {
  final _queryController = TextEditingController();

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _editCell(String column, Map<String, Object?> row) async {
    final controller = widget.controller;
    final textController = TextEditingController(text: '${row[column]}');
    final newValue = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $column'),
        content: TextField(controller: textController, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, textController.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newValue == null) return;
    final ok = await controller.updateCellValue(
      column: column,
      newValue: newValue,
      row: row,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Updated' : 'Update failed')),
    );
  }

  Future<void> _runQuery(DbLensController controller) async {
    controller.setQueryText(_queryController.text);
    if (await controller.shouldConfirmQuery()) {
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm'),
          content: const Text('Query ini akan mengubah data. Lanjutkan?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Run'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await controller.runQuery();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final title = controller.selectedCollection ?? 'Collection';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Refresh rows',
            onPressed: controller.canRefresh ? controller.refresh : null,
            icon: controller.refreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search rows (client-side filter)...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: controller.setSearchText,
            ),
          ),
          if (controller.supportsRawSql)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _queryController,
                      decoration: const InputDecoration(
                        hintText: 'SELECT * FROM users WHERE age > 30',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => _runQuery(controller),
                    child: const Text('Run'),
                  ),
                ],
              ),
            ),
          if (controller.queryError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                controller.queryError!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          const Divider(height: 24),
          Expanded(
            child: controller.loading
                ? const Center(child: CircularProgressIndicator())
                : _RowList(controller: controller, onEditCell: _editCell),
          ),
        ],
      ),
    );
  }
}

class _RowList extends StatelessWidget {
  const _RowList({required this.controller, required this.onEditCell});

  final DbLensController controller;
  final void Function(String column, Map<String, Object?> row) onEditCell;

  @override
  Widget build(BuildContext context) {
    final columns = controller.activeColumns;
    final rows = controller.visibleRows(columns: columns);

    if (rows.isEmpty) {
      return const Center(child: Text('No rows'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final row = rows[index];
        return ListTile(
          title: Text(columns.take(2).map((c) => '${row[c]}').join(' · ')),
          subtitle: Text(
            columns.skip(2).map((c) => '$c=${row[c]}').join('  '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: controller.canEditCells && columns.isNotEmpty
              ? () => onEditCell(columns.first, row)
              : null,
        );
      },
    );
  }
}

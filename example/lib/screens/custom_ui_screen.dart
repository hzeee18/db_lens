import 'package:db_lens/db_lens.dart';
import 'package:flutter/material.dart';

/// Demo compose UI sendiri di atas `db_lens` — bukan lewat [DbLensPanel]
/// bawaan, cuma [DbLensControllerScope] + widget publik (search bar, query
/// editor, list view, cell editor) yang sama persis dipakai internal oleh
/// panel bawaan.
class CustomUiScreen extends StatelessWidget {
  const CustomUiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom UI (DbLensControllerScope)')),
      body: DbLensControllerScope(
        theme: DbLensThemeData.fromMaterialTheme(Theme.of(context)),
        child: const _BrowseHome(),
      ),
    );
  }
}

class _BrowseHome extends StatefulWidget {
  const _BrowseHome();

  @override
  State<_BrowseHome> createState() => _BrowseHomeState();
}

class _BrowseHomeState extends State<_BrowseHome> {
  final _searchController = TextEditingController();
  DbLensController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller == null) {
      _controller = DbLensControllerScope.of(context);
      _controller!.loadBrowseSnapshot();
    }
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
    final c = _controller!;
    await c.selectSource(sourceId);
    await c.selectCollection(collection);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DbLensControllerScope(
          controller: c,
          child: const _CollectionDetailScreen(),
        ),
      ),
    );
    if (!mounted) return;
    await c.browse.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final c = DbLensControllerScope.of(context);

    return AnimatedBuilder(
      animation: c.browse,
      builder: (context, _) {
        if (c.browse.loading && !c.browse.hasSnapshot) {
          return const Center(child: CircularProgressIndicator());
        }

        final snapshot = c.browse.filteredSnapshot;

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
                      onChanged: c.browse.setSearchText,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: c.browse.refreshing ? null : c.browse.refresh,
                    icon: c.browse.refreshing
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
            if (c.lastError != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  c.lastError!,
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
                              for (final collection in sourceSnapshot.collections)
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
      },
    );
  }
}

class _CollectionDetailScreen extends StatefulWidget {
  const _CollectionDetailScreen();

  @override
  State<_CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<_CollectionDetailScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = DbLensControllerScope.of(context);
    final title = c.source.selectedCollection ?? 'Collection';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: const [DbLensRefreshAction()],
      ),
      body: AnimatedBuilder(
        animation: c,
        builder: (context, _) {
          final columns = c.activeColumns;
          final rows = c.visibleRows(columns: columns);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DbLensSearchBar(
                controller: _searchController,
                hintText: 'Search rows (client-side filter)...',
                onChanged: c.table.setSearchText,
                onClear: c.table.clearSearch,
                showClear: c.table.searchText.isNotEmpty,
              ),
              if (c.source.supportsRawSql)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: DbLensQueryEditor(),
                ),
              if (c.query.queryError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(c.query.queryError!, style: const TextStyle(color: Colors.red)),
                ),
              const Divider(height: 24),
              Expanded(
                child: c.table.loading
                    ? const Center(child: CircularProgressIndicator())
                    : rows.isEmpty
                        ? const Center(child: Text('No rows'))
                        : DbLensListView(
                            rows: rows,
                            columns: columns,
                            canEditColumn: (_) => c.canEditCells,
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}

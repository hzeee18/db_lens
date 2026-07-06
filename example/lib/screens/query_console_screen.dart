import 'package:db_lens/db_lens.dart';
import 'package:flutter/material.dart';

/// Demo [DbLensQueryConsole] — konsol SQL penuh tanpa controller.
class QueryConsoleScreen extends StatefulWidget {
  const QueryConsoleScreen({super.key});

  @override
  State<QueryConsoleScreen> createState() => _QueryConsoleScreenState();
}

class _QueryConsoleScreenState extends State<QueryConsoleScreen> {
  bool _loading = true;
  List<_SourceOption> _sources = [];

  @override
  void initState() {
    super.initState();
    _loadSources();
  }

  Future<void> _loadSources() async {
    final options = <_SourceOption>[];
    for (final source in DbLens.registry.getSources()) {
      if (source.sourceType != SourceType.sqlite) continue;
      final tableNames = await source.collections();
      options.add(
        _SourceOption(name: source.sourceName, tableNames: tableNames),
      );
    }
    if (!mounted) return;
    setState(() {
      _sources = options;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Query Console')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sources.isEmpty
              ? const Center(child: Text('Tidak ada sumber SQL terdaftar'))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _sources.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final opt = _sources[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.terminal_rounded),
                        title: Text(opt.name),
                        subtitle: Text('${opt.tableNames.length} tables'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => DbLensQueryConsole.push(
                          context,
                          source: opt.name,
                          tableNames: opt.tableNames,
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _SourceOption {
  const _SourceOption({required this.name, required this.tableNames});

  final String name;
  final List<String> tableNames;
}

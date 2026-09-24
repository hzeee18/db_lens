import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/enums/source_type.dart';
import '../../data/datasources/lens_datasource.dart';
import '../../db_lens_facade.dart';

/// Palet browser ini (nilai sama dengan token JColors yang dipakai tampilan
/// aslinya) — sengaja tidak mengikuti DbLensThemeData supaya tampilan tetap.
abstract final class _JC {
  static const neutral0 = Color(0xFFFFFFFF);
  static const neutral50 = Color(0xFFE3E3E3);
  static const neutral500 = Color(0xFF8D8C8C);
  static const neutral700 = Color(0xFF717171);
  static const neutral900 = Color(0xFF1A1A1A);
  static const primaryOrange30 = Color(0xFFFFF2EA);
  static const primaryOrange500 = Color(0xFFFF6600);
  static const primaryOrange700 = Color(0xFF993D00);
  static const secondaryTeal500 = Color(0xFF17A398);
  static const blueButtonText = Color(0xFF0079F5);
  static const textFieldBg = Color(0xFFF9F4EF);
}

bool _isOpen = false;

/// Membuka browser database full-page. Gating release ada di
/// [DbLens.openBrowser].
Future<void> openDbLensBrowserPage(BuildContext context) async {
  if (!context.mounted || _isOpen) return;
  _isOpen = true;
  try {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => const _DbLensBrowserPage(),
        fullscreenDialog: true,
      ),
    );
  } finally {
    _isOpen = false;
  }
}

// ─────────────────────────────────────────────────────────────────────

class _SourceData {
  const _SourceData({required this.source, required this.collections});
  final LensDataSource source;
  final List<_CollectionData> collections;
}

class _CollectionData {
  const _CollectionData({
    required this.source,
    required this.name,
    required this.rowCount,
  });
  final LensDataSource source;
  final String name;
  final int rowCount;
}

// ─────────────────────────────────────────────────────────────────────
// Browse page
// ─────────────────────────────────────────────────────────────────────

class _DbLensBrowserPage extends StatefulWidget {
  const _DbLensBrowserPage();

  @override
  State<_DbLensBrowserPage> createState() => _DbLensBrowserPageState();
}

class _DbLensBrowserPageState extends State<_DbLensBrowserPage> {
  bool _loading = true;
  List<_SourceData> _sources = [];
  String? _error;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_SourceData> get _filteredSources {
    if (_searchQuery.isEmpty) return _sources;
    final q = _searchQuery.toLowerCase();
    final result = <_SourceData>[];
    for (final sd in _sources) {
      final sourceMatches = sd.source.sourceName.toLowerCase().contains(q);
      final matchedCollections = sourceMatches
          ? sd.collections
          : sd.collections
              .where((c) => c.name.toLowerCase().contains(q))
              .toList();
      if (matchedCollections.isNotEmpty) {
        result.add(_SourceData(
          source: sd.source,
          collections: matchedCollections,
        ));
      }
    }
    return result;
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rawSources = DbLens.registry.getSources();
      final result = <_SourceData>[];
      for (final source in rawSources) {
        final names = await source.collections();
        final cols = <_CollectionData>[];
        for (final name in names) {
          final count = await source.count(name);
          cols.add(
              _CollectionData(source: source, name: name, rowCount: count));
        }
        result.add(_SourceData(source: source, collections: cols));
      }
      if (mounted) {
        setState(() {
          _sources = result;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _JC.neutral0,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _JC.neutral0,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded, color: _JC.neutral900),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Database Inspector',
            style: TextStyle(
              color: _JC.neutral900,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'Pilih collection untuk lihat data',
            style: TextStyle(color: _JC.neutral500, fontSize: 11),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: _JC.primaryOrange500),
          onPressed: _loadAll,
          tooltip: 'Refresh',
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: _JC.neutral50),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: _JC.primaryOrange500,
          strokeWidth: 2.5,
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: _JC.neutral700, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _loadAll,
                style: FilledButton.styleFrom(
                    backgroundColor: _JC.primaryOrange500),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }
    if (_sources.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.storage_outlined, size: 52, color: _JC.neutral500),
            SizedBox(height: 12),
            Text(
              'Belum ada sumber data',
              style: TextStyle(
                color: _JC.neutral900,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Panggil DbLens.register() sebelum membuka inspector',
              textAlign: TextAlign.center,
              style: TextStyle(color: _JC.neutral500, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final filtered = _filteredSources;
    final totalCollections =
        filtered.fold<int>(0, (sum, s) => sum + s.collections.length);
    final isSearching = _searchQuery.isNotEmpty;

    return Column(
      children: [
        _buildSearchBar(),
        _buildSummaryBar(filtered.length, totalCollections, isSearching),
        Expanded(
          child: filtered.isEmpty
              ? _buildSearchEmpty()
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _SourceSection(
                    data: filtered[i],
                    forceExpanded: isSearching,
                    searchQuery: _searchQuery,
                    onCollectionTap: _openCollection,
                    onQueryConsole:
                        filtered[i].source.sourceType == SourceType.sqlite
                            ? () => _openQueryConsole(filtered[i])
                            : null,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Cari nama DB atau collection...',
          hintStyle: const TextStyle(color: _JC.neutral500, fontSize: 13),
          prefixIcon: const Icon(Icons.search, size: 18, color: _JC.neutral500),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16),
                  color: _JC.neutral500,
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                ),
          isDense: true,
          filled: true,
          fillColor: _JC.textFieldBg,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _JC.neutral50),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _JC.neutral50),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: _JC.primaryOrange500, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryBar(
      int sourceCount, int collectionCount, bool isSearching) {
    final label = isSearching
        ? '$collectionCount hasil ditemukan'
        : '$sourceCount source · $collectionCount collection';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: _JC.textFieldBg,
      child: Row(
        children: [
          Icon(
            isSearching
                ? Icons.filter_list_rounded
                : Icons.info_outline_rounded,
            size: 14,
            color: isSearching ? _JC.primaryOrange500 : _JC.neutral500,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isSearching ? _JC.primaryOrange700 : _JC.neutral700,
              fontSize: 12,
              fontWeight: isSearching ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded, size: 48, color: _JC.neutral500),
          const SizedBox(height: 12),
          Text(
            'Tidak ada hasil untuk "$_searchQuery"',
            style: const TextStyle(
              color: _JC.neutral900,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Coba kata kunci lain',
            style: TextStyle(color: _JC.neutral500, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _openCollection(_CollectionData collection) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _CollectionDataPage(collection: collection),
      ),
    );
  }

  void _openQueryConsole(_SourceData sd) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _QueryConsolePage(
          source: sd.source,
          tableNames: sd.collections.map((c) => c.name).toList(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────

class _SourceSection extends StatefulWidget {
  const _SourceSection({
    required this.data,
    required this.onCollectionTap,
    this.forceExpanded = false,
    this.searchQuery = '',
    this.onQueryConsole,
  });

  final _SourceData data;
  final void Function(_CollectionData) onCollectionTap;
  final bool forceExpanded;
  final String searchQuery;
  final VoidCallback? onQueryConsole;

  @override
  State<_SourceSection> createState() => _SourceSectionState();
}

class _SourceSectionState extends State<_SourceSection> {
  bool _expanded = true;

  bool get _isExpanded => widget.forceExpanded || _expanded;

  @override
  Widget build(BuildContext context) {
    final source = widget.data.source;
    final isSQLite = source.sourceType == SourceType.sqlite;
    final collections = widget.data.collections;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Source header
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: _JC.primaryOrange30,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isSQLite ? Icons.storage_rounded : Icons.tune_rounded,
                    color: _JC.primaryOrange500,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        source.sourceName,
                        style: const TextStyle(
                          color: _JC.neutral900,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        isSQLite ? 'SQLite Database' : 'SharedPreferences',
                        style: const TextStyle(
                          color: _JC.neutral500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _JC.textFieldBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _JC.neutral50),
                  ),
                  child: Text(
                    '${collections.length} table',
                    style: const TextStyle(
                      color: _JC.neutral700,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (isSQLite && widget.onQueryConsole != null) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: widget.onQueryConsole,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _JC.primaryOrange30,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _JC.primaryOrange500.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.terminal_rounded,
                              size: 11, color: _JC.primaryOrange500),
                          SizedBox(width: 4),
                          Text(
                            'Query',
                            style: TextStyle(
                              color: _JC.primaryOrange700,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                if (!widget.forceExpanded)
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: _JC.neutral500,
                  ),
              ],
            ),
          ),
        ),
        if (_isExpanded) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: collections
                  .map((c) => _CollectionTile(
                        collection: c,
                        searchQuery: widget.searchQuery,
                        onTap: () => widget.onCollectionTap(c),
                      ))
                  .toList(),
            ),
          ),
        ],
        const Divider(height: 1, color: _JC.neutral50),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────

class _CollectionTile extends StatelessWidget {
  const _CollectionTile({
    required this.collection,
    required this.onTap,
    this.searchQuery = '',
  });

  final _CollectionData collection;
  final VoidCallback onTap;
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    final isHighlighted = searchQuery.isNotEmpty &&
        collection.name.toLowerCase().contains(searchQuery.toLowerCase());

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isHighlighted ? _JC.primaryOrange30 : _JC.textFieldBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isHighlighted ? _JC.primaryOrange500 : _JC.neutral50,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.table_rows_outlined,
                size: 15,
                color: isHighlighted ? _JC.primaryOrange500 : _JC.neutral700,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  collection.name,
                  style: TextStyle(
                    color:
                        isHighlighted ? _JC.primaryOrange700 : _JC.neutral900,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: collection.rowCount > 0
                      ? _JC.primaryOrange30
                      : _JC.neutral50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  collection.rowCount == 0
                      ? 'kosong'
                      : '${collection.rowCount} rows',
                  style: TextStyle(
                    color: collection.rowCount > 0
                        ? _JC.primaryOrange700
                        : _JC.neutral500,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: _JC.neutral500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Collection detail page
// ─────────────────────────────────────────────────────────────────────

class _CollectionDataPage extends StatefulWidget {
  const _CollectionDataPage({required this.collection});

  final _CollectionData collection;

  @override
  State<_CollectionDataPage> createState() => _CollectionDataPageState();
}

class _CollectionDataPageState extends State<_CollectionDataPage> {
  static const _pageSize = 20;

  // ── Table state ──────────────────────────────────────────────────────
  bool _loading = true;
  List<Map<String, dynamic>> _rows = [];
  List<String> _columns = [];
  int _page = 0;
  int _totalRows = 0;
  String _search = '';
  String? _tableError;
  bool _isJsonView = false;

  // ── Query state (SQLite only) ────────────────────────────────────────
  bool _queryPanelOpen = false;
  bool _queryRunning = false;
  bool _queryMode = false;
  List<Map<String, dynamic>> _queryRows = [];
  List<String> _queryColumns = [];
  String? _queryError;
  String? _queryInfo;

  // ── Controllers ──────────────────────────────────────────────────────
  final _searchController = TextEditingController();
  final _queryController = TextEditingController();

  // ── Derived ──────────────────────────────────────────────────────────
  bool get _isSQLite =>
      widget.collection.source.sourceType == SourceType.sqlite;

  bool _canEditField(String column) {
    if (column == '_rowid_') return false;
    if (!_isSQLite) {
      // SharedPreferences: only the 'value' column is safe to edit
      return column == 'value';
    }
    return true;
  }

  static bool _isSelectSql(String sql) {
    final t = sql.trim().toUpperCase();
    return t.startsWith('SELECT') ||
        t.startsWith('WITH') ||
        t.startsWith('PRAGMA') ||
        t.startsWith('EXPLAIN');
  }

  // ── Lifecycle ────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadPage(0);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _queryController.dispose();
    super.dispose();
  }

  // ── Data loading ─────────────────────────────────────────────────────
  Future<void> _loadPage(int page) async {
    setState(() {
      _loading = true;
      _tableError = null;
    });
    try {
      final source = widget.collection.source;
      final colName = widget.collection.name;
      final results = await Future.wait([
        source.columnNames(colName),
        source.rows(colName, _pageSize, page * _pageSize),
        source.count(colName),
      ]);
      if (mounted) {
        setState(() {
          _columns = (results[0] as List<String>)
              .where((c) => c != '_rowid_')
              .toList();
          _rows = results[1] as List<Map<String, dynamic>>;
          _totalRows = results[2] as int;
          _page = page;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _tableError = e.toString();
          _loading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredRows {
    final base = _queryMode ? _queryRows : _rows;
    if (_search.isEmpty) return base;
    final q = _search.toLowerCase();
    return base
        .where((row) => row.values
            .any((v) => v?.toString().toLowerCase().contains(q) ?? false))
        .toList();
  }

  int get _totalPages => _totalRows == 0 ? 1 : (_totalRows / _pageSize).ceil();

  // ── SQL query ─────────────────────────────────────────────────────────
  Future<void> _runQuery() async {
    final sql = _queryController.text.trim();
    if (sql.isEmpty) {
      setState(() => _queryError = 'Query tidak boleh kosong.');
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();

    if (_isSelectSql(sql)) {
      setState(() {
        _queryRunning = true;
        _queryError = null;
        _queryInfo = null;
      });
      try {
        final sourceName = widget.collection.source.sourceName;
        final rows = await DbLens.runRawQuery(sourceName, sql);
        if (mounted) {
          setState(() {
            _queryRows = rows
                .map((r) => r.map((k, v) => MapEntry(k, v as dynamic)))
                .toList();
            _queryColumns = rows.isNotEmpty
                ? rows.first.keys.where((k) => k != '_rowid_').toList()
                : [];
            _queryMode = true;
            _queryRunning = false;
            _queryInfo =
                '${rows.length} row${rows.length == 1 ? '' : 's'} returned';
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _queryError = e.toString();
            _queryRunning = false;
          });
        }
      }
    } else {
      // Non-SELECT: confirm first
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Konfirmasi Query'),
          content: const Text(
            '⚠️ Query ini dapat mengubah atau menghapus data.\nLanjutkan?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              style:
                  FilledButton.styleFrom(backgroundColor: _JC.primaryOrange500),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Jalankan'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;

      setState(() {
        _queryRunning = true;
        _queryError = null;
        _queryInfo = null;
      });
      try {
        final sourceName = widget.collection.source.sourceName;
        await DbLens.executeStatement(sourceName, sql);
        if (mounted) {
          setState(() {
            _queryRunning = false;
            _queryMode = false;
            _queryRows = [];
            _queryColumns = [];
            _queryInfo = null;
          });
          await _loadPage(_page);
          _showSnack('Query berhasil dijalankan');
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _queryError = e.toString();
            _queryRunning = false;
          });
        }
      }
    }
  }

  void _clearQuery() {
    setState(() {
      _queryMode = false;
      _queryRows = [];
      _queryColumns = [];
      _queryError = null;
      _queryInfo = null;
    });
  }

  // ── Cell editing ──────────────────────────────────────────────────────
  Future<void> _editCell(
    String column,
    Object? currentValue,
    Map<String, dynamic> row,
  ) async {
    final result = await showDialog<_EditResult>(
      context: context,
      builder: (_) => _EditCellDialog(
        column: column,
        currentValue: currentValue,
        isSQLite: _isSQLite,
      ),
    );

    if (result == null || result.cancelled || !mounted) return;

    try {
      await widget.collection.source.updateCell(
        widget.collection.name,
        column,
        result.value,
        row,
      );
      await _loadPage(_page);
      _showSnack('Nilai "$column" berhasil diperbarui');
    } catch (e) {
      _showSnack('Gagal memperbarui: $e', isError: true);
    }
  }

  // ── Row deletion (SharedPreferences) ──────────────────────────────────
  bool get _canDeleteRows =>
      !_queryMode && widget.collection.source.supportsRowDelete;

  Future<void> _deleteRow(Map<String, dynamic> row) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteRowDialog(
        keyName: '${row['key']}',
        value: row['value'],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await widget.collection.source.deleteRow(widget.collection.name, row);
      await _loadPage(_page);
      _showSnack('Data berhasil dihapus');
    } catch (e) {
      _showSnack('Gagal menghapus: $e', isError: true);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────
  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: isError ? Colors.redAccent : _JC.neutral900,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final activeColumns = _queryMode ? _queryColumns : _columns;
    return Scaffold(
      backgroundColor: _JC.neutral0,
      appBar: _buildAppBar(),
      body: _buildBody(activeColumns),
      bottomNavigationBar: _loading || _queryMode || _totalPages <= 1
          ? null
          : _buildPaginationBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _JC.neutral0,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      iconTheme: const IconThemeData(color: _JC.neutral900),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.collection.name,
            style: const TextStyle(
              color: _JC.neutral900,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            widget.collection.source.sourceName,
            style: const TextStyle(color: _JC.neutral500, fontSize: 11),
          ),
        ],
      ),
      actions: [
        if (!_loading && _totalRows > 0 && !_queryMode)
          Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _JC.textFieldBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _JC.neutral50),
            ),
            child: Text(
              '$_totalRows rows',
              style: const TextStyle(
                color: _JC.neutral700,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        if (_isSQLite)
          IconButton(
            icon: Icon(
              Icons.terminal_rounded,
              color: _queryPanelOpen ? _JC.primaryOrange500 : _JC.neutral700,
              size: 20,
            ),
            onPressed: () => setState(() => _queryPanelOpen = !_queryPanelOpen),
            tooltip: 'SQL Query',
          ),
        IconButton(
          icon: Icon(
            _isJsonView
                ? Icons.table_rows_outlined
                : Icons.data_object_outlined,
            color: _JC.primaryOrange500,
            size: 20,
          ),
          onPressed: () => setState(() => _isJsonView = !_isJsonView),
          tooltip: _isJsonView ? 'Table view' : 'JSON view',
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded,
              color: _JC.primaryOrange500, size: 20),
          onPressed: () {
            _clearQuery();
            _loadPage(0);
          },
          tooltip: 'Refresh',
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: _JC.neutral50),
      ),
    );
  }

  Widget _buildBody(List<String> activeColumns) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
            color: _JC.primaryOrange500, strokeWidth: 2.5),
      );
    }
    if (_tableError != null && !_queryMode) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 40, color: Colors.redAccent),
              const SizedBox(height: 8),
              Text(
                _tableError!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: _JC.neutral700, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => _loadPage(_page),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        if (_isSQLite && _queryPanelOpen) _buildQueryPanel(),
        _buildSearchBar(),
        if (_queryMode) _buildQueryResultBanner(),
        const Divider(height: 1, color: _JC.neutral50),
        Expanded(child: _buildContent(activeColumns)),
      ],
    );
  }

  // ── Query panel ───────────────────────────────────────────────────────
  Widget _buildQueryPanel() {
    return Container(
      decoration: const BoxDecoration(
        color: _JC.textFieldBg,
        border: Border(bottom: BorderSide(color: _JC.neutral50)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.terminal_rounded,
                  size: 14, color: _JC.neutral500),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Raw SQL Query',
                  style: TextStyle(
                    color: _JC.neutral900,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_queryMode)
                GestureDetector(
                  onTap: _clearQuery,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _JC.primaryOrange30,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.close_rounded,
                            size: 12, color: _JC.primaryOrange700),
                        SizedBox(width: 4),
                        Text(
                          'Kembali ke tabel',
                          style: TextStyle(
                            color: _JC.primaryOrange700,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _queryController,
            minLines: 2,
            maxLines: 5,
            onChanged: (_) => setState(() => _queryError = null),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: _JC.neutral900,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText: 'SELECT * FROM ${widget.collection.name} LIMIT 20',
              hintStyle: const TextStyle(color: _JC.neutral500, fontSize: 12),
              isDense: true,
              filled: true,
              fillColor: _JC.neutral0,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _JC.neutral50),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _JC.neutral50),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: _JC.primaryOrange500, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'SELECT: langsung dijalankan. Non-SELECT: butuh konfirmasi.',
                  style: TextStyle(color: _JC.neutral500, fontSize: 11),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _queryRunning ? null : _runQuery,
                style: FilledButton.styleFrom(
                  backgroundColor: _JC.primaryOrange500,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: _queryRunning
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.play_arrow_rounded,
                        size: 16, color: Colors.white),
                label: Text(
                  _queryRunning ? 'Menjalankan...' : 'Jalankan',
                  style: const TextStyle(fontSize: 13, color: Colors.white),
                ),
              ),
            ],
          ),
          if (_queryError != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline,
                      size: 14, color: Colors.redAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _queryError!,
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQueryResultBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: _JC.primaryOrange30,
      child: Row(
        children: [
          const Icon(Icons.query_stats_rounded,
              size: 14, color: _JC.primaryOrange700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _queryInfo ?? 'Hasil query kustom',
              style: const TextStyle(
                  color: _JC.primaryOrange700,
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
          ),
          GestureDetector(
            onTap: _clearQuery,
            child: const Icon(Icons.close_rounded,
                size: 16, color: _JC.primaryOrange700),
          ),
        ],
      ),
    );
  }

  // ── Search bar ────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _search = v),
        decoration: InputDecoration(
          hintText: 'Cari di halaman ini...',
          hintStyle: const TextStyle(color: _JC.neutral500, fontSize: 13),
          prefixIcon: const Icon(Icons.search, size: 18, color: _JC.neutral500),
          suffixIcon: _search.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16),
                  color: _JC.neutral500,
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _search = '');
                  },
                ),
          isDense: true,
          filled: true,
          fillColor: _JC.textFieldBg,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _JC.neutral50),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _JC.neutral50),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: _JC.primaryOrange500, width: 1.5),
          ),
        ),
      ),
    );
  }

  // ── Content ───────────────────────────────────────────────────────────
  Widget _buildContent(List<String> activeColumns) {
    final rows = _filteredRows;
    if (rows.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _search.isEmpty
                  ? (_queryMode
                      ? Icons.search_off_outlined
                      : Icons.inbox_outlined)
                  : Icons.search_off_outlined,
              size: 44,
              color: _JC.neutral500,
            ),
            const SizedBox(height: 10),
            Text(
              _search.isEmpty
                  ? (_queryMode
                      ? 'Query tidak mengembalikan data'
                      : 'Collection ini kosong')
                  : 'Tidak ada hasil untuk "$_search"',
              style: const TextStyle(
                  color: _JC.neutral700,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    if (_isJsonView) return _buildJsonView(rows);
    return _buildRowsList(rows, activeColumns);
  }

  Widget _buildJsonView(List<Map<String, dynamic>> rows) {
    final json = const JsonEncoder.withIndent('  ').convert(
      rows
          .map((r) =>
              Map.fromEntries(r.entries.where((e) => e.key != '_rowid_')))
          .toList(),
    );
    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          json,
          style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: _JC.neutral900,
              height: 1.55),
        ),
      ),
    );
  }

  Widget _buildRowsList(
      List<Map<String, dynamic>> rows, List<String> activeColumns) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final rowNum = _queryMode ? index + 1 : _page * _pageSize + index + 1;
        return _RowCard(
          row: rows[index],
          columns: activeColumns,
          rowNum: rowNum,
          searchQuery: _search,
          canEdit: _queryMode ? null : _canEditField,
          onEditCell: _queryMode ? null : _editCell,
          onDelete: _canDeleteRows ? () => _deleteRow(rows[index]) : null,
        );
      },
    );
  }

  Widget _buildPaginationBar() {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: _JC.neutral0,
        border: Border(top: BorderSide(color: _JC.neutral50)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _page > 0 ? () => _loadPage(_page - 1) : null,
            icon: const Icon(Icons.chevron_left_rounded),
            color: _JC.primaryOrange500,
            disabledColor: _JC.neutral500,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Halaman ${_page + 1} dari $_totalPages',
              style: const TextStyle(
                  color: _JC.neutral700,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            onPressed:
                _page < _totalPages - 1 ? () => _loadPage(_page + 1) : null,
            icon: const Icon(Icons.chevron_right_rounded),
            color: _JC.primaryOrange500,
            disabledColor: _JC.neutral500,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Row card
// ─────────────────────────────────────────────────────────────────────

class _RowCard extends StatefulWidget {
  const _RowCard({
    required this.row,
    required this.columns,
    required this.rowNum,
    required this.searchQuery,
    this.canEdit,
    this.onEditCell,
    this.onDelete,
  });

  final Map<String, dynamic> row;
  final List<String> columns;
  final int rowNum;
  final String searchQuery;
  // null = editing disabled for all fields (e.g. query result mode)
  final bool Function(String column)? canEdit;
  final Future<void> Function(String, Object?, Map<String, dynamic>)?
      onEditCell;
  // null = row deletion not supported (SQLite, query result mode)
  final VoidCallback? onDelete;

  @override
  State<_RowCard> createState() => _RowCardState();
}

class _RowCardState extends State<_RowCard> {
  bool _expanded = false;

  void _copyJson() {
    final exportRow = Map<String, dynamic>.from(widget.row)..remove('_rowid_');
    Clipboard.setData(ClipboardData(
        text: const JsonEncoder.withIndent('  ').convert(exportRow)));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text('Copied as JSON'),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: _JC.neutral900,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _JC.neutral0,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _JC.neutral50),
        boxShadow: const [
          BoxShadow(
              color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            if (_expanded) ...[
              const Divider(height: 1, color: _JC.neutral50),
              _buildFields(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _JC.primaryOrange30,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                '#${widget.rowNum}',
                style: const TextStyle(
                    color: _JC.primaryOrange700,
                    fontSize: 10,
                    fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: _buildPreview()),
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: const Icon(Icons.copy_rounded,
                  size: 15, color: _JC.neutral500),
              onPressed: _copyJson,
              tooltip: 'Copy as JSON',
            ),
            if (widget.onDelete != null)
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 17, color: Colors.redAccent),
                onPressed: widget.onDelete,
                tooltip: 'Hapus',
              ),
            Icon(
              _expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: _JC.neutral500,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final previewCols = widget.columns.take(2).toList();
    if (previewCols.isEmpty) {
      return const Text('(empty)',
          style: TextStyle(color: _JC.neutral500, fontSize: 12));
    }
    return Row(
      children: previewCols.map((col) {
        final value = widget.row[col];
        return Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(col,
                  style: const TextStyle(color: _JC.neutral500, fontSize: 10)),
              Text(
                _formatValue(value),
                style: TextStyle(
                    color: _valueColor(value),
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFields() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        children: widget.columns.map((col) {
          final value = widget.row[col];
          final q = widget.searchQuery.toLowerCase();
          final isMatch = q.isNotEmpty &&
              (value?.toString().toLowerCase().contains(q) ?? false);
          final editable = widget.canEdit?.call(col) ?? false;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Column label
                SizedBox(
                  width: 100,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          col,
                          style: const TextStyle(
                            color: _JC.neutral500,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Value
                Expanded(
                  child: GestureDetector(
                    onLongPress: editable
                        ? () => widget.onEditCell?.call(col, value, widget.row)
                        : null,
                    child: Container(
                      padding: isMatch
                          ? const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1)
                          : null,
                      decoration: isMatch
                          ? BoxDecoration(
                              color: _JC.primaryOrange30,
                              borderRadius: BorderRadius.circular(4),
                            )
                          : null,
                      child: SelectableText(
                        _formatValue(value),
                        style: TextStyle(
                          color: _valueColor(value),
                          fontSize: 12,
                          height: 1.4,
                          fontStyle: value == null
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                      ),
                    ),
                  ),
                ),
                // Edit button
                if (editable)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: InkWell(
                      onTap: () =>
                          widget.onEditCell?.call(col, value, widget.row),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _JC.textFieldBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _JC.neutral50),
                        ),
                        child: const Icon(Icons.edit_rounded,
                            size: 12, color: _JC.primaryOrange500),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatValue(Object? value) {
    if (value == null) return 'null';
    if (value is String) return '"$value"';
    return value.toString();
  }

  Color _valueColor(Object? value) {
    if (value == null) return _JC.neutral500;
    if (value is String) return _JC.secondaryTeal500;
    if (value is num) return _JC.primaryOrange700;
    if (value is bool) return _JC.blueButtonText;
    return _JC.neutral900;
  }
}

// ─────────────────────────────────────────────────────────────────────
// Query Console
// ─────────────────────────────────────────────────────────────────────

class _HistoryItem {
  const _HistoryItem({
    required this.sql,
    required this.info,
    required this.isError,
  });
  final String sql;
  final String info;
  final bool isError;
}

class _QueryConsolePage extends StatefulWidget {
  const _QueryConsolePage({
    required this.source,
    required this.tableNames,
  });

  final LensDataSource source;
  final List<String> tableNames;

  @override
  State<_QueryConsolePage> createState() => _QueryConsolePageState();
}

class _QueryConsolePageState extends State<_QueryConsolePage> {
  static const _editorBg = Color(0xFF1A1D23);
  static const _editorFg = Color(0xFFCDD6F4);
  static const _editorSubtle = Color(0xFF6B7280);
  static const _editorBorder = Color(0xFF2D3142);
  static const _editorAccent = Color(0xFF4D9DE0);
  static const _editorGreen = Color(0xFF4EC9B0);

  final _queryCtrl = TextEditingController();
  bool _running = false;
  bool _hasResult = false;
  List<Map<String, dynamic>> _rows = [];
  List<String> _cols = [];
  Map<String, double> _colWidths = {};
  String? _error;
  String? _info;
  bool _editorExpanded = true;
  final _history = <_HistoryItem>[];

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  static bool _isSelectSql(String sql) {
    final t = sql.trim().toUpperCase();
    return t.startsWith('SELECT') ||
        t.startsWith('WITH') ||
        t.startsWith('PRAGMA') ||
        t.startsWith('EXPLAIN');
  }

  static Map<String, double> _computeWidths(
      List<String> cols, List<Map<String, dynamic>> rows) {
    const minW = 80.0;
    const maxW = 240.0;
    const charW = 7.5;
    final widths = <String, double>{};
    for (final col in cols) {
      double w = col.length * charW + 40;
      for (final row in rows.take(60)) {
        final v = row[col]?.toString() ?? 'null';
        final vw = v.length * charW + 28;
        if (vw > w) w = vw;
      }
      widths[col] = w.clamp(minW, maxW);
    }
    return widths;
  }

  Future<void> _run() async {
    final sql = _queryCtrl.text.trim();
    if (sql.isEmpty) return;
    FocusManager.instance.primaryFocus?.unfocus();

    if (_isSelectSql(sql)) {
      setState(() {
        _running = true;
        _error = null;
        _info = null;
        _hasResult = false;
      });
      try {
        final sw = Stopwatch()..start();
        final rawRows = await DbLens.runRawQuery(widget.source.sourceName, sql);
        sw.stop();
        final ms = sw.elapsedMilliseconds;
        if (!mounted) return;
        final cols = rawRows.isNotEmpty
            ? rawRows.first.keys.where((k) => k != '_rowid_').toList()
            : <String>[];
        final rows = rawRows
            .map((r) => r.map((k, v) => MapEntry(k, v as dynamic)))
            .toList();
        final infoText =
            '${rows.length} row${rows.length == 1 ? '' : 's'} · ${ms}ms';
        setState(() {
          _rows = rows;
          _cols = cols.cast<String>();
          _colWidths = _computeWidths(_cols, _rows);
          _info = infoText;
          _hasResult = true;
          _running = false;
        });
        _addHistory(sql, infoText, isError: false);
      } catch (e) {
        if (!mounted) return;
        final msg = e.toString();
        setState(() {
          _error = msg;
          _hasResult = false;
          _running = false;
        });
        _addHistory(sql, msg, isError: true);
      }
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: _JC.neutral0,
          surfaceTintColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Text('Konfirmasi Eksekusi',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '⚠️ Statement ini akan mengubah atau menghapus data. Tidak bisa di-undo.',
                style:
                    TextStyle(color: _JC.neutral700, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _editorBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  sql,
                  style: const TextStyle(
                      fontFamily: 'monospace', fontSize: 12, color: _editorFg),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child:
                  const Text('Batal', style: TextStyle(color: _JC.neutral700)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Jalankan'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      setState(() {
        _running = true;
        _error = null;
      });
      try {
        await DbLens.executeStatement(widget.source.sourceName, sql);
        if (!mounted) return;
        setState(() => _running = false);
        _addHistory(sql, 'Berhasil dijalankan', isError: false);
        _showSnack('Statement berhasil dijalankan');
      } catch (e) {
        if (!mounted) return;
        final msg = e.toString();
        setState(() {
          _error = msg;
          _running = false;
        });
        _addHistory(sql, msg, isError: true);
      }
    }
  }

  void _addHistory(String sql, String info, {required bool isError}) {
    _history.insert(0, _HistoryItem(sql: sql, info: info, isError: isError));
    if (_history.length > 40) _history.removeLast();
  }

  void _clearAll() {
    setState(() {
      _queryCtrl.clear();
      _hasResult = false;
      _rows = [];
      _cols = [];
      _colWidths = {};
      _error = null;
      _info = null;
    });
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ]),
        duration: const Duration(seconds: 2),
        backgroundColor: isError ? Colors.redAccent : _JC.neutral900,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  void _showHistory() {
    if (_history.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _JC.neutral0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
              child: Row(
                children: [
                  const Icon(Icons.history_rounded,
                      size: 16, color: _JC.neutral700),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Riwayat Query',
                      style: TextStyle(
                          color: _JC.neutral900,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                    color: _JC.neutral500,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _JC.neutral50),
            Expanded(
              child: ListView.separated(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(12),
                itemCount: _history.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final item = _history[i];
                  return InkWell(
                    onTap: () {
                      _queryCtrl.text = item.sql;
                      setState(() {});
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _JC.textFieldBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: item.isError
                              ? Colors.redAccent.withValues(alpha: 0.3)
                              : _JC.neutral50,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.sql,
                            style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                color: _JC.neutral900,
                                height: 1.4),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                item.isError
                                    ? Icons.error_outline
                                    : Icons.check_circle_outline,
                                size: 12,
                                color: item.isError
                                    ? Colors.redAccent
                                    : _JC.secondaryTeal500,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  item.info,
                                  style: TextStyle(
                                    color: item.isError
                                        ? Colors.redAccent
                                        : _JC.neutral500,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Pakai',
                                style: TextStyle(
                                  color: _JC.primaryOrange500,
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _JC.neutral0,
      appBar: _buildAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildEditorPanel(),
          Expanded(child: _buildResultsPanel()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _editorBg,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      iconTheme: const IconThemeData(color: _editorFg),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Query Console',
            style: TextStyle(
                color: _editorFg, fontSize: 15, fontWeight: FontWeight.w600),
          ),
          Text(
            widget.source.sourceName,
            style: const TextStyle(color: _editorSubtle, fontSize: 11),
          ),
        ],
      ),
      actions: [
        if (_history.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.history_rounded,
                color: _editorSubtle, size: 20),
            onPressed: _showHistory,
            tooltip: 'Riwayat',
          ),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded,
              color: _editorSubtle, size: 20),
          onPressed: _clearAll,
          tooltip: 'Bersihkan',
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: _editorBorder),
      ),
    );
  }

  // ── Editor panel ──────────────────────────────────────────────────────

  Widget _buildEditorPanel() {
    return Container(
      color: _editorBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Toolbar row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 12, 6),
            child: Row(
              children: [
                const Icon(Icons.terminal_rounded,
                    size: 13, color: _editorAccent),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'SQL EDITOR',
                    style: TextStyle(
                      color: _editorSubtle,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () =>
                      setState(() => _editorExpanded = !_editorExpanded),
                  child: Icon(
                    _editorExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: _editorSubtle,
                  ),
                ),
              ],
            ),
          ),
          // Collapsible body
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child:
                _editorExpanded ? _buildEditorBody() : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Text field
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: TextField(
            controller: _queryCtrl,
            minLines: 3,
            maxLines: 8,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: _editorFg,
              height: 1.65,
            ),
            cursorColor: _JC.primaryOrange500,
            decoration: InputDecoration(
              hintText:
                  '-- Ketik SQL di sini\nSELECT * FROM ${widget.tableNames.firstOrNull ?? 'table_name'} LIMIT 20',
              hintStyle: const TextStyle(
                fontFamily: 'monospace',
                color: _editorSubtle,
                fontSize: 12,
                height: 1.65,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        // Table chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Row(
            children: [
              const Text(
                'Tables:',
                style: TextStyle(
                    color: _editorSubtle,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 10),
              ...widget.tableNames.map(
                (t) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () {
                      final text = _queryCtrl.text;
                      final sel = _queryCtrl.selection;
                      final start = sel.start < 0 ? text.length : sel.start;
                      final end = sel.end < 0 ? text.length : sel.end;
                      final newText = text.replaceRange(start, end, t);
                      _queryCtrl.value = TextEditingValue(
                        text: newText,
                        selection:
                            TextSelection.collapsed(offset: start + t.length),
                      );
                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF252836),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF3D4460)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.table_rows_outlined,
                              size: 10, color: _editorAccent),
                          const SizedBox(width: 5),
                          Text(
                            t,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              color: _editorFg,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Run bar
        Container(
          decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _editorBorder))),
          padding: const EdgeInsets.fromLTRB(16, 8, 12, 10),
          child: Row(
            children: [
              if (_info != null && !_running) ...[
                const Icon(Icons.check_circle_outline,
                    size: 13, color: _editorGreen),
                const SizedBox(width: 6),
                Text(
                  _info!,
                  style: const TextStyle(
                      color: _editorGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w500),
                ),
              ],
              const Spacer(),
              if (_queryCtrl.text.isNotEmpty) ...[
                GestureDetector(
                  onTap: () {
                    _queryCtrl.clear();
                    setState(() {});
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      'Hapus',
                      style: TextStyle(
                          color: _editorSubtle,
                          fontSize: 11,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              FilledButton.icon(
                onPressed: _running ? null : _run,
                style: FilledButton.styleFrom(
                  backgroundColor: _JC.primaryOrange500,
                  disabledBackgroundColor:
                      _JC.primaryOrange500.withValues(alpha: 0.4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                icon: _running
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.play_arrow_rounded,
                        size: 16, color: Colors.white),
                label: Text(
                  _running ? 'Running...' : 'Run',
                  style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Results panel ─────────────────────────────────────────────────────

  Widget _buildResultsPanel() {
    if (_running) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
                color: _JC.primaryOrange500, strokeWidth: 2.5),
            SizedBox(height: 14),
            Text(
              'Menjalankan query...',
              style: TextStyle(color: _JC.neutral500, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.error_outline, size: 16, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Text(
                    'Query Error',
                    style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SelectableText(
                _error!,
                style: const TextStyle(
                    color: Colors.redAccent, fontSize: 12, height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    if (!_hasResult) return _buildIdleState();

    if (_rows.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 44, color: _JC.neutral500),
            SizedBox(height: 10),
            Text(
              'Query berhasil — tidak ada data',
              style: TextStyle(color: _JC.neutral700, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildResultBanner(),
        Expanded(child: _buildDataGrid()),
      ],
    );
  }

  Widget _buildIdleState() {
    final tables = widget.tableNames;
    final examples = [
      if (tables.isNotEmpty) 'SELECT * FROM ${tables.first} LIMIT 20',
      if (tables.length >= 2)
        'SELECT a.*, b.*\nFROM ${tables[0]} a\nJOIN ${tables[1]} b ON a.id = b.id',
      if (tables.isNotEmpty) 'PRAGMA table_info(${tables.first})',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: _JC.primaryOrange30,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.terminal_rounded,
                size: 32, color: _JC.primaryOrange500),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tulis SQL dan tekan Run',
            style: TextStyle(
                color: _JC.neutral900,
                fontSize: 16,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'Supports SELECT, JOIN, INSERT, UPDATE, DELETE, PRAGMA, dan lainnya.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _JC.neutral500, fontSize: 12, height: 1.5),
          ),
          if (examples.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Contoh query:',
                style: TextStyle(
                    color: _JC.neutral700,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),
            ...examples.map(
              (sql) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () {
                    _queryCtrl.text = sql;
                    if (!_editorExpanded) {
                      setState(() => _editorExpanded = true);
                    } else {
                      setState(() {});
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _editorBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _editorBorder),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            sql,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              color: _editorFg,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.north_west_rounded,
                            size: 14, color: _editorSubtle),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: _JC.textFieldBg,
        border: Border(bottom: BorderSide(color: _JC.neutral50)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
                color: _JC.secondaryTeal500, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            _info ?? '${_rows.length} rows',
            style: const TextStyle(
                color: _JC.neutral900,
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _JC.primaryOrange30,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${_cols.length} col',
              style: const TextStyle(
                  color: _JC.primaryOrange700,
                  fontSize: 10,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const Spacer(),
          _CopyButton(
            label: 'CSV',
            icon: Icons.file_copy_outlined,
            onTap: _copyAsCsv,
          ),
          const SizedBox(width: 12),
          _CopyButton(
            label: 'JSON',
            icon: Icons.data_object_outlined,
            onTap: _copyAsJson,
          ),
        ],
      ),
    );
  }

  void _copyAsJson() {
    Clipboard.setData(
        ClipboardData(text: const JsonEncoder.withIndent('  ').convert(_rows)));
    _showSnack('Disalin sebagai JSON');
  }

  void _copyAsCsv() {
    final header = _cols.join(',');
    final body = _rows.map((r) {
      return _cols.map((c) {
        final v = r[c]?.toString() ?? '';
        return v.contains(',') || v.contains('"')
            ? '"${v.replaceAll('"', '""')}"'
            : v;
      }).join(',');
    }).join('\n');
    Clipboard.setData(ClipboardData(text: '$header\n$body'));
    _showSnack('Disalin sebagai CSV');
  }

  // ── Data grid ─────────────────────────────────────────────────────────

  Widget _buildDataGrid() {
    if (_cols.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalW = _colWidths.values.fold(0.0, (s, w) => s + w);
        final tableW = max(constraints.maxWidth, totalW);
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableW,
            child: Column(
              children: [
                _buildGridHeader(tableW),
                Expanded(
                  child: ListView.builder(
                    itemCount: _rows.length,
                    itemBuilder: (_, i) => _buildGridRow(_rows[i], i, tableW),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridHeader(double tableW) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF1F3F5),
        border: Border(bottom: BorderSide(color: _JC.neutral50, width: 1.5)),
      ),
      child: Row(
        children: _cols.map((col) {
          final w = _cols.length == 1 ? tableW : (_colWidths[col] ?? 120.0);
          return SizedBox(
            width: w,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text(
                col,
                style: const TextStyle(
                  color: _JC.neutral700,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGridRow(Map<String, dynamic> row, int index, double tableW) {
    return Container(
      decoration: BoxDecoration(
        color: index.isEven
            ? _JC.neutral0
            : _JC.textFieldBg.withValues(alpha: 0.7),
        border:
            const Border(bottom: BorderSide(color: _JC.neutral50, width: 0.5)),
      ),
      child: Row(
        children: _cols.map((col) {
          final value = row[col];
          final w = _cols.length == 1 ? tableW : (_colWidths[col] ?? 120.0);
          return GestureDetector(
            onLongPress: () {
              Clipboard.setData(
                  ClipboardData(text: value?.toString() ?? 'null'));
              _showSnack('Nilai disalin');
            },
            child: SizedBox(
              width: w,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                child: Text(
                  value == null ? 'null' : value.toString(),
                  style: TextStyle(
                    color: _cellColor(value),
                    fontSize: 12,
                    fontFamily: 'monospace',
                    fontStyle:
                        value == null ? FontStyle.italic : FontStyle.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _cellColor(Object? v) {
    if (v == null) return _JC.neutral500;
    if (v is String) return _JC.secondaryTeal500;
    if (v is num) return _JC.primaryOrange700;
    if (v is bool) return _JC.blueButtonText;
    return _JC.neutral900;
  }
}

// Small reusable copy button used in the result banner
class _CopyButton extends StatelessWidget {
  const _CopyButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: _JC.neutral500),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
                color: _JC.neutral500,
                fontSize: 11,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Edit cell dialog
// ─────────────────────────────────────────────────────────────────────

/// Konfirmasi hapus satu key SharedPreferences — gaya sama dengan
/// [_EditCellDialog].
class _DeleteRowDialog extends StatelessWidget {
  const _DeleteRowDialog({required this.keyName, required this.value});

  final String keyName;
  final Object? value;

  static const _danger = Color(0xFFDC2626);
  static const _dangerSoft = Color(0xFFFEF2F2);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _JC.neutral0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      actionsPadding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _dangerSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.delete_outline_rounded,
                size: 18, color: _danger),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Hapus data?',
              style: TextStyle(
                color: _JC.neutral900,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _JC.textFieldBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _JC.neutral50),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('key',
                    style: TextStyle(color: _JC.neutral500, fontSize: 10)),
                Text(
                  keyName,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: _JC.neutral900,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                const Text('value',
                    style: TextStyle(color: _JC.neutral500, fontSize: 10)),
                Text(
                  '$value',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: _JC.neutral700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Data dihapus permanen dan tidak bisa di-undo.',
            style: TextStyle(color: _JC.neutral700, fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal', style: TextStyle(color: _JC.neutral700)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _danger,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Hapus'),
        ),
      ],
    );
  }
}

class _EditResult {
  const _EditResult({required this.value, this.cancelled = false});
  static const cancel = _EditResult(value: null, cancelled: true);
  final Object? value;
  final bool cancelled;
}

class _EditCellDialog extends StatefulWidget {
  const _EditCellDialog({
    required this.column,
    required this.currentValue,
    required this.isSQLite,
  });

  final String column;
  final Object? currentValue;
  final bool isSQLite;

  @override
  State<_EditCellDialog> createState() => _EditCellDialogState();
}

class _EditCellDialogState extends State<_EditCellDialog> {
  late final TextEditingController _ctrl;
  late bool _boolValue;
  String? _validationError;

  bool get _isBool => widget.currentValue is bool;
  bool get _isInt => widget.currentValue is int;
  bool get _isDouble =>
      widget.currentValue is double && widget.currentValue is! int;
  bool get _isNum => widget.currentValue is num && widget.currentValue is! bool;
  bool get _isNull => widget.currentValue == null;

  String get _typeLabel {
    final v = widget.currentValue;
    if (v == null) return 'null';
    if (v is bool) return 'Boolean';
    if (v is int) return 'Integer';
    if (v is double) return 'Double';
    if (v is num) return 'Number';
    return 'String';
  }

  @override
  void initState() {
    super.initState();
    _boolValue =
        widget.currentValue is bool ? widget.currentValue! as bool : false;
    _ctrl = TextEditingController(
      text: _isBool ? '' : (widget.currentValue?.toString() ?? ''),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Object? _parseAndValidate() {
    final raw = _ctrl.text.trim();
    if (_isBool) return _boolValue;

    if (_isInt) {
      final parsed = int.tryParse(raw);
      if (parsed == null) {
        setState(
            () => _validationError = 'Harus berupa bilangan bulat (integer).');
        return _EditResult.cancel.value; // signal validation failed
      }
      return parsed;
    }

    if (_isDouble) {
      final parsed = double.tryParse(raw);
      if (parsed == null) {
        setState(() => _validationError = 'Harus berupa angka desimal.');
        return _EditResult.cancel.value;
      }
      return parsed;
    }

    if (_isNum) {
      final parsed = num.tryParse(raw);
      if (parsed == null) {
        setState(() => _validationError = 'Harus berupa angka.');
        return _EditResult.cancel.value;
      }
      return parsed;
    }

    // String / null: empty → null for SQLite if original was null, else empty string
    if (_isNull && raw.isEmpty) return null;
    return raw;
  }

  void _save() {
    setState(() => _validationError = null);
    final result = _parseAndValidate();
    if (_validationError != null) return; // stay open
    Navigator.pop(context, _EditResult(value: result));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _JC.neutral0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      actionsPadding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit: ${widget.column}',
            style: const TextStyle(
              color: _JC.neutral900,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: _JC.textFieldBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _JC.neutral50),
                ),
                child: Text(
                  _typeLabel,
                  style: const TextStyle(
                    color: _JC.neutral700,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (!widget.isSQLite)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: _JC.primaryOrange30,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'SharedPreferences — tipe tidak bisa diubah',
                      style:
                          TextStyle(color: _JC.primaryOrange700, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          if (_isBool)
            Row(
              children: [
                const Text(
                  'Value',
                  style: TextStyle(color: _JC.neutral700, fontSize: 13),
                ),
                const Spacer(),
                Switch(
                  value: _boolValue,
                  activeThumbColor: _JC.primaryOrange500,
                  activeTrackColor: _JC.primaryOrange30,
                  onChanged: (v) => setState(() => _boolValue = v),
                ),
                Text(
                  _boolValue ? 'true' : 'false',
                  style: TextStyle(
                    color: _boolValue ? _JC.blueButtonText : _JC.neutral500,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          else
            TextField(
              controller: _ctrl,
              autofocus: true,
              maxLines: _isNull || (!_isNum && !_isBool) ? 3 : 1,
              keyboardType: _isNum
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.multiline,
              onChanged: (_) {
                if (_validationError != null) {
                  setState(() => _validationError = null);
                }
              },
              style: const TextStyle(
                fontSize: 13,
                color: _JC.neutral900,
                fontFamily: 'monospace',
              ),
              decoration: InputDecoration(
                hintText: _isNull ? '(kosong = null)' : null,
                hintStyle: const TextStyle(color: _JC.neutral500, fontSize: 12),
                isDense: true,
                filled: true,
                fillColor: _JC.textFieldBg,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: _validationError != null
                        ? Colors.redAccent
                        : _JC.neutral50,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: _validationError != null
                        ? Colors.redAccent
                        : _JC.neutral50,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: _validationError != null
                        ? Colors.redAccent
                        : _JC.primaryOrange500,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          if (_validationError != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.error_outline,
                    size: 13, color: Colors.redAccent),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    _validationError!,
                    style: const TextStyle(
                        color: Colors.redAccent, fontSize: 11.5),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 4),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, _EditResult.cancel),
          child: const Text(
            'Batal',
            style: TextStyle(color: _JC.neutral700),
          ),
        ),
        FilledButton(
          onPressed: _save,
          style: FilledButton.styleFrom(
            backgroundColor: _JC.primaryOrange500,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

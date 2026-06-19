import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'db_lens.dart';

class DbLensPanel extends StatefulWidget {
  const DbLensPanel({super.key});

  @override
  State<DbLensPanel> createState() => _DbLensPanelState();
}

class _DbLensPanelState extends State<DbLensPanel> {
  String? _selectedDb;
  String? _selectedTable;
  List<String> _tables = [];
  List<Map<String, Object?>> _rows = [];
  List<String> _columns = [];
  int _rowCount = 0;
  bool _loading = false;
  int _page = 0;
  static const _pageSize = 50;

  // Minimal, calm UI theme
  static const _surface = Color(0xFFFFFFFF);
  static const _bg = Color(0xFFF9FAFB);
  static const _accent = Color(0xFF4F46E5); // Indigo
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);
  static const _rowEven = Color(0xFFFFFFFF);
  static const _rowOdd = Color(0xFFF9FAFB);

  static const _headerFontSize = 13.0;
  static const _dataFontSize = 13.0;
  static const _cellPaddingH = 16.0;
  static const _cellPaddingV = 12.0;
  static const _cellMinWidth = 120.0;

  @override
  void initState() {
    super.initState();
    if (DbLens.databaseNames.isNotEmpty) {
      _selectedDb = DbLens.databaseNames.first;
      _loadTables(_selectedDb!);
    }
  }

  Future<void> _loadTables(String dbName) async {
    setState(() => _loading = true);
    final tables = await DbLens.getTables(dbName);
    setState(() {
      _tables = tables;
      _selectedTable = null;
      _rows = [];
      _columns = [];
      _loading = false;
    });
  }

  Future<void> _loadRows(String table, {int page = 0}) async {
    if (_selectedDb == null) return;
    setState(() => _loading = true);
    final rows = await DbLens.getRows(
      _selectedDb!,
      table,
      limit: _pageSize,
      offset: page * _pageSize,
    );
    final columns = await DbLens.getColumns(_selectedDb!, table);
    final count = await DbLens.getRowCount(_selectedDb!, table);
    setState(() {
      _rows = rows;
      _columns = columns;
      _rowCount = count;
      _page = page;
      _loading = false;
    });
  }

  void _copyRow(Map<String, Object?> row) {
    final text = jsonEncode(row);
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Row copied as JSON'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 16,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHandle(),
              _buildHeader(),
              if (DbLens.databaseNames.isEmpty)
                Expanded(child: _buildEmptyState())
              else ...[
                _buildSelectorSection(),
                const Divider(height: 1, thickness: 1, color: _border),
                Expanded(child: _buildContent(scrollController)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: _border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.storage_rounded, color: _textSecondary, size: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'DbLens',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_selectedTable != null)
            Text(
              '$_rowCount rows',
              style: const TextStyle(
                color: _textSecondary,
                fontSize: 13,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectorSection() {
    return Container(
      color: _surface,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChipRow(
            label: 'Database',
            items: DbLens.databaseNames,
            selected: _selectedDb,
            onSelected: (db) {
              setState(() => _selectedDb = db);
              _loadTables(db);
            },
          ),
          if (_tables.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildChipRow(
              label: 'Table',
              items: _tables,
              selected: _selectedTable,
              onSelected: (table) {
                setState(() => _selectedTable = table);
                _loadRows(table);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChipRow({
    required String label,
    required List<String> items,
    required String? selected,
    required ValueChanged<String> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: items.map((item) {
              final isSelected = item == selected;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => onSelected(item),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? _accent : _surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? _accent : _border,
                      ),
                    ),
                    child: Text(
                      item,
                      style: TextStyle(
                        color: isSelected ? Colors.white : _textPrimary,
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(ScrollController scrollController) {
    if (_loading) {
      return _buildLoadingState();
    }

    if (_selectedTable == null) {
      return _buildPlaceholder(
        icon: Icons.table_chart_outlined,
        title: 'Select a table',
        subtitle: 'Choose a table above to browse its rows',
      );
    }

    if (_rows.isEmpty) {
      return _buildPlaceholder(
        icon: Icons.inbox_outlined,
        title: 'Table is empty',
        subtitle: 'No rows found in "$_selectedTable"',
      );
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: scrollController,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _buildDataTable(),
            ),
          ),
        ),
        _buildPagination(),
      ],
    );
  }

  Widget _buildDataTable() {
    return Table(
      defaultColumnWidth: const IntrinsicColumnWidth(),
      border: const TableBorder(
        horizontalInside: BorderSide(color: _border),
        bottom: BorderSide(color: _border),
      ),
      children: [
        TableRow(
          decoration: const BoxDecoration(color: _surface),
          children: _columns
              .map((col) => _buildHeaderCell(col))
              .toList(),
        ),
        ..._rows.asMap().entries.map((entry) {
          final index = entry.key;
          final row = entry.value;
          return TableRow(
            decoration: BoxDecoration(
              color: index.isEven ? _rowEven : _rowOdd,
            ),
            children: _columns.map((col) {
              final val = row[col]?.toString() ?? 'null';
              final display =
                  val.length > 48 ? '${val.substring(0, 48)}…' : val;
              return _buildDataCell(display, val, row);
            }).toList(),
          );
        }),
      ],
    );
  }

  Widget _buildHeaderCell(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _cellPaddingH,
        vertical: _cellPaddingV,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: _cellMinWidth),
        child: Text(
          label,
          style: const TextStyle(
            color: _textSecondary,
            fontSize: _headerFontSize,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildDataCell(String display, String fullValue, Map<String, Object?> row) {
    final isNull = fullValue == 'null';
    return GestureDetector(
      onLongPress: () => _copyRow(row),
      child: Container(
        color: Colors.transparent, // Ensure full area is clickable
        padding: const EdgeInsets.symmetric(
          horizontal: _cellPaddingH,
          vertical: _cellPaddingV,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: _cellMinWidth),
          child: Text(
            display,
            style: TextStyle(
              color: isNull ? _textSecondary.withValues(alpha: 0.5) : _textPrimary,
              fontSize: _dataFontSize,
              fontStyle: isNull ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: _accent,
        strokeWidth: 2,
      ),
    );
  }

  Widget _buildEmptyState() {
    return _buildPlaceholder(
      icon: Icons.storage_outlined,
      title: 'No databases registered',
      subtitle: 'Call DbLens.register(\'Name\', db) before opening the panel',
    );
  }

  Widget _buildPlaceholder({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _textSecondary.withValues(alpha: 0.5), size: 32),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: _textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    if (_rowCount <= _pageSize) return const SizedBox.shrink();
    final totalPages = (_rowCount / _pageSize).ceil();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 20),
            color: _page > 0 ? _textPrimary : _textSecondary.withValues(alpha: 0.3),
            onPressed: _page > 0
                ? () => _loadRows(_selectedTable!, page: _page - 1)
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            'Page ${_page + 1} of $totalPages',
            style: const TextStyle(
              color: _textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 20),
            color: _page < totalPages - 1 ? _textPrimary : _textSecondary.withValues(alpha: 0.3),
            onPressed: _page < totalPages - 1
                ? () => _loadRows(_selectedTable!, page: _page + 1)
                : null,
          ),
        ],
      ),
    );
  }
}

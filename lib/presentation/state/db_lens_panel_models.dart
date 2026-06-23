/// Snapshot ringan untuk restore view tabel setelah query mode.
class DbLensTableViewCache {
  const DbLensTableViewCache({
    required this.columns,
    required this.columnsTable,
  });

  final List<String> columns;
  final String? columnsTable;
}

/// Konstanta dan helper untuk menyembunyikan kolom internal SQLite `rowid`.
const kDbLensRowIdColumn = '_rowid_';

List<String> withoutRowIdColumn(List<String> columns) =>
    columns.where((c) => c != kDbLensRowIdColumn).toList();

Map<String, dynamic> withoutRowIdEntry(Map<String, dynamic> row) =>
    Map.fromEntries(row.entries.where((e) => e.key != kDbLensRowIdColumn));

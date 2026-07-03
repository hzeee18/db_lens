import '../../domain/entities/source_entity.dart';

/// Satu koleksi dalam snapshot browse beserta jumlah barisnya.
class BrowseCollectionSnapshot {
  const BrowseCollectionSnapshot({
    required this.name,
    required this.rowCount,
  });

  final String name;
  final int rowCount;
}

/// Snapshot browse untuk satu sumber beserta semua koleksinya.
class BrowseSourceSnapshot {
  const BrowseSourceSnapshot({
    required this.source,
    required this.collections,
  });

  final SourceEntity source;
  final List<BrowseCollectionSnapshot> collections;

  String get sourceId => source.id;
  String get sourceName => source.name;

  int get totalRowCount =>
      collections.fold<int>(0, (sum, c) => sum + c.rowCount);
}

/// Snapshot ringan untuk restore view tabel setelah query mode.
class DbLensTableViewCache {
  const DbLensTableViewCache({
    required this.columns,
    required this.columnsTable,
  });

  final List<String> columns;
  final String? columnsTable;
}

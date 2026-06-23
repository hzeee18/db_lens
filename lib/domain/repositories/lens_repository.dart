import '../../domain/entities/collection_entity.dart';
import '../../domain/entities/row_entity.dart';
import '../../domain/entities/source_entity.dart';

/// Kontrak akses data untuk semua engine penyimpanan.
abstract class LensRepository {
  Future<List<SourceEntity>> getSources();

  Future<List<CollectionEntity>> getCollections(String sourceId);

  Future<List<RowEntity>> getRows(
    String sourceId,
    String collection,
    int limit,
    int offset,
  );

  Future<int> getRowCount(String sourceId, String collection);

  /// Nama kolom untuk koleksi (kosong jika tidak didukung).
  Future<List<String>> getColumns(String sourceId, String collection);

  /// SELECT arbitrer dengan pagination (hanya sumber yang mendukung SQL).
  Future<List<Map<String, dynamic>>> runRawQueryPaged(
    String sourceId,
    String sql, {
    required int limit,
    required int offset,
  });

  /// Total baris hasil SELECT arbitrer.
  Future<int> runRawQueryCount(String sourceId, String sql);

  /// Eksekusi perintah non-SELECT (hanya sumber yang mendukung SQL).
  Future<void> executeStatement(String sourceId, String sql);

  /// Apakah sumber mendukung raw SQL.
  bool supportsRawSql(String sourceId);
}

import '../../core/enums/source_type.dart';

/// Abstraksi akses data per engine penyimpanan.
abstract class LensDataSource {
  String get sourceId;

  String get sourceName;

  SourceType get sourceType;

  Future<List<String>> collections();

  Future<List<Map<String, dynamic>>> rows(
    String collection,
    int limit,
    int offset,
  );

  Future<int> count(String collection);

  /// Nama kolom untuk header tabel UI.
  Future<List<String>> columnNames(String collection);

  /// Perbarui nilai satu sel. Implementasi spesifik per engine.
  Future<void> updateCell(
    String collection,
    String column,
    Object? newValue,
    Map<String, dynamic> row,
  );

  /// Ambil semua baris (untuk ekspor).
  Future<List<Map<String, dynamic>>> allRows(String collection);
}

import '../lens_datasource.dart';

/// Kemampuan query SQL mentah — hanya untuk engine berbasis SQL.
abstract class SqlQueryableDataSource implements LensDataSource {
  Future<List<Map<String, dynamic>>> rawQuery(String sql);

  Future<List<Map<String, dynamic>>> rawQueryPaged(
    String sql, {
    required int limit,
    required int offset,
  });

  Future<int> rawQueryCount(String sql);

  Future<void> execute(String sql);
}

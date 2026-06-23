import '../../core/enums/source_type.dart';
import '../../domain/entities/collection_entity.dart';
import '../../domain/entities/row_entity.dart';
import '../../domain/entities/source_entity.dart';
import '../../domain/repositories/lens_repository.dart';
import '../datasources/lens_datasource.dart';
import '../datasources/sqlite/sql_queryable_data_source.dart';
import '../registry/db_lens_registry.dart';

/// Implementasi [LensRepository] — memetakan [LensDataSource] ke entitas domain.
class LensRepositoryImpl implements LensRepository {
  LensRepositoryImpl(this._registry);

  final DbLensRegistry _registry;

  LensDataSource _requireSource(String sourceId) {
    final source = _registry.getSource(sourceId);
    if (source == null) {
      throw StateError('Source not found: $sourceId');
    }
    return source;
  }

  SqlQueryableDataSource _requireSqlSource(String sourceId) {
    final source = _requireSource(sourceId);
    if (source is! SqlQueryableDataSource) {
      throw UnsupportedError(
        'Source "$sourceId" does not support raw SQL operations.',
      );
    }
    return source;
  }

  @override
  Future<List<SourceEntity>> getSources() async {
    return _registry.getSources().map((source) {
      return SourceEntity(
        id: source.sourceId,
        name: source.sourceName,
        type: source.sourceType,
      );
    }).toList();
  }

  @override
  Future<List<CollectionEntity>> getCollections(String sourceId) async {
    final names = await _requireSource(sourceId).collections();
    return names.map((name) => CollectionEntity(name: name)).toList();
  }

  @override
  Future<List<RowEntity>> getRows(
    String sourceId,
    String collection,
    int limit,
    int offset,
  ) async {
    final rows = await _requireSource(sourceId).rows(collection, limit, offset);
    return rows.map((data) => RowEntity(data: data)).toList();
  }

  @override
  Future<int> getRowCount(String sourceId, String collection) {
    return _requireSource(sourceId).count(collection);
  }

  @override
  Future<List<String>> getColumns(String sourceId, String collection) {
    return _requireSource(sourceId).columnNames(collection);
  }

  @override
  Future<List<Map<String, dynamic>>> runRawQueryPaged(
    String sourceId,
    String sql, {
    required int limit,
    required int offset,
  }) {
    return _requireSqlSource(sourceId).rawQueryPaged(
      sql,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<int> runRawQueryCount(String sourceId, String sql) {
    return _requireSqlSource(sourceId).rawQueryCount(sql);
  }

  @override
  Future<void> executeStatement(String sourceId, String sql) {
    return _requireSqlSource(sourceId).execute(sql);
  }

  @override
  bool supportsRawSql(String sourceId) {
    return _registry.getSource(sourceId) is SqlQueryableDataSource;
  }

  @override
  Future<void> updateCell(
    String sourceId,
    String collection,
    String column,
    Object? newValue,
    Map<String, dynamic> row,
  ) {
    return _requireSource(sourceId).updateCell(
      collection,
      column,
      newValue,
      row,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getAllRows(
    String sourceId,
    String collection,
  ) {
    return _requireSource(sourceId).allRows(collection);
  }

  @override
  SourceType? getSourceType(String sourceId) {
    return _registry.getSource(sourceId)?.sourceType;
  }
}

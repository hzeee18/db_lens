import '../repositories/lens_repository.dart';

/// Menjalankan SELECT arbitrer dengan pagination.
class RunRawQueryPagedUseCase {
  const RunRawQueryPagedUseCase(this._repository);

  final LensRepository _repository;

  Future<List<Map<String, dynamic>>> call(
    String sourceId,
    String sql, {
    required int limit,
    required int offset,
  }) =>
      _repository.runRawQueryPaged(
        sourceId,
        sql,
        limit: limit,
        offset: offset,
      );
}

import '../repositories/lens_repository.dart';

/// Menghitung total baris hasil SELECT arbitrer.
class RunRawQueryCountUseCase {
  const RunRawQueryCountUseCase(this._repository);

  final LensRepository _repository;

  Future<int> call(String sourceId, String sql) =>
      _repository.runRawQueryCount(sourceId, sql);
}

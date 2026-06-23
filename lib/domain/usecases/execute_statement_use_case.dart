import '../repositories/lens_repository.dart';

/// Mengeksekusi perintah SQL non-SELECT.
class ExecuteStatementUseCase {
  const ExecuteStatementUseCase(this._repository);

  final LensRepository _repository;

  Future<void> call(String sourceId, String sql) =>
      _repository.executeStatement(sourceId, sql);
}

import '../repositories/history_repository.dart';

class ClearHistoryUseCase {
  const ClearHistoryUseCase(this._repository);

  final HistoryRepository _repository;

  Future<void> call(String sourceId) => _repository.clearHistory(sourceId);
}

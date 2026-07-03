import '../entities/history_entry_entity.dart';
import '../repositories/history_repository.dart';

class GetHistoryUseCase {
  const GetHistoryUseCase(this._repository);

  final HistoryRepository _repository;

  Future<List<HistoryEntry>> call(String sourceId, {int? limit}) =>
      _repository.getHistory(sourceId, limit: limit);
}

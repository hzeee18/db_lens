import '../repositories/lens_repository.dart';

class GetAllRowsUseCase {
  const GetAllRowsUseCase(this._repository);

  final LensRepository _repository;

  Future<List<Map<String, dynamic>>> call(String sourceId, String collection) =>
      _repository.getAllRows(sourceId, collection);
}

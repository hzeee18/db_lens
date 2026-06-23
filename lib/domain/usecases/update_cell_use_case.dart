import '../repositories/lens_repository.dart';

class UpdateCellUseCase {
  const UpdateCellUseCase(this._repository);

  final LensRepository _repository;

  Future<void> call(
    String sourceId,
    String collection,
    String column,
    Object? newValue,
    Map<String, dynamic> row,
  ) =>
      _repository.updateCell(sourceId, collection, column, newValue, row);
}

import '../repositories/lens_repository.dart';

/// Mengambil nama kolom untuk header tabel.
class GetColumnsUseCase {
  const GetColumnsUseCase(this._repository);

  final LensRepository _repository;

  Future<List<String>> call(String sourceId, String collection) =>
      _repository.getColumns(sourceId, collection);
}

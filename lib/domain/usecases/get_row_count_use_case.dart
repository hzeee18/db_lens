import '../repositories/lens_repository.dart';

/// Menghitung total baris dalam satu koleksi.
class GetRowCountUseCase {
  const GetRowCountUseCase(this._repository);

  final LensRepository _repository;

  Future<int> call(String sourceId, String collection) =>
      _repository.getRowCount(sourceId, collection);
}

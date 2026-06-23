import '../entities/collection_entity.dart';
import '../repositories/lens_repository.dart';

/// Mengambil koleksi (tabel/grup) dari satu sumber.
class GetCollectionsUseCase {
  const GetCollectionsUseCase(this._repository);

  final LensRepository _repository;

  Future<List<CollectionEntity>> call(String sourceId) =>
      _repository.getCollections(sourceId);
}

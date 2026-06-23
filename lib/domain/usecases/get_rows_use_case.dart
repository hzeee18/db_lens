import '../entities/row_entity.dart';
import '../repositories/lens_repository.dart';

/// Mengambil baris dengan pagination dari satu koleksi.
class GetRowsUseCase {
  const GetRowsUseCase(this._repository);

  final LensRepository _repository;

  Future<List<RowEntity>> call(
    String sourceId,
    String collection,
    int limit,
    int offset,
  ) =>
      _repository.getRows(sourceId, collection, limit, offset);
}

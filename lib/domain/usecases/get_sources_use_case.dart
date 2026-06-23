import '../entities/source_entity.dart';
import '../repositories/lens_repository.dart';

/// Mengambil semua sumber data terdaftar.
class GetSourcesUseCase {
  const GetSourcesUseCase(this._repository);

  final LensRepository _repository;

  Future<List<SourceEntity>> call() => _repository.getSources();
}

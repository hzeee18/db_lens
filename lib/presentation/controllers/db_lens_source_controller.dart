import 'package:flutter/foundation.dart';

import '../../core/enums/source_type.dart';
import '../../domain/entities/source_entity.dart';
import '../../domain/repositories/lens_repository.dart';
import '../utils/row_utils.dart';

/// Mengelola daftar source, source terpilih, dan koleksinya.
///
/// Tidak tahu apa-apa soal pagination, query, atau edit — cukup depend ke
/// [LensRepository] untuk daftar source/collection.
class DbLensSourceController extends ChangeNotifier {
  DbLensSourceController({required LensRepository repository})
      : _repository = repository;

  final LensRepository _repository;

  List<SourceEntity> sources = [];
  String? selectedSourceId;
  List<String> collections = [];
  String? selectedCollection;
  String sourceSearchText = '';
  String collectionSearchText = '';
  bool loading = false;
  String? lastError;

  bool get hasSources => sources.isNotEmpty;

  List<String> get sourceNames => sources.map((s) => s.name).toList();

  List<String> get filteredSourceNames =>
      DbLensRowUtils.filterItems(sourceNames, sourceSearchText);

  List<String> get filteredCollections =>
      DbLensRowUtils.filterItems(collections, collectionSearchText);

  String? get selectedSourceName {
    final id = selectedSourceId;
    if (id == null) return null;
    for (final source in sources) {
      if (source.id == id) return source.name;
    }
    return null;
  }

  SourceType? get selectedSourceType => selectedSourceId != null
      ? _repository.getSourceType(selectedSourceId!)
      : null;

  bool get supportsRawSql =>
      selectedSourceId != null && _repository.supportsRawSql(selectedSourceId!);

  Future<void> initialize() async {
    sources = await _repository.getSources();
    if (sources.isNotEmpty) {
      selectedSourceId = sources.first.id;
      await loadCollections(selectedSourceId!);
    }
    notifyListeners();
  }

  Future<void> selectSource(String sourceId) async {
    selectedSourceId = sourceId;
    sourceSearchText = '';
    collectionSearchText = '';
    notifyListeners();
    await loadCollections(sourceId);
  }

  Future<void> loadCollections(String sourceId) async {
    loading = true;
    lastError = null;
    notifyListeners();
    try {
      final result = await _repository.getCollections(sourceId);
      collections = result.map((c) => c.name).toList();
      selectedCollection = null;
      loading = false;
      notifyListeners();
    } catch (error) {
      loading = false;
      lastError = 'Failed to load collections: $error';
      notifyListeners();
    }
  }

  void selectCollection(String collection) {
    selectedCollection = collection;
    collectionSearchText = '';
    notifyListeners();
  }

  void setSourceSearchText(String value) {
    sourceSearchText = value;
    notifyListeners();
  }

  void setCollectionSearchText(String value) {
    collectionSearchText = value;
    notifyListeners();
  }

  void reset() {
    selectedCollection = null;
    collectionSearchText = '';
    notifyListeners();
  }
}

import 'package:flutter/foundation.dart';

import '../../domain/repositories/lens_repository.dart';
import '../state/db_lens_panel_models.dart';

/// Snapshot semua source + collection + row count, untuk tampilan "browse
/// semua data sekaligus" (dipakai di [DbLensSourceList]).
class DbLensBrowseController extends ChangeNotifier {
  DbLensBrowseController({required LensRepository repository})
      : _repository = repository;

  final LensRepository _repository;

  List<BrowseSourceSnapshot> snapshot = [];
  bool loading = false;
  bool refreshing = false;
  String searchText = '';
  String? lastError;

  bool get hasSnapshot => snapshot.isNotEmpty;

  List<BrowseSourceSnapshot> get filteredSnapshot {
    final query = searchText.trim().toLowerCase();
    if (query.isEmpty) return snapshot;

    final filtered = <BrowseSourceSnapshot>[];
    for (final sourceSnapshot in snapshot) {
      final sourceMatches =
          sourceSnapshot.sourceName.toLowerCase().contains(query);
      final matchingCollections = sourceMatches
          ? sourceSnapshot.collections
          : sourceSnapshot.collections
              .where((c) => c.name.toLowerCase().contains(query))
              .toList();
      if (matchingCollections.isEmpty) continue;
      filtered.add(
        BrowseSourceSnapshot(
          source: sourceSnapshot.source,
          collections: matchingCollections,
        ),
      );
    }
    return filtered;
  }

  void setSearchText(String value) {
    searchText = value;
    notifyListeners();
  }

  Future<void> load() async {
    loading = true;
    lastError = null;
    notifyListeners();
    try {
      snapshot = await _build();
      loading = false;
      notifyListeners();
    } catch (error) {
      loading = false;
      lastError = 'Failed to load browse snapshot: $error';
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (loading || refreshing) return;
    refreshing = true;
    lastError = null;
    notifyListeners();
    try {
      snapshot = await _build();
      refreshing = false;
      notifyListeners();
    } catch (error) {
      refreshing = false;
      lastError = 'Failed to refresh browse snapshot: $error';
      notifyListeners();
    }
  }

  Future<List<BrowseSourceSnapshot>> _build() async {
    final allSources = await _repository.getSources();

    final snapshots = <BrowseSourceSnapshot>[];
    for (final source in allSources) {
      final collectionEntities = await _repository.getCollections(source.id);
      final collectionSnapshots = <BrowseCollectionSnapshot>[];
      for (final collection in collectionEntities) {
        final rowCount =
            await _repository.getRowCount(source.id, collection.name);
        collectionSnapshots.add(
          BrowseCollectionSnapshot(name: collection.name, rowCount: rowCount),
        );
      }
      snapshots.add(
        BrowseSourceSnapshot(source: source, collections: collectionSnapshots),
      );
    }
    return snapshots;
  }
}

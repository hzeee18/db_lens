import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/history_entry_entity.dart';
import '../../domain/repositories/history_repository.dart';

/// Controller untuk panel riwayat perubahan data per source.
class DbLensHistoryController extends ChangeNotifier {
  DbLensHistoryController({
    required HistoryRepository historyRepository,
    bool Function()? isTrackingEnabled,
    void Function({bool? enabled})? configureTracking,
  })  : _historyRepository = historyRepository,
        _isTrackingEnabled = isTrackingEnabled,
        _configureTracking = configureTracking;

  final HistoryRepository _historyRepository;
  final bool Function()? _isTrackingEnabled;
  final void Function({bool? enabled})? _configureTracking;

  String? _sourceId;
  List<HistoryEntry> _entries = const [];
  bool _loading = false;
  bool _disposed = false;
  String _searchText = '';
  StreamSubscription<void>? _changedSubscription;

  String? get sourceId => _sourceId;
  List<HistoryEntry> get entries => _entries;
  bool get loading => _loading;
  bool get isEmpty => _entries.isEmpty;
  String get searchText => _searchText;

  /// Entries yang cocok dengan [searchText] (cari di nama collection & rowKey).
  List<HistoryEntry> get filteredEntries {
    final query = _searchText.trim().toLowerCase();
    if (query.isEmpty) return _entries;
    return _entries
        .where(
          (e) =>
              e.collection.toLowerCase().contains(query) ||
              e.rowKey.toLowerCase().contains(query),
        )
        .toList();
  }

  /// Apakah UI boleh menampilkan toggle aktif/nonaktifkan tracking.
  bool get canToggleTracking => _configureTracking != null;

  /// Status tracking riwayat saat ini (selalu true jika tidak ada callback).
  bool get trackingEnabled => _isTrackingEnabled?.call() ?? true;

  void setSearchText(String value) {
    _searchText = value;
    notifyListeners();
  }

  /// Aktifkan/nonaktifkan pelacakan riwayat perubahan secara global.
  void setTrackingEnabled(bool enabled) {
    _configureTracking?.call(enabled: enabled);
    notifyListeners();
  }

  Future<void> loadFor(String sourceId) async {
    _sourceId = sourceId;
    _loading = true;
    notifyListeners();

    _entries = await _historyRepository.getHistory(sourceId);
    if (_disposed) return;
    _loading = false;
    notifyListeners();
  }

  Future<void> clear() async {
    final sourceId = _sourceId;
    if (sourceId == null) return;

    await _historyRepository.clearHistory(sourceId);
    if (_disposed) return;
    _entries = const [];
    notifyListeners();
  }

  void startListening() {
    _changedSubscription ??=
        _historyRepository.onChanged.listen((_) => _reloadQuietly());
  }

  void stopListening() {
    unawaited(_changedSubscription?.cancel());
    _changedSubscription = null;
  }

  Future<void> _reloadQuietly() async {
    final sourceId = _sourceId;
    if (sourceId == null) return;
    _entries = await _historyRepository.getHistory(sourceId);
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    stopListening();
    super.dispose();
  }
}

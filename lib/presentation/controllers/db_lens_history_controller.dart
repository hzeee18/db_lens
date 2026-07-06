import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/history_entry_entity.dart';
import '../../domain/repositories/history_repository.dart';

/// Controller for per-source change history.
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
  String? _tableFilter;
  Set<HistoryChangeType> _changeTypeFilter = {};
  bool _searchExpanded = false;
  bool _filtersExpanded = false;
  StreamSubscription<void>? _changedSubscription;

  String? get sourceId => _sourceId;
  List<HistoryEntry> get entries => _entries;
  bool get loading => _loading;
  bool get isEmpty => _entries.isEmpty;
  String get searchText => _searchText;
  String? get tableFilter => _tableFilter;
  Set<HistoryChangeType> get changeTypeFilter => _changeTypeFilter;
  bool get searchExpanded => _searchExpanded;
  bool get filtersExpanded => _filtersExpanded;
  bool get hasActiveSearch => _searchText.trim().isNotEmpty;
  bool get hasActiveChangeTypeFilters => _changeTypeFilter.isNotEmpty;
  bool get hasActiveTableFilter => _tableFilter != null;

  /// Unique collection names from all entries, sorted.
  List<String> get availableTables {
    final tables = _entries.map((e) => e.collection).toSet().toList()..sort();
    return tables;
  }

  /// Entries matching table, change-type, and search filters.
  List<HistoryEntry> get filteredEntries {
    return _entries.where(_matchesFilters).toList();
  }

  bool _matchesFilters(HistoryEntry e) {
    if (_tableFilter != null && e.collection != _tableFilter) return false;
    if (_changeTypeFilter.isNotEmpty && !_changeTypeFilter.contains(e.changeType)) {
      return false;
    }
    final query = _searchText.trim().toLowerCase();
    if (query.isEmpty) return true;
    return e.collection.toLowerCase().contains(query) ||
        e.rowKey.toLowerCase().contains(query);
  }

  /// Whether the UI may show the tracking toggle.
  bool get canToggleTracking => _configureTracking != null;

  /// Current tracking state (true when no callback is provided).
  bool get trackingEnabled => _isTrackingEnabled?.call() ?? true;

  void setSearchText(String value) {
    _searchText = value;
    notifyListeners();
  }

  void toggleSearchExpanded() {
    _searchExpanded = !_searchExpanded;
    notifyListeners();
  }

  void toggleFiltersExpanded() {
    _filtersExpanded = !_filtersExpanded;
    notifyListeners();
  }

  void setTableFilter(String? table) {
    _tableFilter = table;
    notifyListeners();
  }

  void toggleChangeTypeFilter(HistoryChangeType type) {
    if (_changeTypeFilter.contains(type)) {
      _changeTypeFilter = Set.of(_changeTypeFilter)..remove(type);
    } else {
      _changeTypeFilter = Set.of(_changeTypeFilter)..add(type);
    }
    notifyListeners();
  }

  void clearFilters() {
    _tableFilter = null;
    _changeTypeFilter = {};
    _searchText = '';
    notifyListeners();
  }

  bool get hasActiveFilters =>
      _tableFilter != null || _changeTypeFilter.isNotEmpty || _searchText.trim().isNotEmpty;

  /// Enable or disable change tracking globally.
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

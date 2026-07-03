import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/history_entry_entity.dart';
import '../../domain/repositories/history_repository.dart';
import '../../domain/usecases/clear_history_use_case.dart';
import '../../domain/usecases/get_history_use_case.dart';

/// Controller untuk panel riwayat perubahan data per source.
class DbLensHistoryController extends ChangeNotifier {
  DbLensHistoryController({
    required GetHistoryUseCase getHistory,
    required ClearHistoryUseCase clearHistory,
    required HistoryRepository historyRepository,
  })  : _getHistory = getHistory,
        _clearHistory = clearHistory,
        _historyRepository = historyRepository;

  final GetHistoryUseCase _getHistory;
  final ClearHistoryUseCase _clearHistory;
  final HistoryRepository _historyRepository;

  String? _sourceId;
  List<HistoryEntry> _entries = const [];
  bool _loading = false;
  bool _disposed = false;
  StreamSubscription<void>? _changedSubscription;

  String? get sourceId => _sourceId;
  List<HistoryEntry> get entries => _entries;
  bool get loading => _loading;
  bool get isEmpty => _entries.isEmpty;

  Future<void> loadFor(String sourceId) async {
    _sourceId = sourceId;
    _loading = true;
    notifyListeners();

    _entries = await _getHistory(sourceId);
    if (_disposed) return;
    _loading = false;
    notifyListeners();
  }

  Future<void> clear() async {
    final sourceId = _sourceId;
    if (sourceId == null) return;

    await _clearHistory(sourceId);
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
    _entries = await _getHistory(sourceId);
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

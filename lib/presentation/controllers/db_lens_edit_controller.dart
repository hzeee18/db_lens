import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../domain/repositories/lens_repository.dart';
import '../utils/db_lens_row_id_utils.dart';
import '../utils/json_view_utils.dart';

/// Mengelola edit sel/baris. Validasi tipe-nilai khusus per source
/// (mis. SharedPreferences) sudah ditangani di [LensDataSource.updateCell]
/// masing-masing, controller ini cuma meneruskan dan menangani error.
class DbLensEditController extends ChangeNotifier {
  DbLensEditController({required LensRepository repository})
      : _repository = repository;

  final LensRepository _repository;

  bool busy = false;
  String? lastError;

  Future<bool> updateCell({
    required String sourceId,
    required String collection,
    required String column,
    required Object? newValue,
    required Map<String, Object?> row,
  }) async {
    busy = true;
    lastError = null;
    notifyListeners();
    try {
      await _repository.updateCell(sourceId, collection, column, newValue, row);
      busy = false;
      notifyListeners();
      return true;
    } catch (error) {
      busy = false;
      lastError = 'Failed to update cell: $error';
      notifyListeners();
      return false;
    }
  }

  /// Hapus satu baris. Mengembalikan pesan error atau null jika sukses.
  Future<String?> deleteRow({
    required String sourceId,
    required String collection,
    required Map<String, Object?> row,
  }) async {
    busy = true;
    lastError = null;
    notifyListeners();
    try {
      await _repository.deleteRow(sourceId, collection, row);
      busy = false;
      notifyListeners();
      return null;
    } catch (error) {
      busy = false;
      final message = 'Failed to delete row: $error';
      lastError = message;
      notifyListeners();
      return message;
    }
  }

  /// Perbarui baris dari map JSON hasil edit. Mengembalikan pesan error
  /// atau null jika sukses.
  Future<String?> updateRowFromJson({
    required String sourceId,
    required String collection,
    required Map<String, Object?> originalRow,
    required Map<String, Object?> updatedRow,
  }) async {
    final original = Map<String, Object?>.from(originalRow);
    final originalDisplay = DbLensJsonUtils.prepareRow(original);
    final updated = Map<String, Object?>.from(
      withoutRowIdEntry(Map<String, dynamic>.from(updatedRow)),
    );

    final changedColumns = <String>[];
    for (final key in originalDisplay.keys) {
      if (!updated.containsKey(key)) continue;
      if (!_valuesEqual(originalDisplay[key], updated[key])) {
        changedColumns.add(key);
      }
    }

    if (changedColumns.isEmpty) return null;

    busy = true;
    lastError = null;
    notifyListeners();
    try {
      for (final column in changedColumns) {
        await _repository.updateCell(
          sourceId,
          collection,
          column,
          updated[column],
          original,
        );
      }
      busy = false;
      notifyListeners();
      return null;
    } catch (error) {
      busy = false;
      final message = 'Failed to update row: $error';
      lastError = message;
      notifyListeners();
      return message;
    }
  }

  bool _valuesEqual(Object? a, Object? b) {
    if (a is List && b is List) {
      return a.length == b.length &&
          List.generate(a.length, (i) => _valuesEqual(a[i], b[i]))
              .every((e) => e);
    }
    return jsonEncode(a) == jsonEncode(b) || a == b;
  }
}

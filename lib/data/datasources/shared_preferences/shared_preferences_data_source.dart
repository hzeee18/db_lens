import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/enums/source_type.dart';
import '../lens_datasource.dart';

/// Implementasi [LensDataSource] untuk Flutter SharedPreferences.
///
/// Satu koleksi `preferences` dengan kolom `key`, `type`, `value`.
class SharedPreferencesDataSource implements LensDataSource {
  SharedPreferencesDataSource({
    required String sourceId,
    required String sourceName,
    required SharedPreferences preferences,
  })  : _sourceId = sourceId,
        _sourceName = sourceName,
        _preferences = preferences;

  static const String collectionName = 'preferences';
  static const List<String> columns = ['key', 'type', 'value'];

  final String _sourceId;
  final String _sourceName;
  final SharedPreferences _preferences;

  @override
  String get sourceId => _sourceId;

  @override
  String get sourceName => _sourceName;

  @override
  SourceType get sourceType => SourceType.sharedPreferences;

  @override
  Future<List<String>> collections() async => [collectionName];

  @override
  Future<List<Map<String, dynamic>>> rows(
    String collection,
    int limit,
    int offset,
  ) async {
    final all = await _allRows();
    if (offset >= all.length) return [];
    final end = offset + limit;
    return all.sublist(
      offset,
      end > all.length ? all.length : end,
    );
  }

  @override
  Future<int> count(String collection) async {
    final keys = _preferences.getKeys().toList()..sort();
    return keys.length;
  }

  @override
  Future<List<String>> columnNames(String collection) async =>
      List<String>.from(columns);

  Future<List<Map<String, dynamic>>> _allRows() async {
    final keys = _preferences.getKeys().toList()..sort();
    return keys.map(_rowForKey).toList();
  }

  Map<String, dynamic> _rowForKey(String key) {
    final value = _preferences.get(key);
    return {
      'key': key,
      'type': _typeName(value),
      'value': value,
    };
  }

  String _typeName(Object? value) {
    if (value is bool) return 'bool';
    if (value is int) return 'int';
    if (value is double) return 'double';
    if (value is List<String>) return 'StringList';
    if (value is String) return 'String';
    return value?.runtimeType.toString() ?? 'null';
  }
}

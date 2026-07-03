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

  @override
  Future<List<Map<String, dynamic>>> allRows(String collection) async =>
      _allRows();

  @override
  Future<List<String>> identityColumns(String collection) async =>
      const ['key'];

  @override
  Future<void> updateCell(
    String collection,
    String column,
    Object? newValue,
    Map<String, dynamic> row,
  ) async {
    final key = row['key'] as String?;
    final expectedType = row['type'] as String?;

    if (column == 'type') {
      throw ArgumentError('Cannot change the type field (expected "$expectedType").');
    }

    if (column == 'key') {
      if (key == null || newValue is! String || newValue.isEmpty) {
        throw ArgumentError('Invalid key value.');
      }
      final currentValue = _preferences.get(key);
      final typeName = expectedType ?? _typeName(currentValue);
      await _preferences.remove(key);
      await _setValue(newValue, currentValue, typeName);
      return;
    }

    if (column != 'value') {
      throw UnsupportedError('Only key and value columns can be edited.');
    }

    if (key == null) throw ArgumentError('Row has no key.');

    if (expectedType != null && !_valueMatchesType(newValue, expectedType)) {
      throw ArgumentError(
        'Value must remain $expectedType (got ${_describeValueType(newValue)}).',
      );
    }

    final typeName = expectedType ?? _typeName(newValue);
    await _setValue(key, newValue, typeName);
  }

  bool _valueMatchesType(Object? value, String type) {
    switch (type) {
      case 'bool':
        return value is bool;
      case 'int':
        return value is int;
      case 'double':
        return value is double || value is int;
      case 'String':
        return value is String;
      case 'StringList':
        return value is List && value.every((e) => e is String);
      default:
        return true;
    }
  }

  String _describeValueType(Object? value) {
    if (value == null) return 'null';
    if (value is List) return 'List';
    return value.runtimeType.toString();
  }

  Future<void> _setValue(String key, Object? newValue, String type) async {
    switch (type) {
      case 'bool':
        await _preferences.setBool(key, newValue as bool);
      case 'int':
        await _preferences.setInt(key, newValue as int);
      case 'double':
        await _preferences.setDouble(key, newValue as double);
      case 'StringList':
        await _preferences.setStringList(key, List<String>.from(newValue as List));
      case 'String':
      default:
        await _preferences.setString(key, newValue?.toString() ?? '');
    }
  }
}

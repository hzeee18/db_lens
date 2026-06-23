import 'package:flutter_test/flutter_test.dart';
import 'package:db_lens/presentation/utils/json_view_utils.dart';

void main() {
  group('JsonViewUtils', () {
    test('prepareRow removes _rowid_', () {
      final prepared = JsonViewUtils.prepareRow({
        '_rowid_': 1,
        'name': 'Alice',
      });
      expect(prepared.containsKey('_rowid_'), isFalse);
      expect(prepared['name'], 'Alice');
    });

    test('normalizeValue parses JSON string', () {
      final result = JsonViewUtils.normalizeValue('{"key":"value"}');
      expect(result, {'key': 'value'});
    });

    test('normalizeValue parses nested JSON string', () {
      final result = JsonViewUtils.normalizeValue(
        '{"nested":"{\\"a\\":1}"}',
      );
      expect(result, {
        'nested': {'a': 1},
      });
    });

    test('encodePretty produces indented JSON', () {
      final json = JsonViewUtils.encodePretty({'id': 1, 'name': 'test'});
      expect(json, contains('\n'));
      expect(json, contains('"id"'));
    });

    test('looksLikeJson rejects plain strings', () {
      expect(JsonViewUtils.looksLikeJson('hello'), isFalse);
      expect(JsonViewUtils.looksLikeJson('{"a":1}'), isTrue);
      expect(JsonViewUtils.looksLikeJson('[1,2]'), isTrue);
    });

    test('encodePrettyArray produces JSON array', () {
      final json = JsonViewUtils.encodePrettyArray([
        {'id': 1, 'name': 'Alice'},
        {'id': 2, 'name': 'Bob'},
      ]);
      expect(json.startsWith('['), isTrue);
      expect(json, contains('"Alice"'));
      expect(json, contains('"Bob"'));
    });

    test('parseRowJson parses object', () {
      final map = JsonViewUtils.parseRowJson('{"name": "Alice", "age": 30}');
      expect(map['name'], 'Alice');
      expect(map['age'], 30);
    });

    test('parseRowJson rejects non-object', () {
      expect(() => JsonViewUtils.parseRowJson('[1, 2]'), throwsFormatException);
    });
  });
}

import 'package:db_lens/presentation/utils/db_lens_row_id_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('db_lens_row_id_utils', () {
    test('withoutRowIdColumn removes _rowid_', () {
      expect(
        withoutRowIdColumn(['id', '_rowid_', 'name']),
        ['id', 'name'],
      );
    });

    test('withoutRowIdEntry removes _rowid_ key', () {
      final cleaned = withoutRowIdEntry({
        '_rowid_': 42,
        'name': 'Alice',
      });
      expect(cleaned.containsKey(kDbLensRowIdColumn), isFalse);
      expect(cleaned['name'], 'Alice');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:db_lens/presentation/utils/history_diff_utils.dart';

void main() {
  group('DbLensHistoryDiffUtils.compute', () {
    test('marks fields present only in after as added (insert)', () {
      final fields = DbLensHistoryDiffUtils.compute(
        beforeJson: null,
        afterJson: '{"id":1,"name":"Alice"}',
      );

      expect(fields, hasLength(2));
      expect(fields.every((f) => f.kind == DbLensDiffKind.added), isTrue);
      expect(
        fields.firstWhere((f) => f.key == 'name').afterValue,
        'Alice',
      );
    });

    test('marks fields present only in before as removed (delete)', () {
      final fields = DbLensHistoryDiffUtils.compute(
        beforeJson: '{"id":1,"name":"Alice"}',
        afterJson: null,
      );

      expect(fields, hasLength(2));
      expect(fields.every((f) => f.kind == DbLensDiffKind.removed), isTrue);
      expect(
        fields.firstWhere((f) => f.key == 'name').beforeValue,
        'Alice',
      );
    });

    test('uses changedColumns to mark changed vs unchanged fields', () {
      final fields = DbLensHistoryDiffUtils.compute(
        beforeJson: '{"id":1,"name":"Alice","age":30}',
        afterJson: '{"id":1,"name":"Alice","age":31}',
        changedColumns: ['age'],
      );

      final byKey = {for (final f in fields) f.key: f};
      expect(byKey['id']!.kind, DbLensDiffKind.unchanged);
      expect(byKey['name']!.kind, DbLensDiffKind.unchanged);
      expect(byKey['age']!.kind, DbLensDiffKind.changed);
      expect(byKey['age']!.beforeValue, 30);
      expect(byKey['age']!.afterValue, 31);
    });

    test('falls back to value comparison when changedColumns is null', () {
      final fields = DbLensHistoryDiffUtils.compute(
        beforeJson: '{"age":30}',
        afterJson: '{"age":31}',
      );

      expect(fields.single.kind, DbLensDiffKind.changed);
    });

    test('returns empty list when both before and after are null', () {
      final fields = DbLensHistoryDiffUtils.compute();
      expect(fields, isEmpty);
    });

    test('treats malformed JSON as an empty object rather than throwing',
        () {
      final fields = DbLensHistoryDiffUtils.compute(
        beforeJson: 'not json',
        afterJson: '{"id":1}',
      );

      expect(fields, hasLength(1));
      expect(fields.single.kind, DbLensDiffKind.added);
    });
  });
}

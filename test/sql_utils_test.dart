import 'package:flutter_test/flutter_test.dart';
import 'package:db_lens/core/utils/sql_utils.dart';

void main() {
  group('SqlUtils.extractSimpleFromTable', () {
    test('extracts table from simple SELECT', () {
      expect(
        SqlUtils.extractSimpleFromTable('SELECT * FROM users'),
        'users',
      );
      expect(
        SqlUtils.extractSimpleFromTable('  select id from products where id = 1'),
        'products',
      );
    });

    test('returns null for JOIN queries', () {
      expect(
        SqlUtils.extractSimpleFromTable(
          'SELECT * FROM users JOIN orders ON users.id = orders.user_id',
        ),
        isNull,
      );
    });

    test('returns null for subqueries', () {
      expect(
        SqlUtils.extractSimpleFromTable(
          'SELECT * FROM (SELECT id FROM users) AS sub',
        ),
        isNull,
      );
    });
  });

  group('SqlUtils.isComplexSelectQuery', () {
    test('simple query is not complex', () {
      expect(SqlUtils.isComplexSelectQuery('SELECT * FROM users'), isFalse);
    });

    test('JOIN is complex', () {
      expect(
        SqlUtils.isComplexSelectQuery('SELECT * FROM a JOIN b ON a.id = b.id'),
        isTrue,
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:db_lens/core/utils/sql_utils.dart';

void main() {
  group('DbLensSqlUtils.extractSimpleFromTable', () {
    test('extracts table from simple SELECT', () {
      expect(
        DbLensSqlUtils.extractSimpleFromTable('SELECT * FROM users'),
        'users',
      );
      expect(
        DbLensSqlUtils.extractSimpleFromTable('  select id from products where id = 1'),
        'products',
      );
    });

    test('returns null for JOIN queries', () {
      expect(
        DbLensSqlUtils.extractSimpleFromTable(
          'SELECT * FROM users JOIN orders ON users.id = orders.user_id',
        ),
        isNull,
      );
    });

    test('returns null for subqueries', () {
      expect(
        DbLensSqlUtils.extractSimpleFromTable(
          'SELECT * FROM (SELECT id FROM users) AS sub',
        ),
        isNull,
      );
    });
  });

  group('DbLensSqlUtils.isComplexSelectQuery', () {
    test('simple query is not complex', () {
      expect(DbLensSqlUtils.isComplexSelectQuery('SELECT * FROM users'), isFalse);
    });

    test('JOIN is complex', () {
      expect(
        DbLensSqlUtils.isComplexSelectQuery('SELECT * FROM a JOIN b ON a.id = b.id'),
        isTrue,
      );
    });
  });

  group('DbLensSqlUtils.isSelectQuery', () {
    test('writable CTE is not select', () {
      expect(
        DbLensSqlUtils.isSelectQuery(
          'WITH cte AS (SELECT id FROM users) DELETE FROM users WHERE id IN (SELECT id FROM cte)',
        ),
        isFalse,
      );
    });

    test('read-only CTE with SELECT main statement is select', () {
      expect(
        DbLensSqlUtils.isSelectQuery(
          'WITH cte AS (SELECT id FROM users) SELECT * FROM cte',
        ),
        isTrue,
      );
    });

    test('mutating PRAGMA is not select', () {
      expect(DbLensSqlUtils.isSelectQuery('PRAGMA journal_mode = WAL'), isFalse);
    });

    test('read-only PRAGMA is select', () {
      expect(DbLensSqlUtils.isSelectQuery('PRAGMA table_info(users)'), isTrue);
    });
  });
}

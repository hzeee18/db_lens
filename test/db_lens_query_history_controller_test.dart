import 'package:db_lens/db_lens.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('record caps entries at maxEntries and keeps newest first', () {
    final controller = DbLensQueryHistoryController(maxEntries: 3);

    controller.record('SELECT 1', isError: false);
    controller.record('SELECT 2', isError: false);
    controller.record('SELECT 3', isError: false);
    controller.record('SELECT 4', isError: true, info: 'boom');

    expect(controller.entries, hasLength(3));
    expect(controller.entries.first.sql, 'SELECT 4');
    expect(controller.entries.first.isError, isTrue);
    expect(controller.entries.last.sql, 'SELECT 2');
  });

  test('record ignores blank sql', () {
    final controller = DbLensQueryHistoryController();
    controller.record('   ', isError: false);
    expect(controller.isEmpty, isTrue);
  });

  test('clear empties entries', () {
    final controller = DbLensQueryHistoryController();
    controller.record('SELECT 1', isError: false);
    expect(controller.isEmpty, isFalse);

    controller.clear();
    expect(controller.isEmpty, isTrue);
  });

  test('record stores table context', () {
    final controller = DbLensQueryHistoryController();
    controller.record('SELECT * FROM users', isError: false, table: 'users');
    controller.record('SELECT 1', isError: false, table: 'orders');

    expect(controller.entries.first.table, 'orders');
    expect(controller.entries.last.table, 'users');
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:db_lens/db_lens.dart';

void main() {
  test('DbLens initial state has no databases', () {
    expect(DbLens.databaseNames, isEmpty);
  });
}
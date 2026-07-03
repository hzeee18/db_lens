import 'package:db_lens/data/history/row_identity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RowIdentity', () {
    test('distinct rows with separator-like values do not collide', () {
      final keyA = RowIdentity.of({'a': 'x|y', 'b': 'z'}, ['a', 'b']);
      final keyB = RowIdentity.of({'a': 'x', 'b': 'y|z'}, ['a', 'b']);
      expect(keyA, isNot(equals(keyB)));
    });

    test('values containing equals sign do not collide', () {
      final keyA = RowIdentity.of({'name': 'a=b'}, ['name']);
      final keyB = RowIdentity.of({'name': 'a', 'extra': 'b'}, ['name', 'extra']);
      expect(keyA, isNot(equals(keyB)));
    });
  });
}

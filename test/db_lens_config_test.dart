import 'package:db_lens/db_lens.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DbLensConfig.presentationMode defaults to bottomSheet', () {
    const config = DbLensConfig();
    expect(config.presentationMode, DbLensPresentationMode.bottomSheet);
  });

  test('DbLensConfig.fullscreenDialog defaults to true', () {
    const config = DbLensConfig();
    expect(config.fullscreenDialog, isTrue);
  });

  test('DbLensConfig.enableHistory defaults to false', () {
    const config = DbLensConfig();
    expect(config.enableHistory, isFalse);
  });

  test('history tracking is off by default until configureHistory', () {
    expect(DbLens.registry.enableHistory, isFalse);
  });
}

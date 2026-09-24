import 'package:db_lens/data/datasources/shared_preferences/shared_preferences_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late SharedPreferencesDataSource source;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'a': 'x', 'b': 1});
    prefs = await SharedPreferences.getInstance();
    source = SharedPreferencesDataSource(
      sourceId: 'p',
      sourceName: 'Prefs',
      preferences: prefs,
    );
  });

  test('supports row delete', () {
    expect(source.supportsRowDelete, isTrue);
  });

  test('deleteRow removes only that key', () async {
    await source.deleteRow('preferences', {'key': 'a', 'type': 'String'});

    expect(prefs.containsKey('a'), isFalse);
    expect(prefs.getInt('b'), 1);
    expect(await source.count('preferences'), 1);
  });

  test('deleteRow without key throws', () async {
    expect(
      () => source.deleteRow('preferences', {'type': 'String'}),
      throwsArgumentError,
    );
  });
}

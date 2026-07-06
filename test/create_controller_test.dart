import 'package:db_lens/db_lens.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('createController().initialize() loads sources from registry', () async {
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE t (id INTEGER PRIMARY KEY)');
      },
    );
    DbLens.register('Test DB', db);
    addTearDown(() => DbLens.unregisterSource('Test DB'));

    final controller = DbLens.createController();
    await controller.initialize();
    expect(controller.source.sources, isNotEmpty);

    controller.dispose();
    await db.close();
  });
}

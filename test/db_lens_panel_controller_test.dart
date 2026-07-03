import 'package:db_lens/db_lens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() {
    for (final name in List.of(DbLens.databaseNames)) {
      DbLens.unregister(name);
    }
  });

  testWidgets(
    'DbLensPanel asserts when given an external controller that was not initialized',
    (tester) async {
      final controller = DbLens.createController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: DbLens.buildPanel(controller: controller),
        ),
      );

      expect(tester.takeException(), isAssertionError);
    },
  );

  testWidgets(
    'DbLensPanel mounts fine when the external controller was initialized first',
    (tester) async {
      final db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('CREATE TABLE t (id INTEGER PRIMARY KEY)');
        },
      );
      DbLens.register('Test DB', db);

      final controller = DbLens.createController();
      await controller.initialize();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: DbLens.buildPanel(controller: controller),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(DbLensPanel), findsOneWidget);

      await db.close();
    },
  );
}

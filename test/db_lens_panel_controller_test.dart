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
      late Database db;
      late DbLensController controller;
      // Real sqflite I/O harus lewat runAsync — testWidgets menahan
      // penyelesaian isolate/port asli sqflite_common_ffi kalau dipanggil
      // langsung tanpa runAsync, menyebabkan await ini hang selamanya.
      await tester.runAsync(() async {
        db = await openDatabase(  
          inMemoryDatabasePath,
          version: 1,
          onCreate: (db, version) async {
            await db.execute('CREATE TABLE t (id INTEGER PRIMARY KEY)');
          },
        );
        DbLens.register('Test DB', db);

        controller = DbLens.createController();
        await controller.initialize();
      });
      addTearDown(() => DbLens.unregisterSource('Test DB'));
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DbLens.buildPanel(controller: controller)),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(DbLensPanel), findsOneWidget);

      await tester.runAsync(() => db.close());
    },
  );
}

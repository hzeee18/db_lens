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
    'DbLensHistoryPanel renders in a plain Scaffold body — not locked to a bottom sheet',
    (tester) async {
      final historyController = DbLens.createHistoryController();
      // Real sqflite I/O harus lewat runAsync — testWidgets menahan
      // penyelesaian isolate/port asli sqflite_common_ffi kalau dipanggil
      // langsung tanpa runAsync, menyebabkan await ini hang selamanya.
      await tester.runAsync(
        () => historyController.loadFor('non-existent-source'),
      );
      addTearDown(historyController.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DbLensThemeScope(
              theme: DbLensTheme(),
              child: DbLensHistoryPanel(
                controller: historyController,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DbLensHistoryPanel), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('No changes yet'), findsOneWidget);
    },
  );
}

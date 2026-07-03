import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:db_lens_example/main.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('Home screen smoke test', (WidgetTester tester) async {
    final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    addTearDown(db.close);

    await tester.pumpWidget(MyApp(database: db));
    await tester.pumpAndSettle();

    expect(find.text('DbLens Example'), findsOneWidget);
    expect(find.text('Database Inspector Framework'), findsOneWidget);
  });
}

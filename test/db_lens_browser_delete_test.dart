import 'package:db_lens/db_lens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('browser deletes a SharedPreferences key after confirmation',
      (tester) async {
    SharedPreferences.setMockInitialValues({'farm_id': 'abc', 'other': 1});
    final prefs = await SharedPreferences.getInstance();
    DbLens.configureHistory(enabled: false);
    DbLens.registerSharedPreferences('Browser Prefs', prefs);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => DbLens.openBrowser(context),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('preferences'));
    await tester.pumpAndSettle();

    // Rows are sorted by key: farm_id is #1.
    await tester.tap(find.byIcon(Icons.delete_outline_rounded).first);
    await tester.pumpAndSettle();
    expect(find.text('Hapus data?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Hapus'));
    await tester.pumpAndSettle();

    expect(prefs.containsKey('farm_id'), isFalse);
    expect(prefs.containsKey('other'), isTrue);
    expect(find.text('Data berhasil dihapus'), findsOneWidget);

    // Let the snackbar timer finish.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}

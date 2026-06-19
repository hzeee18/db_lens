import 'package:flutter_test/flutter_test.dart';

import 'package:db_lens_example/main.dart';

void main() {
  testWidgets('Home screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('DbLens Example'), findsOneWidget);
    expect(find.text('db_lens example'), findsOneWidget);
    expect(find.text('DB Lens'), findsOneWidget);
  });
}

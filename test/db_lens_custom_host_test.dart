import 'package:db_lens/db_lens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DbLensControllerScope.of throws without an ancestor scope', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            expect(() => DbLensControllerScope.of(context), throwsAssertionError);
            return const SizedBox();
          },
        ),
      ),
    );
  });

  testWidgets('DbLensControllerScope provides an initialized controller to descendants',
      (tester) async {
    DbLensController? captured;

    await tester.pumpWidget(
      MaterialApp(
        home: DbLensControllerScope(
          child: Builder(
            builder: (context) {
              captured = DbLensControllerScope.of(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(captured, isNotNull);
    expect(captured!.isInitialized, isTrue);
  });

  testWidgets('DbLensControllerScope disposes an owned controller when unmounted',
      (tester) async {
    DbLensController? captured;

    await tester.pumpWidget(
      MaterialApp(
        home: DbLensControllerScope(
          child: Builder(
            builder: (context) {
              captured = DbLensControllerScope.of(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(captured, isNotNull);

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pumpAndSettle();

    expect(() => captured!.addListener(() {}), throwsFlutterError);
  });
}

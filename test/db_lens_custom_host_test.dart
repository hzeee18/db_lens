import 'package:db_lens/db_lens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('openCustom disposes controller on pop', (tester) async {
    DbLensController? capturedController;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => DbLens.openCustom(
              context,
              builder: (ctx, controller) {
                capturedController = controller;
                return const SizedBox();
              },
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(capturedController, isNotNull);

    Navigator.of(tester.element(find.byType(SizedBox))).pop();
    await tester.pumpAndSettle();
  });
}

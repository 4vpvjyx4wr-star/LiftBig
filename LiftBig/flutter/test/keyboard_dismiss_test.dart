import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftbig/theme.dart';
import 'package:liftbig/ui/keyboard_dismiss.dart';

void main() {
  testWidgets('Done stays hidden unless a text field is focused', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLiftBigTheme(),
        home: const MediaQuery(
          data: MediaQueryData(viewInsets: EdgeInsets.only(bottom: 300)),
          child: Scaffold(
            body: KeyboardDismiss(
              child: TextField(),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Done'), findsNothing);
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.pump();
    expect(find.text('Done'), findsOneWidget);

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await tester.pump();
    expect(find.text('Done'), findsNothing);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftbig/theme.dart';
import 'package:liftbig/ui/basic_calculator_page.dart';

void main() {
  test('weight and distance swaps use the stated constants', () {
    expect(convertCalculatorUnit(1, 'lb'), closeTo(2.2046226218, 0.0000000001));
    expect(convertCalculatorUnit(2.2046226218, 'kg'), closeTo(1, 0.0000000001));
    expect(convertCalculatorUnit(1, 'km'), closeTo(1.609344, 0.0000000001));
    expect(convertCalculatorUnit(1.609344, 'mi'), closeTo(1, 0.0000000001));
    expect(formatCalculatorConversion(100 / 2.2046226218), '45.359');
    expect(formatCalculatorConversion(1.609344), '1.609');
    expect(formatCalculatorConversion(10), '10');
  });

  testWidgets('keypad matches the simplified calculator positions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: buildLiftBigTheme(), home: const BasicCalculatorPage()),
    );

    expect(keyCenter(tester, 'C').dy, closeTo(keyCenter(tester, '%').dy, 1));
    expect(keyCenter(tester, '%').dy, closeTo(keyCenter(tester, 'Swap To').dy, 1));
    expect(keyCenter(tester, 'Swap To').dy, closeTo(keyCenter(tester, '÷').dy, 1));
    expect(keyCenter(tester, 'C').dx, lessThan(keyCenter(tester, '%').dx));
    expect(keyCenter(tester, '%').dx, lessThan(keyCenter(tester, 'Swap To').dx));
    expect(keyCenter(tester, 'Swap To').dx, lessThan(keyCenter(tester, '÷').dx));

    expect(keyCenter(tester, '7').dy, lessThan(keyCenter(tester, '4').dy));
    expect(keyCenter(tester, '4').dy, lessThan(keyCenter(tester, '1').dy));
    expect(keyCenter(tester, '1').dy, lessThan(keyCenter(tester, '0').dy));
    expect(keyCenter(tester, '9').dx, lessThan(keyCenter(tester, '×').dx));
    expect(keyCenter(tester, '6').dx, lessThan(keyCenter(tester, '-').dx));
    expect(keyCenter(tester, '3').dx, lessThan(keyCenter(tester, '+').dx));
    expect(keyCenter(tester, '0').dy, closeTo(keyCenter(tester, '.').dy, 1));
    expect(keyCenter(tester, '.').dy, closeTo(keyCenter(tester, '=').dy, 1));
    expect(keyCenter(tester, '0').dx, lessThan(keyCenter(tester, '.').dx));
    expect(keyCenter(tester, '.').dx, lessThan(keyCenter(tester, '=').dx));

    final zero = tester.getSize(find.widgetWithText(FilledButton, '0'));
    final one = tester.getSize(find.widgetWithText(FilledButton, '1'));
    expect(zero.width, greaterThan(one.width * 1.5));
  });

  testWidgets('swap converts the typed number and leaves preferences alone', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: buildLiftBigTheme(), home: const BasicCalculatorPage()),
    );

    await tester.tap(find.widgetWithText(FilledButton, '1'));
    await tester.tap(find.widgetWithText(FilledButton, '0'));
    await tester.tap(find.widgetWithText(FilledButton, '0'));
    await tester.pump();
    await tester.tap(find.text('Swap To'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('kg'));
    await tester.pumpAndSettle();

    expect(find.text('45.359'), findsOneWidget);
    expect(find.text('kg'), findsWidgets);

    await tester.tap(find.text('Swap To'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('lb').last);
    await tester.pumpAndSettle();
    expect(find.text('100'), findsOneWidget);
    expect(find.text('lb'), findsWidgets);

    await tester.tap(find.text('Swap To'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('km'));
    await tester.pumpAndSettle();
    expect(find.text('160.934'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '%'));
    await tester.pump();
    expect(find.text('1.609344'), findsOneWidget);
    expect(find.text('km'), findsNothing);
  });
}

Offset keyCenter(WidgetTester tester, String label) {
  return tester.getCenter(find.widgetWithText(FilledButton, label));
}

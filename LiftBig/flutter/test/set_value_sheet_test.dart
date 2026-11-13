import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftbig/theme.dart';
import 'package:liftbig/ui/set_value_sheet.dart';
import 'package:liftbig/utils/weight_units.dart';

void main() {
  test('wheel locks to the first axis and steps one increment at a time', () {
    expect(sheetWheelLock(dx: 10, dy: 4), isNull);
    expect(sheetWheelLock(dx: 24, dy: 4), SheetWheelLock.horizontal);
    expect(sheetWheelLock(dx: -24, dy: 4), SheetWheelLock.horizontal);
    expect(sheetWheelLock(dx: 4, dy: 24), SheetWheelLock.vertical);
    expect(sheetWheelLock(dx: 22, dy: 40), SheetWheelLock.vertical);
    expect(sheetWheelLock(dx: 40, dy: 22), SheetWheelLock.horizontal);

    expect(sheetWheelSteps(0).steps, 0);
    expect(sheetWheelSteps(sheetWheelPixelsPerStep).steps, 1);
    expect(sheetWheelSteps(sheetWheelPixelsPerStep).remainder, 0);
    expect(sheetWheelSteps(sheetWheelPixelsPerStep - 0.1).steps, 0);
    expect(sheetWheelSteps(sheetWheelPixelsPerStep * 2).steps, 2);

    final right = sheetWheelSteps(sheetWheelPixelsPerStep + 4);
    expect(right.steps, 1);
    final more = sheetWheelSteps(right.remainder + sheetWheelPixelsPerStep);
    expect(more.steps, 1);
    expect(more.remainder, 4);

    final left = sheetWheelSteps(-(sheetWheelPixelsPerStep * 1.5));
    expect(left.steps, -1);
    expect(left.remainder, closeTo(-sheetWheelPixelsPerStep / 2, 0.001));
  });

  testWidgets('goal reps are green and the range is bracketed', (
    tester,
  ) async {
    await openReps(tester, initial: '');

    for (final reps in ['8', '9', '10', '11', '12']) {
      expect(wheelColor(tester, reps), LiftBigColors.success);
    }
    expect(wheelColor(tester, '7'), LiftBigColors.foreground);
    expect(wheelColor(tester, '13'), LiftBigColors.foreground);
    final top = outlineOf(tester, '12');
    expect(top, isNotNull);
    expect(top!.top.color, LiftBigColors.success.withValues(alpha: 0.7));
    expect(top.top.width, greaterThan(0));
    expect(top.bottom.style, BorderStyle.none);
    expect(top.left.style, BorderStyle.none);
    expect(top.right.style, BorderStyle.none);
    final bottom = outlineOf(tester, '8');
    expect(bottom, isNotNull);
    expect(bottom!.bottom.color, LiftBigColors.success.withValues(alpha: 0.7));
    expect(bottom.bottom.width, greaterThan(0));
    expect(bottom.top.style, BorderStyle.none);
    expect(outlineOf(tester, '10'), isNull);
    expect(find.byIcon(Icons.chevron_left), findsNothing);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
    expect(find.byIcon(Icons.arrow_back), findsNothing);
    expect(find.byIcon(Icons.arrow_forward), findsNothing);
    expect(find.byIcon(Icons.keyboard_arrow_left), findsNothing);
    expect(find.byIcon(Icons.keyboard_arrow_right), findsNothing);
  });

  testWidgets('a chosen goal rep stays green', (tester) async {
    await openReps(tester, initial: '10');
    expect(wheelColor(tester, '10'), LiftBigColors.success);
    expect(wheelColor(tester, '12'), LiftBigColors.success);
    expect(wheelColor(tester, '7'), LiftBigColors.foreground);
  });

  testWidgets('horizontal drag steps the slider and counts as a choice', (
    tester,
  ) async {
    String? saved;
    await openReps(tester, initial: '', onSaved: (value) => saved = value);

    expect(heroText(tester), isEmpty);
    await dragWheel(tester, '10', const Offset(sheetWheelPixelsPerStep + 6, 0));
    expect(heroText(tester), '2');

    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(saved, '2');
  });

  testWidgets('a longer horizontal drag steps one increment at a time', (
    tester,
  ) async {
    await openReps(tester, initial: '10');
    await dragWheel(
      tester,
      '10',
      const Offset(sheetWheelPixelsPerStep * 2 + 4, 0),
    );
    expect(heroText(tester), '12');

    await dragWheel(
      tester,
      '12',
      const Offset(-(sheetWheelPixelsPerStep + 6), 0),
    );
    expect(heroText(tester), '11');
  });

  testWidgets('vertical drag scrolls the wheel and is not a choice', (
    tester,
  ) async {
    String? saved;
    await openReps(tester, initial: '', onSaved: (value) => saved = value);
    final before = tester.getTopLeft(wheel('12'));

    await tester.drag(wheel('12'), const Offset(0, 120));
    await tester.pump();

    expect(heroText(tester), isEmpty);
    expect(tester.getTopLeft(wheel('12')).dy, greaterThan(before.dy + 40));

    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(saved, isEmpty);
  });

  testWidgets('the axis that moves first locks out the other', (tester) async {
    await openReps(tester, initial: '10');
    final row = wheel('12');
    final start = tester.getCenter(row);
    final before = tester.getTopLeft(row);

    final horizontal = await tester.startGesture(start);
    await horizontal.moveBy(const Offset(sheetWheelPixelsPerStep + 6, 0));
    await tester.pump();
    expect(heroText(tester), '11');
    final locked = tester.getTopLeft(row);
    expect(locked.dy, closeTo(before.dy, 0.5));

    await horizontal.moveBy(const Offset(0, 90));
    await tester.pump();
    expect(heroText(tester), '11');
    expect(tester.getTopLeft(row).dy, closeTo(locked.dy, 0.5));
    await horizontal.up();
    await tester.pump();

    final verticalStart = tester.getCenter(row);
    final verticalTop = tester.getTopLeft(row);
    final vertical = await tester.startGesture(verticalStart);
    await vertical.moveBy(const Offset(0, 30));
    await vertical.moveBy(const Offset(0, 70));
    await tester.pump();
    expect(heroText(tester), '11');
    expect(tester.getTopLeft(row).dy, greaterThan(verticalTop.dy + 30));
    final scrolled = tester.getTopLeft(row);

    await vertical.moveBy(const Offset(80, 0));
    await tester.pump();
    expect(heroText(tester), '11');
    expect(tester.getTopLeft(row).dy, closeTo(scrolled.dy, 0.5));
    await vertical.up();
  });

  testWidgets('a diagonal locks to the larger axis', (tester) async {
    await openReps(tester, initial: '10');
    final row = wheel('12');
    final top = tester.getTopLeft(row);
    final gesture = await tester.startGesture(tester.getCenter(row));
    await gesture.moveBy(const Offset(40, 22));
    await tester.pump();
    expect(heroText(tester), '12');
    expect(tester.getTopLeft(row).dy, closeTo(top.dy, 0.5));
    await gesture.moveBy(const Offset(0, 80));
    await tester.pump();
    expect(heroText(tester), '12');
    expect(tester.getTopLeft(row).dy, closeTo(top.dy, 0.5));
    await gesture.up();
    await tester.pump();

    final down = await tester.startGesture(tester.getCenter(wheel('11')));
    final before = tester.getTopLeft(wheel('11'));
    await down.moveBy(const Offset(22, 40));
    await down.moveBy(const Offset(0, 60));
    await tester.pump();
    expect(heroText(tester), '12');
    expect(tester.getTopLeft(wheel('11')).dy, greaterThan(before.dy + 20));
    final scrolled = tester.getTopLeft(wheel('11'));
    await down.moveBy(const Offset(70, 0));
    await tester.pump();
    expect(heroText(tester), '12');
    expect(tester.getTopLeft(wheel('11')).dy, closeTo(scrolled.dy, 0.5));
    await down.up();
  });

  testWidgets(
    'horizontal drag on the weight wheel steps by the plate increment',
    (tester) async {
      await openWeight(tester, initial: '100');
      final row = firstWheelNumber();
      await dragWheelAt(
        tester,
        row,
        const Offset(sheetWheelPixelsPerStep + 6, 0),
      );
      expect(heroText(tester), '105');
      await dragWheelAt(
        tester,
        firstWheelNumber(),
        const Offset(-(sheetWheelPixelsPerStep + 6), 0),
      );
      expect(heroText(tester), '100');
    },
  );

  testWidgets('tapping a rep still chooses it', (tester) async {
    String? saved;
    await openReps(tester, initial: '', onSaved: (value) => saved = value);
    await tester.tap(wheel('9'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(saved, '9');
  });
}

Finder wheel(String reps) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is Text && widget.data == reps && widget.style?.fontSize == 18,
  );
}

Color? wheelColor(WidgetTester tester, String reps) {
  return tester.widget<Text>(wheel(reps)).style?.color;
}

Border? outlineOf(WidgetTester tester, String reps) {
  final boxes = find.ancestor(
    of: wheel(reps),
    matching: find.byType(DecoratedBox),
  );
  for (final element in boxes.evaluate()) {
    final decoration = (element.widget as DecoratedBox).decoration;
    if (decoration is BoxDecoration && decoration.border != null) {
      return decoration.border as Border;
    }
  }
  return null;
}

String heroText(WidgetTester tester) {
  final heroes = tester
      .widgetList<Text>(find.byType(Text))
      .where((text) => text.style?.fontSize == 40);
  expect(heroes, hasLength(1));
  return heroes.single.data ?? '';
}

Future<void> dragWheel(WidgetTester tester, String reps, Offset offset) {
  return dragWheelAt(tester, wheel(reps), offset);
}

Future<void> dragWheelAt(WidgetTester tester, Finder row, Offset offset) async {
  final gesture = await tester.startGesture(tester.getCenter(row));
  await gesture.moveBy(offset);
  await gesture.up();
  await tester.pump();
}

Finder firstWheelNumber() {
  return find
      .byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.style?.fontSize == 18 &&
            int.tryParse(widget.data ?? '') != null,
      )
      .hitTestable()
      .first;
}

Future<void> openReps(
  WidgetTester tester, {
  required String initial,
  ValueChanged<String?>? onSaved,
  String? goal = '8-12',
}) async {
  await _open(
    tester,
    onPressed: (context) async {
      final value = await showSetValueSheet(
        context,
        title: 'Reps',
        initial: initial,
        goalLabel: goal,
        options: repsPickerOptions(max: 17),
        sliderMin: 1,
        sliderMax: 17,
        sliderDivisions: 16,
        sliderStep: 1,
      );
      onSaved?.call(value);
    },
  );
}

Future<void> openWeight(WidgetTester tester, {required String initial}) async {
  await _open(
    tester,
    onPressed: (context) {
      return showSetValueSheet(
        context,
        title: 'Weight (lb)',
        initial: initial,
        options: weightPickerOptions(WeightUnit.lb),
        weightUnit: WeightUnit.lb,
        sliderStep: 5,
        sliderMin: 0,
        sliderMax: 500,
        sliderDivisions: 100,
      );
    },
  );
}

Future<void> _open(
  WidgetTester tester, {
  required Future<void> Function(BuildContext context) onPressed,
}) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: buildLiftBigTheme(),
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () => onPressed(context),
              child: const Text('Open'),
            );
          },
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

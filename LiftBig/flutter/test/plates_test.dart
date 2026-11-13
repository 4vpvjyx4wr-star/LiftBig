import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftbig/theme.dart';
import 'package:liftbig/ui/machine_plates_hint.dart';
import 'package:liftbig/ui/plate_load_graphic.dart';
import 'package:liftbig/utils/plates.dart';
import 'package:liftbig/utils/variable_machine.dart';
import 'package:liftbig/utils/weight_units.dart';

void main() {
  test('calculatePlates matches Vue example for 225 on a 45 bar', () {
    const target = 225.0;
    const bar = 45.0;
    final result = calculatePlates(target, bar, plateSizesLb);
    expect(result.plates, [45, 45]);
    expect(result.remainder, 0);
    expect(totalWeightLb(bar, result.plates), target);
    expect(platesAreExact(result.remainder), isTrue);
  });

  testWidgets(
    'shared plate graphic keeps the calculator bar and a compact sled',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLiftBigTheme(),
          home: const Scaffold(
            body: Column(
              children: [
                PlateLoadGraphic(plates: [45, 45], unit: WeightUnit.lb),
                PlateLoadGraphic(plates: [], unit: WeightUnit.lb),
                PlateLoadGraphic(
                  plates: [45, 45, 45, 25],
                  unit: WeightUnit.lb,
                  centerLabel: 'SLED',
                  compact: true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('BAR'), findsNWidgets(2));
      expect(find.text('Just the bar — no plates needed.'), findsOneWidget);
      expect(find.text('SLED'), findsOneWidget);
      expect(
        tester.getSize(find.text('SLED')).height,
        lessThan(tester.getSize(find.text('BAR').first).height),
      );
    },
  );

  testWidgets('set-row hint shows each side counts on a smaller sled or bar', (
    tester,
  ) async {
    final starting = TextEditingController(text: '100');
    final weight = TextEditingController(text: '420');
    addTearDown(starting.dispose);
    addTearDown(weight.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildLiftBigTheme(),
        home: Scaffold(
          body: MachineSetPlateHint(
            kind: VariableMachineKind.legPress,
            startingController: starting,
            weightController: weight,
            unit: WeightUnit.lb,
          ),
        ),
      ),
    );

    expect(find.text('Each Side: 3×45, 1×25'), findsOneWidget);
    expect(find.text('SLED'), findsOneWidget);
    expect(find.textContaining('45, 45, 45, 25'), findsNothing);

    weight.text = '135';
    starting.text = '25';
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLiftBigTheme(),
        home: Scaffold(
          body: MachineSetPlateHint(
            kind: VariableMachineKind.smith,
            startingController: starting,
            weightController: weight,
            unit: WeightUnit.lb,
          ),
        ),
      ),
    );

    expect(find.text('Each Side: 1×45, 1×10'), findsOneWidget);
    expect(find.text('BAR'), findsOneWidget);
  });
}

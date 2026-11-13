import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftbig/theme.dart';
import 'package:liftbig/ui/machine_plates_hint.dart';
import 'package:liftbig/utils/barbell_compound.dart';
import 'package:liftbig/utils/plates.dart';
import 'package:liftbig/utils/variable_machine.dart';
import 'package:liftbig/utils/weight_units.dart';

void main() {
  test('barbell plate lifts match library ids and names, not accessories', () {
    const included = [
      ('squat', 'Barbell Back Squat'),
      ('front-squat', 'Front Squat'),
      ('zercher-squat', 'Zercher Squat'),
      ('bench-press', 'Barbell Bench Press'),
      ('decline-bench-press', 'Decline Barbell Bench Press'),
      ('overhead-press', 'Overhead Press'),
      ('deadlift', 'Conventional Deadlift'),
      ('sumo-deadlift', 'Sumo Deadlift'),
      ('romanian-deadlift', 'Romanian Deadlift (RDL)'),
      ('barbell-row', 'Barbell Row'),
      ('pendlay-row', 'Pendlay Row'),
      ('hip-thrust', 'Hip Thrust'),
      ('good-morning', 'Good Morning'),
    ];
    for (final (id, name) in included) {
      expect(
        isBarbellCompoundPlateLift(libraryId: id, name: name),
        isTrue,
        reason: id,
      );
      expect(
        isBarbellCompoundPlateLift(libraryId: null, name: name),
        isTrue,
        reason: name,
      );
    }

    expect(
      isBarbellCompoundPlateLift(libraryId: null, name: 'Squat'),
      isTrue,
    );
    expect(
      isBarbellCompoundPlateLift(libraryId: null, name: 'RDL'),
      isTrue,
    );
    expect(
      isBarbellCompoundPlateLift(libraryId: 'rdl', name: 'RDL'),
      isTrue,
    );

    for (final name in [
      'Barbell Curl',
      'Barbell Shrug',
      'Skull Crusher',
      'Incline Bench Press',
      'Hack Squat',
      'Dumbbell Bench Press',
      'Smith Machine Bench Press',
    ]) {
      expect(
        isBarbellCompoundPlateLift(libraryId: null, name: name),
        isFalse,
        reason: name,
      );
    }
    expect(
      isBarbellCompoundPlateLift(
        libraryId: 'barbell-curl',
        name: 'Barbell Curl',
      ),
      isFalse,
    );
  });

  test('plate graphic stays on unless hidden, and the bar is 45 or a stored 35', () {
    expect(showPlateGraphicFromStored(null), isTrue);
    expect(showPlateGraphicFromStored(''), isTrue);
    expect(showPlateGraphicFromStored('true'), isTrue);
    expect(showPlateGraphicFromStored('false'), isFalse);
    expect(standardBarLbFromStored(null), defaultBarLb);
    expect(standardBarLbFromStored('45'), 45);
    expect(standardBarLbFromStored('35'), 35);
    expect(standardBarLbFromStored('20'), defaultBarLb);
  });

  testWidgets('barbell hint draws the bar and a hidden machine graphic stays text', (
    tester,
  ) async {
    final weight = TextEditingController(text: '225');
    final starting = TextEditingController(text: '100');
    addTearDown(weight.dispose);
    addTearDown(starting.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildLiftBigTheme(),
        home: Scaffold(
          body: BarbellSetPlateHint(
            weightController: weight,
            unit: WeightUnit.lb,
            barLb: defaultBarLb,
          ),
        ),
      ),
    );

    expect(find.text('BAR'), findsOneWidget);
    expect(find.text('Each Side: 2×45'), findsOneWidget);
    expect(find.text('SLED'), findsNothing);

    weight.text = '420';
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLiftBigTheme(),
        home: Scaffold(
          body: MachineSetPlateHint(
            kind: VariableMachineKind.legPress,
            startingController: starting,
            weightController: weight,
            unit: WeightUnit.lb,
            showGraphic: false,
          ),
        ),
      ),
    );

    expect(find.text('Each Side: 3×45, 1×25'), findsOneWidget);
    expect(find.text('SLED'), findsNothing);
    expect(find.text('BAR'), findsNothing);
  });
}

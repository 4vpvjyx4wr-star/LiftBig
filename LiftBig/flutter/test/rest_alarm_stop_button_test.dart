import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftbig/theme.dart';
import 'package:liftbig/ui/rest_timer_tile.dart';

void main() {
  testWidgets('alarm replay and edit do not fire Stop', (tester) async {
    var stopped = 0;
    var replayed = 0;
    var edited = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildLiftBigTheme(),
        home: Scaffold(
          body: RestAlarmStopButton(
            onStop: () => stopped += 1,
            onReplay: () => replayed += 1,
            onEdit: () => edited += 1,
          ),
        ),
      ),
    );

    final stop = find.widgetWithText(FilledButton, 'Stop');
    expect(tester.getSize(stop), const Size(220, 220));
    expect(
      find.descendant(of: stop, matching: find.byIcon(Icons.replay)),
      findsNothing,
    );
    expect(
      find.descendant(of: stop, matching: find.byIcon(Icons.edit_outlined)),
      findsNothing,
    );

    await tester.tap(find.byTooltip('Reset'));
    await tester.pump();
    expect(replayed, 1);
    expect(stopped, 0);
    expect(edited, 0);

    await tester.tap(find.byTooltip('Edit'));
    await tester.pump();
    expect(edited, 1);
    expect(stopped, 0);
    expect(replayed, 1);

    await tester.tap(find.text('Stop'));
    await tester.pump();
    expect(stopped, 1);
    expect(replayed, 1);
    expect(edited, 1);
  });
}

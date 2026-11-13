import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftbig/theme.dart';
import 'package:liftbig/ui/rest_timer_banner.dart';

void main() {
  testWidgets('small menus and dialogs keep a colored border', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLiftBigTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Column(
                children: [
                  TextButton(
                    onPressed: () => confirmCancelRestTimer(context),
                    child: const Text('Cancel Timer'),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Menu',
                    icon: const Icon(Icons.menu),
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'settings', child: Text('Settings')),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Cancel Timer'));
    await tester.pumpAndSettle();
    expect(find.text('Cancel Timer?'), findsOneWidget);
    expect(borderedMaterial(tester), isNotNull);

    await tester.tap(find.text('No'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(borderedMaterial(tester), isNotNull);
  });
}

Material? borderedMaterial(WidgetTester tester) {
  for (final material in tester.widgetList<Material>(find.byType(Material))) {
    final shape = material.shape;
    if (shape is RoundedRectangleBorder &&
        shape.side.color == LiftBigColors.primary &&
        shape.side.width >= 1.5) {
      return material;
    }
  }
  return null;
}

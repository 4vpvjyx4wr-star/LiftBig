import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftbig/theme.dart';
import 'package:liftbig/ui/rest_timer_banner.dart';
import 'package:liftbig/ui/rest_timer_tile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('rest buttons fit the floating card and the anchored bar', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    Future<void> pumpAt(Size size) async {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLiftBigTheme(),
          home: Scaffold(
            appBar: AppBar(
              title: AnchoredRestTimer(
                remaining: 90,
                running: true,
                onPause: () {},
                onReset: () {},
                onFloat: () {},
                onCancel: () {},
              ),
              actions: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.menu),
                ),
              ],
            ),
            body: Align(
              alignment: Alignment.topCenter,
              child: RestTimerBanner(
                remaining: 90,
                running: true,
                onPause: () {},
                onReset: () {},
                onDismiss: () {},
                onCancel: () {},
                onOpen: () {},
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);

      final card = tester.getRect(find.byType(RestTimerBanner));
      expect(card.width, restTimerTileWidth);
      final cardCancel = tester.getRect(
        find.descendant(
          of: find.byType(RestTimerBanner),
          matching: find.byTooltip('Cancel'),
        ),
      );
      expect(cardCancel.right, lessThanOrEqualTo(card.right + 0.1));
      expect(cardCancel.left, greaterThanOrEqualTo(card.left - 0.1));

      final bar = tester.getRect(find.byType(AnchoredRestTimer));
      final barCancel = tester.getRect(
        find.descendant(
          of: find.byType(AnchoredRestTimer),
          matching: find.byTooltip('Cancel'),
        ),
      );
      expect(barCancel.right, lessThanOrEqualTo(bar.right + 0.1));
      expect(barCancel.left, greaterThanOrEqualTo(bar.left - 0.1));
    }

    await pumpAt(const Size(390, 844));
    await pumpAt(const Size(320, 568));
  });

  test('a new rest card is centered above the tab bar', () {
    final offset = defaultRestTimerOffset(
      const BoxConstraints(maxWidth: 390, maxHeight: 700),
    );
    expect(offset.dx, (390 - restTimerTileWidth) / 2);
    expect(
      offset.dy,
      (700 - restTimerTabBarClearance - restTimerTileHeight) / 2,
    );
    expect(restTimerOffsetIsLegacyTopDefault(const Offset(100, 8)), isTrue);
    expect(restTimerOffsetIsLegacyTopDefault(const Offset(12, 8.4)), isTrue);
    expect(restTimerOffsetIsLegacyTopDefault(const Offset(40, 180)), isFalse);
  });
}

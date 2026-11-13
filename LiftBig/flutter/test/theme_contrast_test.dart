import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftbig/theme.dart';
import 'package:liftbig/ui/theme_backdrop.dart';
import 'package:liftbig/utils/barbell_compound.dart';

void main() {
  test('onPrimary follows estimateBrightnessForColor', () {
    expect(liftBigPaletteById('loud').onPrimary, const Color(0xFF111111));
    for (final palette in liftBigThemePresets) {
      final light =
          ThemeData.estimateBrightnessForColor(palette.primary) ==
          Brightness.light;
      expect(
        palette.onPrimary,
        light ? const Color(0xFF111111) : const Color(0xFFFFFFFF),
        reason: palette.id,
      );
    }
  });

  test('default and forest muted text clears 4.5:1', () {
    final fallback = liftBigPaletteById('default');
    expect(
      _contrast(fallback.muted, fallback.canvas),
      greaterThanOrEqualTo(4.5),
    );
    expect(_contrast(fallback.muted, fallback.card), greaterThanOrEqualTo(4.5));
    final forest = liftBigPaletteById('forest');
    expect(_contrast(forest.muted, forest.card), greaterThanOrEqualTo(4.5));
    expect(_contrast(forest.muted, forest.canvas), greaterThanOrEqualTo(4.5));
  });

  test('default, iron, and titanium cards sit above the page', () {
    for (final id in ['default', 'iron', 'titanium']) {
      final palette = liftBigPaletteById(id);
      expect(
        palette.card.computeLuminance(),
        greaterThan(palette.canvas.computeLuminance()),
        reason: id,
      );
      expect(
        palette.border.computeLuminance(),
        greaterThan(palette.card.computeLuminance()),
        reason: id,
      );
      expect(palette.proOnly, isFalse, reason: id);
      expect(palette.backdrop, LiftBigBackdrop.none, reason: id);
    }
  });

  test('retrowave is second and pro themes follow the free group', () {
    expect(liftBigThemePresets.first.id, defaultLiftBigThemeId);
    expect(liftBigThemePresets[1].id, 'retrowave');
    expect(liftBigThemePresets[1].proOnly, isFalse);
    expect(liftBigThemePresets[1].backdrop, LiftBigBackdrop.none);

    final firstPro = liftBigThemePresets.indexWhere(
      (palette) => palette.proOnly,
    );
    expect(firstPro, greaterThan(1));
    expect(
      liftBigThemePresets.take(firstPro).every((palette) => !palette.proOnly),
      isTrue,
    );
    expect(
      liftBigThemePresets.skip(firstPro).every((palette) => palette.proOnly),
      isTrue,
    );
    expect(
      liftBigThemePresets.take(firstPro).map((palette) => palette.id).toList(),
      [
        'default',
        'retrowave',
        'forest',
        'violet',
        'sunset',
        'loud',
        'cyberpunk',
        'iron',
        'aurora',
        'bubblegum',
        'midnight',
        'sandstorm',
        'cherrylime',
        'terminal',
        'disco',
        'ocean',
        'voltage',
        'dragonfruit',
        'glacier',
        'lavaflow',
        'nebula',
        'toxic',
        'sapphire',
        'mango',
        'prism',
        'mintchip',
        'tidal',
        'cottoncandy',
        'bloodmoon',
        'titanium',
      ],
    );
  });

  test('pro themes fall back unless Pro is active', () {
    const ids = [
      'plate-stack',
      'chalk-grid',
      'hazard-stripe',
      'signal-sweep',
      'ember-drift',
      'bar-path',
      'rack-glow',
      'knurl',
    ];
    expect(
      liftBigThemePresets.where((palette) => palette.proOnly).map((p) => p.id),
      ids,
    );
    for (final id in ids) {
      expect(
        liftBigPaletteById(id, proActive: false).id,
        defaultLiftBigThemeId,
      );
      final open = liftBigPaletteById(id, proActive: true);
      expect(open.proOnly, isTrue);
      expect(open.backdrop, id);
      expect(open.background, Colors.transparent);
      expect(
        LiftBigBackdrop.animates(open.backdrop),
        id == 'signal-sweep' ||
            id == 'ember-drift' ||
            id == 'bar-path' ||
            id == 'rack-glow',
        reason: id,
      );
    }

    final stored = LiftBigThemeController();
    addTearDown(stored.dispose);
    stored.applyStored('knurl');
    expect(stored.id, 'knurl');
    expect(stored.palette.id, defaultLiftBigThemeId);
    stored.setProActive(true);
    expect(stored.palette.id, 'knurl');
    expect(stored.palette.backdrop, LiftBigBackdrop.knurl);

    final themes = LiftBigThemeController();
    addTearDown(themes.dispose);
    themes.applyStored('signal-sweep');
    expect(themes.id, 'signal-sweep');
    expect(themes.palette.id, defaultLiftBigThemeId);
    themes.setProActive(true);
    expect(themes.palette.backdrop, LiftBigBackdrop.signalSweep);
    themes.select('hazard-stripe');
    expect(themes.palette.id, 'hazard-stripe');
    themes.setProActive(false);
    themes.select('ember-drift');
    expect(themes.id, 'hazard-stripe');
    expect(themes.palette.id, defaultLiftBigThemeId);
    themes.applyStored('missing-theme', proActive: true);
    expect(themes.palette.id, defaultLiftBigThemeId);
  });

  test('filled buttons use onPrimary', () {
    final loud = buildLiftBigTheme(liftBigPaletteById('loud'));
    final button = loud.filledButtonTheme.style!.foregroundColor!.resolve(
      const <WidgetState>{},
    );
    expect(button, liftBigPaletteById('loud').onPrimary);
    expect(loud.colorScheme.onPrimary, liftBigPaletteById('loud').onPrimary);
  });

  test('plate graphic subtitle lists the plate lifts', () {
    expect(
      plateGraphicExamplesLabel,
      'Squat, bench, decline bench, overhead press, deadlift variants, '
      'barbell row, Pendlay row, hip thrust, and good morning.',
    );
  });

  testWidgets('pro backdrops paint, and the animated ones tick', (
    tester,
  ) async {
    final motion = AnimationController(
      vsync: tester,
      duration: const Duration(seconds: 16),
    )..repeat();
    addTearDown(motion.dispose);
    for (final id in [
      'plate-stack',
      'chalk-grid',
      'hazard-stripe',
      'signal-sweep',
      'ember-drift',
      'bar-path',
      'rack-glow',
      'knurl',
    ]) {
      final palette = liftBigPaletteById(id);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLiftBigTheme(palette),
          home: Scaffold(
            body: RepaintBoundary(
              child: LiftBigThemeBackdrop(
                palette: palette,
                motion: LiftBigBackdrop.animates(palette.backdrop)
                    ? motion
                    : null,
              ),
            ),
          ),
        ),
      );
      expect(find.byType(CustomPaint), findsWidgets);
      await tester.pump(const Duration(milliseconds: 400));
    }

    final sweep = liftBigPaletteById('signal-sweep');
    final held = motion.value;
    await tester.pump(const Duration(milliseconds: 500));
    expect(motion.value, isNot(held));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLiftBigTheme(sweep),
        home: Scaffold(
          body: RepaintBoundary(
            child: LiftBigThemeBackdrop(palette: sweep, motion: motion),
          ),
        ),
      ),
    );
    final duringRebuild = motion.value;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLiftBigTheme(sweep),
        home: Scaffold(
          body: RepaintBoundary(
            child: LiftBigThemeBackdrop(palette: sweep, motion: motion),
          ),
        ),
      ),
    );
    expect((motion.value - duringRebuild).abs(), lessThan(0.05));
    expect(motion.value, greaterThan(0.05));

    motion.stop();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

double _contrast(Color foreground, Color background) {
  final lighter = foreground.computeLuminance() > background.computeLuminance()
      ? foreground.computeLuminance()
      : background.computeLuminance();
  final darker = foreground.computeLuminance() > background.computeLuminance()
      ? background.computeLuminance()
      : foreground.computeLuminance();
  return (lighter + 0.05) / (darker + 0.05);
}

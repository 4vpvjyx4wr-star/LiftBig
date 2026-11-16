import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Full-screen pattern for a Pro theme.
///
/// Motion comes from one controller owned above the navigator. Passing it in
/// keeps the phase stable when this widget is rebuilt. Static patterns omit
/// [motion] and paint a single frame.
class LiftBigThemeBackdrop extends StatelessWidget {
  const LiftBigThemeBackdrop({super.key, required this.palette, this.motion});

  final LiftBigPalette palette;
  final Animation<double>? motion;

  @override
  Widget build(BuildContext context) {
    final moving = motion != null && LiftBigBackdrop.animates(palette.backdrop);
    return IgnorePointer(
      child: CustomPaint(
        painter: _LiftBigBackdropPainter(
          palette: palette,
          motion: moving ? motion : null,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// Small static swatch. Backdrop themes get one frozen frame of the pattern.
class LiftBigThemePreview extends StatelessWidget {
  const LiftBigThemePreview({super.key, required this.palette});

  final LiftBigPalette palette;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LiftBigBackdropPainter(palette: palette, hint: true),
      child: const SizedBox.expand(),
    );
  }
}

/// Drops the page underneath a transparent route on the first frame.
///
/// A Pro scaffold is transparent so the single backdrop behind the navigator
/// can show through. Until the push animation completes, the previous route
/// is still painted between that backdrop and the new page, so the new text
/// appears over the old screen and the pattern pops in when the transition
/// ends. Hiding this page while the covering route is entering lets the
/// backdrop and the new text paint together. A reverse transition shows the
/// page again so the back gesture reveals it.
class LiftBigRouteUnderlay extends StatelessWidget {
  const LiftBigRouteUnderlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Always the same wrapper. Returning the child directly for flat themes
    // and AnimatedBuilder for patterned ones swapped the element and dropped
    // scroll state whenever the palette crossed that line.
    final patterned = context.liftBig.backdrop != LiftBigBackdrop.none;
    final secondary = ModalRoute.of(context)?.secondaryAnimation;
    final animation = secondary ?? const AlwaysStoppedAnimation<double>(0);
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final covered =
            patterned &&
            secondary != null &&
            (secondary.status == AnimationStatus.forward ||
                secondary.status == AnimationStatus.completed);
        return Visibility(
          visible: !covered,
          maintainState: true,
          maintainAnimation: true,
          maintainSize: true,
          child: child!,
        );
      },
      child: child,
    );
  }
}

class _LiftBigBackdropPainter extends CustomPainter {
  _LiftBigBackdropPainter({
    required this.palette,
    this.motion,
    this.hint = false,
  }) : super(repaint: hint ? null : motion);

  final LiftBigPalette palette;
  final Animation<double>? motion;
  final bool hint;

  double get _t => hint ? 0.42 : (motion?.value ?? 0);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = palette.canvas);
    if (palette.backdrop == LiftBigBackdrop.none) return;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    var target = size;
    if (hint && size.width > 0 && size.width < 280) {
      final scale = size.width / 280;
      canvas.scale(scale);
      target = Size(280, size.height / scale);
    }
    switch (palette.backdrop) {
      case LiftBigBackdrop.plateStack:
        _plateStack(canvas, target);
      case LiftBigBackdrop.chalkGrid:
        _chalkGrid(canvas, target);
      case LiftBigBackdrop.hazardStripe:
        _hazardStripe(canvas, target);
      case LiftBigBackdrop.signalSweep:
        _signalSweep(canvas, target);
      case LiftBigBackdrop.emberDrift:
        _emberDrift(canvas, target);
      case LiftBigBackdrop.knurl:
        _knurl(canvas, target);
      case LiftBigBackdrop.cosmicMoon:
        _cosmicMoon(canvas, target);
      case LiftBigBackdrop.deepOcean:
        _deepOcean(canvas, target);
      case LiftBigBackdrop.sakuraBlossom:
        _sakuraBlossom(canvas, target);
    }
    canvas.restore();
  }

  void _plateStack(Canvas canvas, Size size) {
    const stepX = 176.0;
    const stepY = 92.0;
    final iron = palette.foreground.withValues(alpha: 0.09);
    final accent = palette.primary.withValues(alpha: 0.24);
    final barPaint = Paint()
      ..color = palette.foreground.withValues(alpha: 0.09);
    for (var row = 0; row * stepY < size.height + stepY; row++) {
      final stagger = row.isOdd ? 48.0 : 0.0;
      for (var col = -1; col * stepX < size.width + stepX; col++) {
        final origin = Offset(col * stepX + stagger, row * stepY + 18);
        canvas.drawRRect(
          RRect.fromLTRBR(
            origin.dx + 16,
            origin.dy + 12,
            origin.dx + 156,
            origin.dy + 18,
            const Radius.circular(2),
          ),
          barPaint,
        );
        _disc(canvas, Offset(origin.dx + 30, origin.dy + 15), 40, accent);
        _disc(canvas, Offset(origin.dx + 42, origin.dy + 15), 28, iron);
        _disc(canvas, Offset(origin.dx + 130, origin.dy + 15), 28, iron);
        _disc(canvas, Offset(origin.dx + 142, origin.dy + 15), 40, accent);
        canvas.drawCircle(
          Offset(origin.dx + 86, origin.dy + 15),
          3,
          Paint()..color = palette.blue.withValues(alpha: 0.18),
        );
      }
    }
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF000000).withValues(alpha: 0.46),
    );
  }

  void _disc(Canvas canvas, Offset center, double height, Color color) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 8, height: height),
        const Radius.circular(2),
      ),
      Paint()..color = color,
    );
  }

  void _chalkGrid(Canvas canvas, Size size) {
    final random = math.Random(7);
    const chalks = <Color>[
      Color(0xFFE7E2D2),
      Color(0xFF8EC8FF),
      Color(0xFFE7A4C4),
      Color(0xFFB6E2A1),
    ];
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 18; i++) {
      final color = chalks[i % chalks.length];
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final len = 26 + random.nextDouble() * 68;
      final angle = random.nextDouble() * math.pi;
      final wobble = random.nextDouble() * 16 - 8;
      stroke
        ..color = color.withValues(alpha: 0.32 + random.nextDouble() * 0.22)
        ..strokeWidth = 2.6 + random.nextDouble() * 2.8;
      canvas.drawPath(
        Path()
          ..moveTo(x, y)
          ..quadraticBezierTo(
            x + math.cos(angle) * len * 0.5 + wobble,
            y + math.sin(angle) * len * 0.5 - wobble,
            x + math.cos(angle) * len,
            y + math.sin(angle) * len,
          ),
        stroke,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x + wobble, y),
          width: 22 + random.nextDouble() * 34,
          height: 8 + random.nextDouble() * 12,
        ),
        Paint()
          ..color = color.withValues(alpha: 0.07 + random.nextDouble() * 0.06),
      );
    }
    final dust = Paint();
    for (var i = 0; i < 64; i++) {
      dust.color = chalks[i % chalks.length].withValues(
        alpha: 0.16 + random.nextDouble() * 0.26,
      );
      canvas.drawCircle(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        0.7 + random.nextDouble() * 2.3,
        dust,
      );
    }
  }

  void _hazardStripe(Canvas canvas, Size size) {
    final stripe = Paint()..color = palette.primary.withValues(alpha: 0.08);
    const band = 72.0;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final span = size.width + size.height;
    for (var x = -size.height; x < span; x += band * 2) {
      final path = Path()
        ..moveTo(x, 0)
        ..lineTo(x + band, 0)
        ..lineTo(x + band - size.height, size.height)
        ..lineTo(x - size.height, size.height)
        ..close();
      canvas.drawPath(path, stripe);
    }
    canvas.restore();
  }

  void _signalSweep(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = palette.primary.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (var x = 0.0; x <= size.width; x += 48) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    final phase = _t * math.pi * 2;
    final y = size.height * (0.5 + 0.5 * math.sin(phase));
    final glow = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          palette.primary.withValues(alpha: 0),
          palette.primary.withValues(alpha: 0.28),
          palette.primary.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(0, y - 56, size.width, 112));
    canvas.drawRect(Rect.fromLTWH(0, y - 56, size.width, 112), glow);
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      Paint()
        ..color = palette.primary.withValues(alpha: 0.7)
        ..strokeWidth = 1.5,
    );
  }

  void _emberDrift(Canvas canvas, Size size) {
    final angle = _t * math.pi * 2;
    _glow(
      canvas,
      Offset(size.width * (0.5 + 0.06 * math.cos(angle)), size.height * 0.9),
      size.shortestSide * 0.38,
      palette.primary,
      strength: 0.2,
    );
    _glow(
      canvas,
      Offset(size.width * (0.24 + 0.05 * math.sin(angle)), size.height * 0.82),
      size.shortestSide * 0.2,
      palette.blue,
      strength: 0.14,
    );

    for (var i = 0; i < 46; i++) {
      final column = ((i * 97) % 1000) / 1000.0;
      final stagger = ((i * 53) % 100) / 100.0;
      final speed = 0.85 + (i % 6) * 0.18;
      final rise = (stagger + _t * speed) % 1.0;
      final sway = math.sin(angle * 0.8 + i * 0.7) * size.width * 0.016;
      final x = column * size.width + sway;
      final y = size.height * (1 - rise);
      final life = math.sin(rise * math.pi);
      final alpha = 0.12 + 0.7 * life;
      final hot = i % 4 == 0;
      final color = hot ? palette.primary : palette.blue;
      canvas.drawCircle(
        Offset(x, y),
        hot ? 2.15 : 1.15,
        Paint()..color = color.withValues(alpha: alpha),
      );
      canvas.drawLine(
        Offset(x, y + (7 + (i % 4) * 3) * (1.15 - rise)),
        Offset(x, y),
        Paint()
          ..color = color.withValues(alpha: alpha * 0.55)
          ..strokeWidth = 1.15
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _deepOcean(Canvas canvas, Size size) {
    final phase = _t * math.pi * 2;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            palette.primary.withValues(alpha: 0.09),
            palette.blue.withValues(alpha: 0.03),
            palette.primary.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.2, 0.5],
        ).createShader(Offset.zero & size),
    );
    final shaft = Paint()..color = palette.foreground.withValues(alpha: 0.035);
    for (var i = 0; i < 4; i++) {
      final x = size.width * (0.16 + i * 0.2) + math.sin(phase + i) * 10;
      final path = Path()
        ..moveTo(x, size.height * 0.08)
        ..lineTo(x + 26, size.height * 0.08)
        ..lineTo(x + 64, size.height * 0.46)
        ..lineTo(x + 16, size.height * 0.46)
        ..close();
      canvas.drawPath(path, shaft);
    }
    final caustic = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..color = palette.primary.withValues(alpha: 0.14);
    for (var row = 0; row < 5; row++) {
      final y = size.height * (0.62 + row * 0.07);
      final path = Path();
      for (var i = 0; i <= 24; i++) {
        final x = size.width * i / 24;
        final wobble = math.sin(i * 0.7 + phase * 0.8 + row) * 6;
        final point = Offset(x, y + wobble);
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(path, caustic);
    }
    _glow(
      canvas,
      Offset(size.width * 0.5, size.height * 1.02),
      size.width * 0.62,
      palette.blue,
      strength: 0.08,
    );
  }

  void _sakuraBlossom(Canvas canvas, Size size) {
    final phase = _t * math.pi * 2;
    _glow(
      canvas,
      Offset(size.width * 0.84, size.height * 0.82),
      size.shortestSide * 0.38,
      palette.primary,
      strength: 0.09,
    );
    final random = math.Random(11);
    for (var i = 0; i < 16; i++) {
      final baseX = random.nextDouble() * size.width;
      final baseY = size.height * (0.42 + random.nextDouble() * 0.5);
      final drift = (phase * (0.12 + (i % 5) * 0.03) + i * 0.17) % 1.0;
      final x = (baseX + math.sin(phase + i) * 18) % size.width;
      final y = baseY + drift * 14;
      final petal = palette.primary.withValues(alpha: 0.10 + (i % 3) * 0.04);
      _petal(canvas, Offset(x, y), 4.5 + (i % 4), petal, phase * 0.4 + i);
    }
  }

  void _petal(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    double angle,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final path = Path()
      ..moveTo(0, -radius)
      ..quadraticBezierTo(radius * 0.85, -radius * 0.15, 0, radius)
      ..quadraticBezierTo(-radius * 0.85, -radius * 0.15, 0, -radius)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.restore();
  }

  void _knurl(Canvas canvas, Size size) {
    final groove = Paint()
      ..color = palette.blue.withValues(alpha: 0.08)
      ..strokeWidth = 1.35;
    final tooth = Paint()
      ..color = palette.primary.withValues(alpha: 0.2)
      ..strokeWidth = 1.05;
    const gap = 18.0;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final span = size.width + size.height;
    for (var i = -size.height; i < span; i += gap) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        groove,
      );
      canvas.drawLine(
        Offset(i, 0),
        Offset(i - size.height, size.height),
        tooth,
      );
    }
    canvas.restore();
  }

  void _cosmicMoon(Canvas canvas, Size size) {
    final random = math.Random(19);
    for (var i = 0; i < 72; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final phase = random.nextDouble() * math.pi * 2;
      final rate = 5 + (i % 5) * 1.7;
      final twinkle = 0.5 + 0.5 * math.sin(_t * math.pi * 2 * rate + phase);
      final bright = i % 9 == 0;
      final alpha = 0.1 + twinkle * (bright ? 0.7 : 0.38);
      final color = i % 6 == 0 ? palette.primary : palette.foreground;
      canvas.drawCircle(
        Offset(x, y),
        bright ? 1.7 : 0.65 + (i % 4) * 0.28,
        Paint()..color = color.withValues(alpha: alpha),
      );
    }

    final moonR = math.min(
      math.max(18.0, size.shortestSide * 0.085),
      size.height * 0.16,
    );
    // The backdrop is the full screen, including the band the Lift tab covers
    // with the shell header and the pinned date/icon row. Keep the disc below
    // that chrome. Short preview swatches use a fraction so the moon still fits.
    const liftChrome = 230.0;
    final clearance = size.height < 480 ? size.height * 0.30 : liftChrome;
    final minCy = moonR + 4;
    final maxCy = math.max(minCy, size.height - moonR - 4);
    final cy = (clearance + moonR + 10).clamp(minCy, maxCy).toDouble();
    final maxCx = math.max(moonR + 4, size.width - moonR - 4);
    final cx = (size.width * 0.74).clamp(moonR + 4, maxCx).toDouble();
    final moonCenter = Offset(cx, cy);
    _glow(canvas, moonCenter, moonR * 3.2, palette.primary, strength: 0.16);
    canvas.drawCircle(
      moonCenter,
      moonR,
      Paint()..color = palette.foreground.withValues(alpha: 0.92),
    );
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: moonCenter, radius: moonR)),
    );
    canvas.drawCircle(
      moonCenter.translate(moonR * 0.45, -moonR * 0.08),
      moonR * 0.88,
      Paint()..color = palette.canvas,
    );
    canvas.restore();
    canvas.drawCircle(
      moonCenter.translate(-moonR * 0.28, moonR * 0.1),
      moonR * 0.14,
      Paint()..color = palette.canvas.withValues(alpha: 0.16),
    );
  }

  void _glow(
    Canvas canvas,
    Offset center,
    double radius,
    Color color, {
    double strength = 0.32,
  }) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: strength),
            color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(covariant _LiftBigBackdropPainter oldDelegate) {
    return oldDelegate.palette != palette ||
        oldDelegate.motion != motion ||
        oldDelegate.hint != hint;
  }
}

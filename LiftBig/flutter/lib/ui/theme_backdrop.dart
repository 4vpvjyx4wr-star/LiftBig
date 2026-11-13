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
    if (context.liftBig.backdrop == LiftBigBackdrop.none) return child;
    final secondary = ModalRoute.of(context)?.secondaryAnimation;
    if (secondary == null) return child;
    return AnimatedBuilder(
      animation: secondary,
      builder: (context, child) {
        final covered =
            secondary.status == AnimationStatus.forward ||
            secondary.status == AnimationStatus.completed;
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
      case LiftBigBackdrop.barPath:
        _barPath(canvas, target);
      case LiftBigBackdrop.rackGlow:
        _rackGlow(canvas, target);
      case LiftBigBackdrop.knurl:
        _knurl(canvas, target);
    }
    canvas.restore();
  }

  void _plateStack(Canvas canvas, Size size) {
    const stepX = 176.0;
    const stepY = 92.0;
    final iron = palette.foreground.withValues(alpha: 0.16);
    final accent = palette.primary.withValues(alpha: 0.42);
    final barPaint = Paint()
      ..color = palette.foreground.withValues(alpha: 0.18);
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
          Paint()..color = palette.blue.withValues(alpha: 0.45),
        );
      }
    }
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
    final line = Paint()
      ..color = palette.foreground.withValues(alpha: 0.14)
      ..strokeWidth = 1.25;
    const gap = 36.0;
    for (var x = 0.0; x <= size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (var y = 0.0; y <= size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    final dust = Paint()..color = palette.primary.withValues(alpha: 0.22);
    final random = math.Random(7);
    for (var i = 0; i < 48; i++) {
      canvas.drawCircle(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        1 + random.nextDouble() * 1.8,
        dust,
      );
    }
  }

  void _hazardStripe(Canvas canvas, Size size) {
    final stripe = Paint()..color = palette.primary.withValues(alpha: 0.2);
    const band = 22.0;
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
    final y = size.height * (0.5 + 0.46 * math.sin(phase));
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
      Offset(
        size.width * (0.28 + 0.16 * math.cos(angle)),
        size.height * (0.32 + 0.12 * math.sin(angle)),
      ),
      size.shortestSide * 0.46,
      palette.primary,
    );
    _glow(
      canvas,
      Offset(
        size.width * (0.72 + 0.12 * math.sin(angle * 0.85)),
        size.height * (0.64 + 0.14 * math.cos(angle * 0.85)),
      ),
      size.shortestSide * 0.4,
      palette.blue,
    );
    _glow(
      canvas,
      Offset(
        size.width * (0.48 + 0.18 * math.cos(angle * 0.6 + 1.4)),
        size.height * (0.18 + 0.1 * math.sin(angle * 0.6 + 1.4)),
      ),
      size.shortestSide * 0.32,
      palette.primary,
    );
  }

  void _barPath(Canvas canvas, Size size) {
    final upright = Paint()..color = palette.foreground.withValues(alpha: 0.1);
    for (final x in [size.width * 0.16, size.width * 0.84]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height * 0.08, 4, size.height * 0.84),
          const Radius.circular(2),
        ),
        upright,
      );
    }
    final phase = _t * math.pi * 2;
    final center = Offset(
      size.width * (0.5 + 0.22 * math.sin(phase)),
      size.height * (0.62 + 0.16 * math.sin(phase * 2)),
    );
    _glow(canvas, center, size.shortestSide * 0.22, palette.primary);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: size.width * 0.58, height: 7),
        const Radius.circular(4),
      ),
      Paint()..color = palette.primary.withValues(alpha: 0.72),
    );
    _disc(
      canvas,
      Offset(center.dx - size.width * 0.24, center.dy),
      28,
      palette.blue.withValues(alpha: 0.45),
    );
    _disc(
      canvas,
      Offset(center.dx + size.width * 0.24, center.dy),
      28,
      palette.blue.withValues(alpha: 0.45),
    );
  }

  void _rackGlow(Canvas canvas, Size size) {
    final phase = _t * math.pi * 2;
    final pulse = 0.5 + 0.5 * math.sin(phase);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.16, size.width, 3),
      Paint()..color = palette.primary.withValues(alpha: 0.16 + 0.12 * pulse),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.78, size.width, 3),
      Paint()..color = palette.blue.withValues(alpha: 0.14),
    );
    _glow(
      canvas,
      Offset(size.width * 0.5, size.height * 0.38),
      size.shortestSide * (0.4 + 0.08 * pulse),
      palette.primary,
    );
    _glow(
      canvas,
      Offset(
        size.width * (0.3 + 0.04 * math.sin(phase + 1.1)),
        size.height * 0.7,
      ),
      size.shortestSide * (0.28 + 0.05 * math.cos(phase)),
      palette.blue,
    );
  }

  void _knurl(Canvas canvas, Size size) {
    final line = Paint()
      ..color = palette.foreground.withValues(alpha: 0.16)
      ..strokeWidth = 1.1;
    const gap = 16.0;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final span = size.width + size.height;
    for (var i = -size.height; i < span; i += gap) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), line);
      canvas.drawLine(Offset(i, 0), Offset(i - size.height, size.height), line);
    }
    canvas.restore();
  }

  void _glow(Canvas canvas, Offset center, double radius, Color color) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [color.withValues(alpha: 0.32), color.withValues(alpha: 0)],
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

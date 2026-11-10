import 'package:flutter/material.dart';

import '../theme.dart';
import '../utils/plates.dart';
import '../utils/weight_units.dart';

/// Barbell or sled loaded with the same plates on each side.
///
/// [compact] is the set-row size. The plate calculator uses the full size.
class PlateLoadGraphic extends StatelessWidget {
  const PlateLoadGraphic({
    super.key,
    required this.plates,
    required this.unit,
    this.centerLabel = 'BAR',
    this.compact = false,
  });

  final List<double> plates;
  final WeightUnit unit;

  /// Short name on the sleeve, such as `BAR` or `SLED`.
  final String centerLabel;
  final bool compact;

  static const _full = _PlateGraphicScale(
    collarWidth: 12,
    collarHeight: 46,
    sleeveWidth: 72,
    sleeveHeight: 16,
    sleeveFont: 9,
    plateWidth: 30,
    plateBase: 32,
    plateSpan: 70,
    plateFont: 12,
    gap: 2,
    maxShown: 8,
  );

  static const _compact = _PlateGraphicScale(
    collarWidth: 6,
    collarHeight: 22,
    sleeveWidth: 36,
    sleeveHeight: 10,
    sleeveFont: 7,
    plateWidth: 16,
    plateBase: 16,
    plateSpan: 30,
    plateFont: 8,
    gap: 1,
    maxShown: 6,
  );

  @override
  Widget build(BuildContext context) {
    final scale = compact ? _compact : _full;
    final sleeveWidth = centerLabel == 'BAR'
        ? scale.sleeveWidth
        : scale.sleeveWidth + (compact ? 8 : 12);
    final shown = plates.take(scale.maxShown).toList();
    final overflow = plates.length - shown.length;
    final left = shown.reversed.toList();
    final empty = shown.isEmpty;
    final semantic = empty
        ? (centerLabel == 'BAR' ? 'Bar only' : 'Sled only')
        : 'Plates per side: ${shown.map((plate) => plateFaceLabel(plate, unit)).join(', ')}';

    return Semantics(
      label: semantic,
      child: Container(
        width: compact ? null : double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 0 : 12,
          vertical: compact ? 2 : 16,
        ),
        decoration: compact
            ? null
            : BoxDecoration(
                color: context.liftBig.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.liftBig.border),
              ),
        child: Column(
          crossAxisAlignment: compact
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: compact ? Alignment.centerLeft : Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _Collar(scale: scale),
                  for (final plate in left)
                    _PlateDisc(weightLb: plate, unit: unit, scale: scale),
                  _CarrierSleeve(
                    label: centerLabel,
                    width: sleeveWidth,
                    scale: scale,
                  ),
                  for (final plate in shown)
                    _PlateDisc(weightLb: plate, unit: unit, scale: scale),
                  _Collar(scale: scale),
                ],
              ),
            ),
            if (overflow > 0) ...[
              const SizedBox(height: 8),
              Text(
                '+$overflow more',
                style: TextStyle(
                  color: context.liftBig.muted,
                  fontSize: compact ? 11 : 12,
                ),
              ),
            ] else if (empty) ...[
              const SizedBox(height: 8),
              Text(
                centerLabel == 'BAR'
                    ? 'Just the bar — no plates needed'
                    : 'Just the sled — no plates needed',
                style: TextStyle(
                  color: context.liftBig.muted,
                  fontSize: compact ? 12 : 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String plateFaceLabel(double weightLb, WeightUnit unit) {
  return lbsToDisplayWeightString(weightLb, unit);
}

Color plateColorForWeight(BuildContext context, double weightLb) {
  final hex = plateColorsLb[weightLb];
  if (hex == null || hex.length < 7) return context.liftBig.primary;
  final value = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
  if (value == null) return context.liftBig.primary;
  return Color(0xFF000000 | value);
}

class _PlateGraphicScale {
  const _PlateGraphicScale({
    required this.collarWidth,
    required this.collarHeight,
    required this.sleeveWidth,
    required this.sleeveHeight,
    required this.sleeveFont,
    required this.plateWidth,
    required this.plateBase,
    required this.plateSpan,
    required this.plateFont,
    required this.gap,
    required this.maxShown,
  });

  final double collarWidth;
  final double collarHeight;
  final double sleeveWidth;
  final double sleeveHeight;
  final double sleeveFont;
  final double plateWidth;
  final double plateBase;
  final double plateSpan;
  final double plateFont;
  final double gap;
  final int maxShown;
}

class _Collar extends StatelessWidget {
  const _Collar({required this.scale});

  final _PlateGraphicScale scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: scale.collarWidth,
      height: scale.collarHeight,
      margin: EdgeInsets.symmetric(horizontal: scale.gap),
      decoration: BoxDecoration(
        color: const Color(0xFF9CA3AF),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class _CarrierSleeve extends StatelessWidget {
  const _CarrierSleeve({
    required this.label,
    required this.width,
    required this.scale,
  });

  final String label;
  final double width;
  final _PlateGraphicScale scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: scale.sleeveHeight,
      alignment: Alignment.center,
      margin: EdgeInsets.symmetric(horizontal: scale.gap),
      decoration: BoxDecoration(
        color: const Color(0xFF6B7280),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: const Color(0xFFD1D5DB),
          fontSize: scale.sleeveFont,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _PlateDisc extends StatelessWidget {
  const _PlateDisc({
    required this.weightLb,
    required this.unit,
    required this.scale,
  });

  final double weightLb;
  final WeightUnit unit;
  final _PlateGraphicScale scale;

  @override
  Widget build(BuildContext context) {
    final color = plateColorForWeight(context, weightLb);
    final ink = color.computeLuminance() > 0.62
        ? const Color(0xFF111827)
        : Colors.white;
    final height =
        scale.plateBase + (weightLb / 45).clamp(0.12, 1.0) * scale.plateSpan;
    return Container(
      width: scale.plateWidth,
      height: height,
      margin: EdgeInsets.symmetric(horizontal: scale.gap),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.black.withValues(alpha: 0.28)),
      ),
      child: RotatedBox(
        quarterTurns: 1,
        child: Text(
          plateFaceLabel(weightLb, unit),
          maxLines: 1,
          style: TextStyle(
            color: ink,
            fontSize: scale.plateFont,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}

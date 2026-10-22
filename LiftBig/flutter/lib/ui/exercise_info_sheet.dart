import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../catalog/liftbig_catalog.dart';
import '../date_key.dart';
import '../journal/journal_repository.dart';
import '../journal/lift_name_convergence.dart';
import '../progress/exercise_forecast.dart';
import '../progress/lift_progress.dart';
import '../theme.dart';
import '../utils/weight_units.dart';
import '../utils/youtube_video_id.dart';
import 'chart_axis_labels.dart';
import 'exercise_tutorial.dart';
import 'liftbig_sheet.dart';

/// Catalog lift for a logged exercise: library id first, then normalized name.
LibraryLift? catalogLiftForLoggedExercise(
  LiftBigCatalog catalog, {
  required String name,
  String? libraryId,
}) {
  final id = libraryId?.trim();
  if (id != null && id.isNotEmpty) {
    final byId = catalog.liftById(id);
    if (byId != null) return byId;
  }
  final key = normalizeForExerciseMatch(name);
  if (key.isEmpty) return null;
  for (final lift in catalog.lifts) {
    if (normalizeForExerciseMatch(lift.name) == key) return lift;
  }
  return null;
}

Future<void> showExerciseInfoSheet(
  BuildContext context, {
  required JournalRepository journal,
  required String exerciseName,
  String? libraryId,
}) {
  return showLiftBigSheet<void>(
    context,
    backgroundColor: context.liftBig.background,
    builder: (context) {
      return ExerciseInfoSheet(
        journal: journal,
        exerciseName: exerciseName,
        libraryId: libraryId,
      );
    },
  );
}

class ExerciseInfoSheet extends StatefulWidget {
  const ExerciseInfoSheet({
    super.key,
    required this.journal,
    required this.exerciseName,
    this.libraryId,
  });

  final JournalRepository journal;
  final String exerciseName;
  final String? libraryId;

  @override
  State<ExerciseInfoSheet> createState() => _ExerciseInfoSheetState();
}

class _ExerciseInfoSheetState extends State<ExerciseInfoSheet> {
  var _loading = true;
  List<LiftSessionPoint> _sessions = const [];
  List<PredictedLiftSession> _forecast = const [];
  var _unit = WeightUnit.lb;
  LibraryLift? _lift;
  String? _historyError;
  String? _libraryNote;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    List<LiftSessionPoint> sessions = const [];
    List<PredictedLiftSession> forecast = const [];
    var unit = WeightUnit.lb;
    LibraryLift? lift;
    String? historyError;
    String? libraryNote;

    try {
      final days = await widget.journal.allDays();
      unit = await widget.journal.storedWeightUnit();
      sessions = collectSameLiftHistory(
        days,
        name: widget.exerciseName,
        libraryId: widget.libraryId,
      );
      forecast = predictFutureLiftSessions(
        exerciseName: widget.exerciseName,
        history: historySetsForLoggedLift(
          days,
          exerciseName: widget.exerciseName,
          libraryId: widget.libraryId,
        ),
      );
    } catch (_) {
      historyError = 'Could not load lift history.';
    }

    try {
      final catalog = await LiftBigCatalog.load();
      lift = catalogLiftForLoggedExercise(
        catalog,
        name: widget.exerciseName,
        libraryId: widget.libraryId,
      );
      if (lift == null) {
        libraryNote = 'Instructions are not in the library.';
      }
    } catch (_) {
      libraryNote = 'Could not load the library.';
    }

    if (!mounted) return;
    setState(() {
      _sessions = sessions;
      _forecast = forecast;
      _unit = unit;
      _lift = lift;
      _historyError = historyError;
      _libraryNote = libraryNote;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final lift = _lift;
    final tutorialUrl = lift?.tutorialUrl.trim() ?? '';
    final tutorialVideoId = youtubeVideoIdFromUrl(tutorialUrl);
    final unitLabel = _unit == WeightUnit.lb ? 'lb' : 'kg';
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SheetHeader(title: widget.exerciseName),
              Flexible(
                child: ListView(
                  primary: false,
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else ...[
                      Text(
                        'Heaviest working set ($unitLabel)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                       Text(
                        'Warmup sets stay in the log and do not move this chart.',
                        style: TextStyle(
                          color: context.liftBig.muted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_historyError != null)
                        Text(
                          _historyError!,
                          style:  TextStyle(color: context.liftBig.muted),
                        )
                      else if (_sessions.isEmpty)
                         Text(
                          'No working sets logged for this lift yet.',
                          style: TextStyle(color: context.liftBig.muted),
                        )
                      else
                        _HeaviestSetChart(
                          sessions: _sessions,
                          forecast: _forecast,
                          unit: _unit,
                        ),
                      if (_libraryNote != null) ...[
                        const SizedBox(height: 20),
                        Text(
                          _libraryNote!,
                          style:  TextStyle(color: context.liftBig.muted),
                        ),
                      ],
                      if (lift != null && _hasWrittenInstructions(lift)) ...[
                        const SizedBox(height: 20),
                        const Text(
                          'How to perform it',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (lift.summary.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(lift.summary.trim()),
                          ),
                        for (final entry in _numbered(lift.instructions))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text('${entry.$1}. ${entry.$2}'),
                          ),
                      ],
                      if (lift != null && _nonEmpty(lift.cues).isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Cues',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (final cue in _nonEmpty(lift.cues))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text('• $cue'),
                          ),
                      ],
                      if (lift != null && _nonEmpty(lift.tips).isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Tips',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (final tip in _nonEmpty(lift.tips))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text('• $tip'),
                          ),
                      ],
                      if (tutorialVideoId != null) ...[
                        const SizedBox(height: 20),
                        const Text(
                          'Tutorial',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ExerciseTutorial(
                          url: tutorialUrl,
                          videoId: tutorialVideoId,
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.liftBig.background,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          const _SheetHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 4, 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style:  TextStyle(
                      color: context.liftBig.foreground,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  visualDensity: VisualDensity.compact,
                  color: context.liftBig.foreground,
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: context.liftBig.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

bool _hasWrittenInstructions(LibraryLift lift) {
  return lift.summary.trim().isNotEmpty ||
      _nonEmpty(lift.instructions).isNotEmpty;
}

List<String> _nonEmpty(List<String> lines) {
  return [
    for (final line in lines)
      if (line.trim().isNotEmpty) line.trim(),
  ];
}

List<(int, String)> _numbered(List<String> lines) {
  final kept = _nonEmpty(lines);
  return [for (var i = 0; i < kept.length; i++) (i + 1, kept[i])];
}

class _HeaviestSetChart extends StatelessWidget {
  const _HeaviestSetChart({
    required this.sessions,
    required this.forecast,
    required this.unit,
  });

  final List<LiftSessionPoint> sessions;
  final List<PredictedLiftSession> forecast;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final pastSpots = <FlSpot>[
      for (var i = 0; i < sessions.length; i++)
        FlSpot(i.toDouble(), _displayWeight(sessions[i].maxWeightLbs, unit)),
    ];
    final futureSpots = <FlSpot>[
      if (forecast.isNotEmpty && sessions.isNotEmpty)
        FlSpot(
          (sessions.length - 1).toDouble(),
          _displayWeight(sessions.last.maxWeightLbs, unit),
        ),
      for (var i = 0; i < forecast.length; i++)
        FlSpot(
          (sessions.length + i).toDouble(),
          _displayWeight(forecast[i].weightLbs, unit),
        ),
    ];
    final ys = <double>[
      for (final spot in pastSpots) spot.y,
      for (final spot in futureSpots) spot.y,
    ];
    final minValue = ys.reduce(math.min);
    final maxValue = ys.reduce(math.max);
    final span = maxValue - minValue;
    final pad = span == 0 ? math.max(maxValue * 0.15, 1) : span * 0.25;
    final minY = math.max(0, minValue - pad).toDouble();
    final maxY = (maxValue + pad).toDouble();
    final yInterval = _axisInterval(minY, maxY);
    final lastX = sessions.length + forecast.length - 1;
    final single = lastX == 0;
    final showDots = sessions.length + forecast.length <= 24;
    final pointCount = sessions.length + forecast.length;
    var measuredAxisWidth = double.nan;
    var visibleLabels = <int>{};

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.liftBig.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.liftBig.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 180,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 12, 4),
              child: LineChart(
                LineChartData(
                  minX: single ? -1 : -0.2,
                  maxX: single ? 1 : lastX + 0.2,
                  minY: minY,
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: yInterval,
                    getDrawingHorizontalLine: (value) =>  FlLine(
                      color: context.liftBig.border,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: yInterval,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            _axisNumber(value, unit),
                            style:  TextStyle(
                              color: context.liftBig.muted,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          if (meta.parentAxisSize != measuredAxisWidth) {
                            measuredAxisWidth = meta.parentAxisSize;
                            visibleLabels = chartAxisLabelIndices(
                              sessionCount: sessions.length,
                              forecastCount: forecast.length,
                              pixelsPerIndex: chartPixelsPerIndex(
                                axisWidth: meta.parentAxisSize,
                                pointCount: pointCount,
                              ),
                              labelWidth: (index) =>
                                  chartAxisLabelWidth(_labelText(index)),
                            ).toSet();
                          }
                          return _axisLabel(context, value, visibleLabels);
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      maxContentWidth: 180,
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipColor: (spot) => context.liftBig.cardInner,
                      getTooltipItems: (touched) {
                        return [for (final spot in touched) _tooltip(context, spot)];
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: pastSpots,
                      isCurved: sessions.length > 2,
                      preventCurveOverShooting: true,
                      color: context.liftBig.foreground,
                      barWidth: 2,
                      dotData: FlDotData(show: showDots),
                      belowBarData: BarAreaData(
                        show: true,
                        color: context.liftBig.foreground.withValues(alpha: 0.12),
                      ),
                    ),
                    if (futureSpots.length > 1)
                      LineChartBarData(
                        spots: futureSpots,
                        isCurved: forecast.length > 2,
                        preventCurveOverShooting: true,
                        color: context.liftBig.primary,
                        barWidth: 2,
                        dashArray: const [6, 4],
                        dotData: FlDotData(
                          show: showDots,
                          checkToShowDot: (spot, bar) =>
                              spot.x.round() >= sessions.length,
                        ),
                        belowBarData: BarAreaData(show: false),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (forecast.isNotEmpty)
             Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Row(
                children: [
                  _LegendSwatch(color: context.liftBig.foreground),
                  SizedBox(width: 6),
                  Text(
                    'Past',
                    style: TextStyle(color: context.liftBig.muted, fontSize: 12),
                  ),
                  SizedBox(width: 14),
                  _DashedLegendSwatch(),
                  SizedBox(width: 6),
                  Text(
                    'Predicted',
                    style: TextStyle(color: context.liftBig.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _labelText(int index) {
    if (index >= sessions.length) {
      return _futureSessionLabel(index - sessions.length);
    }
    return _shortDate(sessions[index].dateKey);
  }

  Widget _axisLabel(BuildContext context, double value, Set<int> visible) {
    final index = value.round();
    if ((value - index).abs() > 0.01) return const SizedBox.shrink();
    if (!visible.contains(index)) return const SizedBox.shrink();
    final future = index >= sessions.length;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        _labelText(index),
        maxLines: 1,
        softWrap: false,
        style: TextStyle(
          color: future ? context.liftBig.primary : context.liftBig.muted,
          fontSize: 10,
        ),
      ),
    );
  }

  LineTooltipItem? _tooltip(BuildContext context, LineBarSpot spot) {
    final index = spot.x.round();
    if (spot.barIndex == 0) {
      if (index < 0 || index >= sessions.length) return null;
      final session = sessions[index];
      return LineTooltipItem(
        '${formatDisplayDate(session.dateKey)}\n'
        '${formatWeightWithUnit(session.maxWeightLbs, unit)} × ${session.maxReps}',
         TextStyle(
          color: context.liftBig.foreground,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      );
    }
    final futureIndex = index - sessions.length;
    if (futureIndex < 0 || futureIndex >= forecast.length) return null;
    final point = forecast[futureIndex];
    return LineTooltipItem(
      'Predicted\n'
      '${formatWeightWithUnit(point.weightLbs, unit)} × ${point.reps}',
       TextStyle(
        color: context.liftBig.primary,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    );
  }
}

class _LegendSwatch extends StatelessWidget {
  const _LegendSwatch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 3,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _DashedLegendSwatch extends StatelessWidget {
  const _DashedLegendSwatch();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LegendDash(),
        SizedBox(width: 3),
        _LegendDash(),
        SizedBox(width: 3),
        _LegendDash(),
      ],
    );
  }
}

class _LegendDash extends StatelessWidget {
  const _LegendDash();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 3,
      decoration: BoxDecoration(
        color: context.liftBig.primary,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

String _futureSessionLabel(int index) {
  if (index <= 0) return 'Next';
  return '+${index + 1}';
}

double _displayWeight(double lbs, WeightUnit unit) {
  return unit == WeightUnit.lb ? lbs : lbsToKg(lbs);
}

String _axisNumber(double value, WeightUnit unit) {
  if (unit == WeightUnit.lb || value == value.roundToDouble()) {
    return value.round().toString();
  }
  return value.toStringAsFixed(1);
}

double _axisInterval(double minY, double maxY) {
  final span = maxY - minY;
  if (span <= 0) return 1;
  final rough = span / 4;
  final magnitude = math
      .pow(10, (math.log(rough) / math.ln10).floor())
      .toDouble();
  if (magnitude == 0) return 1;
  final residual = rough / magnitude;
  final nice = residual >= 5
      ? 5
      : residual >= 2
      ? 2
      : 1;
  final interval = nice * magnitude;
  return interval == 0 ? 1 : interval;
}

String _shortDate(String dateKey) {
  final parts = dateKey.split('-');
  if (parts.length != 3) return dateKey;
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (month == null || day == null) return dateKey;
  return '$month/$day';
}

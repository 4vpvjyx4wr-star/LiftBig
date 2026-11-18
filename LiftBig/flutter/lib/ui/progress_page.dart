import 'package:flutter/material.dart';

import '../catalog/liftbig_catalog.dart';
import '../date_key.dart';
import '../health/body_weight_health.dart';
import '../journal/body_weight_settings.dart';
import '../journal/journal_repository.dart';
import '../progress/lift_progress.dart';
import '../theme.dart';
import 'liftbig_sheet.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key, required this.journal, this.refreshToken = 0});

  final JournalRepository journal;
  final int refreshToken;

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  List<LiftSeries> _series = const [];
  Set<String> _earned = const {};
  List<GoalProgress> _upcoming = const [];
  TrainingSnapshot? _snapshot;
  List<BodyWeightPoint> _weights = const [];
  List<StepDay> _steps = const [];
  String? _selected;
  var _loaded = false;
  var _healthOn = false;
  var _showLocked = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(ProgressPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) _load();
  }

  Future<void> _load() async {
    final days = await widget.journal.allDays();
    if (!mounted) return;
    List<LibraryLift> lifts = const [];
    try {
      lifts = (await LiftBigCatalog.load()).lifts;
    } catch (_) {}
    if (!mounted) return;
    final service = BodyWeightSettingsService(journal: widget.journal);
    var healthOn = false;
    var weights = const <BodyWeightPoint>[];
    var steps = const <StepDay>[];
    try {
      healthOn = await widget.journal.appleHealthSyncEnabled();
      weights = await service.importWeightHistory();
      if (healthOn) steps = await service.loadRecentSteps();
    } catch (_) {}
    if (!mounted) return;
    final series = strengthSeries(days, lifts: lifts);
    setState(() {
      _series = series;
      _earned = unlockedAchievements(days);
      _upcoming = upcomingTrainingGoals(days);
      _snapshot = trainingSnapshot(days);
      _weights = weights;
      _steps = steps;
      _healthOn = healthOn;
      _selected = series.any((item) => item.name == _selected)
          ? _selected
          : (series.isEmpty ? null : series.first.name);
      _loaded = true;
    });
  }

  Future<void> _pickLift(BuildContext context) async {
    final picked = await showLiftBigSheet<String>(
      context,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'Lifts Over Time',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          for (final item in _series)
            ListTile(
              title: Text(item.name),
              subtitle: Text(
                '${item.latestCompleted ? 'Completed' : 'Not completed'}'
                ' · ${item.sessions.length} ${item.sessions.length == 1 ? 'time' : 'times'}.',
              ),
              trailing: item.name == _selected
                  ? Icon(Icons.check, color: context.liftBig.primary)
                  : null,
              onTap: () => Navigator.of(context).pop(item.name),
            ),
        ],
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _selected = picked);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Center(child: CircularProgressIndicator());
    }
    LiftSeries? selected;
    for (final item in _series) {
      if (item.name == _selected) selected = item;
    }
    final earned = [
      for (final item in achievements)
        if (_earned.contains(item.id)) item,
    ];
    final locked = [
      for (final item in achievements)
        if (!_earned.contains(item.id)) item,
    ];
    final shownUpcoming = _upcoming;
    final upcomingIds = {for (final goal in shownUpcoming) goal.achievement.id};
    final otherLocked = [
      for (final item in locked)
        if (!upcomingIds.contains(item.id)) item,
    ];
    final snapshot = _snapshot;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (snapshot != null) _Headline(snapshot: snapshot),
        if (snapshot != null && snapshot.trainedDays == 0) ...[
          const SizedBox(height: 12),
          Text(
            'Your numbers start with a working set. A plan on the Plans tab sets up the next one.',
            style: TextStyle(color: context.liftBig.muted, height: 1.35),
          ),
        ],
        const SizedBox(height: 16),
        _BodyCard(weights: _weights, steps: _steps, healthOn: _healthOn),
        const SizedBox(height: 16),
        _LiftCard(
          series: _series,
          selected: selected,
          onPick: () => _pickLift(context),
        ),
        const SizedBox(height: 20),
        Text(
          'Badges · ${earned.length} of ${achievements.length}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        if (earned.isEmpty)
          Text(
            'None earned yet. A logged working day unlocks the first one.',
            style: TextStyle(color: context.liftBig.muted),
          )
        else
          _Card(
            child: Column(
              children: [
                for (var i = 0; i < earned.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  _AchievementTile(item: earned[i], earned: true),
                ],
              ],
            ),
          ),
        const SizedBox(height: 16),
        const Text(
          "What's next",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        if (shownUpcoming.isEmpty)
          Text(
            'Every goal on this list is earned.',
            style: TextStyle(color: context.liftBig.muted),
          )
        else
          _Card(
            child: Column(
              children: [
                for (var i = 0; i < shownUpcoming.length; i++) ...[
                  if (i > 0) const SizedBox(height: 14),
                  _GoalRow(goal: shownUpcoming[i]),
                ],
              ],
            ),
          ),
        if (otherLocked.isNotEmpty) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => setState(() => _showLocked = !_showLocked),
              child: Text(
                _showLocked ? 'Hide the rest' : 'See every locked goal',
              ),
            ),
          ),
          if (_showLocked)
            for (final item in otherLocked)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _AchievementTile(item: item, earned: false),
              ),
        ],
      ],
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.snapshot});

  final TrainingSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final current = snapshot.currentStreak;
    final next = snapshot.nextStreakGoal;
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final previous = snapshot.previousWeekVolumeLb;
    final delta = previous == null ? null : snapshot.weekVolumeLb - previous;
    final records = <String>[
      if (snapshot.benchLb > 0) 'Bench ${snapshot.benchLb.toStringAsFixed(0)}',
      if (snapshot.squatLb > 0) 'Squat ${snapshot.squatLb.toStringAsFixed(0)}',
      if (snapshot.deadliftLb > 0)
        'Deadlift ${snapshot.deadliftLb.toStringAsFixed(0)}',
      if (snapshot.heaviest != null)
        '${snapshot.heaviest!.name} ${snapshot.heaviest!.weightLb.toStringAsFixed(0)}',
    ];
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            current == 0 ? 'Train today to start a streak.' : '$current',
            style: TextStyle(
              fontSize: current == 0 ? 22 : 44,
              fontWeight: FontWeight.w800,
              color: context.liftBig.primary,
              height: 1.05,
            ),
          ),
          if (current > 0)
            Text(
              current == 1 ? 'day streak' : 'days streak',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          const SizedBox(height: 4),
          Text(
            'Longest ${snapshot.longestStreak}'
            ' · ${snapshot.trainedDays} trained days'
            ' · ${snapshot.totalVolumeLb.toStringAsFixed(0)} lb moved',
            style: TextStyle(color: context.liftBig.muted),
          ),
          if (next != null) ...[
            const SizedBox(height: 10),
            Text(
              '$current of $next days',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: next == 0 ? 0 : (current / next).clamp(0, 1),
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
              color: context.liftBig.primary,
              backgroundColor: context.liftBig.border,
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'This week',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Center(
                    child: Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: snapshot.weekTrained[i]
                            ? context.liftBig.primary
                            : context.liftBig.background,
                        shape: BoxShape.circle,
                        border: Border.all(color: context.liftBig.border),
                      ),
                      child: Text(
                        labels[i],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: snapshot.weekTrained[i]
                              ? context.liftBig.background
                              : context.liftBig.muted,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${snapshot.weekSessions} sessions · ${snapshot.weekSets} sets · ${snapshot.weekVolumeLb.toStringAsFixed(0)} lb',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (delta != null) ...[
            const SizedBox(height: 4),
            Text(
              delta >= 0
                  ? '${delta.toStringAsFixed(0)} lb more than last week'
                  : '${delta.abs().toStringAsFixed(0)} lb less than last week',
              style: TextStyle(color: context.liftBig.muted),
            ),
          ],
          if (records.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final record in records)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: context.liftBig.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.liftBig.border),
                    ),
                    child: Text(
                      record,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _BodyCard extends StatelessWidget {
  const _BodyCard({
    required this.weights,
    required this.steps,
    required this.healthOn,
  });

  final List<BodyWeightPoint> weights;
  final List<StepDay> steps;
  final bool healthOn;

  @override
  Widget build(BuildContext context) {
    final latest = weights.isEmpty ? null : weights.last;
    final stepTotal = steps.fold<int>(0, (sum, day) => sum + day.steps);
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Body',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text(
            latest == null
                ? 'Body weight'
                : 'Body weight · ${latest.lbs.toStringAsFixed(latest.lbs == latest.lbs.roundToDouble() ? 0 : 1)} lb',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (weights.isEmpty)
            Text(
              'Save a body weight in Settings to start this chart.',
              style: TextStyle(color: context.liftBig.muted),
            )
          else
            _BarChart(
              values: [for (final point in weights) point.lbs],
              captions: [
                for (final point in weights) formatDisplayDate(point.dateKey),
              ],
            ),
          const SizedBox(height: 16),
          Text(
            stepTotal == 0 ? 'Steps' : 'Steps · $stepTotal in two weeks',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (!healthOn)
            Text(
              'Turn on Apple Health in Settings to chart steps.',
              style: TextStyle(color: context.liftBig.muted),
            )
          else if (stepTotal == 0)
            Text(
              'No steps in the last two weeks.',
              style: TextStyle(color: context.liftBig.muted),
            )
          else
            _BarChart(
              values: [for (final day in steps) day.steps.toDouble()],
              captions: [
                for (final day in steps)
                  '${formatDisplayDate(day.dateKey)} · ${day.steps}',
              ],
            ),
        ],
      ),
    );
  }
}

class _LiftCard extends StatelessWidget {
  const _LiftCard({
    required this.series,
    required this.selected,
    required this.onPick,
  });

  final List<LiftSeries> series;
  final LiftSeries? selected;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final chosen = selected;
    final best = chosen == null
        ? 0.0
        : chosen.sessions
              .map((point) => point.maxWeightLbs)
              .reduce((a, b) => a > b ? a : b);
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lifts Over Time',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Working sets only. Warmup sets stay in the log and do not move these numbers.',
            style: TextStyle(color: context.liftBig.muted),
          ),
          const SizedBox(height: 12),
          if (series.isEmpty)
            Text(
              'Log a working set to see a lift over time.',
              style: TextStyle(color: context.liftBig.muted),
            )
          else ...[
            Material(
              color: context.liftBig.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: context.liftBig.border),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onPick,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              chosen?.name ?? 'Choose a Lift',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (chosen != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                '${chosen.latestCompleted ? 'Completed' : 'Not completed'}'
                                ' · ${chosen.sessions.length} ${chosen.sessions.length == 1 ? 'time' : 'times'}'
                                ' · best ${best.toStringAsFixed(0)} lb',
                                style: TextStyle(color: context.liftBig.muted),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(Icons.expand_more, color: context.liftBig.primary),
                    ],
                  ),
                ),
              ),
            ),
            if (chosen != null) ...[
              const SizedBox(height: 12),
              _BarChart(
                values: [
                  for (final point in chosen.sessions) point.maxWeightLbs,
                ],
                captions: [
                  for (final point in chosen.sessions)
                    '${formatDisplayDate(point.dateKey)} · ${point.maxWeightLbs.toStringAsFixed(0)} lb',
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({required this.goal});

  final GoalProgress goal;

  @override
  Widget build(BuildContext context) {
    final current = goal.current >= 100
        ? goal.current.toStringAsFixed(0)
        : goal.current.toStringAsFixed(
            goal.current == goal.current.roundToDouble() ? 0 : 1,
          );
    final target = goal.target.toStringAsFixed(0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          goal.achievement.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          goal.achievement.description,
          style: TextStyle(color: context.liftBig.muted),
        ),
        const SizedBox(height: 8),
        Text(
          '$current of $target',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: goal.ratio.toDouble(),
          minHeight: 8,
          borderRadius: BorderRadius.circular(8),
          color: context.liftBig.primary,
          backgroundColor: context.liftBig.border,
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.liftBig.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.liftBig.border),
      ),
      child: child,
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.values, required this.captions});

  final List<double> values;
  final List<String> captions;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();
    var maxValue = 0.0;
    for (final value in values) {
      if (value > maxValue) maxValue = value;
    }
    final shown = values.length > 24
        ? values.sublist(values.length - 24)
        : values;
    final shownCaptions = captions.length == values.length
        ? (captions.length > 24
              ? captions.sublist(captions.length - 24)
              : captions)
        : captions;
    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < shown.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Tooltip(
                  message: i < shownCaptions.length ? shownCaptions[i] : '',
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: maxValue <= 0
                          ? 0
                          : (shown[i] / maxValue).clamp(0.08, 1),
                      widthFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: context.liftBig.primary,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.item, required this.earned});

  final Achievement item;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: earned ? const Color(0xFF163020) : context.liftBig.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: earned ? context.liftBig.success : context.liftBig.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            earned ? Icons.emoji_events : Icons.emoji_events_outlined,
            color: earned ? context.liftBig.success : context.liftBig.muted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: earned
                        ? context.liftBig.foreground
                        : context.liftBig.muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.description,
                  style: TextStyle(color: context.liftBig.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

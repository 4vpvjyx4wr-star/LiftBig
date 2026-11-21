import 'package:flutter/material.dart';

import '../catalog/liftbig_catalog.dart';
import '../date_key.dart';
import '../journal/journal_repository.dart';
import '../progress/lift_progress.dart';
import '../theme.dart';
import '../utils/weight_units.dart';
import 'liftbig_sheet.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({
    super.key,
    required this.journal,
    this.refreshToken = 0,
  });

  final JournalRepository journal;
  final int refreshToken;

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  List<LiftSeries> _series = const [];
  Set<String> _earned = const {};
  TrainingSnapshot? _snapshot;
  String? _selected;
  var _weightUnit = WeightUnit.lb;
  var _loaded = false;
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
    final series = strengthSeries(days, lifts: lifts);
    final weightUnit = await widget.journal.storedWeightUnit();
    if (!mounted) return;
    setState(() {
      _series = series;
      _earned = unlockedAchievements(days);
      _snapshot = trainingSnapshot(days);
      _weightUnit = weightUnit;
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

    final snapshot = _snapshot;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (snapshot != null) ...[
          _StreakCard(snapshot: snapshot),
          const SizedBox(height: 12),
          _WeekCard(snapshot: snapshot, unit: _weightUnit),
          const SizedBox(height: 12),
          _RecordsCard(snapshot: snapshot, unit: _weightUnit),
          if (snapshot.nextGoal != null) ...[
            const SizedBox(height: 12),
            _GoalCard(goal: snapshot.nextGoal!),
          ],
          if (snapshot.trainedDays == 0) ...[
            const SizedBox(height: 12),
            Text(
              'Your numbers start with a working set. A plan on the Plans tab sets up the next one.',
              style: TextStyle(color: context.liftBig.muted, height: 1.35),
            ),
          ],
          const SizedBox(height: 24),
        ],
        const Text(
          'Lifts Over Time',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
         Text(
          'Working sets only. Warmup sets stay in the log and do not move these numbers.',
          style: TextStyle(color: context.liftBig.muted),
        ),
        const SizedBox(height: 12),
        if (_series.isEmpty)
           Text(
            'Log a working set to see a lift over time.',
            style: TextStyle(color: context.liftBig.muted),
          )
        else ...[
          Material(
            color: context.liftBig.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: context.liftBig.border),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _pickLift(context),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selected?.name ?? 'Choose a Lift',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (selected != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              '${selected.latestCompleted ? 'Completed' : 'Not completed'}'
                              ' · ${selected.sessions.length} ${selected.sessions.length == 1 ? 'time' : 'times'}.',
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
          if (selected != null) ...[
            const SizedBox(height: 12),
            _WeightChart(sessions: selected.sessions, unit: _weightUnit),
            const SizedBox(height: 8),
            Text(
              'Best ${formatWeightWithUnit(selected.sessions.map((point) => point.maxWeightLbs).reduce((a, b) => a > b ? a : b), _weightUnit)}'
              ' · ${selected.sessions.length} sessions',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            for (final point in selected.sessions.reversed)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${formatDisplayDate(point.dateKey)} · ${formatWeightWithUnit(point.maxWeightLbs, _weightUnit)}'
                  ' · ${point.setCount} sets · ${point.maxReps} reps'
                  ' · ${formatWeightWithUnit(point.volumeLbs, _weightUnit, maxDecimals: 0)} volume',
                ),
              ),
          ],
        ],
        const SizedBox(height: 24),
        Text(
          'Achievements · ${earned.length} of ${achievements.length}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        if (earned.isEmpty)
           Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'None earned yet. A logged working day unlocks the first one.',
              style: TextStyle(color: context.liftBig.muted),
            ),
          ),
        for (final item in earned) _AchievementTile(item: item, earned: true),
        if (locked.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => setState(() => _showLocked = !_showLocked),
              child: Text(_showLocked ? 'Hide Locked' : 'See All'),
            ),
          ),
        if (_showLocked)
          for (final item in locked) _AchievementTile(item: item, earned: false),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.liftBig.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.liftBig.border),
      ),
      child: child,
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.snapshot});

  final TrainingSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final current = snapshot.currentStreak;
    final next = snapshot.nextStreakGoal;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            current == 0 ? 'Train today to start a streak.' : '$current',
            style: TextStyle(
              fontSize: current == 0 ? 20 : 40,
              fontWeight: FontWeight.w800,
              color: context.liftBig.primary,
              height: 1.1,
            ),
          ),
          if (current > 0)
            Text(
              'day streak',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          const SizedBox(height: 6),
          Text(
            'Longest streak: ${snapshot.longestStreak}',
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
        ],
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.snapshot, required this.unit});

  final TrainingSnapshot snapshot;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final previous = snapshot.previousWeekVolumeLb;
    final delta = previous == null ? null : snapshot.weekVolumeLb - previous;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This Week',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Column(
                    children: [
                      Container(
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
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${snapshot.weekSessions} sessions · ${snapshot.weekSets} sets · ${formatWeightWithUnit(snapshot.weekVolumeLb, unit, maxDecimals: 0)}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (delta != null) ...[
            const SizedBox(height: 4),
            Text(
              delta >= 0
                  ? '${formatWeightWithUnit(delta, unit, maxDecimals: 0)} more than last week'
                  : '${formatWeightWithUnit(delta.abs(), unit, maxDecimals: 0)} less than last week',
              style: TextStyle(color: context.liftBig.muted),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecordsCard extends StatelessWidget {
  const _RecordsCard({required this.snapshot, required this.unit});

  final TrainingSnapshot snapshot;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final lines = <String>[
      if (snapshot.heaviest != null)
        'Heaviest set: ${snapshot.heaviest!.name} ${formatWeightWithUnit(snapshot.heaviest!.weightLb, unit)}',
      if (snapshot.benchLb > 0)
        'Bench ${formatWeightWithUnit(snapshot.benchLb, unit)}',
      if (snapshot.squatLb > 0)
        'Squat ${formatWeightWithUnit(snapshot.squatLb, unit)}',
      if (snapshot.deadliftLb > 0)
        'Deadlift ${formatWeightWithUnit(snapshot.deadliftLb, unit)}',
      '${snapshot.trainedDays} trained days · ${formatWeightWithUnit(snapshot.totalVolumeLb, unit, maxDecimals: 0)} moved',
    ];
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Records',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(line),
            ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal});

  final GoalProgress goal;

  @override
  Widget build(BuildContext context) {
    final current = goal.current >= 100
        ? goal.current.toStringAsFixed(0)
        : goal.current.toStringAsFixed(goal.current == goal.current.roundToDouble() ? 0 : 1);
    final target = goal.target.toStringAsFixed(0);
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Up Next',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            goal.achievement.title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            goal.achievement.description,
            style: TextStyle(color: context.liftBig.muted),
          ),
          const SizedBox(height: 8),
          Text('$current of $target', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: goal.ratio.toDouble(),
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
            color: context.liftBig.primary,
            backgroundColor: context.liftBig.border,
          ),
        ],
      ),
    );
  }
}

class _WeightChart extends StatelessWidget {
  const _WeightChart({required this.sessions, required this.unit});

  final List<LiftSessionPoint> sessions;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final maxWeight = sessions
        .map((point) => point.maxWeightLbs)
        .reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final point in sessions)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Tooltip(
                  message:
                      '${point.dateKey} · ${formatWeightWithUnit(point.maxWeightLbs, unit)}',
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: maxWeight <= 0
                          ? 0
                          : (point.maxWeightLbs / maxWeight).clamp(0.08, 1),
                      widthFactor: 1,
                      child:  DecoratedBox(
                        decoration: BoxDecoration(
                          color: context.liftBig.primary,
                          borderRadius: BorderRadius.vertical(
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: earned ? const Color(0xFF163020) : context.liftBig.card,
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
                    style:  TextStyle(color: context.liftBig.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

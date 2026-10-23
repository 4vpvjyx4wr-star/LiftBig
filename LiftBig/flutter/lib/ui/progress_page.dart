import 'package:flutter/material.dart';

import '../date_key.dart';
import '../journal/journal_repository.dart';
import '../progress/lift_progress.dart';
import '../theme.dart';
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
  String? _selected;
  var _loaded = false;

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
    final series = strengthSeries(days);
    setState(() {
      _series = series;
      _earned = unlockedAchievements(days);
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
              'Lifts over time',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          for (final item in _series)
            ListTile(
              title: Text(item.name),
              subtitle: Text(
                '${item.latestCompleted ? 'Completed' : 'Not completed'}'
                ' · ${item.sessions.length} ${item.sessions.length == 1 ? 'time' : 'times'}',
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const Text(
          'Lifts over time',
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
                            selected?.name ?? 'Choose a lift',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (selected != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              '${selected.latestCompleted ? 'Completed' : 'Not completed'}'
                              ' · ${selected.sessions.length} ${selected.sessions.length == 1 ? 'time' : 'times'}',
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
            _WeightChart(sessions: selected.sessions),
            const SizedBox(height: 8),
            Text(
              'Best ${selected.sessions.map((point) => point.maxWeightLbs).reduce((a, b) => a > b ? a : b).toStringAsFixed(0)} lb'
              ' · ${selected.sessions.length} sessions',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            for (final point in selected.sessions.reversed)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${formatDisplayDate(point.dateKey)} · ${point.maxWeightLbs.toStringAsFixed(0)} lb'
                  ' · ${point.setCount} sets · ${point.volumeLbs.toStringAsFixed(0)} lb volume',
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
        for (final item in locked) _AchievementTile(item: item, earned: false),
      ],
    );
  }
}

class _WeightChart extends StatelessWidget {
  const _WeightChart({required this.sessions});

  final List<LiftSessionPoint> sessions;

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
                      '${point.dateKey} · ${point.maxWeightLbs.toStringAsFixed(0)} lb',
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

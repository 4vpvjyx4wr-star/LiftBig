import 'package:flutter/material.dart';

import '../date_key.dart';
import '../journal/journal_repository.dart';
import '../model/journal_day.dart';
import '../theme.dart';
import 'day_page.dart';
import 'day_transfer.dart';
import 'exercise_info_sheet.dart';
import 'workout_details_section.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.journal,
    this.refreshToken = 0,
    this.focusDateKey,
    this.onOpenSettings,
  });

  final JournalRepository journal;
  final Future<void> Function()? onOpenSettings;

  /// Bumped by the shell after import or when Home is opened again.
  final int refreshToken;

  /// When set, Home selects this day and shows its month.
  final String? focusDateKey;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late DateTime _month;
  late String _selectedKey;
  Map<String, DaySummary> _summaries = {};
  JournalDay? _day;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selectedKey = todayKey(now);
    _reload();
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final focus = widget.focusDateKey;
    if (focus != null &&
        isValidDateKey(focus) &&
        (focus != oldWidget.focusDateKey ||
            oldWidget.refreshToken != widget.refreshToken)) {
      final parsed = parseDateKey(focus);
      _selectedKey = focus;
      _month = DateTime(parsed.year, parsed.month);
    }
    if (oldWidget.refreshToken != widget.refreshToken) _reload();
  }

  Future<void> _reload() async {
    final summaries = await widget.journal.summariesForMonth(_month);
    final day = await widget.journal.getDay(_selectedKey);
    if (!mounted) return;
    setState(() {
      _summaries = {for (final summary in summaries) summary.dateKey: summary};
      _day = day;
    });
  }

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
    });
    _reload();
  }

  void _selectDay(String dateKey) {
    _selectedKey = dateKey;
    _reload();
  }

  Future<void> _openLog() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DayPage(
          journal: widget.journal,
          dateKey: _selectedKey,
          onOpenSettings: widget.onOpenSettings,
        ),
      ),
    );
    if (!mounted) return;
    await _reload();
  }

  Future<void> _copyDay() async {
    final changed = await copyLoggedDay(context, widget.journal, _selectedKey);
    if (changed && mounted) await _reload();
  }

  Future<void> _moveDay() async {
    final changed = await moveLoggedDay(context, widget.journal, _selectedKey);
    if (changed && mounted) await _reload();
  }

  Future<void> _toggleRest(bool rest) async {
    final ok = await widget.journal.setRestDay(_selectedKey, rest: rest);
    if (!mounted) return;
    if (!ok) {
      _snack('This day already has exercises.');
      return;
    }
    await _reload();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _openExerciseInfo(JournalExercise exercise) {
    showExerciseInfoSheet(
      context,
      journal: widget.journal,
      exerciseName: exercise.name,
      libraryId: exercise.libraryId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final first = DateTime(_month.year, _month.month, 1);
    final leading = first.weekday % 7;
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final today = todayKey();

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => _shiftMonth(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  '${monthNames[_month.month - 1]} ${_month.year}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                onPressed: () => _shiftMonth(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              for (final label in weekdayLabels)
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: LiftBigColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (var i = 0; i < leading; i++) const SizedBox.shrink(),
              for (var day = 1; day <= daysInMonth; day++)
                _DayCell(
                  dateKey: toDateKey(DateTime(_month.year, _month.month, day)),
                  selected: toDateKey(DateTime(_month.year, _month.month, day)) ==
                      _selectedKey,
                  today: toDateKey(DateTime(_month.year, _month.month, day)) == today,
                  summary: _summaries[toDateKey(
                    DateTime(_month.year, _month.month, day),
                  )],
                  onTap: () {
                    _selectDay(
                      toDateKey(DateTime(_month.year, _month.month, day)),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          _DayPanel(
            dateKey: _selectedKey,
            day: _day,
            onLog: _openLog,
            onRest: _toggleRest,
            onCopy: _copyDay,
            onMove: _moveDay,
            onExerciseInfo: _openExerciseInfo,
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.dateKey,
    required this.selected,
    required this.today,
    required this.summary,
    required this.onTap,
  });

  final String dateKey;
  final bool selected;
  final bool today;
  final DaySummary? summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dayNumber = int.parse(dateKey.split('-').last);
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        color: selected ? LiftBigColors.primary.withValues(alpha: 0.18) : LiftBigColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: today ? LiftBigColors.primary : LiftBigColors.border,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$dayNumber'),
              const SizedBox(height: 2),
              if (summary?.hasWorkout == true)
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: LiftBigColors.primary,
                    shape: BoxShape.circle,
                  ),
                )
              else if (summary?.isRestDay == true)
                const Text(
                  'R',
                  style: TextStyle(
                    color: LiftBigColors.success,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                )
              else
                const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayPanel extends StatelessWidget {
  const _DayPanel({
    required this.dateKey,
    required this.day,
    required this.onLog,
    required this.onRest,
    required this.onCopy,
    required this.onMove,
    required this.onExerciseInfo,
  });

  final String dateKey;
  final JournalDay? day;
  final VoidCallback onLog;
  final ValueChanged<bool> onRest;
  final VoidCallback onCopy;
  final VoidCallback onMove;
  final ValueChanged<JournalExercise> onExerciseInfo;

  @override
  Widget build(BuildContext context) {
    final exercises = day?.exercises ?? const <JournalExercise>[];
    final workoutNotes = day?.workoutNotes;
    final showRest = exercises.isEmpty;
    final compactActionStyle = OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      minimumSize: const Size(0, 28),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: onLog,
                        child: Text(
                          formatNumericDate(dateKey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (day?.workoutName != null) ...[
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: onLog,
                          child: Text(
                            day!.workoutName!,
                            style: const TextStyle(color: LiftBigColors.primary),
                          ),
                        ),
                      ],
                      if (day?.planName != null)
                        Text(
                          day!.planName!,
                          style: const TextStyle(color: LiftBigColors.muted),
                        ),
                      if (day?.notes != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          day!.notes!,
                          style: const TextStyle(color: LiftBigColors.muted),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 148,
                      height: 60,
                      child: FilledButton(
                        onPressed: onLog,
                        style: FilledButton.styleFrom(
                          backgroundColor: LiftBigColors.primary,
                          foregroundColor: LiftBigColors.foreground,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          minimumSize: const Size(148, 60),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.standard,
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Log'),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton(
                          onPressed: exercises.isEmpty ? null : onCopy,
                          style: compactActionStyle,
                          child: const Text('Copy'),
                        ),
                        const SizedBox(width: 4),
                        OutlinedButton(
                          onPressed: exercises.isEmpty ? null : onMove,
                          style: compactActionStyle,
                          child: const Text('Move'),
                        ),
                      ],
                    ),
                    if (showRest) ...[
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Rest day',
                            style: TextStyle(
                              color: day?.isRestDay == true
                                  ? LiftBigColors.success
                                  : LiftBigColors.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Switch(
                            value: day?.isRestDay == true,
                            activeThumbColor: LiftBigColors.primary,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            onChanged: onRest,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
            if (workoutNotes != null && workoutNotes.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              WorkoutDetailsSection(
                key: ValueKey('workout-notes-$dateKey'),
                text: workoutNotes,
              ),
            ],
            const SizedBox(height: 12),
            if (exercises.isEmpty && day?.isRestDay != true)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Nothing logged.',
                  style: TextStyle(color: LiftBigColors.muted),
                ),
              ),
            for (final exercise in exercises) ...[
              Row(
                children: [
                  Flexible(
                    child: GestureDetector(
                      onTap: onLog,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          exercise.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => onExerciseInfo(exercise),
                    tooltip: 'Exercise info',
                    style: IconButton.styleFrom(
                      foregroundColor: LiftBigColors.primary,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.all(4),
                      minimumSize: const Size(28, 28),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.info_outline, size: 18),
                  ),
                ],
              ),
              if (exercise.notes != null)
                Text(
                  exercise.notes!,
                  style: const TextStyle(color: LiftBigColors.muted),
                ),
              for (final set in exercise.sets)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    _setLine(exercise, set),
                    style: const TextStyle(color: LiftBigColors.foreground),
                  ),
                ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 8),
            FilledButton(
              onPressed: onLog,
              child: Text(exercises.isEmpty ? 'Log workout' : 'Open log'),
            ),
          ],
        ),
      ),
    );
  }
}

String _setLine(JournalExercise exercise, JournalSet set) {
  if (exercise.isCardio && !exercise.isCircuit) {
    final minutes = set.reps.trim().isEmpty ? '—' : '${set.reps.trim()} min';
    final distance = set.weight.trim();
    if (distance.isEmpty) return minutes;
    return '$minutes · $distance';
  }
  if (exercise.isCircuit) {
    final done = set.checked ? 'Done · ' : '';
    final reps = set.reps.trim().isEmpty ? 'AMRAP' : set.reps.trim();
    return '$done Set ${set.sortOrder + 1}  $reps';
  }
  final done = set.checked ? 'Done · ' : '';
  final warmup = set.isWarmup ? 'Warmup · ' : '';
  final reps = set.reps.isEmpty ? '—' : set.reps;
  final weight = set.weight.isEmpty ? '—' : '${set.weight} lb';
  final time = set.durationSeconds?.trim();
  final timeLabel = exercise.isCore && time != null && time.isNotEmpty
      ? ' · $time sec'
      : '';
  return '$done$warmup Set ${set.sortOrder + 1}  $reps × $weight$timeLabel';
}

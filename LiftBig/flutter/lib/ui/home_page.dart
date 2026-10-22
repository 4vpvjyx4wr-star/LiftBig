import 'package:flutter/material.dart';

import '../date_key.dart';
import '../journal/journal_repository.dart';
import '../journal/set_prescription.dart';
import '../model/journal_day.dart';
import '../theme.dart';
import 'assign_plan_sheet.dart';
import 'clear_day.dart';
import 'day_page.dart';
import 'day_transfer.dart';
import 'edit_exercise_sheet.dart';
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

  Future<void> _openLog([String? exerciseId]) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DayPage(
          journal: widget.journal,
          dateKey: _selectedKey,
          onOpenSettings: widget.onOpenSettings,
          initialExerciseId: exerciseId,
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

  Future<void> _clearDay() async {
    final confirmed = await confirmClearDay(context);
    if (!confirmed || !mounted) return;
    try {
      await widget.journal.deleteDay(_selectedKey);
    } catch (error) {
      if (mounted) _snack('$error');
      return;
    }
    if (!mounted) return;
    await _reload();
  }

  Future<void> _editExercise(JournalExercise exercise) async {
    final saved = await showEditExerciseSheet(
      context,
      journal: widget.journal,
      exercise: exercise,
    );
    if (saved && mounted) await _reload();
  }

  Future<void> _assignPlan() async {
    final pick = await showAssignPlanSheet(
      context,
      journal: widget.journal,
    );
    if (pick == null || !mounted) return;
    final existing = _day;
    if (existing != null && existing.exercises.isNotEmpty) {
      final add = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Add to this day?'),
          content: const Text(
            'This day already has exercises. The workout will be added alongside them.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Add'),
            ),
          ],
        ),
      );
      if (add != true || !mounted) return;
    }
    final notes = pick.workout.notes.trim();
    await widget.journal.updateDayHeader(
      _selectedKey,
      workoutName: pick.workout.name,
      setWorkoutName: true,
      planName: pick.planName,
      setPlanName: true,
      workoutNotes: notes,
      setWorkoutNotes: true,
    );
    final prescribeWarmup = await widget.journal.prescribeWarmupEnabled();
    for (final lift in pick.workout.lifts) {
      final prescribed = prescriptionFromCatalogSets([
        for (final set in lift.sets) (reps: set.reps, weight: set.weight),
      ]);
      await widget.journal.addExercise(
        dateKey: _selectedKey,
        name: lift.name,
        libraryId: lift.libraryId,
        isCardio: lift.isCardio,
        isCore: lift.isCore,
        isCircuit: lift.isCircuit,
        prescribeWarmup: prescribeWarmup,
        targetReps: prescribed.targetReps,
        targetWeight: prescribed.targetWeight,
        sets: [
          for (var i = 0; i < prescribed.sets.length; i++)
            JournalSet(
              id: '',
              sortOrder: i,
              reps: prescribed.sets[i].reps,
              weight: prescribed.sets[i].weight,
            ),
        ],
      );
    }
    if (!mounted) return;
    _snack('${pick.workout.name} added.');
    await _reload();
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
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
                    style:  TextStyle(
                      color: context.liftBig.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            // A nested grid with null padding copies the safe-area inset and
            // opens a gap under the weekday labels.
            padding: EdgeInsets.zero,
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
            isToday: _selectedKey == today,
            day: _day,
            onLog: _openLog,
            onRest: _toggleRest,
            onCopy: _copyDay,
            onMove: _moveDay,
            onAssignPlan: _assignPlan,
            onClearDay: _clearDay,
            onEditExercise: _editExercise,
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
        color: selected ? context.liftBig.primary.withValues(alpha: 0.18) : context.liftBig.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: today ? context.liftBig.primary : context.liftBig.border,
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
                  decoration:  BoxDecoration(
                    color: context.liftBig.primary,
                    shape: BoxShape.circle,
                  ),
                )
              else if (summary?.isRestDay == true)
                 Text(
                  'R',
                  style: TextStyle(
                    color: context.liftBig.success,
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
    required this.isToday,
    required this.day,
    required this.onLog,
    required this.onRest,
    required this.onCopy,
    required this.onMove,
    required this.onAssignPlan,
    required this.onClearDay,
    required this.onEditExercise,
    required this.onExerciseInfo,
  });

  final String dateKey;
  final bool isToday;
  final JournalDay? day;
  final void Function([String? exerciseId]) onLog;
  final ValueChanged<bool> onRest;
  final VoidCallback onCopy;
  final VoidCallback onMove;
  final VoidCallback onAssignPlan;
  final VoidCallback onClearDay;
  final ValueChanged<JournalExercise> onEditExercise;
  final ValueChanged<JournalExercise> onExerciseInfo;

  @override
  Widget build(BuildContext context) {
    final exercises = day?.exercises ?? const <JournalExercise>[];
    final workoutNotes = day?.workoutNotes;
    final resting = day?.isRestDay == true;
    final showRest = exercises.isEmpty;
    final workoutName = day?.workoutName;
    final planName = day?.planName;
    final showPlan = planName != null && planName != workoutName;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _DateBox(dateKey: dateKey, isToday: isToday),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workoutName ?? (resting ? 'Rest day' : 'No workout yet'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: resting && workoutName == null
                              ? context.liftBig.success
                              : context.liftBig.foreground,
                        ),
                      ),
                      if (showPlan) ...[
                        const SizedBox(height: 2),
                        Text(
                          planName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:  TextStyle(
                            color: context.liftBig.muted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                      if (day?.notes != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          day!.notes!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:  TextStyle(
                            color: context.liftBig.muted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
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
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  flex: showRest ? 3 : 1,
                  child: FilledButton.icon(
                    onPressed: onLog,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    icon: Icon(
                      exercises.isEmpty
                          ? Icons.edit_outlined
                          : Icons.open_in_new,
                      size: 18,
                    ),
                    label: Text(exercises.isEmpty ? 'Log workout' : 'Open log'),
                  ),
                ),
                if (showRest) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      onPressed: () => onRest(!resting),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        foregroundColor: resting
                            ? context.liftBig.success
                            : context.liftBig.foreground,
                        backgroundColor: resting
                            ? context.liftBig.success.withValues(alpha: 0.12)
                            : context.liftBig.cardInner,
                        side: BorderSide(
                          color: resting
                              ? context.liftBig.success
                              : context.liftBig.border,
                        ),
                      ),
                      child: Text(resting ? 'Clear rest' : 'Rest day'),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onAssignPlan,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                foregroundColor: context.liftBig.foreground,
                backgroundColor: context.liftBig.cardInner,
                side:  BorderSide(color: context.liftBig.border),
              ),
              icon:  Icon(
                Icons.assignment_outlined,
                size: 18,
                color: context.liftBig.primary,
              ),
              label: const Text('Assign a plan'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _SecondaryAction(
                    icon: Icons.copy_outlined,
                    label: 'Copy',
                    onPressed: exercises.isEmpty ? null : onCopy,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SecondaryAction(
                    icon: Icons.swap_horiz,
                    label: 'Move',
                    onPressed: exercises.isEmpty ? null : onMove,
                  ),
                ),
              ],
            ),
            if (exercises.isNotEmpty) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onClearDay,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                  foregroundColor: context.liftBig.foreground,
                  backgroundColor: context.liftBig.cardInner,
                  side:  BorderSide(color: context.liftBig.border),
                ),
                icon:  Icon(
                  Icons.delete_outline,
                  size: 16,
                  color: context.liftBig.primary,
                ),
                label: const Text('Clear day'),
              ),
            ],
            if (exercises.isNotEmpty) ...[
              const SizedBox(height: 14),
              for (var i = 0; i < exercises.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                _ExerciseCard(
                  exercise: exercises[i],
                  onOpen: () => onLog(exercises[i].id),
                  onEdit: () => onEditExercise(exercises[i]),
                  onInfo: () => onExerciseInfo(exercises[i]),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  const _DateBox({required this.dateKey, required this.isToday});

  final String dateKey;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final parsed = parseDateKey(dateKey);
    final weekday = weekdayLabels[parsed.weekday % 7];
    final month = monthNames[parsed.month - 1].substring(0, 3).toUpperCase();
    return Container(
      width: 64,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: context.liftBig.cardInner,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isToday ? context.liftBig.primary : context.liftBig.border,
        ),
      ),
      child: Column(
        children: [
          Text(
            weekday,
            style: TextStyle(
              color: isToday ? context.liftBig.primary : context.liftBig.muted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          Text(
            '${parsed.day}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1.1),
          ),
          Text(
            month,
            style:  TextStyle(
              color: context.liftBig.muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        foregroundColor: context.liftBig.foreground,
        backgroundColor: context.liftBig.cardInner,
        side:  BorderSide(color: context.liftBig.border),
      ),
      icon: Icon(icon, size: 16, color: context.liftBig.muted),
      label: Text(label),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.exercise,
    required this.onOpen,
    required this.onEdit,
    required this.onInfo,
  });

  final JournalExercise exercise;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.liftBig.cardInner,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side:  BorderSide(color: context.liftBig.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      exercise.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    onPressed: onEdit,
                    tooltip: 'Edit lift',
                    style: IconButton.styleFrom(
                      foregroundColor: context.liftBig.primary,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.all(4),
                      minimumSize: const Size(32, 32),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                  ),
                  IconButton(
                    onPressed: onInfo,
                    tooltip: 'Exercise info',
                    style: IconButton.styleFrom(
                      foregroundColor: context.liftBig.primary,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.all(4),
                      minimumSize: const Size(32, 32),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.info_outline, size: 18),
                  ),
                ],
              ),
              if (exercise.notes != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    exercise.notes!,
                    style:  TextStyle(color: context.liftBig.muted, fontSize: 13),
                  ),
                ),
              for (final set in exercise.sets)
                Padding(
                  padding: const EdgeInsets.only(top: 2, right: 8),
                  child: Text(
                    _setLine(exercise, set),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
            ],
          ),
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
  final loggedReps = loggedRepsField(set.reps);
  final reps = loggedReps.isEmpty ? '—' : loggedReps;
  final weight = set.weight.isEmpty ? '—' : '${set.weight} lb';
  final time = set.durationSeconds?.trim();
  final timeLabel = exercise.isCore && time != null && time.isNotEmpty
      ? ' · $time sec'
      : '';
  return '$done$warmup Set ${set.sortOrder + 1}  $reps × $weight$timeLabel';
}

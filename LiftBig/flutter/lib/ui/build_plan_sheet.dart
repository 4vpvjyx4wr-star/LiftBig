import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../catalog/lift_search.dart';
import '../catalog/liftbig_catalog.dart';
import '../ids.dart';
import '../journal/journal_repository.dart';
import '../plans/custom_plans.dart';
import '../plans/pasted_plan.dart';
import '../theme.dart';
import 'keyboard_dismiss.dart';
import 'liftbig_sheet.dart';

/// Returns true when a plan was saved into `templates_json`.
Future<bool> showBuildPlanSheet(
  BuildContext context, {
  required LiftBigCatalog catalog,
  required JournalRepository journal,
  ParsedPlan? initial,
  String? replacePlanId,
}) async {
  final saved = await showLiftBigSheet<bool>(
    context,
    builder: (context) => SizedBox(
      height: liftBigPreferredHeight(context, 0.92),
      child: _BuildPlanSheet(
        catalog: catalog,
        journal: journal,
        initial: initial,
        replacePlanId: replacePlanId,
      ),
    ),
  );
  return saved == true;
}

Future<bool> showPastePlanSheet(
  BuildContext context, {
  required LiftBigCatalog catalog,
  required JournalRepository journal,
}) async {
  final text = await showLiftBigSheet<String>(
    context,
    builder: (context) => const SizedBox(
      height: 420,
      child: _PastePlanSheet(),
    ),
  );
  if (text == null || !context.mounted) return false;
  final parsed = parsePastedPlan(text, catalog.lifts);
  if (parsed == null) {
    showLiftBigNotice(context, 'No exercises were found in that text.');
    return false;
  }
  return showBuildPlanSheet(
    context,
    catalog: catalog,
    journal: journal,
    initial: parsed,
  );
}

class _DraftExercise {
  _DraftExercise({
    this.lift,
    this.customName = '',
    String? sets,
    String? reps,
    String? weight,
    this.supersetGroupId,
    this.supersetLabel,
    this.supersetOrder,
  }) : sets = TextEditingController(text: sets ?? '$defaultBuiltSetCount'),
       reps = TextEditingController(text: reps ?? defaultBuiltReps),
       weight = TextEditingController(text: weight ?? '');

  LibraryLift? lift;
  String customName;
  String? supersetGroupId;
  String? supersetLabel;
  int? supersetOrder;
  final TextEditingController sets;
  final TextEditingController reps;
  final TextEditingController weight;

  String get label {
    if (lift != null) return lift!.name;
    final written = customName.trim();
    return written.isEmpty ? 'Lift' : written;
  }

  void dispose() {
    sets.dispose();
    reps.dispose();
    weight.dispose();
  }
}

class _DraftWorkout {
  _DraftWorkout({String name = 'Workout', List<_DraftExercise>? exercises})
    : name = TextEditingController(text: name),
      exercises = exercises ?? <_DraftExercise>[];

  final TextEditingController name;
  final List<_DraftExercise> exercises;

  void dispose() {
    name.dispose();
    for (final exercise in exercises) {
      exercise.dispose();
    }
  }
}

class _BuildPlanSheet extends StatefulWidget {
  const _BuildPlanSheet({
    required this.catalog,
    required this.journal,
    this.initial,
    this.replacePlanId,
  });

  final LiftBigCatalog catalog;
  final JournalRepository journal;
  final ParsedPlan? initial;
  final String? replacePlanId;

  @override
  State<_BuildPlanSheet> createState() => _BuildPlanSheetState();
}

class _BuildPlanSheetState extends State<_BuildPlanSheet> {
  late final TextEditingController _planName;
  late final List<_DraftWorkout> _workouts;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _planName = TextEditingController(text: initial?.name ?? '');
    if (initial == null || initial.workouts.isEmpty) {
      _workouts = [_DraftWorkout()];
    } else {
      _workouts = [
        for (final workout in initial.workouts)
          _DraftWorkout(
            name: workout.name,
            exercises: [
              for (final exercise in workout.exercises)
                _DraftExercise(
                  lift: exercise.lift,
                  customName: exercise.customName ?? '',
                  sets: '${exercise.setCount}',
                  reps: exercise.targetReps,
                  weight: exercise.targetWeight,
                  supersetGroupId: exercise.supersetGroupId,
                  supersetLabel: exercise.supersetLabel,
                  supersetOrder: exercise.supersetOrder,
                ),
            ],
          ),
      ];
    }
  }

  @override
  void dispose() {
    _planName.dispose();
    for (final workout in _workouts) {
      workout.dispose();
    }
    super.dispose();
  }

  Future<void> _addExercise(_DraftWorkout workout) async {
    final lift = await showLiftBigSheet<LibraryLift>(
      context,
      builder: (context) => SizedBox(
        height: liftBigPreferredHeight(context, 0.8),
        child: _LiftPicker(lifts: widget.catalog.lifts),
      ),
    );
    if (lift == null || !mounted) return;
    setState(() => workout.exercises.add(_DraftExercise(lift: lift)));
  }

  void _toggleSuperset(_DraftWorkout workout, int index) {
    if (index <= 0 || index >= workout.exercises.length) return;
    final current = workout.exercises[index];
    final previous = workout.exercises[index - 1];
    final joined =
        current.supersetGroupId != null &&
        current.supersetGroupId == previous.supersetGroupId;
    setState(() {
      if (joined) {
        final group = current.supersetGroupId;
        current.supersetGroupId = null;
        current.supersetLabel = null;
        current.supersetOrder = null;
        if (group != null) {
          final remaining = [
            for (final item in workout.exercises)
              if (item.supersetGroupId == group) item,
          ];
          if (remaining.length < 2) {
            for (final item in remaining) {
              item.supersetGroupId = null;
              item.supersetLabel = null;
              item.supersetOrder = null;
            }
          }
        }
        return;
      }
      final group = previous.supersetGroupId ?? newId();
      if (previous.supersetGroupId == null) {
        previous.supersetGroupId = group;
        previous.supersetLabel = _nextSupersetLabel(workout);
        previous.supersetOrder = 0;
      }
      var nextOrder = 0;
      for (final item in workout.exercises) {
        final order = item.supersetOrder;
        if (item.supersetGroupId == group && order != null && order >= nextOrder) {
          nextOrder = order + 1;
        }
      }
      current.supersetGroupId = group;
      current.supersetLabel = previous.supersetLabel;
      current.supersetOrder = nextOrder;
    });
  }

  String _nextSupersetLabel(_DraftWorkout workout) {
    final used = {
      for (final item in workout.exercises)
        if (item.supersetLabel != null && item.supersetLabel!.isNotEmpty)
          item.supersetLabel!,
    };
    for (var i = 0; i < 26; i++) {
      final label = String.fromCharCode(65 + i);
      if (!used.contains(label)) return label;
    }
    return 'Superset';
  }

  Future<void> _matchExercise(_DraftExercise exercise) async {
    final lift = await showLiftBigSheet<LibraryLift>(
      context,
      builder: (context) => SizedBox(
        height: liftBigPreferredHeight(context, 0.8),
        child: _LiftPicker(lifts: widget.catalog.lifts),
      ),
    );
    if (lift == null || !mounted) return;
    setState(() {
      exercise.lift = lift;
      exercise.customName = '';
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final built = <BuiltPlanWorkout>[];
    for (final workout in _workouts) {
      final exercises = <BuiltPlanExercise>[];
      for (final exercise in workout.exercises) {
        final rawCount = exercise.sets.text.trim();
        final count = int.tryParse(rawCount);
        if (count == null || count < 1 || count > 30) {
          showLiftBigNotice(context, 'Enter a set count from 1 to 30.');
          return;
        }
        if (exercise.lift == null && exercise.customName.trim().isEmpty) {
          showLiftBigNotice(context, 'Name each exercise before saving.');
          return;
        }
        exercises.add(
          BuiltPlanExercise(
            lift: exercise.lift,
            customName: exercise.lift == null ? exercise.customName : null,
            setCount: count,
            targetReps: exercise.reps.text,
            targetWeight: exercise.weight.text,
            supersetGroupId: exercise.supersetGroupId,
            supersetLabel: exercise.supersetLabel,
            supersetOrder: exercise.supersetOrder,
          ),
        );
      }
      built.add(BuiltPlanWorkout(name: workout.name.text, exercises: exercises));
    }
    final payload = appendBuiltPlanToTemplatesJson(
      existing: await widget.journal.templatesJson(),
      planName: _planName.text,
      workouts: built,
      createId: newId,
      replacePlanId: widget.replacePlanId,
    );
    if (!mounted) return;
    if (payload == null) {
      showLiftBigNotice(
        context,
        'Add a plan name and at least one exercise.',
      );
      return;
    }
    setState(() => _saving = true);
    await widget.journal.saveTemplatesJson(payload);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDismiss(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.replacePlanId == null
                        ? 'Build Your Own Plan'
                        : 'Edit Plan',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context, false),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Text(
                  'Name the plan, name each workout, and pick exercises. Each one starts at 3 sets of 8-12. Change the sets and target reps before you save.',
                  style: TextStyle(color: context.liftBig.muted, height: 1.35),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _planName,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Plan name'),
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < _workouts.length; i++) ...[
                  _WorkoutEditor(
                    index: i,
                    workout: _workouts[i],
                    canRemove: _workouts.length > 1,
                    onChanged: () => setState(() {}),
                    onAddExercise: () => _addExercise(_workouts[i]),
                    onMatch: _matchExercise,
                    onToggleSuperset: (index) =>
                        _toggleSuperset(_workouts[i], index),
                    onRemove: () {
                      final removed = _workouts.removeAt(i);
                      removed.dispose();
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                OutlinedButton.icon(
                  onPressed: () => setState(() => _workouts.add(_DraftWorkout())),
                  icon: const Icon(Icons.add),
                  label: const Text('Add a workout'),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  child: Text(
                    _saving
                        ? 'Saving…'
                        : widget.replacePlanId == null
                        ? 'Save Plan'
                        : 'Save Changes',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutEditor extends StatelessWidget {
  const _WorkoutEditor({
    required this.index,
    required this.workout,
    required this.canRemove,
    required this.onChanged,
    required this.onAddExercise,
    required this.onMatch,
    required this.onToggleSuperset,
    required this.onRemove,
  });

  final int index;
  final _DraftWorkout workout;
  final bool canRemove;
  final VoidCallback onChanged;
  final VoidCallback onAddExercise;
  final ValueChanged<_DraftExercise> onMatch;
  final ValueChanged<int> onToggleSuperset;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.liftBig.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.liftBig.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: workout.name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: 'Workout ${index + 1}'),
            ),
            const SizedBox(height: 8),
            if (workout.exercises.isEmpty)
              Text(
                'No exercises yet.',
                style: TextStyle(color: context.liftBig.muted),
              )
            else
              for (var i = 0; i < workout.exercises.length; i++)
                _ExerciseFields(
                  exercise: workout.exercises[i],
                  canLink: i > 0,
                  linkedWithPrevious:
                      i > 0 &&
                      workout.exercises[i].supersetGroupId != null &&
                      workout.exercises[i].supersetGroupId ==
                          workout.exercises[i - 1].supersetGroupId,
                  onToggleSuperset: () => onToggleSuperset(i),
                  onMatch: () => onMatch(workout.exercises[i]),
                  onRemove: () {
                    final removed = workout.exercises.removeAt(i);
                    removed.dispose();
                    onChanged();
                  },
                ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onAddExercise,
                icon: const Icon(Icons.add),
                label: const Text('Add an exercise'),
              ),
            ),
            if (canRemove)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: onRemove,
                  child: const Text('Remove workout'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseFields extends StatelessWidget {
  const _ExerciseFields({
    required this.exercise,
    required this.canLink,
    required this.linkedWithPrevious,
    required this.onToggleSuperset,
    required this.onMatch,
    required this.onRemove,
  });

  final _DraftExercise exercise;
  final bool canLink;
  final bool linkedWithPrevious;
  final VoidCallback onToggleSuperset;
  final VoidCallback onMatch;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  exercise.label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Edit lift',
                icon: const Icon(Icons.edit_outlined),
                onSelected: (value) {
                  if (value == 'lift') onMatch();
                  if (value == 'superset') onToggleSuperset();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'lift',
                    child: Text(
                      exercise.lift == null ? 'Choose lift' : 'Change lift',
                    ),
                  ),
                  if (canLink)
                    PopupMenuItem(
                      value: 'superset',
                      child: Text(
                        linkedWithPrevious
                            ? 'Remove from superset'
                            : 'Superset with previous',
                      ),
                    ),
                ],
              ),
              IconButton(
                tooltip: 'Remove exercise',
                visualDensity: VisualDensity.compact,
                onPressed: onRemove,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          if (exercise.supersetLabel != null)
            Text(
              'Superset ${exercise.supersetLabel}',
              style: TextStyle(
                color: context.liftBig.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 88,
                child: TextField(
                  controller: exercise.sets,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Sets',
                    isDense: true,
                  ),
                  onSubmitted: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: exercise.reps,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Target reps',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 88,
                child: TextField(
                  controller: exercise.weight,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Weight',
                    isDense: true,
                  ),
                  onSubmitted: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PastePlanSheet extends StatefulWidget {
  const _PastePlanSheet();

  @override
  State<_PastePlanSheet> createState() => _PastePlanSheetState();
}

class _PastePlanSheetState extends State<_PastePlanSheet> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDismiss(
      fill: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Paste a plan',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Paste the days and exercises. A line like Bench Press 3x5 @ 185 is enough.',
              style: TextStyle(color: context.liftBig.muted, height: 1.35),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _text,
              autofocus: true,
              minLines: 6,
              maxLines: 8,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Push\nBench Press 3x5 @ 185\n\nPull\nBarbell Row 4x6 @ 135',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                final text = _text.text.trim();
                if (text.isEmpty) return;
                Navigator.pop(context, text);
              },
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: const Text('Read plan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiftPicker extends StatefulWidget {
  const _LiftPicker({required this.lifts});

  final List<LibraryLift> lifts;

  @override
  State<_LiftPicker> createState() => _LiftPickerState();
}

class _LiftPickerState extends State<_LiftPicker> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final matches = [
      for (final lift in widget.lifts)
        if (query.isEmpty || libraryLiftMatchesQuery(lift, query)) lift,
    ];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: TextField(
            controller: _search,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Search exercises',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final lift = matches[index];
              return ListTile(
                title: Text(lift.name),
                subtitle: Text(
                  lift.equipment,
                  style: TextStyle(color: context.liftBig.muted),
                ),
                onTap: () => Navigator.pop(context, lift),
              );
            },
          ),
        ),
      ],
    );
  }
}

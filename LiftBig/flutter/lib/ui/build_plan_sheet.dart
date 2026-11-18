import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../catalog/liftbig_catalog.dart';
import '../ids.dart';
import '../journal/journal_repository.dart';
import '../plans/custom_plans.dart';
import '../theme.dart';
import 'keyboard_dismiss.dart';
import 'liftbig_sheet.dart';

/// Returns true when a plan was saved into `templates_json`.
Future<bool> showBuildPlanSheet(
  BuildContext context, {
  required LiftBigCatalog catalog,
  required JournalRepository journal,
}) async {
  final saved = await showLiftBigSheet<bool>(
    context,
    builder: (context) => SizedBox(
      height: liftBigPreferredHeight(context, 0.92),
      child: _BuildPlanSheet(catalog: catalog, journal: journal),
    ),
  );
  return saved == true;
}

class _DraftExercise {
  _DraftExercise(this.lift)
    : sets = TextEditingController(text: '$defaultBuiltSetCount'),
      reps = TextEditingController(text: defaultBuiltReps);

  final LibraryLift lift;
  final TextEditingController sets;
  final TextEditingController reps;

  void dispose() {
    sets.dispose();
    reps.dispose();
  }
}

class _DraftWorkout {
  _DraftWorkout() : name = TextEditingController(text: 'Workout');

  final TextEditingController name;
  final exercises = <_DraftExercise>[];

  void dispose() {
    name.dispose();
    for (final exercise in exercises) {
      exercise.dispose();
    }
  }
}

class _BuildPlanSheet extends StatefulWidget {
  const _BuildPlanSheet({required this.catalog, required this.journal});

  final LiftBigCatalog catalog;
  final JournalRepository journal;

  @override
  State<_BuildPlanSheet> createState() => _BuildPlanSheetState();
}

class _BuildPlanSheetState extends State<_BuildPlanSheet> {
  final _planName = TextEditingController();
  final _workouts = <_DraftWorkout>[_DraftWorkout()];
  var _saving = false;

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
    setState(() => workout.exercises.add(_DraftExercise(lift)));
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
        exercises.add(
          BuiltPlanExercise(
            lift: exercise.lift,
            setCount: count,
            targetReps: exercise.reps.text,
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
                const Expanded(
                  child: Text(
                    'Build Your Own Plan',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
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
                  child: Text(_saving ? 'Saving…' : 'Save Plan'),
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
    required this.onRemove,
  });

  final int index;
  final _DraftWorkout workout;
  final bool canRemove;
  final VoidCallback onChanged;
  final VoidCallback onAddExercise;
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
  const _ExerciseFields({required this.exercise, required this.onRemove});

  final _DraftExercise exercise;
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
                  exercise.lift.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: 'Remove exercise',
                visualDensity: VisualDensity.compact,
                onPressed: onRemove,
                icon: const Icon(Icons.close),
              ),
            ],
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
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Target reps',
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
        if (query.isEmpty || lift.name.toLowerCase().contains(query)) lift,
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

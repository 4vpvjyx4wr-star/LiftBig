import 'package:flutter/material.dart';

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

class _DraftWorkout {
  _DraftWorkout() : name = TextEditingController(text: 'Workout');

  final TextEditingController name;
  final lifts = <LibraryLift>[];

  void dispose() => name.dispose();
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
    setState(() => workout.lifts.add(lift));
  }

  Future<void> _save() async {
    if (_saving) return;
    final payload = appendBuiltPlanToTemplatesJson(
      existing: await widget.journal.templatesJson(),
      planName: _planName.text,
      workouts: [
        for (final workout in _workouts)
          BuiltPlanWorkout(name: workout.name.text, lifts: workout.lifts),
      ],
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
                  'Name the plan, name each workout, and pick exercises. Each exercise starts at 3 sets of 8–12.',
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
            if (workout.lifts.isEmpty)
              Text(
                'No exercises yet.',
                style: TextStyle(color: context.liftBig.muted),
              )
            else
              for (var i = 0; i < workout.lifts.length; i++)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(workout.lifts[i].name),
                  subtitle: Text(
                    '3 sets · 8–12',
                    style: TextStyle(color: context.liftBig.muted),
                  ),
                  trailing: IconButton(
                    tooltip: 'Remove exercise',
                    onPressed: () {
                      workout.lifts.removeAt(i);
                      onChanged();
                    },
                    icon: const Icon(Icons.close),
                  ),
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

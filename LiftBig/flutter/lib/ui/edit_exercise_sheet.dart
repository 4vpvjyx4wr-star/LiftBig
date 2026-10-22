import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../catalog/liftbig_catalog.dart';
import '../journal/journal_repository.dart';
import '../model/journal_day.dart';
import '../theme.dart';

/// Edits one logged lift: swap it from the library, and change goal reps and sets.
/// Returns true when the journal was updated.
Future<bool> showEditExerciseSheet(
  BuildContext context, {
  required JournalRepository journal,
  required JournalExercise exercise,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: LiftBigColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      side: BorderSide(color: LiftBigColors.border),
    ),
    builder: (context) => EditExerciseSheet(
      journal: journal,
      exercise: exercise,
    ),
  );
  return saved == true;
}

class EditExerciseSheet extends StatefulWidget {
  const EditExerciseSheet({
    super.key,
    required this.journal,
    required this.exercise,
  });

  final JournalRepository journal;
  final JournalExercise exercise;

  @override
  State<EditExerciseSheet> createState() => _EditExerciseSheetState();
}

class _EditExerciseSheetState extends State<EditExerciseSheet> {
  final _search = TextEditingController();
  final _reps = TextEditingController();
  final _sets = TextEditingController();
  LiftBigCatalog? _catalog;
  LibraryLift? _replacement;
  String? _error;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _reps.text = widget.exercise.targetReps ?? '';
    _sets.text = '${widget.exercise.sets.length}';
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    _reps.dispose();
    _sets.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final catalog = await LiftBigCatalog.load();
      if (!mounted) return;
      setState(() => _catalog = catalog);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Could not load the exercise library.');
    }
  }

  List<LibraryLift> get _matches {
    final catalog = _catalog;
    if (catalog == null) return const [];
    return rankExerciseSuggestions(catalog.lifts, _search.text).take(40).toList();
  }

  Future<void> _save() async {
    if (_saving) return;
    final count = int.tryParse(_sets.text.trim());
    if (count == null || count < 1 || count > 30) {
      setState(() => _error = 'Enter a set count from 1 to 30.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final replacement = _replacement;
      final exercise = widget.exercise;
      if (replacement != null &&
          (replacement.id != exercise.libraryId ||
              replacement.name != exercise.name)) {
        await widget.journal.replaceExercise(
          exerciseId: exercise.id,
          name: replacement.name,
          libraryId: replacement.id,
          isCardio: replacement.isCardio,
          isCore: replacement.isCore,
        );
      }
      await widget.journal.updateExerciseGoal(
        exerciseId: exercise.id,
        targetReps: _reps.text,
        targetWeight: replacement?.isCardio == true ? null : exercise.targetWeight,
        setCount: count,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = '$error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final replacement = _replacement;
    final matches = _matches;
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SizedBox(
        height: media.size.height * 0.72,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: LiftBigColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                widget.exercise.name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                'Swap this lift or change its goal. Logged sets stay with it.',
                style: TextStyle(color: LiftBigColors.muted, fontSize: 13),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _search,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Search to swap lifts',
                  isDense: true,
                  prefixIcon: Icon(Icons.search, size: 20),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            if (replacement != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.swap_horiz,
                      size: 18,
                      color: LiftBigColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Swap to ${replacement.name}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Keep current lift',
                      onPressed: () => setState(() => _replacement = null),
                      icon: const Icon(Icons.close, size: 18),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _reps,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Goal reps',
                        isDense: true,
                      ),
                      onSubmitted: (_) =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _sets,
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
                ],
              ),
            ),
            Expanded(
              child: _catalog == null && _error == null
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                      children: [
                        if (_search.text.trim().isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Search the library to swap this lift.',
                              style: TextStyle(color: LiftBigColors.muted),
                            ),
                          )
                        else if (matches.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'No matching lifts.',
                              style: TextStyle(color: LiftBigColors.muted),
                            ),
                          )
                        else
                          for (final lift in matches)
                            ListTile(
                              dense: true,
                              title: Text(lift.name),
                              subtitle: Text(
                                lift.equipment,
                                style: const TextStyle(color: LiftBigColors.muted),
                              ),
                              trailing: _replacement?.id == lift.id
                                  ? const Icon(
                                      Icons.check,
                                      color: LiftBigColors.primary,
                                    )
                                  : null,
                              onTap: () => setState(() => _replacement = lift),
                            ),
                      ],
                    ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  _error!,
                  style: const TextStyle(color: LiftBigColors.primary),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? 'Saving…' : 'Save'),
                    ),
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

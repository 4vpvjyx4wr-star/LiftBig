import 'package:flutter/material.dart';

import '../catalog/comparable_lifts.dart';
import '../catalog/liftbig_catalog.dart';
import '../journal/journal_repository.dart';
import '../model/journal_day.dart';
import '../theme.dart';
import 'liftbig_sheet.dart';

/// Lists similar lifts first, then the rest of the library. Returns true when swapped.
Future<bool> showSwapExerciseSheet(
  BuildContext context, {
  required JournalRepository journal,
  required JournalExercise exercise,
}) async {
  LiftBigCatalog catalog;
  try {
    catalog = await LiftBigCatalog.load();
  } catch (_) {
    return false;
  }
  if (!context.mounted) return false;
  final picked = await showLiftBigSheet<LibraryLift>(
    context,
    backgroundColor: context.liftBig.background,
    builder: (context) => _SwapExerciseSheet(
      exercise: exercise,
      catalog: catalog,
    ),
  );
  if (picked == null) return false;
  await journal.replaceExercise(
    exerciseId: exercise.id,
    name: picked.name,
    libraryId: picked.id,
    isCardio: picked.isCardio,
    isCore: picked.isCore,
  );
  return true;
}

class _SwapExerciseSheet extends StatefulWidget {
  const _SwapExerciseSheet({required this.exercise, required this.catalog});

  final JournalExercise exercise;
  final LiftBigCatalog catalog;

  @override
  State<_SwapExerciseSheet> createState() => _SwapExerciseSheetState();
}

class _SwapExerciseSheetState extends State<_SwapExerciseSheet> {
  final _search = TextEditingController();
  late final List<LibraryLift> _ranked;

  @override
  void initState() {
    super.initState();
    _ranked = comparableLibraryLifts(
      library: widget.catalog.lifts,
      libraryId: widget.exercise.libraryId,
      name: widget.exercise.name,
      isCardio: widget.exercise.isCardio,
      preferredSwapLibraryIds: widget.exercise.preferredSwapLibraryIds,
    );
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<LibraryLift> get _visible {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return _ranked;
    return [
      for (final lift in _ranked)
        if (lift.name.toLowerCase().contains(query)) lift,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final lifts = _visible;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SizedBox(
        height: liftBigPreferredHeight(context, 0.72),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'Swap ${widget.exercise.name}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _search,
                decoration: const InputDecoration(
                  hintText: 'Search lifts',
                ),
              ),
            ),
            Expanded(
              child: lifts.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No matching lifts.',
                        style: TextStyle(color: context.liftBig.muted),
                      ),
                    )
                  : ListView.builder(
                      itemCount: lifts.length,
                      itemBuilder: (context, index) {
                        final lift = lifts[index];
                        final groups = [
                          for (final group in lift.muscleGroups)
                            muscleGroupLabels[group] ?? group,
                        ];
                        return ListTile(
                          title: Text(lift.name),
                          subtitle: groups.isEmpty
                              ? null
                              : Text(groups.join(', ')),
                          onTap: () {
                            liftBigSelectionHaptic();
                            Navigator.of(context).pop(lift);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

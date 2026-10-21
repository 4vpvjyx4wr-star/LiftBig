import 'package:flutter/material.dart';

import '../catalog/liftbig_catalog.dart';
import '../journal/journal_repository.dart';
import '../journal/lift_name_convergence.dart';
import '../theme.dart';

/// Settings block: same lift spelled with different capitalization or spacing.
class LiftNameConvergenceSection extends StatefulWidget {
  const LiftNameConvergenceSection({super.key, required this.journal});

  final JournalRepository journal;

  @override
  State<LiftNameConvergenceSection> createState() =>
      _LiftNameConvergenceSectionState();
}

class _LiftNameConvergenceSectionState extends State<LiftNameConvergenceSection> {
  var _loading = true;
  var _expanded = false;
  String? _catalogError;
  List<DuplicateExerciseGroup> _groups = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    List<LibraryLift> catalogLifts = const [];
    String? catalogError;
    try {
      final catalog = await LiftBigCatalog.load();
      catalogLifts = catalog.lifts;
      await widget.journal.mergeExactLibraryMatches(catalogLifts);
    } catch (error) {
      catalogError = '$error';
    }

    final logged = await widget.journal.distinctLoggedExerciseNames();
    if (!mounted) return;

    final groups = findDuplicateExerciseGroups(
      loggedNames: logged,
      catalogLifts: catalogLifts,
    );

    setState(() {
      _loading = false;
      _catalogError = catalogError;
      _groups = groups;
    });
  }

  Future<void> _merge(DuplicateExerciseGroup group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Merge to canonical name'),
        content: Text(
          'Rename ${group.variants.join(', ')} to ${group.canonicalName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Merge'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await widget.journal.mergeExerciseNameVariants(
      key: group.key,
      canonicalName: group.canonicalName,
      libraryId: group.libraryId,
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = _loading
        ? 'Checking your log…'
        : _catalogError != null
        ? 'Library unavailable.'
        : _groups.isEmpty
        ? 'No duplicate spellings.'
        : '${_groups.length} name${_groups.length == 1 ? '' : 's'} to merge';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: LiftBigColors.cardInner,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: LiftBigColors.border),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _loading
                ? null
                : () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lift name overlap',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(color: LiftBigColors.muted),
                        ),
                      ],
                    ),
                  ),
                  if (_loading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: LiftBigColors.muted,
                    ),
                ],
              ),
            ),
          ),
        ),
        if (_expanded && !_loading) ...[
          const SizedBox(height: 12),
          const Text(
            'Exact library spellings link automatically. These are the same lift with different capitalization or spacing.',
            style: TextStyle(color: LiftBigColors.muted, height: 1.35),
          ),
          const SizedBox(height: 12),
          if (_catalogError != null)
            Text(
              'The Lift Library could not be loaded. Merges still use the first alphabetical spelling.',
              style: TextStyle(color: LiftBigColors.muted.withValues(alpha: 0.9)),
            ),
          if (_groups.isEmpty)
            const Text(
              'No duplicate spellings.',
              style: TextStyle(color: LiftBigColors.muted),
            )
          else
            for (final group in _groups)
              _DuplicateCard(group: group, onMerge: () => _merge(group)),
        ],
      ],
    );
  }
}

class _DuplicateCard extends StatelessWidget {
  const _DuplicateCard({required this.group, required this.onMerge});

  final DuplicateExerciseGroup group;
  final VoidCallback onMerge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: LiftBigColors.cardInner,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: LiftBigColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              group.variants.join(' · '),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onMerge,
              child: const Text('Merge to canonical name'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../catalog/liftbig_catalog.dart';
import '../journal/journal_repository.dart';
import '../plans/custom_plans.dart';
import '../theme.dart';
import 'plan_workout_row.dart';

/// A workout session chosen for one calendar day.
class PlanAssignment {
  const PlanAssignment({required this.workout, required this.planName});

  final CatalogWorkout workout;
  final String planName;
}

/// Picks one workout from premade, starter, and custom plans.
Future<PlanAssignment?> showAssignPlanSheet(
  BuildContext context, {
  required JournalRepository journal,
}) {
  return showModalBottomSheet<PlanAssignment>(
    context: context,
    isScrollControlled: true,
    backgroundColor: LiftBigColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      side: BorderSide(color: LiftBigColors.border),
    ),
    builder: (context) => AssignPlanSheet(journal: journal),
  );
}

class AssignPlanSheet extends StatefulWidget {
  const AssignPlanSheet({super.key, required this.journal});

  final JournalRepository journal;

  @override
  State<AssignPlanSheet> createState() => _AssignPlanSheetState();
}

class _AssignPlanSheetState extends State<AssignPlanSheet> {
  final _search = TextEditingController();
  List<PremadePlan>? _plans;
  Set<String> _favoriteIds = const {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final catalog = await LiftBigCatalog.load();
      final custom = await loadCustomPlans(
        journal: widget.journal,
        catalog: catalog,
      );
      final favorites = await widget.journal.favoritePlanIds();
      if (!mounted) return;
      setState(() {
        _favoriteIds = favorites;
        _plans = [
          ...catalog.plans,
          if (catalog.starterWorkouts.isNotEmpty)
            PremadePlan(
              id: 'starter-workouts',
              name: 'Starter workouts',
              purpose: 'Single sessions',
              workouts: catalog.starterWorkouts,
            ),
          ...custom.where((plan) => plan.workouts.isNotEmpty),
        ];
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = '$error');
    }
  }

  List<PremadePlan> _visible(String query) {
    final plans = _plans ?? const <PremadePlan>[];
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return plans.where((plan) => plan.workouts.isNotEmpty).toList();
    }
    final out = <PremadePlan>[];
    for (final plan in plans) {
      final workouts = plan.workouts.where((workout) {
        if (workout.name.toLowerCase().contains(q)) return true;
        if (plan.name.toLowerCase().contains(q)) return true;
        return workout.lifts.any(
          (lift) => lift.name.toLowerCase().contains(q),
        );
      }).toList();
      if (workouts.isEmpty) continue;
      out.add(
        PremadePlan(
          id: plan.id,
          name: plan.name,
          purpose: plan.purpose,
          workouts: workouts,
        ),
      );
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SizedBox(
        height: media.size.height * 0.72,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: LiftBigColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                'Assign a plan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                'Adds this workout to the selected day.',
                style: TextStyle(color: LiftBigColors.muted, fontSize: 13),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Search plans or exercises',
                  isDense: true,
                  prefixIcon: Icon(Icons.search, size: 20),
                ),
              ),
            ),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Could not load plans.'),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Try again')),
            ],
          ),
        ),
      );
    }
    final plans = _plans;
    if (plans == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final visible = _visible(_search.text);
    if (visible.isEmpty) {
      return const Center(
        child: Text(
          'No matching plans.',
          style: TextStyle(color: LiftBigColors.muted),
        ),
      );
    }
    final favorites = [
      for (final plan in visible)
        if (_favoriteIds.contains(plan.id)) plan,
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        if (favorites.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Favorites',
              style: TextStyle(
                color: LiftBigColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ),
          for (final plan in favorites) _planCard(plan),
          const Padding(
            padding: EdgeInsets.only(top: 4, bottom: 12),
            child: Divider(height: 1, color: LiftBigColors.border),
          ),
        ],
        for (final plan in visible) _planCard(plan),
      ],
    );
  }

  Widget _planCard(PremadePlan plan) {
    final favorited = _favoriteIds.contains(plan.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: LiftBigColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: LiftBigColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          iconColor: LiftBigColors.muted,
          collapsedIconColor: LiftBigColors.muted,
          title: Row(
            children: [
              if (favorited) ...[
                const Icon(Icons.star, size: 16, color: LiftBigColors.primary),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  plan.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          subtitle: Text(
            '${plan.workouts.length} ${plan.workouts.length == 1 ? 'workout' : 'workouts'}',
            style: const TextStyle(color: LiftBigColors.muted, fontSize: 12),
          ),
          children: [
            for (var i = 0; i < plan.workouts.length; i++)
              PlanWorkoutRow(
                key: ValueKey('${plan.id}:${plan.workouts[i].id}:$i'),
                workout: plan.workouts[i],
                trailing: IconButton(
                  tooltip: 'Add to this day',
                  onPressed: () {
                    Navigator.pop(
                      context,
                      PlanAssignment(
                        workout: plan.workouts[i],
                        planName: plan.name,
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, color: LiftBigColors.primary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

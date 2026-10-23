import 'package:flutter/material.dart';

import '../catalog/liftbig_catalog.dart';
import '../journal/journal_repository.dart';
import '../plans/custom_plans.dart';
import '../theme.dart';
import 'liftbig_sheet.dart';
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
  return showLiftBigSheet<PlanAssignment>(
    context,
    backgroundColor: context.liftBig.background,
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
  String? _selectedPlanId;
  var _choosingPlan = true;

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

  PremadePlan? _selected(List<PremadePlan> plans) {
    for (final plan in plans) {
      if (plan.id == _selectedPlanId) return plan;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SizedBox(
        height: liftBigPreferredHeight(context, 0.72),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Text(
                'Assign a plan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Choose one plan, then add a workout to this day.',
                style: TextStyle(color: context.liftBig.muted, fontSize: 13),
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
      return Center(
        child: Text(
          'No matching plans.',
          style: TextStyle(color: context.liftBig.muted),
        ),
      );
    }
    final selected = _selected(visible);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        _planChooser(visible, selected),
        if (!_choosingPlan && selected != null) ...[
          const SizedBox(height: 12),
          Text(
            'Adding from ${selected.name}',
            style: TextStyle(
              color: context.liftBig.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < selected.workouts.length; i++)
            _workoutRow(selected, selected.workouts[i], i),
        ],
      ],
    );
  }

  Widget _planChooser(List<PremadePlan> plans, PremadePlan? selected) {
    return Material(
      color: context.liftBig.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.liftBig.primary, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _choosingPlan = !_choosingPlan),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Plan',
                          style: TextStyle(
                            color: context.liftBig.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          selected?.name ?? 'Choose a plan',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        if (selected != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'This plan will be assigned',
                            style: TextStyle(
                              color: context.liftBig.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    _choosingPlan ? Icons.expand_less : Icons.expand_more,
                    color: context.liftBig.primary,
                  ),
                ],
              ),
            ),
          ),
          if (_choosingPlan)
            for (final plan in plans)
              ListTile(
                dense: true,
                leading: _favoriteIds.contains(plan.id)
                    ? Icon(Icons.star, color: context.liftBig.primary, size: 18)
                    : const SizedBox(width: 18),
                title: Text(plan.name),
                subtitle: Text(
                  '${plan.workouts.length} ${plan.workouts.length == 1 ? 'workout' : 'workouts'}',
                ),
                trailing: plan.id == selected?.id
                    ? Icon(Icons.check, color: context.liftBig.primary)
                    : null,
                onTap: () => setState(() {
                  _selectedPlanId = plan.id;
                  _choosingPlan = false;
                }),
              ),
        ],
      ),
    );
  }

  Widget _workoutRow(PremadePlan plan, CatalogWorkout workout, int index) {
    return PlanWorkoutRow(
      key: ValueKey('${plan.id}:${workout.id}:$index'),
      workout: workout,
      trailing: IconButton(
        tooltip: 'Add to this day',
        onPressed: () {
          Navigator.pop(
            context,
            PlanAssignment(workout: workout, planName: plan.name),
          );
        },
        icon: Icon(Icons.add, color: context.liftBig.primary),
      ),
    );
  }
}

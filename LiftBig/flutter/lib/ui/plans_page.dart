import 'package:flutter/material.dart';
import '../catalog/liftbig_catalog.dart';
import '../date_key.dart';
import '../journal/journal_repository.dart';
import '../model/journal_day.dart';
import '../plans/custom_plans.dart';
import '../plans/plan_quiz.dart';
import '../plans/plan_schedule.dart';
import '../plans/workout_shuffle.dart';
import '../theme.dart';
import 'catalog_load_state.dart';
import 'plan_schedule_sheet.dart';
import 'workout_shuffle_sheet.dart';

class PlansPage extends StatefulWidget {
  const PlansPage({
    super.key,
    required this.journal,
    this.onPlanScheduled,
  });

  final JournalRepository journal;
  final ValueChanged<String>? onPlanScheduled;

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _QuizChoice {
  const _QuizChoice(this.value, this.title, this.detail);
  final Object value;
  final String title;
  final String detail;
}

class _PlansPageState extends State<PlansPage> {
  var _step = 0;
  var _answers = const QuizAnswers();
  var _showQuiz = false;

  final _equipment = <String>{};
  final _focus = <String>{};
  var _includeCardio = false;
  var _minutes = 45;
  final _liftSeconds = TextEditingController(text: '60');
  final _restSeconds = TextEditingController(text: '60');
  ShuffledWorkout? _shuffled;
  String? _shuffleNote;
  Future<List<PremadePlan>>? _customPlansFuture;

  @override
  void initState() {
    super.initState();
    _loadShuffleDefaults();
  }

  Future<void> _loadShuffleDefaults() async {
    final rest = await widget.journal.storedAverageRestSeconds();
    final lift = await widget.journal.storedAverageLiftSeconds();
    if (!mounted) return;
    setState(() {
      _restSeconds.text = '$rest';
      _liftSeconds.text = '$lift';
    });
  }

  @override
  void dispose() {
    _liftSeconds.dispose();
    _restSeconds.dispose();
    super.dispose();
  }

  Future<void> _logWorkout(CatalogWorkout workout, String? planName) async {
    final today = todayKey();
    final existing = await widget.journal.getDay(today);
    if (!mounted) return;
    if (existing != null && existing.exercises.isNotEmpty) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Add to today?'),
          content: const Text(
            'Today already has lifts. This adds the workout onto that day.',
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
      if (replace != true || !mounted) return;
    }
    await widget.journal.updateDayHeader(
      today,
      workoutName: workout.name,
      setWorkoutName: true,
      planName: planName,
      setPlanName: planName != null && planName.isNotEmpty,
    );
    final prescribeWarmup = await widget.journal.prescribeWarmupEnabled();
    for (final lift in workout.lifts) {
      await widget.journal.addExercise(
        dateKey: today,
        name: lift.name,
        libraryId: lift.libraryId,
        isCardio: lift.isCardio,
        isCore: lift.isCore,
        isCircuit: lift.isCircuit,
        prescribeWarmup: prescribeWarmup,
        sets: [
          for (var i = 0; i < lift.sets.length; i++)
            JournalSet(
              id: '',
              sortOrder: i,
              reps: lift.sets[i].reps,
              weight: lift.sets[i].weight,
            ),
        ],
      );
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${workout.name} added to today.')),
    );
  }

  Future<void> _schedulePlan(String planTitle, List<CatalogWorkout> workouts) async {
    if (workouts.isEmpty) return;
    final startDateKey = await showPlanScheduleStartDateSheet(
      context,
      planTitle: planTitle,
      workoutCount: workouts.length,
    );
    if (!mounted || startDateKey == null) return;

    final daysWritten = await applyPlanScheduleToJournal(
      journal: widget.journal,
      startDateKey: startDateKey,
      planName: planTitle,
      workouts: workouts,
      confirmConflict: (message) async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Dates already have workouts'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Continue'),
              ),
            ],
          ),
        );
        return ok == true;
      },
    );
    if (!mounted || daysWritten == null) return;
    if (daysWritten == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing was scheduled.')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$planTitle added to $daysWritten ${daysWritten == 1 ? 'day' : 'days'} on your calendar.',
        ),
      ),
    );
    widget.onPlanScheduled?.call(startDateKey);
  }

  void _shuffle(LiftBigCatalog catalog) {
    final workout = buildShuffledWorkout(
      catalog.lifts,
      ShuffleRequest(
        equipment: _equipment.toList(),
        focus: _focus.toList(),
        includeCardio: _includeCardio,
        targetMinutes: _minutes,
        secondsPerLift: int.tryParse(_liftSeconds.text) ?? 60,
        secondsPerRest: int.tryParse(_restSeconds.text) ?? 60,
      ),
    );
    setState(() {
      _shuffled = workout.lifts.isEmpty ? null : workout;
      _shuffleNote = workout.lifts.isEmpty
          ? 'No lifts match. Pick at least one kind of equipment, or loosen the focus.'
          : null;
    });
  }

  void _openShuffleSheet(LiftBigCatalog catalog) {
    showWorkoutShuffleSheet(
      context,
      catalog: catalog,
      equipment: () => _equipment,
      focus: () => _focus,
      includeCardio: () => _includeCardio,
      minutes: () => _minutes,
      liftSeconds: _liftSeconds,
      restSeconds: _restSeconds,
      shuffled: () => _shuffled,
      shuffleNote: () => _shuffleNote,
      onEquipmentChanged: (equipment, selected) => setState(() {
        if (selected) {
          _equipment.add(equipment);
        } else {
          _equipment.remove(equipment);
        }
      }),
      onFocusChanged: (focus, selected) => setState(() {
        if (selected) {
          _focus.add(focus);
        } else {
          _focus.remove(focus);
        }
      }),
      onIncludeCardioChanged: (value) => setState(() => _includeCardio = value),
      onMinutesChanged: (value) => setState(() => _minutes = value),
      onShuffle: () => _shuffle(catalog),
      onLogWorkout: _logWorkout,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CatalogLoadScope(
      builder: (context, catalog) {
        _customPlansFuture ??= loadCustomPlans(
          journal: widget.journal,
          catalog: catalog,
        );
        return FutureBuilder<List<PremadePlan>>(
          future: _customPlansFuture,
          builder: (context, snapshot) {
            final customPlans = snapshot.data ?? const <PremadePlan>[];
            return _PlansBody(
              catalog: catalog,
              customPlans: customPlans,
              step: _step,
              answers: _answers,
              showQuiz: _showQuiz,
              onStartQuiz: () => setState(() {
                _showQuiz = true;
                _step = 0;
                _answers = const QuizAnswers();
              }),
              onQuizBack: () {
                if (_step == 0) {
                  setState(() => _showQuiz = false);
                } else {
                  setState(() => _step -= 1);
                }
              },
              onQuizChoose: (answers, done) {
                setState(() {
                  _answers = answers;
                  if (done) {
                    _step = 6;
                  } else {
                    _step += 1;
                  }
                });
              },
              onQuizRestart: () => setState(() {
                _step = 0;
                _answers = const QuizAnswers();
              }),
              onLogWorkout: _logWorkout,
              onSchedulePlan: _schedulePlan,
              onOpenShuffle: () => _openShuffleSheet(catalog),
            );
          },
        );
      },
    );
  }
}

class _PlansBody extends StatelessWidget {
  const _PlansBody({
    required this.catalog,
    required this.customPlans,
    required this.step,
    required this.answers,
    required this.showQuiz,
    required this.onStartQuiz,
    required this.onQuizBack,
    required this.onQuizChoose,
    required this.onQuizRestart,
    required this.onLogWorkout,
    required this.onSchedulePlan,
    required this.onOpenShuffle,
  });

  final LiftBigCatalog catalog;
  final List<PremadePlan> customPlans;
  final int step;
  final QuizAnswers answers;
  final bool showQuiz;
  final VoidCallback onStartQuiz;
  final VoidCallback onQuizBack;
  final void Function(QuizAnswers answers, bool done) onQuizChoose;
  final VoidCallback onQuizRestart;
  final Future<void> Function(CatalogWorkout workout, String? planName) onLogWorkout;
  final Future<void> Function(String planTitle, List<CatalogWorkout> workouts)
      onSchedulePlan;
  final VoidCallback onOpenShuffle;

  List<PremadePlan> get _premadePlans => [
        ...catalog.plans,
        if (catalog.starterWorkouts.isNotEmpty)
          PremadePlan(
            id: 'starter-workouts',
            name: 'Starter workouts',
            purpose: 'Single sessions that are not part of a multi-day plan.',
            workouts: catalog.starterWorkouts,
          ),
      ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const Center(
          child: Text(
            'PLANS',
            style: TextStyle(
              color: LiftBigColors.primary,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Plan Picker',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
              foregroundColor: LiftBigColors.primary,
            ),
            onPressed: showQuiz ? null : onStartQuiz,
            child: const Text(
              'Unsure where to start? Click here to see which plan we recommend.',
              textAlign: TextAlign.left,
            ),
          ),
        ),
        if (showQuiz)
          _Quiz(
            step: step,
            answers: answers,
            catalog: catalog.quiz,
            onBack: onQuizBack,
            onChoose: onQuizChoose,
            onRestart: onQuizRestart,
            workoutsFor: (ids) => [
              for (final id in ids)
                if (catalog.workoutById(id) != null) catalog.workoutById(id)!,
            ],
            onLog: onLogWorkout,
            onSchedulePlan: onSchedulePlan,
          ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: onOpenShuffle,
          child: const Text('Shuffle a workout'),
        ),
        const SizedBox(height: 24),
        _SearchablePlanSection(
          title: 'Premade Plans',
          catalog: catalog,
          plans: _premadePlans,
          onLog: onLogWorkout,
        ),
        const SizedBox(height: 8),
        _SearchablePlanSection(
          title: 'Community Plans',
          catalog: catalog,
          plans: const [],
          onLog: onLogWorkout,
          header: const Padding(
            padding: EdgeInsets.fromLTRB(0, 0, 0, 12),
            child: Text(
              'Sharing plans with other people is not available yet. There is no upload, account, or feed.',
              style: TextStyle(color: LiftBigColors.muted),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _SearchablePlanSection(
          title: 'Custom Plans',
          catalog: catalog,
          plans: customPlans,
          onLog: onLogWorkout,
          emptyMessage: 'You have not created a plan yet.',
        ),
      ],
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({required this.plan, required this.onLog});

  final PremadePlan plan;
  final Future<void> Function(CatalogWorkout workout, String? planName) onLog;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(plan.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          '${plan.workouts.length} workouts'
          '${plan.purpose.isEmpty ? '' : ' · ${plan.purpose}'}',
          style: const TextStyle(color: LiftBigColors.muted),
        ),
        children: [
          for (final workout in plan.workouts)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          workout.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        for (final lift in workout.lifts)
                          Text(
                            '${lift.name} · ${lift.sets.length} sets',
                            style: const TextStyle(color: LiftBigColors.muted),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Log this workout today',
                    onPressed: () => onLog(workout, plan.name),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Quiz extends StatelessWidget {
  const _Quiz({
    required this.step,
    required this.answers,
    required this.catalog,
    required this.onBack,
    required this.onChoose,
    required this.onRestart,
    required this.workoutsFor,
    required this.onLog,
    required this.onSchedulePlan,
  });

  final int step;
  final QuizAnswers answers;
  final List<QuizEntry> catalog;
  final VoidCallback onBack;
  final void Function(QuizAnswers answers, bool done) onChoose;
  final VoidCallback onRestart;
  final List<CatalogWorkout> Function(List<String> ids) workoutsFor;
  final Future<void> Function(CatalogWorkout workout, String? planName) onLog;
  final Future<void> Function(String planTitle, List<CatalogWorkout> workouts)
      onSchedulePlan;

  @override
  Widget build(BuildContext context) {
    final results = step >= 6;
    final matches = results ? recommendPlans(catalog, answers) : const <PlanMatch>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            TextButton(onPressed: onBack, child: const Text('Back')),
            const Spacer(),
            Text(
              results ? 'Your recommendations' : 'Step ${step + 1} of 6',
              style: const TextStyle(color: LiftBigColors.muted, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        if (!results) ...[
          Text(
            _titles[step],
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          for (final choice in _choices[step])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                onPressed: () => onChoose(_apply(answers, step, choice.value), step == 5),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(choice.title),
                      Text(
                        choice.detail,
                        style: const TextStyle(color: LiftBigColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ] else ...[
          Text(quizHeadline(answers)),
          const SizedBox(height: 12),
          for (final match in matches) ...[
            Text(match.badge, style: const TextStyle(color: LiftBigColors.primary, fontWeight: FontWeight.w800)),
            Text(match.entry.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            Text(match.entry.description),
            if (match.reasons.isNotEmpty)
              Text(
                match.reasons.join(' · '),
                style: const TextStyle(color: LiftBigColors.muted),
              ),
            if (workoutsFor(match.entry.workoutIds).isNotEmpty) ...[
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => onSchedulePlan(
                  match.entry.title,
                  workoutsFor(match.entry.workoutIds),
                ),
                child: const Text('Add to calendar'),
              ),
            ],
            for (final workout in workoutsFor(match.entry.workoutIds)) ...[
              const SizedBox(height: 6),
              Text(workout.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(
                workout.lifts.map((lift) => lift.name).join(', '),
                style: const TextStyle(color: LiftBigColors.muted),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => onLog(workout, match.entry.title),
                  child: const Text('Log this workout today'),
                ),
              ),
            ],
            const SizedBox(height: 12),
          ],
          OutlinedButton(onPressed: onRestart, child: const Text('Start over')),
        ],
      ],
    );
  }
}

QuizAnswers _apply(QuizAnswers answers, int step, Object value) {
  return switch (step) {
    0 => answers.copyWith(experience: value as String),
    1 => answers.copyWith(goal: value as String),
    2 => answers.copyWith(daysPerWeek: value as int),
    3 => answers.copyWith(duration: value as String),
    4 => answers.copyWith(equipment: value as String),
    _ => answers.copyWith(style: value as String),
  };
}

const _titles = [
  'How experienced are you?',
  "What's your main goal?",
  'How many days can you train?',
  'How long are your sessions?',
  'What equipment do you have?',
  'What training style do you prefer?',
];

const _choices = <List<_QuizChoice>>[
  [
    _QuizChoice('beginner', 'Beginner', 'New to lifting or inconsistent'),
    _QuizChoice('intermediate', 'Intermediate', 'Comfortable in the gym'),
    _QuizChoice('experienced', 'Experienced', 'Several years of training'),
    _QuizChoice('liftaholic', 'Liftaholic', 'Lives in the gym'),
  ],
  [
    _QuizChoice('strength', 'Build Strength', 'Increase compound lifts'),
    _QuizChoice('size', 'Build Size', 'Hypertrophy and aesthetics'),
    _QuizChoice('weightLoss', 'Lose Weight', 'Keep muscle while burning more'),
    _QuizChoice('liftBig', 'I Just Wanna Lift Big', 'High-volume balanced training'),
  ],
  [
    _QuizChoice(2, '2 days', 'Minimal commitment'),
    _QuizChoice(3, '3 days', 'Balanced weekly load'),
    _QuizChoice(4, '4 days', 'Balanced weekly load'),
    _QuizChoice(5, '5 days', 'Balanced weekly load'),
    _QuizChoice(6, '6 days', 'High frequency'),
    _QuizChoice(7, '7 days', 'High frequency'),
  ],
  [
    _QuizChoice('quick', 'Quick (about 30 min)', 'Short, focused sessions'),
    _QuizChoice('standard', 'Standard (about 60 min)', 'Classic gym session'),
    _QuizChoice('long', 'Long (60–90+ min)', 'More volume and accessories'),
  ],
  [
    _QuizChoice('commercialGym', 'Commercial Gym', 'Barbells and machines'),
    _QuizChoice('planetFitness', 'Planet Fitness', 'Full gym access'),
    _QuizChoice('homeGym', 'Home Gym', 'Barbell, rack, and some equipment'),
    _QuizChoice('dumbbellsOnly', 'Dumbbells Only', 'Pairs of dumbbells'),
    _QuizChoice('minimalEquipment', 'Minimal Equipment', 'Bodyweight and bands'),
  ],
  [
    _QuizChoice('balanced', 'Balanced', 'Compounds and accessories'),
    _QuizChoice('compound', 'Heavy Compound Focus', 'Squat, bench, deadlift'),
    _QuizChoice('bodybuilding', 'Bodybuilding', 'Isolation and pump'),
    _QuizChoice('minimalist', 'Minimalist', 'Few exercises, high quality'),
    _QuizChoice('supersets', 'Supersets / Fast Pace', 'Keep the heart rate up'),
    _QuizChoice('machines', 'Machines Preferred', 'Stable paths'),
    _QuizChoice('aesthetic', 'Aesthetic / V-Taper', 'Shoulders, back, proportions'),
    _QuizChoice('athletic', 'Athletic', 'Power and conditioning'),
  ],
];

class _SearchablePlanSection extends StatefulWidget {
  const _SearchablePlanSection({
    required this.title,
    required this.catalog,
    required this.plans,
    required this.onLog,
    this.header,
    this.emptyMessage,
  });

  final String title;
  final LiftBigCatalog catalog;
  final List<PremadePlan> plans;
  final Future<void> Function(CatalogWorkout workout, String? planName) onLog;
  final Widget? header;
  final String? emptyMessage;

  @override
  State<_SearchablePlanSection> createState() => _SearchablePlanSectionState();
}

class _SearchablePlanSectionState extends State<_SearchablePlanSection> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text;
    final filtered = [
      for (final plan in widget.plans)
        if (planMatchesSearch(plan, widget.catalog, query)) plan,
    ];

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: false,
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        iconColor: LiftBigColors.muted,
        collapsedIconColor: LiftBigColors.muted,
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        children: [
          TextField(
            controller: _search,
            decoration: const InputDecoration(
              hintText: 'Search plans',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          if (widget.header != null) widget.header!,
          if (filtered.isEmpty && widget.plans.isNotEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'No plans match your search.',
                style: TextStyle(color: LiftBigColors.muted),
              ),
            )
          else if (filtered.isEmpty && widget.emptyMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                widget.emptyMessage!,
                style: const TextStyle(color: LiftBigColors.muted),
              ),
            )
          else
            for (final plan in filtered)
              _PlanTile(plan: plan, onLog: widget.onLog),
        ],
      ),
    );
  }
}

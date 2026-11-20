import 'package:flutter/material.dart';

import '../catalog/lift_search.dart';
import '../catalog/liftbig_catalog.dart';
import '../theme.dart';
import 'keyboard_dismiss.dart';
import 'liftbig_sheet.dart';

const List<String> commonLifts = [
  'Bench Press',
  'Squat',
  'Deadlift',
  'Overhead Press',
  'Barbell Row',
  'Pull-Up',
  'Romanian Deadlift',
  'Lat Pulldown',
];

typedef AddNamedExercise = void Function(
  String name, {
  String? libraryId,
  bool isCardio,
  bool isCore,
});

/// Bottom-of-day card. The add sheet uses the same form.
class AddExerciseCard extends StatelessWidget {
  const AddExerciseCard({
    super.key,
    required this.name,
    required this.nameFocus,
    required this.error,
    required this.onAddNamed,
    required this.onAddCustom,
  });

  final TextEditingController name;
  final FocusNode nameFocus;
  final String? error;
  final AddNamedExercise onAddNamed;
  final VoidCallback onAddCustom;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _AddExerciseForm(
          name: name,
          nameFocus: nameFocus,
          error: error,
          onAddNamed: onAddNamed,
          onAddCustom: onAddCustom,
        ),
      ),
    );
  }
}

/// Opens the add-exercise sheet. [onAddNamed] is the day's existing add path.
Future<void> showAddExerciseSheet(
  BuildContext context, {
  required AddNamedExercise onAddNamed,
}) async {
  await showLiftBigSheet<void>(
    context,
    builder: (context) => _AddExerciseSheet(onAddNamed: onAddNamed),
  );
}

class _AddExerciseSheet extends StatefulWidget {
  const _AddExerciseSheet({required this.onAddNamed});

  final AddNamedExercise onAddNamed;

  @override
  State<_AddExerciseSheet> createState() => _AddExerciseSheetState();
}

class _AddExerciseSheetState extends State<_AddExerciseSheet> {
  final _name = TextEditingController();
  final _focus = FocusNode();
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _pick(
    String name, {
    String? libraryId,
    bool isCardio = false,
    bool isCore = false,
  }) {
    final add = widget.onAddNamed;
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop();
    add(name, libraryId: libraryId, isCardio: isCardio, isCore: isCore);
  }

  void _addCustom() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name the exercise first.');
      return;
    }
    _pick(name);
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDismiss(
      fill: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wanted = liftBigPreferredHeight(context, 0.7);
          final cap = constraints.maxHeight;
          final height = cap.isFinite && cap < wanted ? cap : wanted;
          return SizedBox(
            height: height,
            child: ListView(
              primary: false,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                _AddExerciseForm(
                  name: _name,
                  nameFocus: _focus,
                  error: _error,
                  onAddNamed: _pick,
                  onAddCustom: _addCustom,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AddExerciseForm extends StatefulWidget {
  const _AddExerciseForm({
    required this.name,
    required this.nameFocus,
    required this.error,
    required this.onAddNamed,
    required this.onAddCustom,
    this.autofocus = false,
  });

  final TextEditingController name;
  final FocusNode nameFocus;
  final String? error;
  final AddNamedExercise onAddNamed;
  final VoidCallback onAddCustom;
  final bool autofocus;

  @override
  State<_AddExerciseForm> createState() => _AddExerciseFormState();
}

class _AddExerciseFormState extends State<_AddExerciseForm> {
  List<LibraryLift> _catalog = const [];

  @override
  void initState() {
    super.initState();
    widget.name.addListener(_onName);
    _loadCatalog();
  }

  @override
  void didUpdateWidget(covariant _AddExerciseForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name) {
      oldWidget.name.removeListener(_onName);
      widget.name.addListener(_onName);
    }
  }

  @override
  void dispose() {
    widget.name.removeListener(_onName);
    super.dispose();
  }

  void _onName() {
    if (mounted) setState(() {});
  }

  Future<void> _loadCatalog() async {
    try {
      final catalog = await LiftBigCatalog.load();
      if (!mounted) return;
      setState(() => _catalog = catalog.lifts);
    } catch (_) {
      return;
    }
  }

  List<LibraryLift> get _suggestions =>
      rankExerciseSuggestions(_catalog, widget.name.text).take(40).toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Add Exercise',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'Pick a common lift or type a name.',
          style: TextStyle(color: context.liftBig.muted),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final lift in commonLifts)
              ActionChip(
                label: Text(lift),
                backgroundColor: context.liftBig.cardInner,
                side: BorderSide(color: context.liftBig.border),
                labelStyle: TextStyle(color: context.liftBig.foreground),
                onPressed: () => widget.onAddNamed(lift),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: widget.name,
                focusNode: widget.nameFocus,
                autofocus: widget.autofocus,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(labelText: 'Exercise Name'),
                onSubmitted: (_) => widget.onAddCustom(),
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: FilledButton(
                onPressed: widget.onAddCustom,
                child: const Text('Add'),
              ),
            ),
          ],
        ),
        if (widget.error != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.error!,
            style: TextStyle(color: context.liftBig.primary),
          ),
        ],
        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 220,
            child: ListView(
              primary: false,
              children: [
                for (final lift in _suggestions)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(lift.name),
                    subtitle: Text(
                      _suggestionDetail(lift),
                      style: TextStyle(color: context.liftBig.muted),
                    ),
                    onTap: () => widget.onAddNamed(
                      lift.name,
                      libraryId: lift.id,
                      isCardio: lift.isCardio,
                      isCore: lift.isCore,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

String _suggestionDetail(LibraryLift lift) {
  final groups = [
    for (final group in lift.muscleGroups) muscleGroupLabels[group] ?? group,
  ];
  if (groups.isEmpty) return lift.equipment;
  return groups.join(', ');
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../catalog/liftbig_catalog.dart';
import '../plans/workout_shuffle.dart';
import '../theme.dart';
import 'liftbig_sheet.dart';

Future<void> showWorkoutShuffleSheet(
  BuildContext context, {
  required LiftBigCatalog catalog,
  required Set<String> Function() equipment,
  required Set<String> Function() focus,
  required bool Function() includeCardio,
  required int Function() minutes,
  required TextEditingController liftSeconds,
  required TextEditingController restSeconds,
  required ShuffledWorkout? Function() shuffled,
  required String? Function() shuffleNote,
  required void Function(String equipment, bool selected) onEquipmentChanged,
  required void Function(String focus, bool selected) onFocusChanged,
  required ValueChanged<bool> onIncludeCardioChanged,
  required ValueChanged<int> onMinutesChanged,
  required VoidCallback onShuffle,
  required Future<void> Function(CatalogWorkout workout, String? planName)
      onLogWorkout,
}) {
  return showLiftBigSheet<void>(
    context,
    builder: (context) => LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        height: constraints.maxHeight,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.94,
          minChildSize: 0.45,
          maxChildSize: 1,
          builder: (context, scrollController) => StatefulBuilder(
        builder: (context, refreshSheet) {
          void refresh() => refreshSheet(() {});
          return _WorkoutShuffleSheet(
            scrollController: scrollController,
            catalog: catalog,
            equipment: equipment,
            focus: focus,
            includeCardio: includeCardio,
            minutes: minutes,
            liftSeconds: liftSeconds,
            restSeconds: restSeconds,
            shuffled: shuffled,
            shuffleNote: shuffleNote,
            onEquipmentChanged: (type, selected) {
              onEquipmentChanged(type, selected);
              refresh();
            },
            onFocusChanged: (type, selected) {
              onFocusChanged(type, selected);
              refresh();
            },
            onIncludeCardioChanged: (value) {
              onIncludeCardioChanged(value);
              refresh();
            },
            onMinutesChanged: (value) {
              onMinutesChanged(value);
              refresh();
            },
            onShuffle: () {
              onShuffle();
              refresh();
            },
            onLogWorkout: onLogWorkout,
          );
        },
      ),
        ),
      ),
    ),
  );
}

class _WorkoutShuffleSheet extends StatelessWidget {
  const _WorkoutShuffleSheet({
    required this.scrollController,
    required this.catalog,
    required this.equipment,
    required this.focus,
    required this.includeCardio,
    required this.minutes,
    required this.liftSeconds,
    required this.restSeconds,
    required this.shuffled,
    required this.shuffleNote,
    required this.onEquipmentChanged,
    required this.onFocusChanged,
    required this.onIncludeCardioChanged,
    required this.onMinutesChanged,
    required this.onShuffle,
    required this.onLogWorkout,
  });

  final ScrollController scrollController;
  final LiftBigCatalog catalog;
  final Set<String> Function() equipment;
  final Set<String> Function() focus;
  final bool Function() includeCardio;
  final int Function() minutes;
  final TextEditingController liftSeconds;
  final TextEditingController restSeconds;
  final ShuffledWorkout? Function() shuffled;
  final String? Function() shuffleNote;
  final void Function(String equipment, bool selected) onEquipmentChanged;
  final void Function(String focus, bool selected) onFocusChanged;
  final ValueChanged<bool> onIncludeCardioChanged;
  final ValueChanged<int> onMinutesChanged;
  final VoidCallback onShuffle;
  final Future<void> Function(CatalogWorkout workout, String? planName)
      onLogWorkout;

  @override
  Widget build(BuildContext context) {
    final equipmentSet = equipment();
    final focusSet = focus();
    final includeCardioValue = includeCardio();
    final minutesValue = minutes();
    final shuffledWorkout = shuffled();
    final note = shuffleNote();

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: context.liftBig.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const Text(
          'Workout shuffle',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
         Text(
          'What you have, what you want to train, how long you have, and how long each lift and rest takes.',
          style: TextStyle(color: context.liftBig.muted),
        ),
        const SizedBox(height: 12),
        _GearMenu(
          title: 'Equipment',
          types: strengthGearChoices(catalog.equipmentTypes),
          selected: equipmentSet,
          onChanged: onEquipmentChanged,
        ),
        _GearMenu(
          title: 'Cardio',
          types: gearPresentInCatalog(cardioGear, catalog.equipmentTypes),
          selected: equipmentSet,
          onChanged: onEquipmentChanged,
        ),
        _GearMenu(
          title: 'Sports',
          types: gearPresentInCatalog(sportsGear, catalog.equipmentTypes),
          selected: equipmentSet,
          onChanged: onEquipmentChanged,
        ),
        const SizedBox(height: 12),
        const Text('Focus', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final focusKey in [
              ...shuffleFocusPatterns,
              ...muscleGroupLabels.keys,
            ])
              FilterChip(
                label: Text(
                  focusKey == 'push' || focusKey == 'pull' || focusKey == 'legs'
                      ? focusKey[0].toUpperCase() + focusKey.substring(1)
                      : muscleGroupLabels[focusKey] ?? focusKey,
                ),
                selected: focusSet.contains(focusKey),
                onSelected: (selected) => onFocusChanged(focusKey, selected),
              ),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Include cardio'),
          value: includeCardioValue,
          activeThumbColor: context.liftBig.primary,
          onChanged: onIncludeCardioChanged,
        ),
        const Text('Time you have', style: TextStyle(fontWeight: FontWeight.w700)),
        Wrap(
          spacing: 8,
          children: [
            for (final option in [30, 45, 60, 90])
              ChoiceChip(
                label: Text('$option min'),
                selected: minutesValue == option,
                onSelected: (_) => onMinutesChanged(option),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: liftSeconds,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Seconds per lift'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: restSeconds,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Seconds per rest'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton(onPressed: onShuffle, child: const Text('Shuffle a workout')),
        if (note != null) ...[
          const SizedBox(height: 8),
          Text(note, style:  TextStyle(color: context.liftBig.primary)),
        ],
        if (shuffledWorkout != null) ...[
          const SizedBox(height: 12),
          Text(
            'About ${shuffledWorkout.minutes} min · ${shuffledWorkout.lifts.length} lifts',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          for (final lift in shuffledWorkout.lifts)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(lift.name),
              subtitle: Text(
                lift.isCardio ? '30 min' : '3 sets · 8-12',
                style:  TextStyle(color: context.liftBig.muted),
              ),
            ),
          OutlinedButton(
            onPressed: () async {
              await onLogWorkout(
                CatalogWorkout(
                  id: 'shuffle',
                  name: 'Shuffled workout',
                  folderId: null,
                  notes: '',
                  lifts: [
                    for (final lift in shuffledWorkout.lifts)
                      CatalogLift(
                        name: lift.name,
                        libraryId: lift.id,
                        isCardio: lift.isCardio,
                        isCore: lift.isCore,
                        isCircuit: false,
                        targetDuration: lift.isCardio ? '30' : null,
                        sets: lift.isCardio
                            ? const [CatalogSet(reps: '30', weight: '')]
                            : const [
                                CatalogSet(reps: '8-12', weight: ''),
                                CatalogSet(reps: '8-12', weight: ''),
                                CatalogSet(reps: '8-12', weight: ''),
                              ],
                      ),
                  ],
                ),
                null,
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Log this workout today'),
          ),
        ],
      ],
    );
  }
}

class _GearMenu extends StatelessWidget {
  const _GearMenu({
    required this.title,
    required this.types,
    required this.selected,
    required this.onChanged,
  });

  final String title;
  final List<String> types;
  final Set<String> selected;
  final void Function(String equipment, bool selected) onChanged;

  @override
  Widget build(BuildContext context) {
    if (types.isEmpty) return const SizedBox.shrink();
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: false,
        tilePadding: EdgeInsets.zero,
        iconColor: context.liftBig.muted,
        collapsedIconColor: context.liftBig.muted,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final equipmentType in types)
                  FilterChip(
                    label: Text(equipmentType),
                    selected: selected.contains(equipmentType),
                    onSelected: (isSelected) =>
                        onChanged(equipmentType, isSelected),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

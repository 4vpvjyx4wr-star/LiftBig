import 'package:flutter/material.dart';

import '../catalog/liftbig_catalog.dart';
import '../theme.dart';
import '../utils/youtube_video_id.dart';
import 'catalog_load_state.dart';
import 'exercise_tutorial.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final _query = TextEditingController();
  String _muscle = 'all';

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CatalogLoadScope(
      builder: (context, catalog) => _LibraryBody(
        catalog: catalog,
        query: _query,
        muscle: _muscle,
        onMuscleChanged: (value) => setState(() => _muscle = value),
        onQueryChanged: () => setState(() {}),
      ),
    );
  }
}

class _LibraryBody extends StatelessWidget {
  const _LibraryBody({
    required this.catalog,
    required this.query,
    required this.muscle,
    required this.onMuscleChanged,
    required this.onQueryChanged,
  });

  final LiftBigCatalog catalog;
  final TextEditingController query;
  final String muscle;
  final ValueChanged<String> onMuscleChanged;
  final VoidCallback onQueryChanged;

  @override
  Widget build(BuildContext context) {
    final filtered = searchLifts(catalog.lifts, query.text).where((lift) {
      if (muscle == 'all') return true;
      if (muscle == 'cardio') return lift.isCardio;
      return lift.muscleGroups.contains(muscle);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lift Library',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                'A lift and an exercise are the same activity. Descriptions, cues, and tutorial links come from the LiftBig catalog.',
                style: TextStyle(color: LiftBigColors.muted),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: query,
                decoration: const InputDecoration(
                  labelText: 'Search lifts',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (_) => onQueryChanged(),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              _FilterChip(
                label: 'All',
                selected: muscle == 'all',
                onTap: () => onMuscleChanged('all'),
              ),
              _FilterChip(
                label: 'Cardio',
                selected: muscle == 'cardio',
                onTap: () => onMuscleChanged('cardio'),
              ),
              for (final entry in muscleGroupLabels.entries)
                _FilterChip(
                  label: entry.value,
                  selected: muscle == entry.key,
                  onTap: () => onMuscleChanged(entry.key),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final lift = filtered[index];
              return Material(
                color: LiftBigColors.card,
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  title: Text(lift.name),
                  subtitle: Text(
                    [
                      if (lift.equipment.isNotEmpty) lift.equipment,
                      ...lift.muscleGroups.map(
                        (group) => muscleGroupLabels[group] ?? group,
                      ),
                    ].join(' · '),
                    style: const TextStyle(color: LiftBigColors.muted),
                  ),
                  trailing: lift.tutorialUrl.isEmpty
                      ? null
                      : const Icon(Icons.smart_display_outlined, color: LiftBigColors.primary),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => LiftDetailPage(lift: lift),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class LiftDetailPage extends StatelessWidget {
  const LiftDetailPage({super.key, required this.lift});

  final LibraryLift lift;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(lift.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(lift.summary, style: const TextStyle(fontSize: 16)),
          if (lift.instructions.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'How to perform it',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < lift.instructions.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('${i + 1}. ${lift.instructions[i]}'),
              ),
          ],
          if (lift.cues.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Cues',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            for (final cue in lift.cues)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('• $cue'),
              ),
          ],
          if (lift.tips.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Tips',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            for (final tip in lift.tips)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('• $tip'),
              ),
          ],
          if (youtubeVideoIdFromUrl(lift.tutorialUrl) case final videoId?) ...[
            const SizedBox(height: 20),
            const Text(
              'Tutorial',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            ExerciseTutorial(url: lift.tutorialUrl, videoId: videoId),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: LiftBigColors.primary,
        labelStyle: TextStyle(
          color: selected ? LiftBigColors.foreground : LiftBigColors.muted,
          fontWeight: FontWeight.w700,
        ),
        side: const BorderSide(color: LiftBigColors.border),
        backgroundColor: LiftBigColors.card,
      ),
    );
  }
}

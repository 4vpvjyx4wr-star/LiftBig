import '../journal/lift_name_convergence.dart';
import 'plates.dart';

/// Library ids for the barbell compounds that draw a plate graphic.
const Set<String> barbellPlateLibraryIds = {
  'squat',
  'back-squat',
  'front-squat',
  'zercher-squat',
  'bench-press',
  'decline-bench-press',
  'overhead-press',
  'deadlift',
  'conventional-deadlift',
  'sumo-deadlift',
  'romanian-deadlift',
  'rdl',
  'barbell-row',
  'pendlay-row',
  'hip-thrust',
  'good-morning',
};

/// Names listed under the Plate Graphic setting, in subtitle order.
const List<String> plateGraphicExampleNames = [
  'Squat',
  'bench',
  'decline bench',
  'overhead press',
  'deadlift variants',
  'barbell row',
  'Pendlay row',
  'hip thrust',
  'good morning',
];

/// Sentence form of [plateGraphicExampleNames], matching the warm-up subtitle.
String get plateGraphicExamplesLabel {
  final names = plateGraphicExampleNames;
  final head = names.sublist(0, names.length - 1).join(', ');
  return '$head, and ${names.last}.';
}

/// Back squat, bench, deadlift, rows, and the other loaded barbell compounds.
///
/// Curls, shrugs, and skull crushers stay off, as do machines and dumbbells.
bool isBarbellCompoundPlateLift({String? libraryId, required String name}) {
  final id = (libraryId ?? '').trim().toLowerCase();
  if (barbellPlateLibraryIds.contains(id)) return true;
  final nameKey = normalizeForExerciseMatch(name);
  final idKey = normalizeForExerciseMatch(id);
  if (_plateGraphicExcluded(nameKey) || _plateGraphicExcluded(idKey)) {
    return false;
  }
  return _plateGraphicName(nameKey) || _plateGraphicName(idKey);
}

bool _plateGraphicExcluded(String key) {
  if (key.isEmpty) return false;
  const blocked = [
    'curl',
    'shrug',
    'skull',
    'hack',
    'smith',
    'goblet',
    'pistol',
    'sissy',
    'dumbbell',
    'kettlebell',
    'cable',
    'machine',
    'incline',
    'trapbar',
  ];
  for (final needle in blocked) {
    if (key.contains(needle)) return true;
  }
  return false;
}

bool _plateGraphicName(String key) {
  if (key.isEmpty) return false;
  if (key.contains('zercher') && key.contains('squat')) return true;
  if (key.contains('frontsquat')) return true;
  if (key == 'squat' || key.contains('backsquat') || key == 'barbellsquat') {
    return true;
  }
  if (key.contains('decline') && key.contains('bench')) return true;
  if (key.contains('benchpress') || key == 'bench') return true;
  if (key.contains('overheadpress') ||
      key == 'ohp' ||
      key.contains('militarypress')) {
    return true;
  }
  if (key.contains('romanian') || key.contains('rdl')) return true;
  if (key.contains('deadlift')) return true;
  if (key.contains('pendlay')) return true;
  if (key.contains('barbellrow') || key == 'bentoverrow') return true;
  if (key.contains('hipthrust')) return true;
  if (key.contains('goodmorning')) return true;
  return false;
}

/// On unless the stored value is the word `false`.
bool showPlateGraphicFromStored(String? raw) => raw != 'false';

/// Plate-calculator bar. 45 lb unless a stored preset is the 35 lb bar.
double standardBarLbFromStored(String? raw) {
  final parsed = double.tryParse((raw ?? '').trim());
  if (parsed == null) return defaultBarLb;
  for (final choice in barChoicesLb) {
    if ((parsed - choice).abs() < 0.001) return choice;
  }
  return defaultBarLb;
}

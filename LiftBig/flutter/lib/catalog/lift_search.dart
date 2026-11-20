import 'liftbig_catalog.dart';

/// Older catalog names that still have to find the renamed lift.
const legacyLiftSearchNames = <String, String>{
  'flat-dumbbell-press': 'flat dumbbell press',
  'incline-dumbbell-press': 'incline dumbbell press',
  'chest-supported-row': 'chest supported row',
  'overhead-press': 'overhead press ohp military press',
  'lateral-raise': 'lateral raise',
  'rear-delt-fly': 'rear delt fly',
  'overhead-tricep-extension': 'overhead tricep extension',
  'hammer-curl': 'hammer curl',
  'romanian-deadlift': 'romanian deadlift rdl',
  'dumbbell-romanian-deadlift': 'romanian deadlift rdl',
  'deadlift': 'conventional deadlift deadlift',
  'walking-lunge': 'walking lunge',
  'goblet-squat': 'goblet squat',
  'hip-thrust': 'hip thrust',
  'arnold-press': 'arnold press',
  'bulgarian-split-squat': 'bulgarian split squat',
  't-bar-row': 't-bar row tbar row',
  'pendlay-row': 'pendlay row',
  'skull-crusher': 'skull crusher',
  'preacher-curl': 'preacher curl',
  'good-morning': 'good morning good mornings',
  'farmers-walk': "farmer's carry farmers walk",
  'sumo-deadlift': 'sumo deadlift',
  'front-squat': 'front squat',
  'zercher-squat': 'zercher squat',
  'sumo-squat': 'sumo squat plie squat',
  'bench-press': 'bench press flat bench',
  'decline-bench-press': 'decline bench press',
  'barbell-row': 'barbell row bent over row',
};

/// One token, or a short phrase, that means a whole family of lifts.
const _abbreviations = <String, List<String>>{
  'rdl': ['romanian deadlift'],
  'rdls': ['romanian deadlift'],
  'ohp': ['overhead press'],
  'dl': ['deadlift'],
  'bp': ['bench press'],
  'gm': ['good morning'],
  'gms': ['good morning'],
};

/// Colloquial muscle and body-part words. A lift matches when it trains any
/// listed group, except the special back phrases below.
const _muscleWords = <String, Set<String>>{
  'hammies': {'hamstrings'},
  'hammy': {'hamstrings'},
  'hamstring': {'hamstrings'},
  'hamstrings': {'hamstrings'},
  'quad': {'quads'},
  'quads': {'quads'},
  'quadricep': {'quads'},
  'quadriceps': {'quads'},
  'thighs': {'quads'},
  'glute': {'glutes'},
  'glutes': {'glutes'},
  'booty': {'glutes'},
  'pec': {'chest'},
  'pecs': {'chest'},
  'chest': {'chest'},
  'delt': {'shoulders'},
  'delts': {'shoulders'},
  'shoulder': {'shoulders'},
  'shoulders': {'shoulders'},
  'bicep': {'biceps'},
  'biceps': {'biceps'},
  'tricep': {'triceps'},
  'triceps': {'triceps'},
  'tris': {'triceps'},
  'calf': {'calves'},
  'calves': {'calves'},
  'ab': {'core'},
  'abs': {'core'},
  'core': {'core'},
  'forearm': {'forearms'},
  'forearms': {'forearms'},
  'lat': {'back'},
  'lats': {'back'},
  'trap': {'back'},
  'traps': {'back'},
  'leg': {'quads', 'hamstrings', 'glutes', 'calves'},
  'legs': {'quads', 'hamstrings', 'glutes', 'calves'},
  'back': {'back'},
  'pull': {'back', 'biceps'},
  'push': {'chest', 'shoulders', 'triceps'},
};

/// Search names, equipment, cues, abbreviations, and muscle groups.
/// An empty query keeps [lifts].
List<LibraryLift> searchLifts(List<LibraryLift> lifts, String query) {
  final prepared = _prepareQuery(query);
  if (prepared.isEmpty) return lifts;
  return [
    for (final lift in lifts)
      if (libraryLiftMatchesQuery(lift, prepared)) lift,
  ];
}

/// True when [query] is a name, abbreviation, nickname, or muscle group for [lift].
bool libraryLiftMatchesQuery(LibraryLift lift, String query) {
  final prepared = _prepareQuery(query);
  if (prepared.isEmpty) return true;
  if (prepared == 'lower back' || prepared == 'lowerback') {
    return _matchesLowerBack(lift);
  }
  if (prepared == 'upper back' || prepared == 'upperback') {
    return _matchesUpperBack(lift);
  }
  final haystack = _haystack(lift);
  final tokens = prepared.split(' ');
  if (tokens.length == 1 && _abbreviations.containsKey(tokens.single)) {
    return _abbreviationMatches(haystack, tokens.single);
  }
  return tokens.every((token) => _tokenMatches(lift, haystack, token));
}

/// Name matches first, then abbreviations, then muscle groups and tags.
List<LibraryLift> rankExerciseSuggestions(List<LibraryLift> lifts, String query) {
  final prepared = _prepareQuery(query);
  if (prepared.isEmpty) return const [];
  final phrases = _namePhrases(prepared);
  final prefix = <LibraryLift>[];
  final contains = <LibraryLift>[];
  final related = <LibraryLift>[];
  for (final lift in lifts) {
    final name = lift.name.toLowerCase();
    if (phrases.any((phrase) => _namePrefixMatch(name, phrase))) {
      prefix.add(lift);
    } else if (phrases.any((phrase) => name.contains(phrase)) ||
        _legacyName(lift).contains(prepared)) {
      contains.add(lift);
    } else if (libraryLiftMatchesQuery(lift, prepared)) {
      related.add(lift);
    }
  }
  return [...prefix, ...contains, ...related];
}

String _prepareQuery(String query) {
  var text = query.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  if (text.isEmpty) return '';
  const phrases = <String, String>{
    'ham strings': 'hamstrings',
    'ham string': 'hamstrings',
    'lower back': 'lower back',
    'upper back': 'upper back',
  };
  for (final entry in phrases.entries) {
    text = text.replaceAll(entry.key, entry.value);
  }
  return text.trim();
}

List<String> _namePhrases(String prepared) {
  final phrases = <String>[prepared];
  final tokens = prepared.split(' ');
  if (tokens.length == 1) {
    phrases.addAll(_abbreviations[tokens.single] ?? const []);
  }
  return phrases;
}

bool _namePrefixMatch(String name, String query) {
  if (query.isEmpty) return false;
  if (name.startsWith(query) && _prefixBoundary(name, query)) return true;
  final words = name.split(RegExp(r'[^a-z0-9]+'));
  return words.any((word) {
    if (word.isEmpty) return false;
    if (query.length < 3) return word == query;
    return word.startsWith(query);
  });
}

/// Two-letter queries such as "ab" match a whole word, not the start of
/// "barbell" or "cable".
bool _prefixBoundary(String name, String query) {
  if (query.length >= 3 || name.length == query.length) return true;
  return !RegExp(r'[a-z0-9]').hasMatch(name[query.length]);
}

bool _tokenMatches(LibraryLift lift, String haystack, String token) {
  if (token.isEmpty) return true;
  final reserved =
      token.length <= 3 &&
      (_muscleWords.containsKey(token) || _abbreviations.containsKey(token));
  if (!reserved && haystack.contains(token)) return true;
  if (reserved && _haystackHasWord(haystack, token)) return true;
  if (_abbreviationMatches(haystack, token)) return true;
  final groups = _muscleWords[token];
  if (groups != null && _trainsAny(lift, groups)) return true;
  return false;
}

bool _haystackHasWord(String haystack, String token) {
  return RegExp('\\b${RegExp.escape(token)}\\b').hasMatch(haystack);
}

bool _abbreviationMatches(String haystack, String token) {
  final phrases = _abbreviations[token];
  if (phrases == null) return false;
  for (final phrase in phrases) {
    if (haystack.contains(phrase)) return true;
  }
  return false;
}

bool _trainsAny(LibraryLift lift, Set<String> groups) {
  for (final group in lift.muscleGroups) {
    if (groups.contains(group.toLowerCase())) return true;
  }
  if (groups.contains('push')) {
    final tags = lift.tags.map((tag) => tag.toLowerCase());
    if (tags.contains('push')) return true;
  }
  return false;
}

bool _matchesLowerBack(LibraryLift lift) {
  final name = '${lift.name} ${_legacyName(lift)}'.toLowerCase();
  if (name.contains('good morning') ||
      name.contains('deadlift') ||
      name.contains('rdl') ||
      name.contains('hyperextension') ||
      name.contains('back extension')) {
    return true;
  }
  final groups = lift.muscleGroups.map((group) => group.toLowerCase()).toSet();
  return groups.contains('back') &&
      (groups.contains('hamstrings') || groups.contains('glutes'));
}

bool _matchesUpperBack(LibraryLift lift) {
  if (_matchesLowerBack(lift) &&
      !lift.name.toLowerCase().contains('row') &&
      !lift.name.toLowerCase().contains('pulldown') &&
      !lift.name.toLowerCase().contains('pull-up') &&
      !lift.name.toLowerCase().contains('pull up')) {
    return false;
  }
  return _trainsAny(lift, const {'back'});
}

String _haystack(LibraryLift lift) {
  return [
    lift.name,
    lift.equipment,
    lift.summary,
    _legacyName(lift),
    ...lift.tags,
    ...lift.muscleGroups.map((group) => muscleGroupLabels[group] ?? group),
    ...lift.cues,
  ].join(' ').toLowerCase();
}

String _legacyName(LibraryLift lift) => legacyLiftSearchNames[lift.id] ?? '';

import '../catalog/liftbig_catalog.dart';

/// Lowercase alphanumeric only — "Push-Up" and "push ups" both become "pushups".
String normalizeForExerciseMatch(String s) {
  return s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
}

/// Same movement spelling after normalization — not token/suffix near-match.
bool isExactNormalizedExerciseNameMatch(String a, String b) {
  final left = normalizeForExerciseMatch(a);
  final right = normalizeForExerciseMatch(b);
  return left.isNotEmpty && left == right;
}

/// Word tokens from an exercise name (lowercase letters and digits).
List<String> exerciseNameTokens(String s) {
  return s
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((token) => token.isNotEmpty)
      .toList();
}

/// True when two lift names likely refer to the same movement (precise, not fuzzy search).
bool liftNamesConverge(String a, String b) {
  final left = a.trim();
  final right = b.trim();
  if (left.isEmpty || right.isEmpty) return false;
  if (left.toLowerCase() == right.toLowerCase()) return true;

  final normLeft = normalizeForExerciseMatch(left);
  final normRight = normalizeForExerciseMatch(right);
  if (normLeft.isNotEmpty && normLeft == normRight) return true;

  return _tokenSuffixConverge(left, right);
}

/// Longer name ends with the shorter name's token sequence (min 2 tokens on the shorter side).
bool _tokenSuffixConverge(String a, String b) {
  final tokensA = exerciseNameTokens(a);
  final tokensB = exerciseNameTokens(b);
  if (tokensA.isEmpty || tokensB.isEmpty) return false;

  final shorter = tokensA.length <= tokensB.length ? tokensA : tokensB;
  final longer = tokensA.length <= tokensB.length ? tokensB : tokensA;
  if (shorter.length < 2) return false;
  if (shorter.length >= longer.length) return false;

  final offset = longer.length - shorter.length;
  for (var i = 0; i < shorter.length; i++) {
    if (longer[offset + i] != shorter[i]) return false;
  }
  return true;
}

/// One library lift that resembles logged names in a cluster.
class LiftNameLibraryMatch {
  const LiftNameLibraryMatch({required this.id, required this.name});

  final String id;
  final String name;
}

/// Logged spellings and matching library lifts that may be the same activity.
class LiftNameConvergenceCluster {
  const LiftNameConvergenceCluster({
    required this.loggedNames,
    required this.libraryMatches,
  });

  final List<String> loggedNames;
  final List<LiftNameLibraryMatch> libraryMatches;

  bool get isEmpty => loggedNames.isEmpty && libraryMatches.isEmpty;
}

/// Groups logged exercise names with each other and with catalog lifts they may match.
List<LiftNameConvergenceCluster> findLiftNameConvergenceClusters({
  required Iterable<String> loggedExerciseNames,
  required List<LibraryLift> catalogLifts,
}) {
  final logged = <String>{};
  for (final raw in loggedExerciseNames) {
    final name = raw.trim();
    if (name.isNotEmpty) logged.add(name);
  }
  if (logged.isEmpty) return const [];

  final loggedList = logged.toList();
  final libraryById = <String, LibraryLift>{
    for (final lift in catalogLifts) lift.id: lift,
  };

  final linkedLibraryIds = <String>{};
  for (final lift in catalogLifts) {
    for (final name in loggedList) {
      if (isExactNormalizedExerciseNameMatch(name, lift.name)) {
        continue;
      }
      if (liftNamesConverge(name, lift.name)) {
        linkedLibraryIds.add(lift.id);
        break;
      }
    }
  }

  final nodeCount = loggedList.length + linkedLibraryIds.length;
  if (nodeCount < 2) return const [];

  final parent = List<int>.generate(nodeCount, (index) => index);

  int find(int index) {
    if (parent[index] != index) parent[index] = find(parent[index]);
    return parent[index];
  }

  void union(int a, int b) {
    final rootA = find(a);
    final rootB = find(b);
    if (rootA != rootB) parent[rootB] = rootA;
  }

  final linkedLibraryList = linkedLibraryIds.toList()..sort();

  int loggedIndex(String name) => loggedList.indexOf(name);
  int libraryIndex(String id) => loggedList.length + linkedLibraryList.indexOf(id);

  for (var i = 0; i < loggedList.length; i++) {
    for (var j = i + 1; j < loggedList.length; j++) {
      if (liftNamesConverge(loggedList[i], loggedList[j])) {
        union(i, j);
      }
    }
  }

  for (final name in loggedList) {
    final logIdx = loggedIndex(name);
    for (final liftId in linkedLibraryList) {
      final lift = libraryById[liftId]!;
      if (isExactNormalizedExerciseNameMatch(name, lift.name)) {
        continue;
      }
      if (liftNamesConverge(name, lift.name)) {
        union(logIdx, libraryIndex(liftId));
      }
    }
  }

  for (var i = 0; i < linkedLibraryList.length; i++) {
    for (var j = i + 1; j < linkedLibraryList.length; j++) {
      final left = libraryById[linkedLibraryList[i]]!;
      final right = libraryById[linkedLibraryList[j]]!;
      if (liftNamesConverge(left.name, right.name)) {
        union(libraryIndex(left.id), libraryIndex(right.id));
      }
    }
  }

  final components = <int, List<int>>{};
  for (var index = 0; index < nodeCount; index++) {
    final root = find(index);
    components.putIfAbsent(root, () => []).add(index);
  }

  final clusters = <LiftNameConvergenceCluster>[];
  for (final indices in components.values) {
    if (indices.length < 2) continue;

    final loggedNames = <String>[];
    final libraryMatches = <LiftNameLibraryMatch>[];
    for (final index in indices) {
      if (index < loggedList.length) {
        loggedNames.add(loggedList[index]);
      } else {
        final liftId = linkedLibraryList[index - loggedList.length];
        final lift = libraryById[liftId]!;
        libraryMatches.add(LiftNameLibraryMatch(id: lift.id, name: lift.name));
      }
    }

    if (loggedNames.isEmpty) continue;

    loggedNames.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    libraryMatches.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    clusters.add(
      LiftNameConvergenceCluster(
        loggedNames: loggedNames,
        libraryMatches: libraryMatches,
      ),
    );
  }

  clusters.sort((a, b) {
    final aKey = a.loggedNames.isNotEmpty
        ? a.loggedNames.first.toLowerCase()
        : a.libraryMatches.first.name.toLowerCase();
    final bKey = b.loggedNames.isNotEmpty
        ? b.loggedNames.first.toLowerCase()
        : b.libraryMatches.first.name.toLowerCase();
    return aKey.compareTo(bKey);
  });
  return clusters;
}

/// Same lift with different capitalization or spacing: trim, lowercase, collapse spaces.
String duplicateExerciseKey(String name) {
  return name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

/// Logged spellings that are the same lift, plus the name a merge should use.
class DuplicateExerciseGroup {
  const DuplicateExerciseGroup({
    required this.key,
    required this.variants,
    required this.canonicalName,
    this.libraryId,
  });

  final String key;
  final List<String> variants;
  final String canonicalName;
  final String? libraryId;
}

/// Groups logged names that differ only by capitalization or spacing.
List<DuplicateExerciseGroup> findDuplicateExerciseGroups({
  required Iterable<String> loggedNames,
  required List<LibraryLift> catalogLifts,
}) {
  final byKey = <String, Set<String>>{};
  for (final raw in loggedNames) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) continue;
    final key = duplicateExerciseKey(trimmed);
    if (key.isEmpty) continue;
    byKey.putIfAbsent(key, () => <String>{}).add(trimmed);
  }

  final groups = <DuplicateExerciseGroup>[];
  for (final entry in byKey.entries) {
    final variants = entry.value.toList()..sort((a, b) => a.compareTo(b));
    if (variants.length <= 1) continue;
    LibraryLift? libraryMatch;
    for (final lift in catalogLifts) {
      if (duplicateExerciseKey(lift.name) == entry.key) {
        libraryMatch = lift;
        break;
      }
    }
    final canonical = libraryMatch?.name ?? variants.first;
    groups.add(
      DuplicateExerciseGroup(
        key: entry.key,
        variants: variants,
        canonicalName: canonical,
        libraryId: libraryMatch?.id,
      ),
    );
  }

  groups.sort((a, b) => a.canonicalName.compareTo(b.canonicalName));
  return groups;
}

/// Name to store when [key] matches. Other names stay as written.
String renamedExerciseName({
  required String name,
  required String key,
  required String canonicalName,
}) {
  final target = canonicalName.trim();
  if (target.isEmpty) return name;
  if (duplicateExerciseKey(name) != key) return name;
  return target;
}

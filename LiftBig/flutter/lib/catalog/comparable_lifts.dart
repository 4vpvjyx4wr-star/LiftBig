import 'liftbig_catalog.dart';

/// Same ranking idea as Vue `getComparableLibraryExercises`.
/// Preferred alternates stay pinned, shared muscle groups follow, then the rest.
List<LibraryLift> comparableLibraryLifts({
  required List<LibraryLift> library,
  String? libraryId,
  required String name,
  bool isCardio = false,
  List<String> preferredSwapLibraryIds = const [],
}) {
  final base = _baseLift(
    library: library,
    libraryId: libraryId,
    name: name,
  );
  if (base == null) return const [];

  final preferredIds = <String>[
    for (final id in preferredSwapLibraryIds)
      if (id.trim().isNotEmpty && id.trim() != base.id) id.trim(),
  ];
  final preferred = <LibraryLift>[
    for (final id in preferredIds) ?_byId(library, id),
  ];
  final preferredSet = preferredIds.toSet();

  if (base.isCardio || isCardio) {
    final cardio = library
        .where(
          (lift) =>
              lift.isCardio &&
              lift.id != base.id &&
              !preferredSet.contains(lift.id),
        )
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final rest = library
        .where(
          (lift) =>
              !lift.isCardio &&
              lift.id != base.id &&
              !preferredSet.contains(lift.id),
        )
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return [...preferred, ...cardio, ...rest];
  }

  final baseGroups = base.muscleGroups.toSet();
  final similar = library.where((lift) {
    if (lift.id == base.id || preferredSet.contains(lift.id)) return false;
    return lift.muscleGroups.any(baseGroups.contains);
  }).toList()..sort((a, b) {
    final overlap = b.muscleGroups.where(baseGroups.contains).length -
        a.muscleGroups.where(baseGroups.contains).length;
    if (overlap != 0) return overlap;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  final rest = library.where((lift) {
    if (lift.id == base.id || preferredSet.contains(lift.id)) return false;
    return !lift.muscleGroups.any(baseGroups.contains);
  }).toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return [...preferred, ...similar, ...rest];
}

LibraryLift? _baseLift({
  required List<LibraryLift> library,
  required String? libraryId,
  required String name,
}) {
  final id = libraryId?.trim();
  if (id != null && id.isNotEmpty) {
    final byId = _byId(library, id);
    if (byId != null) return byId;
  }
  final key = name.trim().toLowerCase();
  if (key.isEmpty) return null;
  for (final lift in library) {
    if (lift.name.trim().toLowerCase() == key) return lift;
  }
  return null;
}

LibraryLift? _byId(List<LibraryLift> library, String id) {
  for (final lift in library) {
    if (lift.id == id) return lift;
  }
  return null;
}

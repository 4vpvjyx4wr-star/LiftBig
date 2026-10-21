import 'dart:math';

/// Opaque id for an exercise or set row. Existing backup ids are kept as-is.
String newId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
}

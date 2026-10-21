import 'package:firebase_core/firebase_core.dart';

/// Stub. This file has no API keys.
///
/// `flutterfire configure` overwrites it with the real options for the LiftBig
/// Firebase project. Until then [currentPlatform] throws, and the flag in
/// `lib/sync/firebase_enabled.dart` stays false so startup never calls it.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    throw StateError(
      'Firebase options are not configured. See README.md for the files to add.',
    );
  }
}

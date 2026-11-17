import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import 'firebase_enabled.dart';

/// Returns true only when the user has turned the flag on and options load.
/// Missing config is a no-op, not a crash.
///
/// iOS takes its keys from the gitignored `GoogleService-Info.plist` in the
/// app bundle, so those keys are not stored in Dart source.
Future<bool> initializeFirebaseIfReady() async {
  if (!kFirebaseEnabled) return false;
  try {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      await Firebase.initializeApp();
      return true;
    }
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return true;
  } catch (_) {
    return false;
  }
}

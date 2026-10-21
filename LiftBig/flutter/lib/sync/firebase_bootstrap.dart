import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';
import 'firebase_enabled.dart';

/// Returns true only when the user has turned the flag on and options load.
/// Missing config is a no-op, not a crash.
Future<bool> initializeFirebaseIfReady() async {
  if (!kFirebaseEnabled) return false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return true;
  } catch (_) {
    return false;
  }
}

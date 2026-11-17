import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// No client keys live in this file. iOS reads `GoogleService-Info.plist`
/// from the app bundle. Android, web, and desktop configs are not downloaded.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Firebase options for web are not downloaded yet.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        throw UnsupportedError(
          'Firebase options for Android are not downloaded yet. '
          'Add android/app/google-services.json before running on Android.',
        );
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'iOS Firebase uses GoogleService-Info.plist. '
          'Call Firebase.initializeApp() without Dart options.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'Firebase options for macOS are not downloaded yet.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'Firebase options for Windows are not downloaded yet.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'Firebase options for Linux are not downloaded yet.',
        );
      default:
        throw UnsupportedError(
          'Firebase options are not supported for this platform.',
        );
    }
  }
}

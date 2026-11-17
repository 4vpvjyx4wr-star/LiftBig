import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// iOS options come from the downloaded Apple config.
/// Android, web, and desktop configs are not downloaded yet.
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
        return ios;
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

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDDlbCIP7fbhO4Q9qv8RLuodaZdB82RuWM',
    appId: '1:969434950771:ios:dfb0ad1cdbca284382ce06',
    messagingSenderId: '969434950771',
    projectId: 'liftbig-2e6bd',
    storageBucket: 'liftbig-2e6bd.firebasestorage.app',
    iosBundleId: 'com.liftbig.app',
    iosClientId:
        '969434950771-8behuh1l361m8j6db6gfrss7ve2a1op3.apps.googleusercontent.com',
  );
}

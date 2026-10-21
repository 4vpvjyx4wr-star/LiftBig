/// Flip this to true only after `flutterfire configure` replaces
/// `lib/firebase_options.dart` and the native config files are in place.
///
/// While this is false, the app never calls Firebase. The journal stays in
/// SQLite and nothing is uploaded.
const bool kFirebaseEnabled = false;

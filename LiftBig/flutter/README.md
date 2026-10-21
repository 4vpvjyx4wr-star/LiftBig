# LiftBig (Flutter)

Local workout journal for a future 2.0. The Vue app and the Capacitor Xcode project in `LiftBig/ios` are untouched. This app does not replace the TestFlight **1.0 (2)** build.

On-device data lives in Drift/SQLite. Weight is stored as pounds. Nothing is uploaded until someone signs in and turns sync on.

Further work follows [docs/REWRITE_PLAN.md](docs/REWRITE_PLAN.md). That file is the source of truth for phases, the schema, and what is already done.

In this app a **Workout** is one session (what the Vue app calls a plan or template). A **Plan** is a named collection of workouts across days (what the Vue app calls a folder). A logged day is still a calendar day. The Vue app and Capacitor **1.0 (2)** keep the old words.

Development application id: **`com.liftbig.app.dev`**

`com.liftbig.app` is reserved for a future 2.0 store upload. Do not change the dev id to that value, or a dev install can overwrite 1.0 (2).

## Run

Flutter 3.47+ (Dart 3.13+). If the SDK is the local clone:

From the repo root:

```bash
export PATH="$HOME/development/flutter/bin:$PATH"
cd LiftBig/flutter
flutter pub get
flutter run -d chrome
```

`flutter run` with no device flag picks an iOS simulator, Android emulator, or connected phone. A signed device build is not required to work on the journal.

```bash
flutter analyze
flutter test
```

## What this slice does

- Month calendar reads days from SQLite.
- Log one exercise and its sets. They are still there after a restart.
- Legacy JSON import for fewer than five early users: paste or pick a LiftBig backup (`liftbig_local_storage` and/or `liftbig_workouts`, `liftbig_templates`, `liftbig_settings`). Dates in the file replace those days. Other local days stay. Keep this importer. Do not add import screens, file-drop flows, or store copy. Import is not part of the store app.
- Settings has a sync switch that defaults to **off**.

Health, Watch, and the Plans screen are not in this slice. That screen will list Plans, and each Plan will contain Workouts.

## Firebase (optional)

Sync is a no-op until the files below exist and `kFirebaseEnabled` is set to `true`. Do not invent API keys. The stub at `lib/firebase_options.dart` has none.

1. Create a Firebase project and enable **Authentication → Email/Password**.
2. Add an iOS app and an Android app with bundle / application id `com.liftbig.app.dev`. Add a web app if you want `flutter run -d chrome` to sync.
3. Download and place:
   - `LiftBig/flutter/android/app/google-services.json`
   - `LiftBig/flutter/ios/Runner/GoogleService-Info.plist`  
     In Xcode, add the plist to the **Runner** target if it is not already in Copy Bundle Resources.
4. From `LiftBig/flutter`:

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure --platforms=android,ios,web --out=lib/firebase_options.dart
   ```

   That command overwrites `lib/firebase_options.dart`.
5. Set `kFirebaseEnabled` to `true` in `lib/sync/firebase_enabled.dart`.
6. Deploy `firestore.rules` (Firebase console or `firebase deploy --only firestore:rules`).

Rules allow a signed-in user to read and write only `users/{uid}/days/{dateKey}` and `users/{uid}/settings/{docId}`.

Each day document has `updatedAt`. The newer stamp wins. If the stamps are equal, the phone keeps its copy. The settings switch itself stays on the phone and is not uploaded, so the cloud cannot turn sync on.

Until step 5, the app never calls Firebase.

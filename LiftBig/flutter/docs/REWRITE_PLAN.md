# LiftBig Flutter rewrite plan

This file is the source of truth for the Flutter rework. A coding agent implements one phase at a time and updates the checkboxes here.

The prompt that asked for this file assumed a greenfield rewrite: no data migration, a schema that would be redesigned, and a backend that still needed approval. Those premises do not apply. The decisions below are already made. Do not reopen them unless this file is updated first.

## Summary

LiftBig is a workout journal. The live product is a Vue app, also wrapped with Capacitor as iOS TestFlight **1.0 (2)**. This rework is a new Flutter app at `LiftBig/flutter/` so one codebase can later ship iOS, Android, and web. The Vue site and the Capacitor Xcode project stay as they are until a later cutover.

The phone keeps the journal in SQLite so history can be queried with no account. Firestore is only an optional cloud copy after sign-in. Fewer than five early users may import an existing LiftBig JSON backup. That importer is a legacy path: keep it, and do not add import screens, file-drop flows, or store copy. Import is not part of the store app. For those users, the imported journal is the product, not a sample.

## Vocabulary

The live Vue app and Capacitor **1.0 (2)** keep saying “plan” and “folder.” This rename is the Flutter rebuild only. Backup JSON still uses the old keys. The parser translates them.

- **Workout** replaces today’s plan/template: one session’s exercises, with target sets, reps, and weight. Stored in the Vue app as `WorkoutTemplate` in `LiftBig/src/types/workout.ts` (`name`, `exercises`, `notes`, `folderId`).
- **Plan** replaces today’s folder: a named collection of workouts across days. Stored in the Vue app as `TemplateFolder` (`id`, `name`, `purpose`).
- A **logged day** stays a calendar day. It is not a Workout. It can record which Workout was used and which Plan that Workout belonged to.
- **Lift** and **exercise** are synonyms for the activity being logged: a strength lift, cardio, or any other logged activity. They are not two entities. The stored row stays `JournalExercise` in the `exercises` table. Do not rename that table. The workout screen may say “lift” next to Done.

Field mapping on a logged day:

| Vue backup JSON | Flutter day field | Meaning |
| --- | --- | --- |
| `planName` | `workoutName` | The template name |
| `planFolderName` | `planName` | The folder name |
| `planNotes` | `workoutNotes` | Coaching notes from that template |

`liftbig_templates` stays the backup key for workouts. Folder objects inside that JSON become plans.

## Decisions already made

- Local persistence is Drift (SQLite). Weight is stored as pounds. A day is one row keyed by local `YYYY-MM-DD`. Exercises and sets are rows, matching `LiftBig/src/types/workout.ts`.
- No account is required. With sync off, nothing is uploaded.
- Optional sync is Firebase Auth plus Firestore `users/{uid}/days/{dateKey}` and a settings document. The newer `updatedAt` wins. Equal stamps keep the local copy. Security rules allow a user to read and write only their own documents. The sync switch itself stays on the device.
- Cloud SQL and Cloud Functions are not part of this rewrite.
- Development bundle id is `com.liftbig.app.dev`. `com.liftbig.app` is reserved for a future 2.0 store upload. A dev install must not overwrite TestFlight **1.0 (2)**.
- iCloud in the Capacitor app is not ported. Optional Firestore replaces it for this version.
- Web is a Flutter target. Replacing https://liftbig.julianmcgookin.com is a late phase, not the next one.
- Schema changes go through a Drift migration and an edit to this file before the code change.
- JSON import is a legacy path for fewer than five early users. The existing importer stays. Do not add import screens, file-drop flows, or store copy. Import is not part of the store app. The only place that opens it is the settings screen.
- Import backup is not on the home calendar. Settings opens the existing import sheet. Do not add a second import flow.
- Empty sets on a lift are filled from that lift’s earlier logged sets. The formula is the Vue one in `LiftBig/src/utils/progressiveOverload.ts` (`predictWorkoutGoals` and the Epley estimated-strength helpers). Do not invent a new formula. Warmup sets do not count (`setCountsTowardProgress` in `LiftBig/src/types/workout.ts`). The reps written on the set are the top of the predicted range (`getDefaultLogRepsForTarget`). Done accepts the weight and reps already on the set as what was performed. Tapping the weight or the reps opens editing: a typed number, or the same kind of stepped selector the Vue set row uses (weight in 5 lb steps from 0 to 500, reps from 1 to 50).
- Auto-fill of that prediction is on by default. The switch lives in `local_settings` under `auto_fill_sets` (`true` or `false`). A missing key means on. When it is off, new sets are not pre-filled.
- Done does not start the rest timer unless `local_settings` key `start_timer_on_done` is `true`. A missing key means off. Every lift shows a timer button next to Done. That button starts the timer even when the switch is on. Long-pressing it sets that lift’s `targetRestSeconds`, clamped to 5–600. The countdown uses that value when it is greater than zero, otherwise the settings average, otherwise 60. This is a Flutter change from the Vue log, which starts rest as soon as a set is completed.

## Current state

### Vue app

The Vue app lives in `LiftBig/`. It persists with `localStorage` keys prefixed `liftbig_`. There is no LiftBig server. Native builds also mirror a snapshot to a private file and, when enabled, to the user's iCloud container. Merge is per day: the newer `liftbig_day_stamps` value wins. This section uses the Vue words “plan” and “folder.” The Flutter names are in Vocabulary above.

Routes in `LiftBig/src/router/index.ts`:

| Route | Screen | What it does |
| --- | --- | --- |
| `/` | Home | Month calendar and the selected day |
| `/overview` | redirect | Sends the user to home. Not a separate screen |
| `/plans` | Plans | Browse, edit, assign, and schedule workout templates |
| `/plates` | Plates | Plate calculator for a target weight |
| `/one-rep-max` | One-rep max | Estimate a one-rep max from a logged set |
| `/library` | Library | Exercise browser, favorites, and detail |
| `/progress` | Progress | Charts and volume from logged sets |
| `/achievements` | Achievements | Consistency and lifting milestones |
| `/workout/:date` | Workout log | Exercises and sets for one day. Invalid dates redirect to today |
| `/pick-plan` | Pick a Plan | Guided plan questionnaire and schedule |

Sheets on top of those screens include settings, backup import, rest timer, plan preview and editor, library picker, copy day, and move day.

User flows that must survive:

- Open a day, add exercises from the library or by name, log sets, mark a set done, mark warmup, delete a set or exercise, reorder, and keep the day after restart.
- Warmup sets are stored and shown. They do not count toward progress or progressive overload (`setCountsTowardProgress` in `LiftBig/src/types/workout.ts`).
- Cardio logs duration and optional distance. Core logs hold time and reps. Circuits and supersets group exercises.
- Assigning a plan copies the template onto a day and keeps the plan name, folder, and coaching notes. Flutter stores those as `workoutName`, `planName`, and `workoutNotes`.
- Rest uses that exercise's `targetRestSeconds` when the plan set one. Otherwise it uses the average rest in settings. In Flutter the timer button next to Done starts the countdown. Done starts it only when the settings switch is on. The Vue log still starts rest when the set becomes complete.
- Field order on a set is weight, then reps. With auto-advance on, focus moves weight, then reps, then the next set's weight.
- Export and import a JSON backup. The authoritative restore is `liftbig_local_storage` (raw strings). Typed `liftbig_workouts`, `liftbig_templates`, and `liftbig_settings` are the fallback.
- Settings cover theme, units, body weight, height, reminder time, timer sound, and the Health and iCloud switches. Those two switches stay off until the user turns them on.
- Apple Health, when allowed, reads body weight and height only and writes logged workouts. It does not read sleep, heart rate, or other apps' workouts.
- Daily reminder and rest-finished alert are local notifications. They fire when the app is closed.
- Watch and Garmin are companions, later, and Pro-gated in the Capacitor app. The journal itself is not Pro-gated.

State in the Vue app is composables (`useLocalWorkouts`, `useSettings`, `useTemplates`, and smaller hooks) plus `localStorage`. Validation that must survive includes date keys `YYYY-MM-DD`, reminder time `HH:MM`, body weight clamped to 50–700 lb when set, height clamped to 36–96 inches when set, and average rest and lift seconds clamped to 5–600.

Third-party pieces in the Vue app: Vue 3, Vite, Tailwind, vue-router, Capacitor (iOS and Android), HealthKit and Health Connect, StoreKit and Play Billing for a later Pro subscription, YouTube links for exercise demos, and a Buy Me a Coffee link. There is no LiftBig API.

### Storage keys

From `LiftBig/src/utils/liftbigStorageKeys.ts`:

| Key | Shape | Written by |
| --- | --- | --- |
| `liftbig_workouts` | `Record<dateKey, Exercise[] or WorkoutDay>` | Workout log |
| `liftbig_templates` | `WorkoutTemplate[]` | Vue Plans screen. Flutter Workouts; folder objects in this JSON are Plans |
| `liftbig_settings` | `AppSettings` | Settings |
| `liftbig_custom_themes` | `CustomTheme[]` | Theme editor |
| `liftbig_library_favorites` | Library ids | Library |
| `liftbig_plan_favorites` | Vue template ids | Flutter workout favorites, Plans phase |
| `liftbig_pick_a_plan` | Pick a Plan answers and schedule | Pick a Plan |
| `liftbig_day_stamps` | `Record<dateKey, ISO timestamp>` | Day merge |
| `liftbig_snapshot_written_at` | ISO timestamp | Native snapshot |
| `liftbig_import_prompt_dismissed` | Boolean | First-run import sheet |
| `liftbig_daily_reminder_dismissed_<date>` | Dismiss flag for that day | Reminder |

Legacy aliases (`workouts`, `templates`, `liftbig_plans`, `settings`, `favorites`, and similar) are read once and folded into the canonical keys. Backup files may still contain them.

### Flutter app today

`LiftBig/flutter/` already builds for iOS, Android, and web. It is not store-listed.

Done:

- Drift schema version 2: `days`, `exercises`, `sets`, `local_settings`. A logged day stores `workoutName`, `planName`, and `workoutNotes` (version 1 columns `plan_name`, `plan_folder_name`, and `plan_notes` are copied forward in `onUpgrade`).
- `JournalRepository` is the only local write path. UI code does not touch Firestore.
- Month calendar. Selecting a day shows that day's logged lifts under the calendar on the same page. Open log pushes the day screen for that date. Add a lift by common name or custom name, add and edit sets, mark done, mark warmup, delete a set or exercise.
- Set fields are weight, then reps. No Material divider between sets.
- Marking a set done records the weight and reps on that set. It does not start rest unless `start_timer_on_done` is on. The timer button beside Done starts the countdown on every lift. Long-press sets that lift’s `targetRestSeconds`. The length is that value when it is greater than zero, otherwise the imported settings average, which defaults to 60. Skip and completion use the app-wide rest banner. A local notification fires when rest finishes, including on the lock screen. Apple Watch rest alerts stay out of scope here; they remain a later, Pro-gated companion like the Capacitor app.
- Empty sets are pre-filled from prior working sets for that lift when `auto_fill_sets` is on (the default). Warmup sets are ignored by the prediction. With no history, auto-fill suggests a working weight from the **Strength Level** Intermediate standard (https://strengthlevel.com/strength-standards) at about the 50th percentile for that lift relative to body weight, converted to the rep goal. If body weight is unset in Settings, suggestions use a labeled **180 lb default** and do not write `body_weight_lbs` until the user saves body weight there. Cardio and circuits are not pre-filled with a weight and rep goal.
- Legacy JSON backup import for fewer than five early users. Dates in the file replace those days. Other local days stay. The parser still reads `planName`, `planFolderName`, and `planNotes` and writes `workoutName`, `planName`, and `workoutNotes`. `liftbig_templates` stays the backup key. Do not add import screens, file-drop flows, or store copy. Templates and settings are stored as JSON strings in `local_settings`, not as their own tables yet.
- Settings screen with a sync switch that defaults to off. Sync does nothing until `kFirebaseEnabled` is true and Firebase config files exist. Do not invent API keys.

Not built yet: library favorites and swap, editing the lifts inside a Plan, scheduling a whole Plan across the calendar, Community Plans, plates, one-rep max, themes, daily reminders, Health, and Watch. Rest-finished lock-screen notifications are in the Flutter app. Watch rest alerts remain later and Pro-gated, matching Capacitor.

### Tab shell

The bottom bar matches the Vue shell in `AppShell.vue`: five equal slots, Home, Progress, LIFT, Plans, Library. LIFT is the round center control. Colors are the existing `lib/theme.dart` palette. The catalog of lifts and premade plans is `assets/liftbig_catalog.json`, copied from the Vue library, tutorials, and guided plans. It is not a schema change.

- [x] Home is the calendar. Tapping a day shows that day's log under the calendar. It does not push a route.
- [x] Open log still pushes the day screen for the selected date.
- [x] LIFT opens today's day screen. That is the logging surface, not the calendar.
- [x] Progress lists each lift's working-set max over time and the achievements that are earned. Warmup sets are excluded.
- [x] Plans runs the six-step Pick a Plan quiz, lists premade Plans and the Workouts inside them, and shuffles a workout from equipment, focus, time, and seconds per lift and rest. Logging a workout writes it onto today and keeps the workout name and plan name.
- [x] Lift Library lists the Vue catalog with the summary, how to perform the lift, cues, tips, and the YouTube links already on those entries.
- [ ] Community Plans. The Plans screen only says sharing is not available yet. No upload, account, or feed.
- [ ] Favorites, swap, editing a Workout inside a Plan, and scheduling a whole Plan across the calendar. Those stay open with their phases.

Logging and import placement for this pass:

- [x] Lift and exercise are documented as synonyms. The `exercises` table is unchanged.
- [x] Import backup is only on the settings screen, through the existing import sheet.
- [x] Predicted weight and reps come from prior working sets. Warmup sets are excluded.
- [x] `auto_fill_sets` defaults on and survives a new repository on the same database.
- [x] `start_timer_on_done` defaults off and survives a new repository on the same database.
- [x] `flutter analyze` and `flutter test` pass.

## Target architecture

```
lib/
  data/        Drift tables and AppDatabase
  model/       Journal day, exercise, and set values
  journal/     JournalRepository
  backup/      JSON backup parser
  catalog/     Lift library and premade plan data
  plans/       Pick a Plan scoring and workout shuffle
  progress/    Lift series and achievements
  sync/        DayRemote, merge, Firebase bootstrap
  rest/        App-wide rest timer and lock-screen notification
  ui/          Screens, including the tab shell
  date_key.dart
  ids.dart
  theme.dart
```

State stays in `JournalRepository` plus the screen that is editing that day. A shared store is not needed until several tabs read the same settings and journal. Adding Riverpod or Bloc now would rewrite working screens without a user-facing gain.

The tab shell keeps Home, Progress, today's log, Plans, and the Lift Library in one scaffold. Selecting a calendar day does not push. Open log, a lift's detail, and Settings still use `Navigator` pushes. A named router package is not required for this shell.

Local persistence stays Drift (`drift` and `drift_flutter`). It is actively maintained, generates the query layer, and supports migrations. `sqflite` would mean writing the SQL by hand. A document store would fight the reason for this rewrite, which is queryable sets. Schema version is `AppDatabase.schemaVersion`, currently 2. Bump it and add an `onUpgrade` step for every column or table change, and describe the change in this file in the same phase.

## Backend

The recommendation is already approved.

| Option | Pros | Cons | Cost | Complexity |
| --- | --- | --- | --- | --- |
| On-device SQLite only | Works offline, no account, matches 1.0 privacy | No second-device copy | None | Low. This is the default path |
| SQLite plus optional Firestore | Same offline journal, optional sync, per-user rules | Needs a Firebase project and sign-in. Not SQL in the cloud | Firebase free tier, then usage | Medium. Already sketched behind `DayRemote` |
| Custom API and Cloud SQL | Full SQL in the cloud | Requires an account, a server, and hosting. Out of scope | Cloud SQL plus functions | High. Rejected for this version |

UI code calls `JournalRepository`. Sync calls `DayRemote`. Swapping the cloud copy later does not require rewriting screens.

## New schema

Entities already in `LiftBig/flutter/lib/data/tables.dart`:

- **Day.** `dateKey` primary key. `notes`, `isRestDay`, `workoutName`, `planName`, `workoutNotes`, `updatedAt` (ISO-8601). `workoutName` is the session that was used. `planName` is the Plan that session belonged to. `workoutNotes` are the coaching notes from that Workout.
- **Exercise.** `id` primary key. `dateKey` references Day and cascades on delete. `sortOrder`, `name`, `libraryId`, `notes`, `isCircuit`, `isCardio`, `isCore`, targets (`targetDuration`, `targetTimeSeconds`, `targetDistance`, `loggedCalories`, `targetReps`, `targetWeight`), superset fields, `preferredSwapLibraryIds` (JSON array), `targetRestSeconds`.
- **Set.** Table name `sets`. `id` primary key. `exerciseId` references Exercise and cascades. `sortOrder`, `reps`, `weight` (pounds, text, matching the Vue strings), `durationSeconds`, `checked`, `isWarmup`.
- **Local setting.** `key` primary key, `value` text. Known keys: `sync_enabled`, `settings_updated_at`, `weight_unit`, `body_weight_lbs`, `templates_json`, `settings_json`, `auto_fill_sets`, `start_timer_on_done`, `rest_timer_state`. The logging switches and rest timer JSON are not new columns, so the schema version stays 2.

Relationships: a day has many exercises ordered by `sortOrder`. An exercise has many sets ordered by `sortOrder`.

### Mapping from localStorage

| Old key or field | New home | Notes |
| --- | --- | --- |
| `liftbig_workouts` date entry | `days` plus child `exercises` and `sets` | Legacy array-of-exercises days import as a day with no notes |
| Day `notes`, `isRestDay`, backup `planName`, `planFolderName`, `planNotes` | `days.notes`, `days.isRestDay`, `days.workoutName`, `days.planName`, `days.workoutNotes` | Parser reads the old JSON keys. The day screen shows the workout name and does not label that line “Plan” |
| Exercise fields in `workout.ts` | `exercises` columns | Imported. The day screen edits name and sets, not cardio, circuits, or supersets |
| Set `reps`, `weight`, `durationSeconds`, `checked`, `isWarmup` | `sets` columns | Weight stays a pound string |
| `liftbig_day_stamps` | `days.updatedAt` | One stamp per day, not a separate map |
| `liftbig_templates` | `local_settings.templates_json` | Backup key stays. Template objects are Workouts. Folder objects are Plans. Not a table until the Plans phase |
| `liftbig_settings` | `local_settings.settings_json`, plus `weight_unit` and `body_weight_lbs` | Full settings UI is a later phase |
| `liftbig_custom_themes` | Not ported yet | Theme editor phase. Reason: no theme UI in Flutter yet |
| `liftbig_library_favorites` | Not ported yet | Library phase |
| `liftbig_plan_favorites` | Not ported yet | Plans phase. Vue stores template ids here; Flutter treats them as workout favorites |
| `liftbig_pick_a_plan` | Not ported yet | Pick a Plan phase |
| `liftbig_snapshot_written_at` | Dropped | Capacitor file snapshot only. Firestore uses each day's `updatedAt` |
| `liftbig_import_prompt_dismissed` | Dropped | The Flutter app has no first-run gate. Import stays available from the settings screen |
| `liftbig_daily_reminder_dismissed_*` | Not ported yet | Reminder phase |
| `iCloudSyncEnabled` | Dropped | Replaced by the on-device sync switch and Firestore. The switch is not uploaded |
| Legacy key aliases | Read by the backup parser when present | Not stored under the old names |

### Schema versioning

`AppDatabase.schemaVersion` is the version. Phase 0 shipped version 1 (`plan_name`, `plan_folder_name`, `plan_notes` on `days`). Version 2 renames those columns to `workout_name`, `plan_name`, and `workout_notes`. `onUpgrade` copies the old values into the new columns. Backup import keeps reading the old JSON keys (`planName`, `planFolderName`, `planNotes`) after the migration. A later phase that adds a column bumps the version, implements `onUpgrade`, and notes the change under that phase in this file.

## Feature parity checklist

- [x] App opens on iOS. Android and web targets exist and are not store-listed.
- [x] Journal survives restart with no account.
- [x] Month calendar shows days that have logged work.
- [x] Open a day and log more than one exercise.
- [x] Edit weight and reps. Weight is shown before reps.
- [x] Mark a set done, mark warmup, add a set, delete a set, delete an exercise.
- [x] In-app rest countdown. The timer button next to Done starts it. Done starts it only when `start_timer_on_done` is on.
- [x] Import a LiftBig JSON backup, including a large one, without pasting into a text field. Legacy path for early users. Do not expand it.
- [x] Imported day shows the workout name, day notes, rest day, cardio, core, circuits, and supersets the way the Vue log does.
- [x] Reorder exercises and sets. Copy a day. Move a day.
- [x] Rest duration comes from `targetRestSeconds`, otherwise from settings. Auto-advance from weight to reps to the next weight.
- [x] Rest-finished notification, including when the app is backgrounded.
- [ ] Exercise library, search, favorites, and swap. Search and the catalog detail, including YouTube links, are on the Lift Library tab. Favorites and swap are still open.
- [ ] Plans screen: list Plans, edit the Workouts inside each Plan, assign a Workout to a day, favorites. The tab lists premade Plans and can log one Workout onto today. Editing a Workout and favorites are still open.
- [ ] Pick a Plan questionnaire and schedule. The quiz and its recommendations are on the Plans tab. Scheduling the whole Plan across the calendar is still open.
- [x] Progress charts. Warmup sets excluded.
- [ ] Plate calculator and one-rep max.
- [x] Achievements.
- [ ] Settings: units, body weight, themes, daily reminder.
- [ ] Optional Firestore sync after the owner adds Firebase config.
- [ ] Apple Health and Health Connect: body weight and height in, logged workouts out, off until allowed.
- [ ] Watch and Garmin companions. Pro-gated. Not in the next phases.
- [ ] Replace the Vue website with Flutter web.
- [ ] Store listing as 2.0 under `com.liftbig.app`.

## Phased implementation plan

Each phase leaves `flutter analyze` and `flutter test` passing, and the app runnable on iOS and Android. Do not start the next phase until this one has been reviewed.

### Phase 0 — Scaffold and local journal

Goal: prove the stack without touching 1.0.

- [x] Create `LiftBig/flutter` with iOS, Android, and web targets.
- [x] Dev bundle id `com.liftbig.app.dev`.
- [x] Drift tables for days, exercises, and sets.
- [x] Backup import into SQLite.
- [x] Home calendar and a day screen that persists sets.
- [x] Firestore sync behind a switch that defaults to off, and does nothing without config.
- [x] `firestore.rules` so a user can only touch their own documents.

Files: `lib/data/`, `lib/journal/`, `lib/backup/`, `lib/sync/`, `lib/ui/home_page.dart`, `lib/ui/settings_page.dart`.

Acceptance: a set logged on a day is still there after restart. A backup file replaces only the dates it contains.

Tests: repository round-trip, backup parser, day-merge newer-wins. Written in `test/`.

### Phase 1 — Logged day matches the original

Goal: an imported day looks and behaves like the Vue workout log for the common case.

- [x] Several exercises on one day. Common lifts plus a custom name.
- [x] Weight field before reps. No white divider between sets.
- [x] On-screen rest countdown after a set is marked done.
- [x] Show and edit day notes, rest day, and the assigned workout name.
- [x] Cardio duration, core time, circuits, and supersets render from imported rows.
- [x] Reorder exercises. Copy day. Move day.
- [x] Rest seconds from `targetRestSeconds`, otherwise the settings average. Default stays the Vue default of 60 when nothing else is set, not a hard-coded 90.
- [x] Auto-advance: weight, then reps, then the next set's weight.

Files: `lib/ui/day_page.dart`, `lib/journal/journal_repository.dart`, `lib/model/journal_day.dart`. Vue reference: `LiftBig/src/views/WorkoutLogView.vue`, `LiftBig/src/components/workout/`.

Acceptance: a day from a real backup shows the same exercises and set values as the Vue app. Editing a set and leaving the screen keeps the edit.

Tests: repository tests for notes, rest day, cardio flags, and order. Do not add a widget test that leaves a Drift query stream timer pending after dispose.

### Phase 2 — Library

Goal: pick an exercise from the same catalog the Vue app uses, instead of a short hard-coded list.

- [ ] Port the catalog data the log needs (name, library id, cardio, core, equipment).
- [ ] Search and add onto the open day.
- [ ] Favorites, stored locally.
- [ ] Swap an exercise, with `preferredSwapLibraryIds` pinned first.

Files: new `lib/library/`, `lib/ui/day_page.dart`. Vue reference: `LiftBig/src/utils/exerciseLibrary.ts`, `LiftBig/src/views/LibraryView.vue`.

Acceptance: adding a library exercise stores its `libraryId`. A favorite is still favorite after restart.

Tests: catalog lookup and favorite persistence.

### Phase 3 — Plans

Goal: the Plans screen lists Plans. Each Plan is a named collection of Workouts across days. A Workout is one session (what the Vue app calls a plan or template). Pick a Plan stays the multi-day chooser.

- [ ] Promote `templates_json` into rows, or keep JSON until the editor needs queries. Record the choice in this file before coding it. `liftbig_templates` stays the backup key. Folder objects in that JSON are Plans. Template objects are Workouts.
- [ ] The screen lists Plans, and each Plan contains its Workouts. Edit a Workout’s exercises, target sets, reps, and weight.
- [ ] Assign a Workout onto a date. The day keeps `workoutName`, `planName`, and `workoutNotes`.
- [ ] Workout favorites and Pick a Plan can follow in this phase only if the editor is already solid. Otherwise they are their own review. Pick a Plan remains the guided multi-day chooser.

Files: `lib/journal/` or a new `lib/plans/`, a Plans screen. Vue reference: `LiftBig/src/views/PlansView.vue`, `LiftBig/src/utils/templateToLog.ts`. Those Vue screens still say “plan” and “folder.”

Acceptance: assigning a Workout creates the day's exercises and sets and records which Plan it belonged to. Re-importing a backup does not duplicate that day.

Tests: workout assign and backup round-trip of `liftbig_templates`.

### Phase 4 — Progress tools

Goal: the journal is queryable, which was the point of SQL.

- [x] Progress for one exercise from set rows. Skip warmups.
- [ ] Plate calculator.
- [ ] One-rep max from a set.
- [x] Achievements from logged days.

Files: new `lib/progress/`, screens matching the Vue routes. Vue reference: `LiftBig/src/utils/exerciseProgress.ts`, `LiftBig/src/utils/plates.ts`, `LiftBig/src/utils/oneRepMax.ts`, `LiftBig/src/utils/achievements.ts`.

Acceptance: a warmup set does not move the progress series. The plate math matches the Vue calculator for the same target.

Tests: progress query, plate math, one-rep max, achievement rules. Use the Vue tests as the expected values.

### Phase 5 — Settings, reminder, and rest alert

Goal: the day-to-day preferences and the two notifications.

- [ ] Settings screen for units, body weight, theme, and reminder time. Reuse the Vue clamps.
- [ ] Daily local notification at the chosen time.
- [x] Rest-finished local notification. The in-app countdown stays in the app-wide banner.

Files: `lib/ui/settings_page.dart`, a small notifications module. Vue reference: `LiftBig/src/composables/useSettings.ts`, `LiftBig/src/native/nativeNotifications.ts`.

Acceptance: changing units does not rewrite stored pounds. A reminder scheduled for a time still exists after restart.

Tests: settings clamps and unit conversion at the boundary. Notification scheduling can be a unit test of the request, not a device test.

### Phase 6 — Turn on optional sync

Goal: the existing sync path works after the owner supplies Firebase config. This phase does not redesign it.

- [ ] Owner adds `google-services.json`, `GoogleService-Info.plist`, and runs `flutterfire configure`.
- [ ] Set `kFirebaseEnabled` to true.
- [ ] Deploy `firestore.rules`.
- [ ] Sign in, turn the switch on, and confirm a newer remote day replaces the local day and an older one does not.

Files: `lib/sync/`, `lib/firebase_options.dart`. Do not invent API keys in the repo.

Acceptance: with the switch off, no Firebase call is made. With it on, only that user's documents are read or written.

Tests: `chooseNewerDay` already covers the merge. Add a test if sign-in state changes the switch.

### Later, not one of the phases above

Health, Watch, Garmin, Pro, the store listing, and replacing the Vue site. Each gets its own section in this file before implementation. Pro does not gate the journal or bug fixes.

## Testing strategy

- Repository and parser: unit tests with an in-memory Drift database. Every phase that writes rows adds one.
- Merge and pure rules (plates, one-rep max, warmup exclusion, settings clamps): unit tests with no widgets.
- Screens: widget tests only when they dispose cleanly. A Drift `watch` that leaves a timer pending fails the test. Prefer repository tests for persistence.
- Integration: one `flutter test` run for the suite, plus `flutter analyze`. A device pass is manual: import, edit a set, restart, confirm the set.

## Platform concerns

- iOS and Android both use the same Dart journal. Permissions differ later: notifications, Health, and nothing else in the next phases.
- The iOS Simulator does not share the Mac clipboard or accept a dropped JSON file. Import reads a file already copied into the app documents (`liftbig-backup.json`) or a file the user picks. Do not send users back to pasting a large backup into a text field.
- Offline is the normal case. Sync is additive.
- Store: do not change the dev bundle id to `com.liftbig.app`. Do not edit `LiftBig/ios` (the Capacitor project) or re-upload 1.0 (2).
- `ITSAppUsesNonExemptEncryption` stays false when a store build exists. That is a later phase.

## Record only (later)

These are noted for a future pass. Do not implement them in the current Flutter rework unless this file is updated first.

- **Same-muscle fatigue adjustment** after logging a set (reduce suggested load on later lifts that share a muscle group the same day).
- **Easy / Moderate / Difficult** effort rating on working sets.
- **Opt-in strength sharing**, off by default (no account feed in this version).
- **Community Plans** stays a placeholder on the Plans tab only (no upload, account, or feed).

## Risks and open questions

- Pro subscription, adaptive plan changes, and the Buy Me a Coffee link are not designed for Flutter yet. Do not add them while porting the journal.
- Phase 1 uses an exercise's prescribed rest, then the settings average. The Vue default of 60 applies when neither is set.
- Workouts live in the `liftbig_templates` JSON blob. The Plans phase has to choose rows versus JSON before coding the editor.
- Firebase config files are still absent, so sync is a no-op on purpose.
- The exercise catalog and the Vue plan catalog (Flutter Workouts, grouped into Plans) are large generated lists. Port the data the log needs. Do not rewrite the generators in the library phase.
- Whether Flutter web replaces the site, and when, is a later decision. The privacy page stays a static HTML file at `/privacy.html` until that cutover is designed.

## Agent rules

- Work on one phase at a time. Stop and wait for review when the phase's acceptance criteria are met.
- Check off tasks in this file as they are completed. Do not check a task that was not verified.
- Do not change the schema, the bundle id, or the sync model without updating this file first.
- Treat `LiftBig/src` as reference for behavior and data shapes. Do not port Vue composables, Capacitor plugins, or Tailwind into Flutter.
- Do not edit the Capacitor Xcode project or the live Vue site as part of a Flutter phase.
- Do not invent Firebase API keys. Do not commit unless the owner asks.
- Keep `JournalRepository` as the local write path and `DayRemote` as the cloud boundary.

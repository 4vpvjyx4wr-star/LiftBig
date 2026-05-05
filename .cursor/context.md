# EZ Workout Tracker — Technical design (LiftBig → Vue)

## Product summary

This is a **mobile-first, desktop-compatible** training journal: calendar-driven logging, reusable workout templates (“plans”), a monthly consistency view, optional progressive-overload hints from history, a rest timer, and a barbell plate calculator. The **original reference implementation** lives under `LiftBig/Original App Reference/` as an **Expo (~54) / React Native** app (Expo Go–friendly) using **expo-router** (file-based tabs), **AsyncStorage** for persistence, and no backend.

The **target product** is the same feature set and UX intent, implemented as a **statically served SPA**: **Vue 3**, **vue-router**, **Tailwind CSS**, **Font Awesome Free** (already in npm).

---

## Source architecture (Expo reference)

| Area | Implementation |
|------|----------------|
| Navigation | `expo-router` tab layout: four visible tabs + hidden `workout-log` route |
| Persistence | `@react-native-async-storage/async-storage` — JSON blobs per key |
| Lists | `@shopify/flash-list` on workout log (Vue: virtualized list optional; start with `v-for` + pagination if needed) |
| Gestures | Header **horizontal swipe** switches tabs (`useTabSwipe`); calendar **swipe** changes month (`PanResponder` + `Animated`) |
| Feedback | `expo-haptics` on plate calc, timer complete, set edits (web: omit or use subtle CSS / `navigator.vibrate` where appropriate) |

### Reference routes → Vue routes

| Expo screen | Role | Suggested Vue path |
|-------------|------|-------------------|
| `(tabs)/index` | “Home”: month calendar, day selection, summary, assign plan, open log | `/` or `/home` |
| `(tabs)/overview` | “Calendar”: monthly stats + day modal (detail / delete / edit) | `/overview` |
| `(tabs)/plans` | CRUD workout templates | `/plans` |
| `(tabs)/plates` | Plate math + quick presets | `/plates` |
| `(tabs)/workout-log` | Per-day exercise/set editor (param: `date` `YYYY-MM-DD`) | `/workout/:date` |

**Lift button (FAB):** In Expo, the tab bar centers a **“LIFT”** control that navigates to today’s log. In Vue, mirror with a **fixed bottom nav** or **center FAB** linking to `/workout/<today>`.

---

## Domain model

### Storage keys (preserve for migration / mental parity)

| Key | Contents |
|-----|----------|
| `liftbig_workouts` | `WorkoutLog` — map `dateKey` → `Exercise[]` |
| `liftbig_templates` | `WorkoutTemplate[]` |

`dateKey` format: **`YYYY-MM-DD`** (local calendar semantics; document that the app uses the **client local timezone** for “today” and calendar cells).

### Types (canonical for Vue + TypeScript)

**Logged set (workout day):**

```ts
type SetLog = {
  id: string;
  reps: string;
  weight: string;
  checked?: boolean; // circuit completion
};
```

**Logged exercise:**

```ts
type Exercise = {
  id: string;
  name: string;
  sets: SetLog[];
  isCircuit?: boolean;
  targetReps?: string;   // from template: rep goal / range / AMRAP
  targetWeight?: string; // template goal weight (lbs)
};
```

**Workout log root:**

```ts
type WorkoutLog = Record<string, Exercise[]>; // key = dateKey
```

**Template (plan) types:**

```ts
type TemplateSet = { targetReps: string; targetWeight: string };
type TemplateExercise = {
  id: string;
  name: string;
  sets: TemplateSet[];
  isCircuit?: boolean;
};
type WorkoutTemplate = {
  id: string;
  name: string;
  exercises: TemplateExercise[];
  isCircuit?: boolean;
};
```

**Reference gap to close in Vue:** In the Expo home screen, assigning a plan maps template exercises to logged exercises but **does not copy** `isCircuit`, `targetReps`, or `targetWeight` onto `Exercise`. The workout log and `defaultPlans` expect those fields for **circuit UI** and **progressive overload**. The Vue port should **assign the full exercise shape** so circuits and suggestions behave consistently.

---

## Feature specifications

### 1. Home (`index`)

- **Month grid** with Sun–Sat headers; empty leading cells for month start weekday.
- **State:** `viewYear`, `viewMonth`, `selectedDate`.
- **Indicators:** dot on days with `workouts[dateKey]?.length`.
- **Styling cues:** selected day (orange), today (blue outline) when not selected.
- **Navigation:** prev/next month (buttons + optional horizontal swipe on grid).
- **Selected day panel:** formatted date, exercise count, **delete entire day** (confirm), **Open Log** → `/workout/:date`.
- **Assign plan:** if templates exist, dashed bar opens bottom sheet; choosing a template **appends** cloned exercises to that day’s array, then persists `liftbig_workouts`.

### 2. Overview / Calendar (`overview`)

- Same month machinery as Home.
- **Stats bar** for visible month: **trained days** (days with ≥1 exercise), **rest days** (`daysInMonth - trained`), **consistency %** (`round(trained/daysInMonth*100)`).
- **Cell behavior:** tap opens **modal** — empty state with “Log workout”; else list cards with aggregates (sets, total reps if parseable, max weight), **Delete day**, **Edit** → log route.
- Swipe-on-header tab switching (optional in Vue; can be CSS touch or omitted on desktop).

### 3. Plans (`plans`)

- Load/save `liftbig_templates`.
- **List** templates with exercise preview (first set’s reps/weight shorthand).
- **FAB:** “+ New Plan”.
- **Modal editor:** plan name, repeatable **exercise cards** (name, sets table: target reps / target lbs, add/remove sets, remove exercise), add exercise, **Save** / close.
- **Validation:** plan name required; ≥1 named exercise.
- **Delete** with confirm.

**Seeding:** On first run (no `liftbig_templates`), seed **`DEFAULT_PLANS`** from reference `utils/defaultPlans.ts` (same IDs and exercise definitions). Implement as a static module imported once by the storage layer.

### 4. Plates (`plates`)

- **Inputs:** target total weight (lbs), bar weight toggle **45** vs **35**.
- **Algorithm:** `weightPerSide = (target - bar) / 2`; greedy load from plate inventory **`[45, 35, 25, 10, 5, 2.5]`** per side; return ordered plate list per side + **remainder** (floating lbs not achievable).
- **UI:** total achieved weight; exact vs “closest achievable” message; visual bar (collars + plates + colors); per-side count breakdown; **quick reference** rows (135, 185, 225, 315, 405) that set input and recalculate.
- Stateless utility: port `calculatePlates` verbatim as a pure function in `src/utils/plates.ts` (or similar).

### 5. Workout log (`workout-log`)

- **Route param:** `date` (default today if missing).
- **Load:** `liftbig_workouts[dateKey]` into reactive list.
- **Autosave:** debounced write on `exercises` change (reference writes on every change; Vue should **debounce** ~300–500 ms to avoid localStorage thrash).
- **Add exercise:** name required; default one empty set `{ reps, weight }`.
- **Normal sets:** row per set with reps/weight inputs, optional **target reps** column label from `exercise.targetReps`; delete set; add set.
- **Circuit sets:** when `isCircuit`, rows are **checkboxes** toggling `checked`; display uses reps/weight as copy (AMRAP / default lbs in reference).
- **Progress:** “completed” = circuit checked vs non-circuit both reps and weight non-empty; badge + green border when all sets complete.
- **Progressive overload suggestion:** for non-circuit exercises with `targetReps`, call `getSuggestedWeight(name, targetReps, base)` where `base` is `parseFloat(sets[0].weight || targetWeight || "0")`; show box when reason ≠ `"No history yet"`.
- **Rest timer:** durations **30 / 60 / 90 / 120** s; tap play/pause; long-press opens picker; countdown to 0 then “done” state (web: audio or toast optional).
- **Finish:** confirm dialog summarizing counts; navigate home (reference: `router.push("/")`).

### 6. Progressive overload (`progressiveOverload`)

Port logic as **framework-agnostic TypeScript** accepting a **`WorkoutLog` (or history interface)** instead of reading storage inside the function — the Vue composable loads `liftbig_workouts` and passes data in. Preserve:

- **`INCREMENT_MAP`:** exercise-name substring → lbs increment.
- **`parseRepRange`:** supports single number, `8-12` style, **AMRAP**.
- **History scan:** all dates, match exercise **case-insensitive** name, sort dates descending, inspect **last session** completed sets.
- **Rules:** all reps at top of range (or AMRAP) → suggest **last weight + increment**; any set below min → **maintain**; else **maintain** with “push reps” copy.

---

## Visual design tokens (Tailwind mapping)

Reference uses a consistent dark palette; map to Tailwind theme / arbitrary values:

| Token | Hex | Usage |
|-------|-----|--------|
| Background | `#0A0F1E` | Page bg |
| Card | `#111827` | Cards, inputs |
| Border | `#1E2A45` | Borders |
| Primary / accent | `#F4501E` | Brand, CTAs, selected calendar |
| Blue | `#1D4ED8` | Secondary buttons |
| Blue soft | `#1E3A5F` | Today highlight |
| Text | `#F0F4FF` | Primary text |
| Muted | `#4A5A7A` | Secondary |

Use **Font Awesome** for nav and actions where the reference uses emoji (optional: keep emoji for parity or swap for `fa-*` icons per project preference).

---

## Vue application structure (recommended)

```
src/
  main.ts
  App.vue
  router/index.ts          # routes above + scrollBehavior
  assets/
  components/
    layout/AppShell.vue    # safe-area padding, bottom nav + center Lift
    calendar/MonthGrid.vue
    calendar/MonthNav.vue
    plans/PlanEditorModal.vue
    workout/ExerciseCard.vue
    workout/SetRow.vue
    workout/RestTimer.vue
  composables/
    useLocalWorkouts.ts    # read/write liftbig_workouts + debounce
    useTemplates.ts
    useMonthCalendar.ts    # cells, dateKey helpers
  utils/
    dateKey.ts
    plates.ts
    progressiveOverload.ts
    defaultPlans.ts
  views/
    HomeView.vue
    OverviewView.vue
    PlansView.vue
    PlatesView.vue
    WorkoutLogView.vue
```

**State:** Prefer **composables + `ref`** backed by **`localStorage`** (same JSON keys). Optionally introduce **Pinia** if multiple views need synchronized cache without prop drilling.

**Persistence adapter:**

```ts
// Web equivalent of AsyncStorage
function loadJson<T>(key: string, fallback: T): T;
function saveJson(key: string, value: unknown): void;
```

Handle **`JSON.parse` errors** and quota exceeded (user-facing toast once).

---

## Routing (`vue-router`)

- **`/`** — HomeView  
- **`/overview`** — OverviewView  
- **`/plans`** — PlansView  
- **`/plates`** — PlatesView  
- **`/workout/:date?`** — WorkoutLogView (`date` regex `^\d{4}-\d{2}-\d{2}$` or validate in `beforeEnter`)

**Navigation guards:** none required for auth; optional future guard if accounts added.

---

## Build and deployment

- **Vite** + Vue 3 + TypeScript (recommended stack; align with existing project tooling if already chosen).
- **Static output:** `vite build` → `dist/` served by any static host (CDN, GitHub Pages, S3, etc.).
- **PWA (optional):** service worker for offline read/write of local data; not in Expo reference but natural fit for gym use.

---

## Testing priorities

1. **Plate calculator:** known totals (225, 315) exact; odd targets produce correct remainder.
2. **`getSuggestedWeight`:** rep ranges, AMRAP, increment map fallback, failed vs max-rep sessions.
3. **Calendar helpers:** `dateKey` boundaries, month lengths, week start Sunday.
4. **Storage:** assign plan append, delete day, template CRUD, seed idempotency.

---

## Out of scope (reference app has no backend)

- User accounts, sync, or server-side backup.
- Push notifications (timer is in-app only).
- Imperial **kg** mode (reference is lbs throughout); future feature would touch templates, log inputs, and plate inventory.

---

## Migration from Expo / AsyncStorage

If users export raw key JSON from a future mobile build, the **same keys and shapes** allow import. For a **one-way** web-only launch, document that data lives in **browser localStorage** and clearing site data resets the journal.

---

## Stack constraints (project)

- Frontend: **Vue.js**; routing: **vue-router**.
- Styling: **Tailwind CSS** (already installed).
- Icons: **Font Awesome Free** (already installed).
- Delivery: **static** hosting, **mobile-first** layout with responsive breakpoints for desktop.

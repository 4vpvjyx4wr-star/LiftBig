# LiftBig — Project Context

Use this document as the source of truth when planning or implementing changes.

## Production target (only)

**All new work targets the live web app:**

**https://liftbig.julianmcgookin.com**

Do not plan or implement features for Expo Go, native mobile builds, or the Expo dev workflow unless the user explicitly asks for that.

## What runs in production

The live site is a **Vue 3 + Vite** progressive web app (PWA), not the Expo/React Native app under `app/`.

| Area | Location |
|------|----------|
| Deployed static site | `dist/` |
| Live URL | https://liftbig.julianmcgookin.com |
| Library UI | `dist/assets/LibraryView-*.js`, `LibraryBrowser-*.js` |
| Exercise catalog | `dist/assets/exerciseLibrary-*.js` |
| Workout / log data (client) | `dist/assets/workout-*.js`, `dist/assets/storage-*.js` |
| Patched source-of-truth for library stats | `web/patches/` |
| Patch build pipeline | `npm run build:web` |

Deployment is via **Cloudflare Pages** from the `main` branch with build output directory **`dist`**.

If changes are in GitHub but not on the live site, Cloudflare is not deploying this repo yet. Fix:

1. In [Cloudflare Pages](https://dash.cloudflare.com/) → **liftbig** → connect **4vpvjyx4wr-star/LiftBig**, branch `main`, output directory `dist` (build command optional: `npm run build:web`).
2. Or add GitHub repo secrets `CLOUDFLARE_API_TOKEN` + `CLOUDFLARE_ACCOUNT_ID` so `.github/workflows/deploy-cloudflare-pages.yml` uploads `dist/` on each push.
3. After deploy, open `https://liftbig.julianmcgookin.com/version.json` — it should list `library-tile-max-avg`.
4. On a phone with the PWA installed: fully close the app, reopen, or clear site data if tiles still look old (service worker cache).

## Expo / React Native (legacy)

The `app/` directory is an **older Expo/React Native client**. It is **not** what powers liftbig.julianmcgookin.com.

- **We are not using Expo Go.**
- Do not add tabs, screens, or features only in `app/(tabs)/` expecting them to appear on the live site.
- If Expo code conflicts with web work, prefer the web app and `dist/`.

## How to implement web changes

1. **Prefer readable patches** in `web/patches/` and `web/scripts/` when the full Vue source tree is not in the repo.
2. Run **`npm run build:web`** to sync production assets and apply patches into `dist/`.
3. **Commit and push `dist/`** so Cloudflare Pages picks up the update.
4. Verify on https://liftbig.julianmcgookin.com (hard refresh if cached).

## Key product facts

- Bottom nav on live site: Home, Progress, LIFT (center), Plans, **Library**.
- Library lists exercises from the built-in catalog (e.g. “Ab Machine / Crunch”) with filters for muscle group, equipment, favorites, and logged history.
- User workout history is stored in the browser (local storage / IndexedDB via the production storage modules).
- Library tile stats (Max / Avg) are computed in `libraryExerciseTracking` and shown on each tile in `LibraryBrowser`; warmups are excluded from stats.

## When in doubt

Ask: *“Will this change appear on liftbig.julianmcgookin.com after `dist/` is deployed?”*  
If no, implement it in `web/` + `dist/` (or the appropriate production bundle), not in Expo-only paths.

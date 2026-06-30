# LiftBig

LiftBig is deployed as a Vue web app at [liftbig.julianmcgookin.com](https://liftbig.julianmcgookin.com).

**Project context:** see [CONTEXT.md](./CONTEXT.md) — we are not on Expo Go; all changes target the live web app.

The `dist/` folder contains the production static site. Library Max/Avg stats are applied via `web/patches/`:

```bash
npm run build:web
```

This syncs the live asset bundle, patches `libraryExerciseTracking` and `LibraryBrowser`, and updates `dist/` for Cloudflare Pages deploy.

The `app/` folder is a legacy Expo/React Native client and is not deployed to the live site.

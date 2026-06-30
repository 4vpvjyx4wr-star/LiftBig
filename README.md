# LiftBig

LiftBig is deployed as a Vue web app at [liftbig.julianmcgookin.com](https://liftbig.julianmcgookin.com).

The `dist/` folder contains the production static site. Library Max/Avg stats are applied via `web/patches/`:

```bash
npm run build:web
```

This syncs the live asset bundle, patches `libraryExerciseTracking` and `LibraryBrowser`, and updates `dist/` for Cloudflare Pages deploy.

The `app/` folder contains an Expo/React Native client (optional).

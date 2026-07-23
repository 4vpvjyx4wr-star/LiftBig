# LiftBig

Vue 3 + Vite workout app.

## Git remotes and live deploys

- **Canonical repo:** [codycon1/LiftBig](https://github.com/codycon1/LiftBig) (`origin`)
- Plain `git push` updates **codycon1** and the live mirror so production stays in sync
- On `npm install`, `scripts/install-git-hooks.mjs` re-applies this remote setup
- Production deploy: [`.github/workflows/deploy-cloudflare.yml`](../.github/workflows/deploy-cloudflare.yml) on every push to `main`

Cloudflare should use **codycon1/LiftBig**, root directory `LiftBig`, build `npm run build`, output `dist`. Add Actions secrets `CLOUDFLARE_API_TOKEN` + `CLOUDFLARE_ACCOUNT_ID` (or `CLOUDFLARE_DEPLOY_HOOK`) on the codycon1 repo.

## Project Setup

```sh
npm install
```

### Compile and Hot-Reload for Development

```sh
npm run dev
```

### Type-Check, Compile and Minify for Production

```sh
npm run build
```

### Lint with [ESLint](https://eslint.org/)

```sh
npm run lint
```

## Adding library exercises

New gym / non-cardio exercises need a **YouTube tutorial** and a **form GIF** (design-system illustration). Follow the checklist in [`tools/exercise-assets/README.md`](tools/exercise-assets/README.md). Cardio/sports skip GIFs; some mobility may omit a GIF intentionally.

## Recommended IDE Setup

[VS Code](https://code.visualstudio.com/) + [Vue (Official)](https://marketplace.visualstudio.com/items?itemName=Vue.volar) (and disable Vetur).

## Recommended Browser Setup

- Chromium-based browsers (Chrome, Edge, Brave, etc.):
  - [Vue.js devtools](https://chromewebstore.google.com/detail/vuejs-devtools/nhdogjmejiglipccpnnnanhbledajbpd)
  - [Turn on Custom Object Formatter in Chrome DevTools](http://bit.ly/object-formatters)
- Firefox:
  - [Vue.js devtools](https://addons.mozilla.org/firefox/addon/vuejs-devtools/)
  - [Turn on Custom Object Formatter in Firefox DevTools](https://fxdx.dev/docs/guide/custom-object-formatters/)

## Type Support for `.vue` Imports in TS

TypeScript cannot handle type information for `.vue` imports by default, so we replace the `tsc` CLI with `vue-tsc` for type checking. In editors, we need [Volar](https://marketplace.visualstudio.com/items?itemName=Vue.volar) to make the TypeScript language service aware of `.vue` types.

## Customize configuration

See [Vite Configuration Reference](https://vite.dev/config/).

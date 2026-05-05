/**
 * Serves the Vite-built Vue app via Workers Static Assets.
 * Wrangler `not_found_handling = "single-page-application"` maps unknown paths to index.html for vue-router.
 */
export default {
  async fetch(request, env) {
    return env.ASSETS.fetch(request);
  },
};

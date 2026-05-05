/**
 * Minimal worker: serve static assets (index.html + static/) for Cloudflare Workers.
 */
export default {
  async fetch(request, env) {
    return env.ASSETS.fetch(request);
  },
};

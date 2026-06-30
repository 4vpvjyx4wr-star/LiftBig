/** Single source of truth for bottom-dashboard tab order and metadata. */
export const DASHBOARD_TABS = [
  { name: "index", path: "/", label: "HOME", icon: "🏠" },
  { name: "overview", path: "/overview", label: "CALENDAR", icon: "📅" },
  { name: "plans", path: "/plans", label: "PLANS", icon: "📋" },
  { name: "library", path: "/library", label: "LIBRARY", icon: "📚" },
  { name: "plates", path: "/plates", label: "PLATES", icon: "🏅" },
] as const;

export type DashboardTabName = (typeof DASHBOARD_TABS)[number]["name"];

export const DASHBOARD_TAB_NAMES = DASHBOARD_TABS.map((t) => t.name);
export const DASHBOARD_TAB_PATHS = DASHBOARD_TABS.map((t) => t.path);

const tabByName = Object.fromEntries(DASHBOARD_TABS.map((t) => [t.name, t]));
const tabByPath = Object.fromEntries(DASHBOARD_TABS.map((t) => [t.path, t]));

export function getTabMeta(name: string) {
  return tabByName[name as DashboardTabName];
}

export function getTabIndexFromPath(pathname: string): number {
  const normalized = pathname.replace(/\/$/, "") || "/";
  const byPath = DASHBOARD_TAB_PATHS.indexOf(normalized as (typeof DASHBOARD_TAB_PATHS)[number]);
  if (byPath >= 0) return byPath;

  const segment = normalized.split("/").filter(Boolean).pop();
  if (!segment) return 0;
  return getTabIndexFromName(segment);
}

export function getTabIndexFromName(name: string): number {
  return DASHBOARD_TAB_NAMES.indexOf(name as DashboardTabName);
}

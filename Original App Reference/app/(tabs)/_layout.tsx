import { BottomTabBarProps } from "@react-navigation/bottom-tabs";
import { Tabs, useRouter } from "expo-router";
import { StatusBar, StyleSheet, Text, TouchableOpacity, View } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

const BG = "#0A0F1E";
const ORANGE = "#F4501E";
const MUTED = "#4A5A7A";
const WHITE = "#F0F4FF";
const BORDER = "#1E2A45";

const TAB_ICONS: Record<string, string> = {
  index: "🏠",
  overview: "📅",
  plans: "📋",
  plates: "🏅",
};
const TAB_LABELS: Record<string, string> = {
  index: "HOME",
  overview: "CALENDAR",
  plans: "PLANS",
  plates: "PLATES",
};

function toDateKey(d: Date) {
  return `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,"0")}-${String(d.getDate()).padStart(2,"0")}`;
}

function CustomTabBar({ state, navigation }: BottomTabBarProps) {
  const insets = useSafeAreaInsets();
  const router = useRouter();
  const todayKey = toDateKey(new Date());

  const visibleRoutes = state.routes.filter((r) => r.name !== "workout-log");
  const leftRoutes  = visibleRoutes.slice(0, 2);
  const rightRoutes = visibleRoutes.slice(2);

  const renderTab = (route: (typeof state.routes)[0]) => {
    const isFocused = state.routes[state.index]?.name === route.name;
    return (
      <TouchableOpacity
        key={route.key}
        style={tb.tab}
        onPress={() => { if (!isFocused) navigation.navigate(route.name as never); }}
        activeOpacity={0.7}
      >
        <Text style={{ fontSize: 22, color: isFocused ? ORANGE : MUTED }}>
          {TAB_ICONS[route.name]}
        </Text>
        <Text style={[tb.label, { color: isFocused ? ORANGE : MUTED }]}>
          {TAB_LABELS[route.name]}
        </Text>
      </TouchableOpacity>
    );
  };

  return (
    <View style={[tb.bar, { paddingBottom: insets.bottom > 0 ? insets.bottom : 10 }]}>
      <View style={tb.side}>{leftRoutes.map(renderTab)}</View>

      {/* ── Center TODAY button ── */}
      <View style={tb.centerWrapper}>
        <TouchableOpacity
          style={tb.centerBtn}
          onPress={() => router.push({ pathname: "/workout-log", params: { date: todayKey } })}
          activeOpacity={0.85}
        >
          <Text style={tb.centerIcon}>💪</Text>
        </TouchableOpacity>
        <Text style={tb.centerLabel}>LIFT</Text>
      </View>

      <View style={tb.side}>{rightRoutes.map(renderTab)}</View>
    </View>
  );
}

const tb = StyleSheet.create({
  bar: {
    flexDirection: "row",
    alignItems: "flex-end",
    backgroundColor: BG,
    borderTopWidth: 1,
    borderTopColor: BORDER,
    paddingTop: 8,
  },
  side: { flex: 2, flexDirection: "row" },
  tab: { flex: 1, alignItems: "center", paddingBottom: 2 },
  label: { fontSize: 9, fontWeight: "700", letterSpacing: 0.5, marginTop: 2 },

  centerWrapper: { flex: 1.2, alignItems: "center", justifyContent: "flex-end", marginBottom: 2 },
  centerBtn: {
    width: 58,
    height: 58,
    borderRadius: 29,
    backgroundColor: ORANGE,
    alignItems: "center",
    justifyContent: "center",
    marginBottom: 2,
    shadowColor: ORANGE,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.5,
    shadowRadius: 8,
    elevation: 10,
    // Lift above the bar
    transform: [{ translateY: -10 }],
  },
  centerIcon: { fontSize: 26 },
  centerLabel: { fontSize: 9, fontWeight: "800", color: ORANGE, letterSpacing: 0.5, marginTop: 0 },
});

export default function TabLayout() {
  return (
    <>
      <StatusBar barStyle="light-content" backgroundColor={BG} />
      <Tabs
        tabBar={(props) => <CustomTabBar {...props} />}
        screenOptions={{
          headerShown: false,
          // Smooth crossfade between tabs
          animation: "fade",
          sceneStyle: { backgroundColor: BG },
        }}
      >
        <Tabs.Screen name="index"    options={{ title: "HOME" }} />
        <Tabs.Screen name="overview" options={{ title: "CALENDAR" }} />
        <Tabs.Screen name="plans"    options={{ title: "PLANS" }} />
        <Tabs.Screen name="plates"   options={{ title: "PLATES" }} />
        <Tabs.Screen name="workout-log" options={{ href: null }} />
      </Tabs>
    </>
  );
}
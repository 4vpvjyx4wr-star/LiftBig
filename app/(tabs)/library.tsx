import AsyncStorage from "@react-native-async-storage/async-storage";
import { useFocusEffect } from "expo-router";
import React, { useCallback, useMemo, useState } from "react";
import {
  Animated,
  FlatList,
  StyleSheet,
  Text,
  TextInput,
  View,
} from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import {
  formatSetStat,
  getLibraryLiftNames,
  getLiftStatsForExercise,
  type WorkoutLog,
  type WorkoutTemplate,
} from "../../utils/liftStats";
import { useTabSwipe } from "../../utils/useTabSwipe";

const WORKOUTS_KEY = "liftbig_workouts";
const TEMPLATES_KEY = "liftbig_templates";

type LiftTileData = {
  name: string;
  maxLabel: string | null;
  avgLabel: string | null;
  hasHistory: boolean;
};

const LiftTile = React.memo(function LiftTile({ item }: { item: LiftTileData }) (
  <View style={s.liftTile}>
    <Text style={s.liftName} numberOfLines={2}>
      {item.name}
    </Text>
    <View style={s.statsRow}>
      <View style={s.statBlock}>
        <Text style={s.statLabel}>Max</Text>
        <Text style={[s.statValue, !item.maxLabel && s.statEmpty]}>
          {item.maxLabel ?? "—"}
        </Text>
      </View>
      <View style={s.statDivider} />
      <View style={s.statBlock}>
        <Text style={s.statLabel}>Avg</Text>
        <Text style={[s.statValue, !item.avgLabel && s.statEmpty]}>
          {item.avgLabel ?? "—"}
        </Text>
      </View>
    </View>
  </View>
));

export default function LibraryScreen() {
  const [workouts, setWorkouts] = useState<WorkoutLog>({});
  const [templates, setTemplates] = useState<WorkoutTemplate[]>([]);
  const [search, setSearch] = useState("");
  const { translateX: tabX, panHandlers: tabPan } = useTabSwipe(3);

  useFocusEffect(
    useCallback(() => {
      Promise.all([
        AsyncStorage.getItem(WORKOUTS_KEY),
        AsyncStorage.getItem(TEMPLATES_KEY),
      ]).then(([workoutsRaw, templatesRaw]) => {
        setWorkouts(workoutsRaw ? JSON.parse(workoutsRaw) : {});
        setTemplates(templatesRaw ? JSON.parse(templatesRaw) : []);
      });
    }, [])
  );

  const liftNames = useMemo(
    () => getLibraryLiftNames(templates, workouts),
    [templates, workouts]
  );

  const tiles: LiftTileData[] = useMemo(() => {
    const query = search.trim().toLowerCase();
    return liftNames
      .filter((name) => !query || name.toLowerCase().includes(query))
      .map((name) => {
        const stats = getLiftStatsForExercise(workouts, name);
        const hasHistory = stats.setCount > 0;
        return {
          name,
          hasHistory,
          maxLabel: stats.max ? formatSetStat(stats.max.weight, stats.max.reps) : null,
          avgLabel: stats.avg ? formatSetStat(stats.avg.weight, stats.avg.reps) : null,
        };
      });
  }, [liftNames, workouts, search]);

  return (
    <SafeAreaView style={s.safe} edges={["top"]}>
      <Animated.View style={[s.header, { transform: [{ translateX: tabX }] }]} {...tabPan}>
        <Text style={s.appName}>LIFTBIG</Text>
        <Text style={s.appTagline}>Exercise Library</Text>
      </Animated.View>

      <View style={s.searchWrap}>
        <TextInput
          style={s.searchInput}
          placeholder="Search lifts..."
          placeholderTextColor={MUTED}
          value={search}
          onChangeText={setSearch}
          autoCapitalize="none"
          autoCorrect={false}
        />
      </View>

      <FlatList
        data={tiles}
        keyExtractor={(item) => item.name}
        numColumns={2}
        columnWrapperStyle={s.row}
        contentContainerStyle={s.listContent}
        keyboardShouldPersistTaps="handled"
        ListEmptyComponent={
          <View style={s.empty}>
            <Text style={s.emptyIcon}>📚</Text>
            <Text style={s.emptyText}>No lifts found.</Text>
            <Text style={s.emptySubtext}>
              Lifts appear here from your plans and workout history.
            </Text>
          </View>
        }
        renderItem={({ item }) => <LiftTile item={item} />}
      />
    </SafeAreaView>
  );
}

const BG = "#0A0F1E";
const CARD = "#111827";
const BORDER = "#1E2A45";
const ORANGE = "#F4501E";
const WHITE = "#F0F4FF";
const MUTED = "#4A5A7A";

const s = StyleSheet.create({
  safe: { flex: 1, backgroundColor: BG },
  header: { paddingHorizontal: 20, paddingTop: 2, paddingBottom: 6 },
  appName: { fontSize: 36, fontWeight: "900", color: ORANGE, letterSpacing: 4 },
  appTagline: { fontSize: 10, color: MUTED, letterSpacing: 2, marginTop: 0 },

  searchWrap: { paddingHorizontal: 16, paddingBottom: 10 },
  searchInput: {
    backgroundColor: CARD,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: BORDER,
    color: WHITE,
    paddingHorizontal: 14,
    paddingVertical: 10,
    fontSize: 15,
  },

  listContent: { paddingHorizontal: 12, paddingBottom: 100 },
  row: { gap: 10, marginBottom: 10 },

  liftTile: {
    flex: 1,
    backgroundColor: CARD,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: BORDER,
    padding: 12,
    minHeight: 110,
    justifyContent: "space-between",
  },
  liftName: {
    color: WHITE,
    fontSize: 13,
    fontWeight: "700",
    marginBottom: 10,
    lineHeight: 17,
  },
  statsRow: {
    flexDirection: "row",
    alignItems: "center",
    borderTopWidth: 1,
    borderTopColor: BORDER,
    paddingTop: 8,
  },
  statBlock: { flex: 1, alignItems: "center" },
  statDivider: { width: 1, height: 28, backgroundColor: BORDER },
  statLabel: {
    color: MUTED,
    fontSize: 9,
    fontWeight: "700",
    letterSpacing: 0.8,
    marginBottom: 2,
  },
  statValue: { color: ORANGE, fontSize: 12, fontWeight: "800" },
  statEmpty: { color: MUTED, fontWeight: "600" },

  empty: { alignItems: "center", marginTop: 80, paddingHorizontal: 30 },
  emptyIcon: { fontSize: 44 },
  emptyText: { color: WHITE, fontSize: 18, fontWeight: "700", marginTop: 12 },
  emptySubtext: { color: MUTED, fontSize: 13, marginTop: 4, textAlign: "center" },
});

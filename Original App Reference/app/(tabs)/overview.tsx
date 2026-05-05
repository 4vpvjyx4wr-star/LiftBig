// app/(tabs)/overview.tsx
import AsyncStorage from "@react-native-async-storage/async-storage";
import { useFocusEffect, useRouter } from "expo-router";
import React, { useCallback, useRef, useState } from "react";
import {
  Alert,
  Animated,
  Dimensions,
  Modal,
  PanResponder,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { useTabSwipe } from "../../utils/useTabSwipe";

const { width: SCREEN_W } = Dimensions.get("window");

type Set        = { id: string; reps: string; weight: string };
type Exercise   = { id: string; name: string; sets: Set[] };
type WorkoutLog = { [dateKey: string]: Exercise[] };

const DAYS   = ["SUN","MON","TUE","WED","THU","FRI","SAT"];
const MONTHS = ["January","February","March","April","May","June","July","August","September","October","November","December"];

function toDateKey(d: Date) {
  return `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,"0")}-${String(d.getDate()).padStart(2,"0")}`;
}
function formatDisplayDate(dateKey: string) {
  const [y,m,d] = dateKey.split("-").map(Number);
  return `${MONTHS[m-1]} ${d}, ${y}`;
}

export default function OverviewScreen() {
  const router = useRouter();
  const today  = new Date();

  const [viewYear, setViewYear]   = useState(today.getFullYear());
  const [viewMonth, setViewMonth] = useState(today.getMonth());
  const [workouts, setWorkouts]   = useState<WorkoutLog>({});
  const [modalDate, setModalDate] = useState<string | null>(null);

  const viewMonthRef = useRef(viewMonth);
  const viewYearRef  = useRef(viewYear);
  const isAnimating  = useRef(false);

  useFocusEffect(useCallback(() => {
    AsyncStorage.getItem("liftbig_workouts").then((raw) => {
      setWorkouts(raw ? JSON.parse(raw) : {});
    });
  }, []));

  // ── Month slide animation ──
  const monthAnim = useRef(new Animated.Value(0)).current;

  const updateMonth = useCallback((delta: number) => {
    let nm = viewMonthRef.current + delta;
    let ny = viewYearRef.current;
    if (nm > 11) { nm = 0; ny++; }
    if (nm < 0)  { nm = 11; ny--; }
    viewMonthRef.current = nm;
    viewYearRef.current  = ny;
    setViewMonth(nm);
    setViewYear(ny);
  }, []);

  const animateAndChangeMonth = useCallback((delta: number) => {
    if (isAnimating.current) return;
    isAnimating.current = true;
    Animated.timing(monthAnim, {
      toValue: delta > 0 ? -SCREEN_W : SCREEN_W,
      duration: 180, useNativeDriver: true,
    }).start(() => {
      updateMonth(delta);
      monthAnim.setValue(delta > 0 ? SCREEN_W : -SCREEN_W);
      Animated.spring(monthAnim, {
        toValue: 0, tension: 130, friction: 15, useNativeDriver: true,
      }).start(() => { isAnimating.current = false; });
    });
  }, [monthAnim, updateMonth]);

  const changeMonthRef = useRef(animateAndChangeMonth);
  changeMonthRef.current = animateAndChangeMonth;

  const calPan = useRef(PanResponder.create({
    onMoveShouldSetPanResponder: (_, gs) =>
      Math.abs(gs.dx) > 14 && Math.abs(gs.dx) > Math.abs(gs.dy) * 1.6,
    onPanResponderMove: (_, gs) => {
      if (!isAnimating.current) monthAnim.setValue(gs.dx * 0.28);
    },
    onPanResponderRelease: (_, gs) => {
      if (isAnimating.current) return;
      if (gs.dx < -50) changeMonthRef.current(1);
      else if (gs.dx > 50) changeMonthRef.current(-1);
      else Animated.spring(monthAnim, { toValue: 0, tension: 180, friction: 18, useNativeDriver: true }).start();
    },
  })).current;

  const { translateX: tabX, panHandlers: tabPan } = useTabSwipe(1);

  const deleteWorkout = (dateKey: string) => {
    Alert.alert("Delete Workout", "Remove all exercises for this day?", [
      { text: "Cancel", style: "cancel" },
      {
        text: "Delete", style: "destructive",
        onPress: async () => {
          const raw = await AsyncStorage.getItem("liftbig_workouts");
          const all: WorkoutLog = raw ? JSON.parse(raw) : {};
          delete all[dateKey];
          await AsyncStorage.setItem("liftbig_workouts", JSON.stringify(all));
          setWorkouts({ ...all });
          setModalDate(null);
        },
      },
    ]);
  };

  const firstDay    = new Date(viewYear, viewMonth, 1).getDay();
  const daysInMonth = new Date(viewYear, viewMonth + 1, 0).getDate();
  const cells: (number | null)[] = [
    ...Array(firstDay).fill(null),
    ...Array.from({ length: daysInMonth }, (_, i) => i + 1),
  ];

  const monthlyWorkoutDays = cells.filter((day) => {
    if (!day) return false;
    const key = `${viewYear}-${String(viewMonth+1).padStart(2,"0")}-${String(day).padStart(2,"0")}`;
    return !!workouts[key]?.length;
  }).length;

  const modalExercises = modalDate ? (workouts[modalDate] ?? []) : [];

  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: BG }} edges={["top"]}>

      {/* ── HEADER ── */}
      <Animated.View style={[s.header, { transform: [{ translateX: tabX }] }]} {...tabPan}>
        <Text style={s.appName}>LIFTBIG</Text>
        <Text style={s.appTagline}>Monthly Overview</Text>
      </Animated.View>

      {/* ── MONTH NAV ── */}
      <View style={s.monthNav}>
        <TouchableOpacity onPress={() => animateAndChangeMonth(-1)} style={s.navBtn}>
          <Text style={s.navArrow}>‹</Text>
        </TouchableOpacity>
        <Text style={s.monthLabel}>{MONTHS[viewMonth]} {viewYear}</Text>
        <TouchableOpacity onPress={() => animateAndChangeMonth(1)} style={s.navBtn}>
          <Text style={s.navArrow}>›</Text>
        </TouchableOpacity>
      </View>

      {/* ── STATS ── */}
      <View style={s.statsBar}>
        <View style={s.statItem}>
          <Text style={s.statNumber}>{monthlyWorkoutDays}</Text>
          <Text style={s.statLabel}>TRAINED</Text>
        </View>
        <View style={s.statDivider} />
        <View style={s.statItem}>
          <Text style={s.statNumber}>{daysInMonth - monthlyWorkoutDays}</Text>
          <Text style={s.statLabel}>REST</Text>
        </View>
        <View style={s.statDivider} />
        <View style={s.statItem}>
          <Text style={s.statNumber}>
            {monthlyWorkoutDays > 0 ? Math.round((monthlyWorkoutDays / daysInMonth) * 100) : 0}%
          </Text>
          <Text style={s.statLabel}>CONSISTENCY</Text>
        </View>
      </View>

      {/* ── DAY HEADERS ── */}
      <View style={s.dayHeaders}>
        {DAYS.map((d) => <Text key={d} style={s.dayHeader}>{d}</Text>)}
      </View>

      {/* ── CALENDAR GRID ── */}
      <Animated.View style={{ transform: [{ translateX: monthAnim }] }} {...calPan.panHandlers}>
        <View style={s.grid}>
          {cells.map((day, idx) => {
            if (!day) return <View key={`e-${idx}`} style={s.cell} />;
            const dateKey  = `${viewYear}-${String(viewMonth+1).padStart(2,"0")}-${String(day).padStart(2,"0")}`;
            const isToday  = dateKey === toDateKey(today);
            const exercises = workouts[dateKey] ?? [];
            const hasWork   = exercises.length > 0;

            return (
              <TouchableOpacity
                key={dateKey}
                style={[s.cell, hasWork && s.cellWorkedOut, isToday && !hasWork && s.cellToday, isToday && hasWork && s.cellTodayWorkedOut]}
                onPress={() => setModalDate(dateKey)}
                activeOpacity={0.7}
              >
                <Text style={[s.cellText, hasWork && s.cellTextActive, isToday && !hasWork && s.cellTextToday]}>
                  {day}
                </Text>
                {hasWork && <Text style={s.cellCount}>{exercises.length}</Text>}
                {!hasWork && isToday && <View style={s.todayDot} />}
              </TouchableOpacity>
            );
          })}
        </View>
      </Animated.View>

      {/* ── LEGEND ── */}
      <View style={s.legend}>
        <View style={s.legendItem}>
          <View style={[s.legendSwatch, { backgroundColor: ORANGE }]} />
          <Text style={s.legendText}>Workout logged</Text>
        </View>
        <View style={s.legendItem}>
          <View style={[s.legendSwatch, { backgroundColor: BLUE_SOFT, borderWidth: 1, borderColor: BLUE }]} />
          <Text style={s.legendText}>Today</Text>
        </View>
      </View>

      {/* ── MODAL ── */}
      <Modal visible={!!modalDate} animationType="slide" transparent onRequestClose={() => setModalDate(null)}>
        <TouchableOpacity style={s.modalOverlay} activeOpacity={1} onPress={() => setModalDate(null)}>
          <TouchableOpacity style={s.modalSheet} activeOpacity={1} onPress={() => {}}>
            <View style={s.sheetHandle} />
            <Text style={s.modalDate}>{modalDate ? formatDisplayDate(modalDate) : ""}</Text>

            {modalExercises.length === 0 ? (
              <View style={s.modalEmpty}>
                <Text style={s.modalEmptyIcon}>🗓️</Text>
                <Text style={s.modalEmptyText}>No workout logged for this day.</Text>
                <TouchableOpacity
                  style={s.modalLogBtn}
                  onPress={() => { setModalDate(null); router.push({ pathname: "/workout-log", params: { date: modalDate ?? "" } }); }}
                >
                  <Text style={s.modalLogBtnText}>+ Log a Workout</Text>
                </TouchableOpacity>
              </View>
            ) : (
              <>
                <Text style={s.modalSubheader}>
                  {modalExercises.length} exercise{modalExercises.length !== 1 ? "s" : ""}
                </Text>
                <ScrollView style={s.modalList} showsVerticalScrollIndicator={false} contentContainerStyle={{ paddingBottom: 20 }}>
                  {modalExercises.map((ex, i) => {
                    const totalReps = ex.sets?.reduce((acc, set) => acc + (parseInt(set.reps)||0), 0) ?? 0;
                    const weights   = ex.sets?.map((set) => parseFloat(set.weight)||0) ?? [];
                    const maxWeight = weights.length > 0 ? Math.max(...weights) : 0;
                    return (
                      <View key={ex.id} style={s.exerciseCard}>
                        <View style={s.exerciseCardLeft}><Text style={s.exerciseNumber}>#{i+1}</Text></View>
                        <View style={s.exerciseCardBody}>
                          <Text style={s.exerciseCardName}>{ex.name}</Text>
                          <View style={s.exerciseStats}>
                            <Text style={s.exerciseStat}><Text style={s.exerciseStatValue}>{ex.sets?.length||0}</Text> sets</Text>
                            {totalReps > 0 && <Text style={s.exerciseStat}><Text style={s.exerciseStatValue}>{totalReps}</Text> reps</Text>}
                            {maxWeight > 0 && <Text style={s.exerciseStat}><Text style={s.exerciseStatValue}>{maxWeight}</Text> lbs</Text>}
                          </View>
                        </View>
                      </View>
                    );
                  })}
                </ScrollView>
                <View style={{ flexDirection: "row", gap: 10, marginTop: 16 }}>
                  <TouchableOpacity
                    style={[s.modalEditBtn, { flex: 1, backgroundColor: "#2a0a0a", borderWidth: 1, borderColor: "#6b1a1a" }]}
                    onPress={() => modalDate && deleteWorkout(modalDate)}
                  >
                    <Text style={[s.modalEditBtnText, { color: "#ff6b6b" }]}>🗑 Delete</Text>
                  </TouchableOpacity>
                  <TouchableOpacity
                    style={[s.modalEditBtn, { flex: 2 }]}
                    onPress={() => { setModalDate(null); router.push({ pathname: "/workout-log", params: { date: modalDate ?? "" } }); }}
                  >
                    <Text style={s.modalEditBtnText}>Edit Workout</Text>
                  </TouchableOpacity>
                </View>
              </>
            )}
          </TouchableOpacity>
        </TouchableOpacity>
      </Modal>
    </SafeAreaView>
  );
}

const BG      = "#0A0F1E";
const CARD    = "#111827";
const BORDER  = "#1E2A45";
const ORANGE  = "#F4501E";
const BLUE    = "#1D4ED8";
const BLUE_SOFT = "#1E3A5F";
const WHITE   = "#F0F4FF";
const MUTED   = "#4A5A7A";

const s = StyleSheet.create({
  header:    { paddingHorizontal: 20, paddingTop: 2, paddingBottom: 4 },
  appName:   { fontSize: 36, fontWeight: "900", color: ORANGE, letterSpacing: 4 },
  appTagline:{ fontSize: 10, color: MUTED, letterSpacing: 2, marginTop: 0 },

  monthNav: {
    flexDirection: "row", alignItems: "center", justifyContent: "space-between",
    paddingHorizontal: 20, paddingVertical: 8,
    borderTopWidth: 1, borderBottomWidth: 1, borderColor: BORDER,
  },
  navBtn:    { padding: 6 },
  navArrow:  { color: ORANGE, fontSize: 26, fontWeight: "300" },
  monthLabel:{ color: WHITE, fontSize: 15, fontWeight: "700", letterSpacing: 1 },

  statsBar: {
    flexDirection: "row", backgroundColor: CARD,
    marginHorizontal: 16, marginVertical: 10,
    borderRadius: 12, borderWidth: 1, borderColor: BORDER, paddingVertical: 10,
  },
  statItem:   { flex: 1, alignItems: "center" },
  statNumber: { color: ORANGE, fontSize: 20, fontWeight: "900" },
  statLabel:  { color: MUTED, fontSize: 9, marginTop: 2, letterSpacing: 1 },
  statDivider:{ width: 1, backgroundColor: BORDER },

  dayHeaders:{ flexDirection: "row", paddingHorizontal: 8, paddingBottom: 3 },
  dayHeader: { flex: 1, textAlign: "center", color: MUTED, fontSize: 10, fontWeight: "700", letterSpacing: 0.5 },

  grid:{ flexDirection: "row", flexWrap: "wrap", paddingHorizontal: 8 },
  cell:{ width: "14.28%", aspectRatio: 1, alignItems: "center", justifyContent: "center", borderRadius: 8 },
  cellWorkedOut:     { backgroundColor: ORANGE },
  cellToday:         { backgroundColor: BLUE_SOFT, borderWidth: 1, borderColor: BLUE },
  cellTodayWorkedOut:{ backgroundColor: ORANGE, borderWidth: 2, borderColor: WHITE },
  cellText:          { color: MUTED, fontSize: 13, fontWeight: "600" },
  cellTextActive:    { color: WHITE, fontWeight: "900" },
  cellTextToday:     { color: "#93C5FD" },
  cellCount:         { fontSize: 9, color: WHITE, fontWeight: "700", marginTop: 1, opacity: 0.85 },
  todayDot:          { width: 4, height: 4, borderRadius: 2, backgroundColor: BLUE, marginTop: 2 },

  legend:    { flexDirection: "row", gap: 20, paddingHorizontal: 16, paddingTop: 8 },
  legendItem:{ flexDirection: "row", alignItems: "center", gap: 6 },
  legendSwatch:{ width: 12, height: 12, borderRadius: 3 },
  legendText:{ color: MUTED, fontSize: 11 },

  modalOverlay:{ flex: 1, backgroundColor: "rgba(0,0,0,0.6)", justifyContent: "flex-end" },
  modalSheet:{
    backgroundColor: "#0D1526", borderTopLeftRadius: 20, borderTopRightRadius: 20,
    paddingHorizontal: 20, paddingBottom: 36, paddingTop: 12,
    minHeight: 300, maxHeight: "70%", borderTopWidth: 1, borderColor: BORDER,
  },
  sheetHandle:{ width: 36, height: 4, backgroundColor: BORDER, borderRadius: 2, alignSelf: "center", marginBottom: 16 },
  modalDate: { color: WHITE, fontSize: 20, fontWeight: "800", letterSpacing: 0.5, marginBottom: 4 },
  modalSubheader:{ color: MUTED, fontSize: 13, marginBottom: 14 },
  modalList: { maxHeight: 240 },

  exerciseCard:     { flexDirection: "row", backgroundColor: CARD, borderRadius: 10, borderWidth: 1, borderColor: BORDER, marginBottom: 8, overflow: "hidden" },
  exerciseCardLeft: { backgroundColor: ORANGE, width: 36, alignItems: "center", justifyContent: "center" },
  exerciseNumber:   { color: WHITE, fontSize: 12, fontWeight: "900" },
  exerciseCardBody: { flex: 1, padding: 12 },
  exerciseCardName: { color: WHITE, fontSize: 15, fontWeight: "700", marginBottom: 6 },
  exerciseStats:    { flexDirection: "row", gap: 14 },
  exerciseStat:     { color: MUTED, fontSize: 12 },
  exerciseStatValue:{ color: ORANGE, fontWeight: "700" },

  modalEmpty:    { alignItems: "center", paddingVertical: 30 },
  modalEmptyIcon:{ fontSize: 36 },
  modalEmptyText:{ color: MUTED, fontSize: 14, marginTop: 10, marginBottom: 20 },
  modalLogBtn:   { backgroundColor: BLUE, borderRadius: 10, paddingHorizontal: 20, paddingVertical: 10 },
  modalLogBtnText:{ color: WHITE, fontWeight: "700", fontSize: 14 },

  modalEditBtn:   { backgroundColor: ORANGE, borderRadius: 12, paddingVertical: 14, alignItems: "center" },
  modalEditBtnText:{ color: WHITE, fontSize: 15, fontWeight: "800", letterSpacing: 0.5 },
});
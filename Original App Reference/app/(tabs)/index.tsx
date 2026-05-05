// app/(tabs)/index.tsx
import AsyncStorage from "@react-native-async-storage/async-storage";
import { useFocusEffect, useRouter } from "expo-router";
import { useCallback, useRef, useState } from "react";
import {
  Alert,
  Animated,
  Dimensions,
  Modal,
  Platform,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { useTabSwipe } from "../../utils/useTabSwipe";

const { width: SCREEN_W } = Dimensions.get("window");

type SetItem      = { id: string; reps: string; weight: string };
type Exercise     = { id: string; name: string; sets: SetItem[] };
type WorkoutLog   = { [dateKey: string]: Exercise[] };
type TemplateSet  = { targetReps: string; targetWeight: string };
type TemplateExercise = { id: string; name: string; sets: TemplateSet[] };
type WorkoutTemplate  = { id: string; name: string; exercises: TemplateExercise[] };

const DAYS   = ["SUN","MON","TUE","WED","THU","FRI","SAT"];
const MONTHS = ["January","February","March","April","May","June","July","August","September","October","November","December"];

function toDateKey(d: Date) {
  return `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,"0")}-${String(d.getDate()).padStart(2,"0")}`;
}

// ─── Assign Plan Bar ────────────────────────────────────────────────────────
const AssignPlanBar = ({ date, onAssigned }: { date: string; onAssigned: () => void }) => {
  const [templates, setTemplates] = useState<WorkoutTemplate[]>([]);
  const [modalVisible, setModalVisible] = useState(false);

  useFocusEffect(useCallback(() => {
    AsyncStorage.getItem("liftbig_templates").then((raw) => {
      setTemplates(raw ? JSON.parse(raw) : []);
    });
  }, []));

  const assignPlan = async (template: WorkoutTemplate) => {
    const raw = await AsyncStorage.getItem("liftbig_workouts");
    const all: WorkoutLog = raw ? JSON.parse(raw) : {};
    const existing = all[date] ?? [];
    const newExercises: Exercise[] = template.exercises.map((ex) => ({
      id: Date.now().toString() + Math.random(),
      name: ex.name,
      sets: ex.sets.map((s) => ({
        id: Date.now().toString() + Math.random(),
        reps: s.targetReps,
        weight: s.targetWeight,
      })),
    }));
    all[date] = [...existing, ...newExercises];
    await AsyncStorage.setItem("liftbig_workouts", JSON.stringify(all));
    setModalVisible(false);
    onAssigned();
  };

  if (templates.length === 0) return null;

  return (
    <>
      <TouchableOpacity style={apb.bar} onPress={() => setModalVisible(true)}>
        <Text style={apb.barText}>📋  Assign a Plan to This Day</Text>
      </TouchableOpacity>

      <Modal visible={modalVisible} animationType="slide" transparent onRequestClose={() => setModalVisible(false)}>
        <TouchableOpacity style={apb.overlay} activeOpacity={1} onPress={() => setModalVisible(false)}>
          <TouchableOpacity style={apb.sheet} activeOpacity={1} onPress={() => {}}>
            <View style={apb.handle} />
            <Text style={apb.sheetTitle}>Choose a Plan</Text>
            <Text style={apb.sheetSubtitle}>Exercises will be appended to this day.</Text>
            {templates.map((t) => (
              <TouchableOpacity key={t.id} style={apb.templateRow} onPress={() => assignPlan(t)}>
                <View style={apb.templateLeft}>
                  <Text style={apb.templateName}>{t.name}</Text>
                  <Text style={apb.templateMeta}>{t.exercises.length} exercise{t.exercises.length !== 1 ? "s" : ""}</Text>
                </View>
                <Text style={apb.templateArrow}>›</Text>
              </TouchableOpacity>
            ))}
          </TouchableOpacity>
        </TouchableOpacity>
      </Modal>
    </>
  );
};

// ─── Main Screen ────────────────────────────────────────────────────────────
export default function CalendarScreen() {
  const router  = useRouter();
  const today   = new Date();

  const [viewYear, setViewYear]         = useState(today.getFullYear());
  const [viewMonth, setViewMonth]       = useState(today.getMonth());
  const [selectedDate, setSelectedDate] = useState<string>(toDateKey(today));
  const [workouts, setWorkouts]         = useState<WorkoutLog>({});

  // Keep refs in sync so PanResponder closure sees fresh values
  const viewMonthRef = useRef(viewMonth);
  const viewYearRef  = useRef(viewYear);
  const isAnimating  = useRef(false);
  useRef(() => { viewMonthRef.current = viewMonth; });

  const reloadWorkouts = useCallback(() => {
    AsyncStorage.getItem("liftbig_workouts").then((raw) => {
      setWorkouts(raw ? JSON.parse(raw) : {});
    });
  }, []);
  useFocusEffect(useCallback(() => { reloadWorkouts(); }, [reloadWorkouts]));

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
      duration: 180,
      useNativeDriver: true,
    }).start(() => {
      updateMonth(delta);
      monthAnim.setValue(delta > 0 ? SCREEN_W : -SCREEN_W);
      Animated.spring(monthAnim, {
        toValue: 0, tension: 130, friction: 15, useNativeDriver: true,
      }).start(() => { isAnimating.current = false; });
    });
  }, [monthAnim, updateMonth]);

  // Stable callback ref for PanResponder
  const changeMonthRef = useRef(animateAndChangeMonth);
  changeMonthRef.current = animateAndChangeMonth;

  // ── Calendar swipe (month) PanResponder ──
  const calPan = useRef(
    PanResponder.create({
      onMoveShouldSetPanResponder: (_, gs) =>
        Math.abs(gs.dx) > 14 && Math.abs(gs.dx) > Math.abs(gs.dy) * 1.6,
      onPanResponderMove: (_, gs) => {
        if (!isAnimating.current) monthAnim.setValue(gs.dx * 0.28);
      },
      onPanResponderRelease: (_, gs) => {
        if (isAnimating.current) return;
        if (gs.dx < -50) changeMonthRef.current(1);
        else if (gs.dx > 50) changeMonthRef.current(-1);
        else Animated.spring(monthAnim, {
          toValue: 0, tension: 180, friction: 18, useNativeDriver: true,
        }).start();
      },
    })
  ).current;

  // ── Tab swipe (on header) ──
  const { translateX: tabX, panHandlers: tabPan } = useTabSwipe(0);

  // ── Delete workout ──
  const deleteWorkout = (dateKey: string) => {
    Alert.alert(
      "Delete Workout",
      `Remove all exercises for ${MONTHS[parseInt(dateKey.split("-")[1])-1]} ${parseInt(dateKey.split("-")[2])}?`,
      [
        { text: "Cancel", style: "cancel" },
        {
          text: "Delete", style: "destructive",
          onPress: async () => {
            const raw = await AsyncStorage.getItem("liftbig_workouts");
            const all: WorkoutLog = raw ? JSON.parse(raw) : {};
            delete all[dateKey];
            await AsyncStorage.setItem("liftbig_workouts", JSON.stringify(all));
            reloadWorkouts();
          },
        },
      ]
    );
  };

  const firstDay    = new Date(viewYear, viewMonth, 1).getDay();
  const daysInMonth = new Date(viewYear, viewMonth + 1, 0).getDate();
  const cells: (number | null)[] = [
    ...Array(firstDay).fill(null),
    ...Array.from({ length: daysInMonth }, (_, i) => i + 1),
  ];
  const selectedExercises  = workouts[selectedDate] ?? [];
  const hasSelectedWorkout = selectedExercises.length > 0;

  return (
    // Full bleed: edges=[] lets us manage all insets manually so BG fills everywhere
    <SafeAreaView style={s.safe} edges={["top"]}>

      {/* ── HEADER — also captures tab-swipe gestures ── */}
      <Animated.View style={[s.header, { transform: [{ translateX: tabX }] }]} {...tabPan}>
        <Text style={s.appName}>LIFTBIG</Text>
        <Text style={s.appTagline}>Training Journal</Text>
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

      {/* ── DAY HEADERS ── */}
      <View style={s.dayHeaders}>
        {DAYS.map((d) => <Text key={d} style={s.dayHeader}>{d}</Text>)}
      </View>

      {/* ── CALENDAR GRID — animated + swipeable ── */}
      <Animated.View
        style={{ transform: [{ translateX: monthAnim }] }}
        {...calPan.panHandlers}
      >
        <View style={s.grid}>
          {cells.map((day, idx) => {
            if (!day) return <View key={`e-${idx}`} style={s.cell} />;
            const dateKey  = `${viewYear}-${String(viewMonth+1).padStart(2,"0")}-${String(day).padStart(2,"0")}`;
            const isToday  = dateKey === toDateKey(today);
            const isSel    = dateKey === selectedDate;
            const hasWork  = !!workouts[dateKey]?.length;

            return (
              <TouchableOpacity
                key={dateKey}
                style={[s.cell, isSel && s.cellSelected, isToday && !isSel && s.cellToday]}
                onPress={() => setSelectedDate(dateKey)}
              >
                <Text style={[s.cellText, isSel && s.cellTextSelected, isToday && !isSel && s.cellTextToday]}>
                  {day}
                </Text>
                {hasWork && <View style={[s.dot, isSel && s.dotSelected]} />}
              </TouchableOpacity>
            );
          })}
        </View>
      </Animated.View>

      {/* ── SCROLLABLE LOWER SECTION ── */}
      <ScrollView
        style={s.bottomSection}
        contentContainerStyle={s.bottomContent}
        showsVerticalScrollIndicator={false}
        keyboardShouldPersistTaps="handled"
      >
        <View style={s.summaryHeader}>
          <View style={{ flex: 1 }}>
            <Text style={s.summaryDate}>
              {MONTHS[parseInt(selectedDate.split("-")[1])-1]}{" "}
              {parseInt(selectedDate.split("-")[2])}, {selectedDate.split("-")[0]}
            </Text>
            <Text style={s.summaryCount}>
              {hasSelectedWorkout
                ? `${selectedExercises.length} exercise${selectedExercises.length !== 1 ? "s" : ""} logged`
                : "No exercises logged"}
            </Text>
          </View>
          <View style={s.summaryActions}>
            {hasSelectedWorkout && (
              <TouchableOpacity style={s.deleteBtn} onPress={() => deleteWorkout(selectedDate)}>
                <Text style={s.deleteBtnText}>🗑</Text>
              </TouchableOpacity>
            )}
            <TouchableOpacity
              style={s.logBtn}
              onPress={() => router.push({ pathname: "/workout-log", params: { date: selectedDate } })}
            >
              <Text style={s.logBtnText}>Open Log ›</Text>
            </TouchableOpacity>
          </View>
        </View>

        <AssignPlanBar date={selectedDate} onAssigned={reloadWorkouts} />

        {hasSelectedWorkout ? (
          selectedExercises.map((item) => (
            <View key={item.id} style={s.exerciseRow}>
              <Text style={s.exerciseRowName}>{item.name}</Text>
              <Text style={s.exerciseRowSets}>{item.sets.length} set{item.sets.length !== 1 ? "s" : ""}</Text>
            </View>
          ))
        ) : (
          <View style={s.empty}>
            <Text style={s.emptyIcon}>📅</Text>
            <Text style={s.emptyText}>No workout logged.</Text>
            <Text style={s.emptySubtext}>Assign a plan above or tap Open Log.</Text>
          </View>
        )}
      </ScrollView>
    </SafeAreaView>
  );
}

// Needed for PanResponder import above
import { PanResponder } from "react-native";

const BG      = "#0A0F1E";
const CARD    = "#111827";
const BORDER  = "#1E2A45";
const ORANGE  = "#F4501E";
const BLUE    = "#1D4ED8";
const BLUE_SOFT = "#1E3A5F";
const WHITE   = "#F0F4FF";
const MUTED   = "#4A5A7A";

const apb = StyleSheet.create({
  bar: {
    marginBottom: 8, backgroundColor: CARD, borderRadius: 10,
    borderWidth: 1, borderColor: BORDER, borderStyle: "dashed",
    paddingVertical: 10, alignItems: "center",
  },
  barText: { color: MUTED, fontSize: 13, fontWeight: "600" },
  overlay: { flex: 1, backgroundColor: "rgba(0,0,0,0.7)", justifyContent: "flex-end" },
  sheet: {
    backgroundColor: "#0D1526", borderTopLeftRadius: 20, borderTopRightRadius: 20,
    paddingHorizontal: 20, paddingBottom: Platform.OS === "ios" ? 48 : 24,
    paddingTop: 12, borderTopWidth: 1, borderColor: BORDER,
  },
  handle: { width: 36, height: 4, backgroundColor: BORDER, borderRadius: 2, alignSelf: "center", marginBottom: 16 },
  sheetTitle:    { color: WHITE, fontSize: 20, fontWeight: "800", marginBottom: 4 },
  sheetSubtitle: { color: MUTED, fontSize: 13, marginBottom: 16 },
  templateRow: {
    flexDirection: "row", alignItems: "center", backgroundColor: CARD,
    borderRadius: 10, borderWidth: 1, borderColor: BORDER, padding: 14, marginBottom: 10,
  },
  templateLeft:  { flex: 1 },
  templateName:  { color: WHITE, fontSize: 16, fontWeight: "700" },
  templateMeta:  { color: MUTED, fontSize: 12, marginTop: 2 },
  templateArrow: { color: ORANGE, fontSize: 24 },
});

const s = StyleSheet.create({
  safe: { flex: 1, backgroundColor: BG },

  // Header pushed up — minimal top padding, logo is the first thing you see
  header: { paddingHorizontal: 20, paddingTop: 2, paddingBottom: 4 },
  appName:   { fontSize: 36, fontWeight: "900", color: ORANGE, letterSpacing: 4 },
  appTagline:{ fontSize: 10, color: MUTED, letterSpacing: 2, marginTop: 0 },

  monthNav: {
    flexDirection: "row", alignItems: "center", justifyContent: "space-between",
    paddingHorizontal: 20, paddingVertical: 5,
    borderTopWidth: 1, borderBottomWidth: 1, borderColor: BORDER,
  },
  navBtn:    { padding: 4 },
  navArrow:  { color: ORANGE, fontSize: 26, fontWeight: "300" },
  monthLabel:{ color: WHITE, fontSize: 16, fontWeight: "700", letterSpacing: 1 },

  dayHeaders: { flexDirection: "row", paddingHorizontal: 8, paddingVertical: 3 },
  dayHeader:  { flex: 1, textAlign: "center", color: MUTED, fontSize: 9, fontWeight: "700", letterSpacing: 0.5 },

  grid: {
    flexDirection: "row", flexWrap: "wrap", paddingHorizontal: 8,
    borderBottomWidth: 1, borderColor: BORDER, paddingBottom: 0,
  },
  // aspectRatio: 1 = square cells
cell: { 
  width: "14.28%", 
  height: 38,             // Remove aspectRatio and set a fixed height
  alignItems: "center", 
  justifyContent: "center", 
  borderRadius: 6 
},
  cellSelected:    { backgroundColor: ORANGE },
  cellToday:       { backgroundColor: BLUE_SOFT, borderWidth: 1, borderColor: BLUE },
  cellText:        { color: WHITE, fontSize: 16, fontWeight: "600" },
  cellTextSelected:{ color: WHITE, fontWeight: "900" },
  cellTextToday:   { color: "#93C5FD" },
  dot:             { width: 3, height: 3, borderRadius: 2, backgroundColor: ORANGE, marginTop: 1 },
  dotSelected:     { backgroundColor: WHITE },

  bottomSection: { flex: 1 },
  bottomContent: { paddingHorizontal: 16, paddingTop: 0, paddingBottom: 30 },

  summaryHeader: { flexDirection: "row", alignItems: "center", paddingVertical: 10 },
  summaryDate:   { color: WHITE, fontSize: 14, fontWeight: "700" },
  summaryCount:  { color: MUTED, fontSize: 11, marginTop: 2 },
  summaryActions:{ flexDirection: "row", alignItems: "center", gap: 8 },
  deleteBtn: {
    backgroundColor: "#1a0a0a", borderRadius: 8,
    borderWidth: 1, borderColor: "#4a1a1a",
    paddingHorizontal: 10, paddingVertical: 7,
  },
  deleteBtnText: { fontSize: 15 },
  logBtn:    { backgroundColor: BLUE, borderRadius: 8, paddingHorizontal: 14, paddingVertical: 8 },
  logBtnText:{ color: WHITE, fontSize: 13, fontWeight: "700" },

  empty:       { alignItems: "center", paddingTop: 16, paddingBottom: 16 },
  emptyIcon:   { fontSize: 30 },
  emptyText:   { color: WHITE, fontSize: 14, fontWeight: "700", marginTop: 8, textAlign: "center" },
  emptySubtext:{ color: MUTED, fontSize: 12, marginTop: 4, textAlign: "center" },

  exerciseRow: {
    flexDirection: "row", justifyContent: "space-between", alignItems: "center",
    backgroundColor: CARD, borderRadius: 10, padding: 12, marginBottom: 6,
    borderWidth: 1, borderColor: BORDER,
  },
  exerciseRowName:{ color: WHITE, fontSize: 13, fontWeight: "700", flex: 1 },
  exerciseRowSets:{ color: MUTED, fontSize: 12 },
});
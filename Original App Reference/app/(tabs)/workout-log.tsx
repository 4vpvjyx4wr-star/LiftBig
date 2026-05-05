// app/(tabs)/workout-log.tsx
import AsyncStorage from "@react-native-async-storage/async-storage";
import { FlashList } from "@shopify/flash-list";
import * as Haptics from "expo-haptics";
import { useLocalSearchParams, useRouter } from "expo-router";
import React, { useCallback, useEffect, useRef, useState } from "react";
import {
  Alert,
  KeyboardAvoidingView,
  Modal,
  Platform,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { seedDefaultPlans } from "../../utils/defaultPlans";
import { getSuggestedWeight } from "../../utils/progressiveOverload";

// --- Types ---
type SetLog = { id: string; reps: string; weight: string; checked?: boolean };
type Exercise = {
  id: string;
  name: string;
  sets: SetLog[];
  isCircuit?: boolean;
  targetReps?: string;
  targetWeight?: string;
};
type WorkoutLog = { [dateKey: string]: Exercise[] };

function formatDisplayDate(dateKey: string) {
  const [y, m, d] = dateKey.split("-").map(Number);
  const months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
  return `${months[m - 1]} ${d}, ${y}`;
}

// ─── Rest Timer ──────────────────────────────────────────────────────────────
const TIMER_OPTIONS = [30, 60, 90, 120];

const RestTimer = React.memo(() => {
  const [duration, setDuration] = useState(60);
  const [remaining, setRemaining] = useState(60);
  const [running, setRunning] = useState(false);
  const [pickerVisible, setPickerVisible] = useState(false);
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);

  useEffect(() => {
    if (running) {
      intervalRef.current = setInterval(() => {
        setRemaining((prev) => {
          if (prev <= 1) {
            clearInterval(intervalRef.current!);
            setRunning(false);
            Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
            setTimeout(() => Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success), 350);
            setTimeout(() => Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success), 700);
            return 0;
          }
          return prev - 1;
        });
      }, 1000);
    } else {
      if (intervalRef.current) clearInterval(intervalRef.current);
    }
    return () => { if (intervalRef.current) clearInterval(intervalRef.current); };
  }, [running]);

  const handlePress = () => {
    if (remaining === 0) { setRemaining(duration); setRunning(true); return; }
    setRunning((r) => !r);
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
  };

  const selectDuration = (d: number) => {
    setDuration(d); setRemaining(d); setRunning(false); setPickerVisible(false);
  };

  const mins = Math.floor(remaining / 60);
  const secs = String(remaining % 60).padStart(2, "0");
  const isFinished = remaining === 0;
  const isPartial = remaining < duration && remaining > 0;

  return (
    <>
      <TouchableOpacity
        style={[t.bubble, running && t.bubbleActive, isFinished && t.bubbleDone]}
        onPress={handlePress}
        onLongPress={() => { setRunning(false); setPickerVisible(true); }}
      >
        <Text style={t.timeText}>{mins}:{secs}</Text>
        <Text style={t.statusText}>
          {isFinished ? "✓ Done" : running ? "⏸ Tap" : isPartial ? "▶ Resume" : "Hold=set"}
        </Text>
      </TouchableOpacity>

      <Modal visible={pickerVisible} transparent animationType="fade" onRequestClose={() => setPickerVisible(false)}>
        <TouchableOpacity style={t.pickerOverlay} activeOpacity={1} onPress={() => setPickerVisible(false)}>
          <View style={t.pickerSheet}>
            <Text style={t.pickerTitle}>Rest Timer</Text>
            <Text style={t.pickerSub}>Long-press timer button to reopen</Text>
            {TIMER_OPTIONS.map((d) => (
              <TouchableOpacity
                key={d}
                style={[t.pickerRow, duration === d && t.pickerRowActive]}
                onPress={() => selectDuration(d)}
              >
                <Text style={[t.pickerRowText, duration === d && t.pickerRowTextActive]}>
                  {d < 60 ? `${d} seconds` : `${d / 60} minute${d > 60 ? "s" : ""}`}
                </Text>
                {duration === d && <Text style={t.pickerCheck}>✓</Text>}
              </TouchableOpacity>
            ))}
          </View>
        </TouchableOpacity>
      </Modal>
    </>
  );
});

// ─── Circuit Set Row ──────────────────────────────────────────────────────────
const CircuitSetRow = React.memo(({
  set, index, onToggle,
}: { set: SetLog; index: number; onToggle: () => void }) => (
  <TouchableOpacity style={cs.row} onPress={onToggle} activeOpacity={0.7}>
    <View style={[cs.checkbox, set.checked && cs.checkboxDone]}>
      {set.checked && <Text style={cs.checkmark}>✓</Text>}
    </View>
    <Text style={cs.setLabel}>Set {index + 1}</Text>
    <Text style={cs.setDetail}>{set.reps || "AMRAP"} reps @ {set.weight || "20"} lbs</Text>
  </TouchableOpacity>
), (prev, next) =>
  prev.set.checked === next.set.checked &&
  prev.set.reps === next.set.reps &&
  prev.index === next.index
);

// ─── Normal Set Row ───────────────────────────────────────────────────────────
const SetRow = React.memo(({
  set, index, targetReps, onUpdate, onDelete,
}: {
  set: SetLog;
  index: number;
  targetReps?: string;
  onUpdate: (field: "reps" | "weight", value: string) => void;
  onDelete: () => void;
}) => (
  <View style={s.setRow}>
    <View style={s.setLabelCol}>
      <Text style={s.setLabelNum}>Set {index + 1}</Text>
      {targetReps && <Text style={s.setLabelTarget}>{targetReps}</Text>}
    </View>
    <TextInput
      style={s.setInput}
      placeholder="Reps"
      placeholderTextColor={MUTED}
      keyboardType="numeric"
      value={set.reps}
      onChangeText={(v) => onUpdate("reps", v)}
      onEndEditing={() => {
        if (set.reps) Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
      }}
    />
    <TextInput
      style={s.setInput}
      placeholder="lbs"
      placeholderTextColor={MUTED}
      keyboardType="numeric"
      value={set.weight}
      onChangeText={(v) => onUpdate("weight", v)}
    />
    <TouchableOpacity onPress={onDelete} style={s.deleteSetBtn}>
      <Text style={s.deleteSetText}>✕</Text>
    </TouchableOpacity>
  </View>
), (prev, next) =>
  prev.set.reps === next.set.reps &&
  prev.set.weight === next.set.weight &&
  prev.index === next.index &&
  prev.targetReps === next.targetReps
);

// ─── Exercise Card ────────────────────────────────────────────────────────────
const ExerciseCard = React.memo(({
  exercise, onAddSet, onUpdateSet, onToggleCircuitSet, onDeleteSet, onDeleteExercise,
}: {
  exercise: Exercise;
  onAddSet: () => void;
  onUpdateSet: (setId: string, field: "reps" | "weight", value: string) => void;
  onToggleCircuitSet: (setId: string) => void;
  onDeleteSet: (setId: string) => void;
  onDeleteExercise: () => void;
}) => {
  const [suggestion, setSuggestion] = useState<{ suggestedWeight: number; reason: string } | null>(null);

  useEffect(() => {
    if (exercise.isCircuit || !exercise.targetReps) return;
    const base = parseFloat(exercise.sets[0]?.weight || exercise.targetWeight || "0");
    getSuggestedWeight(exercise.name, exercise.targetReps, base).then(setSuggestion);
  }, [exercise.name, exercise.targetReps]);

  const completedSets = exercise.sets.filter((s) =>
    exercise.isCircuit ? s.checked : (s.reps !== "" && s.weight !== "")
  ).length;
  const allDone = completedSets === exercise.sets.length && exercise.sets.length > 0;

  return (
    <View style={[s.card, allDone && s.cardDone]}>
      <View style={s.cardHeader}>
        <View style={{ flex: 1 }}>
          <Text style={s.exerciseName}>{exercise.name}</Text>
          {exercise.targetReps && !exercise.isCircuit && (
            <Text style={s.exerciseTarget}>
              Goal: {exercise.sets.length} × {exercise.targetReps}
              {exercise.targetWeight ? ` @ ${exercise.targetWeight} lbs` : ""}
            </Text>
          )}
        </View>
        <View style={{ alignItems: "flex-end", gap: 4 }}>
          <Text style={[s.progressBadge, allDone && s.progressBadgeDone]}>
            {allDone ? "✓ Complete" : `${completedSets}/${exercise.sets.length} sets`}
          </Text>
          <TouchableOpacity onPress={onDeleteExercise}>
            <Text style={s.deleteExerciseText}>Remove</Text>
          </TouchableOpacity>
        </View>
      </View>

      {suggestion && !exercise.isCircuit && suggestion.reason !== "No history yet" && (
        <View style={s.suggestionBox}>
          <Text style={s.suggestionWeight}>📈 Suggested: {suggestion.suggestedWeight} lbs</Text>
          <Text style={s.suggestionReason}>{suggestion.reason}</Text>
        </View>
      )}

      {exercise.isCircuit ? (
        exercise.sets.map((set, index) => (
          <CircuitSetRow
            key={set.id}
            set={set}
            index={index}
            onToggle={() => {
              onToggleCircuitSet(set.id);
              if (!set.checked) Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
            }}
          />
        ))
      ) : (
        <>
          <View style={s.setHeaderRow}>
            <Text style={[s.setHeaderLabel, { width: 64 }]}> </Text>
            <Text style={s.setHeaderLabel}>Reps</Text>
            <Text style={s.setHeaderLabel}>Weight</Text>
            <Text style={[s.setHeaderLabel, { width: 36 }]}> </Text>
          </View>
          {exercise.sets.map((set, index) => (
            <SetRow
              key={set.id}
              set={set}
              index={index}
              targetReps={exercise.targetReps}
              onUpdate={(field, value) => onUpdateSet(set.id, field, value)}
              onDelete={() => onDeleteSet(set.id)}
            />
          ))}
          <TouchableOpacity style={s.addSetBtn} onPress={onAddSet}>
            <Text style={s.addSetText}>+ Add Set</Text>
          </TouchableOpacity>
        </>
      )}
    </View>
  );
});

// ─── Wrapper — fixes Rules of Hooks (useCallback cannot be called in renderItem) ───
const ExerciseCardWrapper = React.memo(({
  item,
  addSet,
  updateSet,
  toggleCircuitSet,
  deleteSet,
  deleteExercise,
}: {
  item: Exercise;
  addSet: (id: string) => void;
  updateSet: (id: string, setId: string, field: "reps" | "weight", value: string) => void;
  toggleCircuitSet: (id: string, setId: string) => void;
  deleteSet: (id: string, setId: string) => void;
  deleteExercise: (id: string) => void;
}) => {
  // ✅ Hooks are now inside a proper component function
  const onAddSet = useCallback(() => addSet(item.id), [item.id, addSet]);
  const onUpdateSet = useCallback((setId: string, field: "reps" | "weight", value: string) =>
    updateSet(item.id, setId, field, value), [item.id, updateSet]);
  const onToggleCircuitSet = useCallback((setId: string) =>
    toggleCircuitSet(item.id, setId), [item.id, toggleCircuitSet]);
  const onDeleteSet = useCallback((setId: string) =>
    deleteSet(item.id, setId), [item.id, deleteSet]);
  const onDeleteExercise = useCallback(() =>
    deleteExercise(item.id), [item.id, deleteExercise]);

  return (
    <ExerciseCard
      exercise={item}
      onAddSet={onAddSet}
      onUpdateSet={onUpdateSet}
      onToggleCircuitSet={onToggleCircuitSet}
      onDeleteSet={onDeleteSet}
      onDeleteExercise={onDeleteExercise}
    />
  );
});

// ─── Main Screen ──────────────────────────────────────────────────────────────
export default function WorkoutLogScreen() {
  const { date } = useLocalSearchParams<{ date?: string }>();
  const router = useRouter();

  const today = new Date();
  const dateKey = date ??
    `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2,"0")}-${String(today.getDate()).padStart(2,"0")}`;

  const [exercises, setExercises] = useState<Exercise[]>([]);
  const [inputName, setInputName] = useState("");
  const [saved, setSaved] = useState(false);
  const inputRef = useRef<TextInput>(null);

  useEffect(() => {
    seedDefaultPlans();
    AsyncStorage.getItem("liftbig_workouts").then((raw) => {
      if (raw) {
        const all: WorkoutLog = JSON.parse(raw);
        if (all[dateKey]) setExercises(all[dateKey]);
      }
    });
  }, [dateKey]);

  useEffect(() => {
    if (exercises.length === 0) return;
    AsyncStorage.getItem("liftbig_workouts").then((raw) => {
      const all: WorkoutLog = raw ? JSON.parse(raw) : {};
      all[dateKey] = exercises;
      AsyncStorage.setItem("liftbig_workouts", JSON.stringify(all));
      setSaved(true);
      setTimeout(() => setSaved(false), 1500);
    });
  }, [exercises]);

  const addExercise = useCallback(() => {
    const trimmed = inputName.trim();
    if (!trimmed) { Alert.alert("Name required", "Please enter an exercise name."); return; }
    setExercises((prev) => [
      ...prev,
      { id: Date.now().toString(), name: trimmed, sets: [{ id: Date.now() + "-s1", reps: "", weight: "" }] },
    ]);
    setInputName("");
    inputRef.current?.blur();
  }, [inputName]);

  const addSet = useCallback((exerciseId: string) => {
    setExercises((prev) => prev.map((ex) =>
      ex.id === exerciseId
        ? { ...ex, sets: [...ex.sets, { id: Date.now().toString(), reps: "", weight: "" }] }
        : ex
    ));
  }, []);

  const updateSet = useCallback((exerciseId: string, setId: string, field: "reps" | "weight", value: string) => {
    setExercises((prev) => prev.map((ex) => {
      if (ex.id !== exerciseId) return ex;
      return { ...ex, sets: ex.sets.map((s) => s.id === setId ? { ...s, [field]: value } : s) };
    }));
  }, []);

  const toggleCircuitSet = useCallback((exerciseId: string, setId: string) => {
    setExercises((prev) => prev.map((ex) => {
      if (ex.id !== exerciseId) return ex;
      return { ...ex, sets: ex.sets.map((s) => s.id === setId ? { ...s, checked: !s.checked } : s) };
    }));
  }, []);

  const deleteSet = useCallback((exerciseId: string, setId: string) => {
    setExercises((prev) => prev.map((ex) =>
      ex.id !== exerciseId ? ex : { ...ex, sets: ex.sets.filter((s) => s.id !== setId) }
    ));
  }, []);

  const deleteExercise = useCallback((exerciseId: string) => {
    setExercises((prev) => prev.filter((ex) => ex.id !== exerciseId));
  }, []);

  const handleFinish = () => {
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    const total = exercises.reduce((acc, ex) => acc + ex.sets.length, 0);
    Alert.alert(
      "Workout Saved! 💪",
      `${exercises.length} exercise(s), ${total} sets logged for ${formatDisplayDate(dateKey)}.`,
      [{ text: "Back to Calendar", onPress: () => router.push("/") }, { text: "Keep Logging" }]
    );
  };

  return (
    <SafeAreaView style={s.safe} edges={["top"]}>
      <KeyboardAvoidingView style={s.flex} behavior={Platform.OS === "ios" ? "padding" : "height"}>

        {/* Header */}
        <View style={s.header}>
          <View>
            <Text style={s.appName}>LIFTBIG</Text>
            <Text style={s.dateLabel}>{formatDisplayDate(dateKey)}</Text>
          </View>
          <View style={s.headerRight}>
            {saved && (
              <View style={s.savedBadge}>
                <Text style={s.savedText}>✓ Saved</Text>
              </View>
            )}
            <RestTimer />
          </View>
        </View>

        {/* Exercise List — renderItem now uses ExerciseCardWrapper (no hook violations) */}
        <FlashList
          data={exercises}
          keyExtractor={(item) => item.id}
          contentContainerStyle={{ padding: 16, paddingBottom: 16 }}
          keyboardShouldPersistTaps="handled"
          ListEmptyComponent={
            <View style={s.emptyState}>
              <Text style={s.emptyIcon}>🏋️</Text>
              <Text style={s.emptyText}>No exercises yet.</Text>
              <Text style={s.emptySubtext}>Add one below or assign a plan from the Home tab.</Text>
            </View>
          }
          renderItem={({ item }) => (
            <ExerciseCardWrapper
              item={item}
              addSet={addSet}
              updateSet={updateSet}
              toggleCircuitSet={toggleCircuitSet}
              deleteSet={deleteSet}
              deleteExercise={deleteExercise}
            />
          )}
        />

        {/* Input Bar */}
        <View style={s.inputBar}>
          <TextInput
            ref={inputRef}
            style={s.exerciseInput}
            placeholder="Add exercise manually..."
            placeholderTextColor={MUTED}
            value={inputName}
            onChangeText={setInputName}
            onSubmitEditing={addExercise}
            returnKeyType="done"
          />
          <TouchableOpacity style={s.addBtn} onPress={addExercise}>
            <Text style={s.addBtnText}>Add</Text>
          </TouchableOpacity>
        </View>

        {exercises.length > 0 && (
          <TouchableOpacity style={s.finishBtn} onPress={handleFinish}>
            <Text style={s.finishBtnText}>Finish Workout</Text>
          </TouchableOpacity>
        )}
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

// --- Palette ---
const BG = "#0A0F1E";
const CARD = "#111827";
const BORDER = "#1E2A45";
const ORANGE = "#F4501E";
const BLUE = "#1D4ED8";
const WHITE = "#F0F4FF";
const MUTED = "#4A5A7A";

const t = StyleSheet.create({
  bubble: {
    backgroundColor: "#1E2A45", borderRadius: 16, paddingHorizontal: 20,
    paddingVertical: 12, alignItems: "center", borderWidth: 1.5,
    borderColor: BORDER, minWidth: 130,
  },
  bubbleActive: { backgroundColor: "#163020", borderColor: "#16A34A" },
  bubbleDone:   { backgroundColor: "#2a1008", borderColor: ORANGE },
  // Font size doubled from 15 → 30
  timeText:   { color: WHITE, fontSize: 30, fontWeight: "800", letterSpacing: 2 },
  statusText: { color: MUTED, fontSize: 10, fontWeight: "700", marginTop: 2 },
  pickerOverlay: { flex: 1, backgroundColor: "rgba(0,0,0,0.65)", justifyContent: "center", alignItems: "center" },
  pickerSheet: {
    backgroundColor: "#0D1526", borderRadius: 16, padding: 20,
    width: 280, borderWidth: 1, borderColor: BORDER,
  },
  pickerTitle:       { color: WHITE, fontSize: 18, fontWeight: "800", marginBottom: 4, textAlign: "center" },
  pickerSub:         { color: MUTED, fontSize: 11, textAlign: "center", marginBottom: 14 },
  pickerRow:         { paddingVertical: 13, paddingHorizontal: 12, borderRadius: 10, flexDirection: "row", justifyContent: "space-between", alignItems: "center" },
  pickerRowActive:   { backgroundColor: "#1E2A45" },
  pickerRowText:     { color: MUTED, fontSize: 15 },
  pickerRowTextActive:{ color: WHITE, fontWeight: "700" },
  pickerCheck:       { color: ORANGE, fontSize: 16, fontWeight: "800" },
});

const cs = StyleSheet.create({
  row: { flexDirection: "row", alignItems: "center", paddingVertical: 9, gap: 12 },
  checkbox: { width: 26, height: 26, borderRadius: 6, borderWidth: 2, borderColor: BORDER, alignItems: "center", justifyContent: "center" },
  checkboxDone: { backgroundColor: ORANGE, borderColor: ORANGE },
  checkmark: { color: WHITE, fontSize: 14, fontWeight: "800" },
  setLabel: { color: MUTED, fontSize: 12, width: 44 },
  setDetail: { color: WHITE, fontSize: 13, flex: 1 },
});

const s = StyleSheet.create({
  safe: { flex: 1, backgroundColor: BG },
  flex: { flex: 1 },

  header: {
    flexDirection: "row", justifyContent: "space-between", alignItems: "center",
    paddingHorizontal: 20, paddingTop: 14, paddingBottom: 12,
    borderBottomWidth: 1, borderBottomColor: BORDER,
  },
  headerRight: { flexDirection: "row", alignItems: "center", gap: 10 },
  appName: { fontSize: 36, fontWeight: "900", color: ORANGE, letterSpacing: 4 },
  dateLabel: { fontSize: 12, color: MUTED, marginTop: 2, letterSpacing: 0.5 },
  savedBadge: {
    backgroundColor: "#14532D", borderRadius: 8,
    paddingHorizontal: 10, paddingVertical: 4,
    borderWidth: 1, borderColor: "#16A34A",
  },
  savedText: { color: "#4ADE80", fontSize: 11, fontWeight: "700" },

  emptyState: { alignItems: "center", marginTop: 60 },
  emptyIcon: { fontSize: 44 },
  emptyText: { color: WHITE, fontSize: 18, fontWeight: "700", marginTop: 12 },
  emptySubtext: { color: MUTED, fontSize: 13, marginTop: 4, textAlign: "center", paddingHorizontal: 20 },

  card: {
    backgroundColor: CARD, borderRadius: 12,
    padding: 14, marginBottom: 14,
    borderWidth: 1, borderColor: BORDER,
  },
  cardDone: { borderColor: "#16A34A" },
  cardHeader: { flexDirection: "row", justifyContent: "space-between", marginBottom: 8 },
  exerciseName: { color: WHITE, fontSize: 16, fontWeight: "700", flexShrink: 1 },
  exerciseTarget: { color: MUTED, fontSize: 11, marginTop: 2 },
  progressBadge: { color: MUTED, fontSize: 11, fontWeight: "700" },
  progressBadgeDone: { color: "#4ADE80" },
  deleteExerciseText: { color: "#E55", fontSize: 12, fontWeight: "600" },

  suggestionBox: {
    backgroundColor: "#0D2010", borderRadius: 8,
    borderWidth: 1, borderColor: "#16A34A",
    padding: 8, marginBottom: 10,
  },
  suggestionWeight: { color: "#4ADE80", fontSize: 13, fontWeight: "700" },
  suggestionReason: { color: "#86EFAC", fontSize: 11, marginTop: 2 },

  setHeaderRow: { flexDirection: "row", alignItems: "center", marginBottom: 4 },
  setHeaderLabel: { flex: 1, color: MUTED, fontSize: 10, textAlign: "center" },

  setRow: { flexDirection: "row", alignItems: "center", marginBottom: 8, gap: 8 },
  setLabelCol: { width: 64, alignItems: "center" },
  setLabelNum: { color: MUTED, fontSize: 11, fontWeight: "600" },
  setLabelTarget: { color: ORANGE, fontSize: 9, marginTop: 1 },
  setInput: {
    flex: 1, backgroundColor: "#0D1526", borderRadius: 8,
    borderWidth: 1, borderColor: BORDER, color: WHITE,
    paddingHorizontal: 10, paddingVertical: 7, fontSize: 15, textAlign: "center",
  },
  deleteSetBtn: { padding: 6, width: 30, alignItems: "center" },
  deleteSetText: { color: MUTED, fontSize: 14 },
  addSetBtn: { marginTop: 4, alignSelf: "flex-start" },
  addSetText: { color: ORANGE, fontSize: 14, fontWeight: "600" },

  inputBar: {
    flexDirection: "row", padding: 12, gap: 10,
    borderTopWidth: 1, borderTopColor: BORDER, backgroundColor: BG,
  },
  exerciseInput: {
    flex: 1, backgroundColor: CARD, borderRadius: 10,
    borderWidth: 1, borderColor: BORDER, color: WHITE,
    paddingHorizontal: 14, paddingVertical: 10, fontSize: 15,
  },
  addBtn: { backgroundColor: BLUE, borderRadius: 10, paddingHorizontal: 18, justifyContent: "center" },
  addBtnText: { color: WHITE, fontWeight: "700", fontSize: 15 },

  finishBtn: {
    backgroundColor: ORANGE, margin: 12, borderRadius: 12,
    paddingVertical: 14, alignItems: "center",
  },
  finishBtnText: { color: WHITE, fontSize: 17, fontWeight: "800", letterSpacing: 1 },
});
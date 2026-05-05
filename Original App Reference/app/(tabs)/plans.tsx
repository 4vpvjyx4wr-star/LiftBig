// app/plans.tsx
import AsyncStorage from "@react-native-async-storage/async-storage";
import { useFocusEffect } from "expo-router";
import React, { useCallback, useState } from "react";
import {
  Alert,
  Animated,
  FlatList,
  KeyboardAvoidingView,
  Modal,
  Platform,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from "react-native";
import { SafeAreaView } from 'react-native-safe-area-context';
import { useTabSwipe } from "../../utils/useTabSwipe";


// --- Types ---
type TemplateSet = { targetReps: string; targetWeight: string };
type TemplateExercise = { id: string; name: string; sets: TemplateSet[] };
type WorkoutTemplate = { id: string; name: string; exercises: TemplateExercise[] };

const STORAGE_KEY = "liftbig_templates";

// --- Helpers ---
function blankExercise(): TemplateExercise {
  return {
    id: Date.now().toString() + Math.random(),
    name: "",
    sets: [{ targetReps: "", targetWeight: "" }],
  };
}

// --- Exercise Editor inside modal ---
const ExerciseEditor = ({
  exercise,
  index,
  onChange,
  onDelete,
}: {
  exercise: TemplateExercise;
  index: number;
  onChange: (updated: TemplateExercise) => void;
  onDelete: () => void;
}) => {
  const updateSet = (i: number, field: keyof TemplateSet, value: string) => {
    const sets = exercise.sets.map((s, idx) =>
      idx === i ? { ...s, [field]: value } : s
    );
    onChange({ ...exercise, sets });
  };

  const addSet = () =>
    onChange({ ...exercise, sets: [...exercise.sets, { targetReps: "", targetWeight: "" }] });

  const removeSet = (i: number) =>
    onChange({ ...exercise, sets: exercise.sets.filter((_, idx) => idx !== i) });

  return (
    <View style={es.card}>
      <View style={es.cardHeader}>
        <Text style={es.exNumber}>Exercise {index + 1}</Text>
        <TouchableOpacity onPress={onDelete}>
          <Text style={es.removeText}>Remove</Text>
        </TouchableOpacity>
      </View>
      <TextInput
        style={es.nameInput}
        placeholder="Exercise name (e.g. Bench Press)"
        placeholderTextColor={MUTED}
        value={exercise.name}
        onChangeText={(v) => onChange({ ...exercise, name: v })}
      />
      <View style={es.setHeaderRow}>
        <Text style={[es.setHeaderLabel, { flex: 2 }]}>Set</Text>
        <Text style={es.setHeaderLabel}>Target Reps</Text>
        <Text style={es.setHeaderLabel}>Target lbs</Text>
        <Text style={{ width: 28 }} />
      </View>
      {exercise.sets.map((set, i) => (
        <View key={i} style={es.setRow}>
          <Text style={[es.setNum, { flex: 2 }]}>{i + 1}</Text>
          <TextInput
            style={es.setInput}
            placeholder="8"
            placeholderTextColor={MUTED}
            keyboardType="numeric"
            value={set.targetReps}
            onChangeText={(v) => updateSet(i, "targetReps", v)}
          />
          <TextInput
            style={es.setInput}
            placeholder="135"
            placeholderTextColor={MUTED}
            keyboardType="numeric"
            value={set.targetWeight}
            onChangeText={(v) => updateSet(i, "targetWeight", v)}
          />
          <TouchableOpacity onPress={() => removeSet(i)} style={{ width: 28, alignItems: "center" }}>
            <Text style={{ color: MUTED, fontSize: 14 }}>✕</Text>
          </TouchableOpacity>
        </View>
      ))}
      <TouchableOpacity onPress={addSet} style={es.addSetBtn}>
        <Text style={es.addSetText}>+ Add Set</Text>
      </TouchableOpacity>
    </View>
  );
};

// --- Main Screen ---
export default function PlansScreen() {
  const [templates, setTemplates] = useState<WorkoutTemplate[]>([]);
  const [modalVisible, setModalVisible] = useState(false);
  const [editingTemplate, setEditingTemplate] = useState<WorkoutTemplate | null>(null);
  const [planName, setPlanName] = useState("");
  const [exercises, setExercises] = useState<TemplateExercise[]>([blankExercise()]);
  const { translateX: tabX, panHandlers: tabPan } = useTabSwipe(2);
  useFocusEffect(
    useCallback(() => {
      AsyncStorage.getItem(STORAGE_KEY).then((raw) => {
        if (raw) setTemplates(JSON.parse(raw));
      });
    }, [])
  );

  const saveTemplates = async (updated: WorkoutTemplate[]) => {
    setTemplates(updated);
    await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(updated));
  };

  const openNewPlan = () => {
    setEditingTemplate(null);
    setPlanName("");
    setExercises([blankExercise()]);
    setModalVisible(true);
  };

  const openEditPlan = (t: WorkoutTemplate) => {
    setEditingTemplate(t);
    setPlanName(t.name);
    setExercises(t.exercises);
    setModalVisible(true);
  };

  const savePlan = async () => {
    if (!planName.trim()) {
      Alert.alert("Name required", "Please give your plan a name.");
      return;
    }
const namedExercises = exercises.filter((e) => e.name && e.name.trim().length > 0);
if (namedExercises.length === 0) {
      Alert.alert("No exercises", "Please add at least one exercise with a name (e.g., 'Bench Press').");
      return;
    }

    let updated: WorkoutTemplate[];
    if (editingTemplate) {
      updated = templates.map((t) =>
        t.id === editingTemplate.id
          ? { ...editingTemplate, name: planName.trim(), exercises: namedExercises }
          : t
      );
    } else {
      const newTemplate: WorkoutTemplate = {
        id: Date.now().toString(),
        name: planName.trim(),
        exercises: namedExercises,
      };
      updated = [...templates, newTemplate];
    }
    
    await saveTemplates(updated);
    setModalVisible(false);
  };

  const deletePlan = (id: string) => {
    Alert.alert("Delete Plan", "Are you sure?", [
      { text: "Cancel", style: "cancel" },
      {
        text: "Delete",
        style: "destructive",
        onPress: () => saveTemplates(templates.filter((t) => t.id !== id)),
      },
    ]);
  };

  const updateExercise = (index: number, updated: TemplateExercise) => {
    setExercises((prev) => prev.map((e, i) => (i === index ? updated : e)));
  };

  return (
    <SafeAreaView style={s.safe} edges={['top']}>
    {/* This Animated.View now contains the text so they move together */}
    <Animated.View 
      style={[s.header, { transform: [{ translateX: tabX }] }]} 
      {...tabPan}
    >
      <Text style={s.appName}>LIFTBIG</Text>
      <Text style={s.appTagline}>Training Journal</Text>
    </Animated.View>

      <FlatList
        data={templates}
        keyExtractor={(item) => item.id}
        contentContainerStyle={s.listContent}
        ListEmptyComponent={
          <View style={s.empty}>
            <Text style={s.emptyIcon}>📋</Text>
            <Text style={s.emptyText}>No plans yet.</Text>
            <Text style={s.emptySubtext}>Create a template to reuse across your calendar.</Text>
          </View>
        }
        renderItem={({ item }) => (
          <View style={s.planCard}>
            <View style={s.planCardTop}>
              <Text style={s.planName}>{item.name}</Text>
              <View style={s.planActions}>
                <TouchableOpacity onPress={() => openEditPlan(item)} style={s.editBtn}>
                  <Text style={s.editBtnText}>Edit</Text>
                </TouchableOpacity>
                <TouchableOpacity onPress={() => deletePlan(item.id)} style={s.deleteBtn}>
                  <Text style={s.deleteBtnText}>Delete</Text>
                </TouchableOpacity>
              </View>
            </View>
            <Text style={s.planMeta}>
              {item.exercises.length} exercise{item.exercises.length !== 1 ? "s" : ""}
            </Text>
            {item.exercises.map((ex, i) => (
              <View key={ex.id} style={s.exerciseRow}>
                <Text style={s.exerciseRowDot}>·</Text>
                <Text style={s.exerciseRowName}>{ex.name}</Text>
                <Text style={s.exerciseRowDetail}>
                  {ex.sets.length} × {ex.sets[0]?.targetReps || "?"}
                  {ex.sets[0]?.targetWeight ? ` @ ${ex.sets[0].targetWeight}lbs` : ""}
                </Text>
              </View>
            ))}
          </View>
        )}
      />

      <TouchableOpacity style={s.fab} onPress={openNewPlan}>
        <Text style={s.fabText}>+ New Plan</Text>
      </TouchableOpacity>

      {/* Create / Edit Modal */}
      <Modal
        visible={modalVisible}
        animationType="slide"
        transparent
        onRequestClose={() => setModalVisible(false)}
      >
        <View style={s.modalOverlay}>
          <KeyboardAvoidingView
            behavior={Platform.OS === "ios" ? "padding" : "height"}
            style={s.modalSheet}
          >
            <View style={s.sheetHandle} />
            <View style={s.modalHeader}>
              <Text style={s.modalTitle}>
                {editingTemplate ? "Edit Plan" : "New Plan"}
              </Text>
              <TouchableOpacity onPress={() => setModalVisible(false)}>
                <Text style={s.modalClose}>✕</Text>
              </TouchableOpacity>
            </View>

            <TextInput
              style={s.planNameInput}
              placeholder="Plan name (e.g. Push Day A)"
              placeholderTextColor={MUTED}
              value={planName}
              onChangeText={setPlanName}
            />

            <ScrollView
              style={s.exerciseScroll}
              showsVerticalScrollIndicator={false}
              keyboardShouldPersistTaps="handled"
            >
              {exercises.map((ex, i) => (
                <ExerciseEditor
                  key={ex.id}
                  exercise={ex}
                  index={i}
                  onChange={(updated) => updateExercise(i, updated)}
                  onDelete={() =>
                    setExercises((prev) => prev.filter((_, idx) => idx !== i))
                  }
                />
              ))}
              <TouchableOpacity
                style={s.addExerciseBtn}
                onPress={() => setExercises((prev) => [...prev, blankExercise()])}
              >
                <Text style={s.addExerciseBtnText}>+ Add Exercise</Text>
              </TouchableOpacity>
              <View style={{ height: 20 }} />
            </ScrollView>

            <TouchableOpacity style={s.saveBtn} onPress={savePlan}>
              <Text style={s.saveBtnText}>Save Plan</Text>
            </TouchableOpacity>
          </KeyboardAvoidingView>
        </View>
      </Modal>
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

// ExerciseEditor styles
const es = StyleSheet.create({
  header: {
    paddingHorizontal: 16,
    paddingVertical: 12,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
  },
  logo: {
    color: ORANGE,
    fontSize: 22,
    fontWeight: "900",
    letterSpacing: 2,
  },
  card: {
    backgroundColor: "#0D1526",
    borderRadius: 10,
    padding: 12,
    marginBottom: 12,
    borderWidth: 1,
    borderColor: BORDER,
  },
  cardHeader: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    marginBottom: 8,
  },
  exNumber: { color: ORANGE, fontSize: 13, fontWeight: "700" },
  removeText: { color: "#E55", fontSize: 12, fontWeight: "600" },
  nameInput: {
    backgroundColor: CARD,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: BORDER,
    color: WHITE,
    paddingHorizontal: 12,
    paddingVertical: 8,
    fontSize: 14,
    marginBottom: 10,
  },
  setHeaderRow: { flexDirection: "row", marginBottom: 4 },
  setHeaderLabel: { flex: 1, color: MUTED, fontSize: 10, textAlign: "center" },
  setRow: { flexDirection: "row", alignItems: "center", marginBottom: 6, gap: 6 },
  setNum: { color: MUTED, fontSize: 13, textAlign: "center" },
  setInput: {
    flex: 1,
    backgroundColor: CARD,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: BORDER,
    color: WHITE,
    paddingHorizontal: 8,
    paddingVertical: 6,
    fontSize: 14,
    textAlign: "center",
  },
  addSetBtn: { marginTop: 4 },
  addSetText: { color: ORANGE, fontSize: 13, fontWeight: "600" },
});

const s = StyleSheet.create({
  safe: { flex: 1, backgroundColor: BG },

  header: { paddingHorizontal: 20, paddingTop: 2, paddingBottom: 6 },
  appName: { fontSize: 36, fontWeight: "900", color: ORANGE, letterSpacing: 4 },
  appTagline: { fontSize: 10, color: MUTED, letterSpacing: 2, marginTop: 0 },

  listContent: { padding: 16, paddingBottom: 100 },

  empty: { alignItems: "center", marginTop: 80 },
  emptyIcon: { fontSize: 44 },
  emptyText: { color: WHITE, fontSize: 18, fontWeight: "700", marginTop: 12 },
  emptySubtext: { color: MUTED, fontSize: 13, marginTop: 4, textAlign: "center", paddingHorizontal: 30 },

  planCard: {
    backgroundColor: CARD,
    borderRadius: 12,
    padding: 16,
    marginBottom: 14,
    borderWidth: 1,
    borderColor: BORDER,
  },
  planCardTop: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    marginBottom: 4,
  },
  planName: { color: WHITE, fontSize: 17, fontWeight: "800", flexShrink: 1 },
  planActions: { flexDirection: "row", gap: 12 },
  editBtn: { paddingHorizontal: 10, paddingVertical: 4, backgroundColor: BLUE, borderRadius: 6 },
  editBtnText: { color: WHITE, fontSize: 12, fontWeight: "700" },
  deleteBtn: { paddingHorizontal: 10, paddingVertical: 4 },
  deleteBtnText: { color: "#E55", fontSize: 12, fontWeight: "600" },
  planMeta: { color: MUTED, fontSize: 12, marginBottom: 10 },
  exerciseRow: { flexDirection: "row", alignItems: "center", gap: 6, marginBottom: 4 },
  exerciseRowDot: { color: ORANGE, fontSize: 18, lineHeight: 20 },
  exerciseRowName: { color: WHITE, fontSize: 13, fontWeight: "600", flex: 1 },
  exerciseRowDetail: { color: MUTED, fontSize: 12 },

  fab: {
    position: "absolute",
    bottom: 24,
    left: 20,
    right: 20,
    backgroundColor: ORANGE,
    borderRadius: 14,
    paddingVertical: 16,
    alignItems: "center",
  },
  fabText: { color: WHITE, fontSize: 16, fontWeight: "800", letterSpacing: 0.5 },

 modalOverlay: {
    flex: 1,
    backgroundColor: "rgba(0,0,0,0.8)",
    justifyContent: "center", // This moves it to the MIDDLE of the screen
    padding: 20,
  },
  modalSheet: {
    backgroundColor: "#0A0F1E",
    borderRadius: 20,          // Rounded on all sides
    padding: 20,
    height: "80%",            // Give it 80% of the screen height
    borderWidth: 1,
    borderColor: "#1E2A45",
  },
  sheetHandle: {
    width: 36, height: 4, backgroundColor: BORDER,
    borderRadius: 2, alignSelf: "center", marginBottom: 14,
  },
  modalHeader: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    marginBottom: 14,
  },
  modalTitle: { color: WHITE, fontSize: 20, fontWeight: "800" },
  modalClose: { color: MUTED, fontSize: 20, padding: 4 },

  planNameInput: {
    backgroundColor: CARD,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: BORDER,
    color: WHITE,
    paddingHorizontal: 14,
    paddingVertical: 11,
    fontSize: 16,
    fontWeight: "700",
    marginBottom: 14,
  },
  exerciseScroll: { flex: 1 },

  addExerciseBtn: {
    borderWidth: 1,
    borderColor: ORANGE,
    borderRadius: 10,
    borderStyle: "dashed",
    paddingVertical: 12,
    alignItems: "center",
    marginTop: 4,
  },
  addExerciseBtnText: { color: ORANGE, fontSize: 14, fontWeight: "700" },

  saveBtn: {
    backgroundColor: ORANGE,
    borderRadius: 12,
    paddingVertical: 14,
    alignItems: "center",
    marginTop: 12,
  },
  saveBtnText: { color: WHITE, fontSize: 16, fontWeight: "800", letterSpacing: 0.5 },
});
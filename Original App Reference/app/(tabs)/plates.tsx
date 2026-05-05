// app/plates.tsx
import * as Haptics from "expo-haptics";
import React, { useState } from "react";
import {
  Animated,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { useTabSwipe } from "../../utils/useTabSwipe";
// --- Plate logic ---
const PLATE_SIZES = [45, 35, 25, 10, 5, 2.5];
const PLATE_COLORS: { [key: number]: string } = {
  45: "#E63946",   // red
  35: "#457B9D",   // blue
  25: "#F4A261",   // yellow-orange
  10: "#2A9D8F",   // green
  5:  "#E9C46A",   // yellow
  2.5:"#A8DADC",   // light blue
};

function calculatePlates(targetWeight: number, barWeight: number): { plates: number[]; remainder: number } {
  const weightPerSide = (targetWeight - barWeight) / 2;
  if (weightPerSide < 0) return { plates: [], remainder: targetWeight };

  const plates: number[] = [];
  let remaining = weightPerSide;

  for (const plate of PLATE_SIZES) {
    while (remaining >= plate - 0.001) {
      plates.push(plate);
      remaining -= plate;
    }
  }

  return { plates, remainder: Math.round(remaining * 10) / 10 };
}

// --- Visual bar component ---
const BarVisual = ({ plates }: { plates: number[] }) => {
  const maxPlates = 8;
  const displayed = plates.slice(0, maxPlates);
  const overflow = plates.length - maxPlates;

  return (
    <View style={bv.container}>
      {/* Left collar */}
      <View style={bv.collar} />
      {/* Plates - left side (reversed so largest is closest to center) */}
      <View style={bv.platesLeft}>
        {[...displayed].reverse().map((p, i) => (
          <View key={i} style={[bv.plate, { backgroundColor: PLATE_COLORS[p], height: 24 + p * 0.6 }]}>
            <Text style={bv.plateText}>{p}</Text>
          </View>
        ))}
      </View>
      {/* Bar center */}
      <View style={bv.barCenter}>
        <Text style={bv.barText}>BAR</Text>
      </View>
      {/* Plates - right side */}
      <View style={bv.platesRight}>
        {displayed.map((p, i) => (
          <View key={i} style={[bv.plate, { backgroundColor: PLATE_COLORS[p], height: 24 + p * 0.6 }]}>
            <Text style={bv.plateText}>{p}</Text>
          </View>
        ))}
      </View>
      {/* Right collar */}
      <View style={bv.collar} />
      {overflow > 0 && (
        <Text style={bv.overflowText}>+{overflow} more</Text>
      )}
    </View>
  );
};

// --- Plate count summary ---
const PlateSummary = ({ plates }: { plates: number[] }) => {
  const counts: { [key: number]: number } = {};
  plates.forEach((p) => { counts[p] = (counts[p] || 0) + 1; });

  return (
    <View style={s.summary}>
      <Text style={s.summaryTitle}>Each Side</Text>
      {PLATE_SIZES.filter((p) => counts[p]).map((p) => (
        <View key={p} style={s.plateRow}>
          <View style={[s.plateSwatch, { backgroundColor: PLATE_COLORS[p] }]}>
            <Text style={s.plateSwatchText}>{p}</Text>
          </View>
          <Text style={s.plateName}>{p} lb plate</Text>
          <Text style={s.plateCount}>× {counts[p]}</Text>
          <Text style={s.plateSub}>({p * counts[p]} lbs)</Text>
        </View>
      ))}
    </View>
  );
};

// --- Main Screen ---
export default function PlatesScreen() {
  const [targetInput, setTargetInput] = useState("");
  const [barWeight, setBarWeight] = useState(45);
  const [result, setResult] = useState<{ plates: number[]; remainder: number } | null>(null);
  const { translateX: tabX, panHandlers: tabPan } = useTabSwipe(3);

  const calculate = () => {
    const target = parseFloat(targetInput);
    if (isNaN(target) || target <= 0) return;
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    setResult(calculatePlates(target, barWeight));
  };

  const totalWeight = result
    ? barWeight + result.plates.reduce((a, b) => a + b, 0) * 2
    : 0;

  const isExact = result && result.remainder < 0.01;

  return (
    <SafeAreaView style={s.safe} edges={["top"]}>
      <ScrollView contentContainerStyle={{ paddingBottom: 40 }} keyboardShouldPersistTaps="handled">
        {/* Header */}
        <Animated.View style={[s.header, { transform: [{ translateX: tabX }] }]} {...tabPan}>
  <Text style={s.appName}>LIFTBIG</Text>
  <Text style={s.appTagline}>Plate Calculator</Text>
</Animated.View>

        {/* Input Card */}
        <View style={s.inputCard}>
          <Text style={s.inputLabel}>Target Weight (lbs)</Text>
          <TextInput
            style={s.weightInput}
            placeholder="e.g. 225"
            placeholderTextColor={MUTED}
            keyboardType="numeric"
            value={targetInput}
            onChangeText={setTargetInput}
            onSubmitEditing={calculate}
            returnKeyType="done"
          />

          <Text style={s.inputLabel}>Bar Weight</Text>
          <View style={s.barToggle}>
            {[45, 35].map((w) => (
              <TouchableOpacity
                key={w}
                style={[s.barOption, barWeight === w && s.barOptionActive]}
                onPress={() => { setBarWeight(w); setResult(null); }}
              >
                <Text style={[s.barOptionText, barWeight === w && s.barOptionTextActive]}>
                  {w} lb{"\n"}{w === 45 ? "Standard" : "Women's"}
                </Text>
              </TouchableOpacity>
            ))}
          </View>

          <TouchableOpacity style={s.calcBtn} onPress={calculate}>
            <Text style={s.calcBtnText}>Calculate Plates</Text>
          </TouchableOpacity>
        </View>

        {/* Result */}
        {result && (
          <>
            {/* Total weight badge */}
            <View style={s.resultBadge}>
              <Text style={s.resultTotal}>{totalWeight} lbs</Text>
              {!isExact && (
                <Text style={s.resultNote}>
                  ⚠ Closest achievable — {result.remainder} lbs cannot be loaded
                </Text>
              )}
              {isExact && <Text style={s.resultExact}>✓ Exact weight achievable</Text>}
            </View>

            {/* Visual bar */}
            {result.plates.length > 0 ? (
              <>
                <BarVisual plates={result.plates} />
                <PlateSummary plates={result.plates} />
              </>
            ) : (
              <View style={s.justBar}>
                <Text style={s.justBarText}>Just the bar — no plates needed</Text>
              </View>
            )}
          </>
        )}

        {/* Quick reference */}
        <View style={s.quickRef}>
          <Text style={s.quickRefTitle}>Quick Reference</Text>
          {[
            { label: "1 plate", weight: 135 },
            { label: "2 plates", weight: 185 },
            { label: "3 plates", weight: 225 },
            { label: "4 plates", weight: 315 },
            { label: "5 plates", weight: 405 },
          ].map(({ label, weight }) => (
            <TouchableOpacity
              key={weight}
              style={s.quickRow}
              onPress={() => {
                setTargetInput(String(weight));
                setResult(calculatePlates(weight, barWeight));
                Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
              }}
            >
              <Text style={s.quickLabel}>{label}</Text>
              <Text style={s.quickWeight}>{weight} lbs</Text>
              <Text style={s.quickArrow}>›</Text>
            </TouchableOpacity>
          ))}
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

// Bar visual styles
const bv = StyleSheet.create({
  container: {
    flexDirection: "row", alignItems: "center", justifyContent: "center",
    marginHorizontal: 16, marginBottom: 16, paddingVertical: 16,
    backgroundColor: "#111827", borderRadius: 12,
    borderWidth: 1, borderColor: "#1E2A45", flexWrap: "wrap",
  },
  collar: { width: 10, height: 40, backgroundColor: "#9CA3AF", borderRadius: 3 },
  barCenter: {
    width: 60, height: 14, backgroundColor: "#6B7280",
    borderRadius: 4, alignItems: "center", justifyContent: "center",
  },
  barText: { color: "#D1D5DB", fontSize: 8, fontWeight: "700" },
  platesLeft: { flexDirection: "row", alignItems: "center" },
  platesRight: { flexDirection: "row", alignItems: "center" },
  plate: {
    width: 14, borderRadius: 3, alignItems: "center",
    justifyContent: "center", marginHorizontal: 1,
  },
  plateText: { color: "#fff", fontSize: 7, fontWeight: "900", transform: [{ rotate: "90deg" }] },
  overflowText: { color: "#4A5A7A", fontSize: 10, width: "100%", textAlign: "center", marginTop: 4 },
});

// --- Palette ---
const BG = "#0A0F1E";
const CARD = "#111827";
const BORDER = "#1E2A45";
const ORANGE = "#F4501E";
const BLUE = "#1D4ED8";
const WHITE = "#F0F4FF";
const MUTED = "#4A5A7A";

const s = StyleSheet.create({
  safe: { flex: 1, backgroundColor: BG },
  header: { paddingHorizontal: 20, paddingTop: 2, paddingBottom: 6 },
  appName: { fontSize: 36, fontWeight: "900", color: ORANGE, letterSpacing: 4 },
  appTagline: { fontSize: 10, color: MUTED, letterSpacing: 2, marginTop: 0 },

  inputCard: {
    margin: 16, backgroundColor: CARD, borderRadius: 14,
    padding: 18, borderWidth: 1, borderColor: BORDER,
  },
  inputLabel: { color: MUTED, fontSize: 12, fontWeight: "700", letterSpacing: 1, marginBottom: 8, marginTop: 12 },
  weightInput: {
    backgroundColor: "#0D1526", borderRadius: 10, borderWidth: 1, borderColor: BORDER,
    color: WHITE, paddingHorizontal: 16, paddingVertical: 14,
    fontSize: 28, fontWeight: "800", textAlign: "center",
  },
  barToggle: { flexDirection: "row", gap: 10 },
  barOption: {
    flex: 1, paddingVertical: 12, borderRadius: 10, alignItems: "center",
    backgroundColor: "#0D1526", borderWidth: 1, borderColor: BORDER,
  },
  barOptionActive: { backgroundColor: BLUE, borderColor: BLUE },
  barOptionText: { color: MUTED, fontSize: 13, fontWeight: "700", textAlign: "center" },
  barOptionTextActive: { color: WHITE },

  calcBtn: {
    backgroundColor: ORANGE, borderRadius: 12, paddingVertical: 14,
    alignItems: "center", marginTop: 16,
  },
  calcBtnText: { color: WHITE, fontSize: 16, fontWeight: "800", letterSpacing: 0.5 },

  resultBadge: {
    marginHorizontal: 16, marginBottom: 12,
    backgroundColor: "#0D2010", borderRadius: 12,
    borderWidth: 1, borderColor: "#16A34A",
    padding: 16, alignItems: "center",
  },
  resultTotal: { color: "#4ADE80", fontSize: 36, fontWeight: "900" },
  resultNote: { color: "#F59E0B", fontSize: 12, marginTop: 4, textAlign: "center" },
  resultExact: { color: "#4ADE80", fontSize: 12, marginTop: 4 },

  summary: {
    marginHorizontal: 16, marginBottom: 16,
    backgroundColor: CARD, borderRadius: 12,
    padding: 16, borderWidth: 1, borderColor: BORDER,
  },
  summaryTitle: { color: WHITE, fontSize: 15, fontWeight: "800", marginBottom: 12 },
  plateRow: { flexDirection: "row", alignItems: "center", marginBottom: 10, gap: 10 },
  plateSwatch: { width: 36, height: 36, borderRadius: 6, alignItems: "center", justifyContent: "center" },
  plateSwatchText: { color: WHITE, fontSize: 11, fontWeight: "900" },
  plateName: { color: WHITE, fontSize: 14, flex: 1 },
  plateCount: { color: ORANGE, fontSize: 15, fontWeight: "800" },
  plateSub: { color: MUTED, fontSize: 12 },

  justBar: { margin: 16, padding: 20, backgroundColor: CARD, borderRadius: 12, alignItems: "center", borderWidth: 1, borderColor: BORDER },
  justBarText: { color: MUTED, fontSize: 14 },

  quickRef: {
    margin: 16, backgroundColor: CARD, borderRadius: 12,
    padding: 16, borderWidth: 1, borderColor: BORDER,
  },
  quickRefTitle: { color: MUTED, fontSize: 11, fontWeight: "700", letterSpacing: 1, marginBottom: 10 },
  quickRow: {
    flexDirection: "row", alignItems: "center", paddingVertical: 12,
    borderBottomWidth: 1, borderBottomColor: BORDER,
  },
  quickLabel: { flex: 1, color: WHITE, fontSize: 14, fontWeight: "600" },
  quickWeight: { color: MUTED, fontSize: 14, marginRight: 8 },
  quickArrow: { color: ORANGE, fontSize: 20 },
});
import { usePathname, useRouter } from "expo-router";
import { useEffect, useRef } from "react";
import { Animated, Dimensions, PanResponder } from "react-native";
import { DASHBOARD_TAB_PATHS, getTabIndexFromPath } from "./tabConfig";

const { width: W } = Dimensions.get("window");

export function useTabSwipe() {
  const router = useRouter();
  const pathname = usePathname();
  const tabIndex = getTabIndexFromPath(pathname);
  const tabIndexRef = useRef(tabIndex);
  const translateX = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    tabIndexRef.current = tabIndex;
  }, [tabIndex]);

  const panResponder = useRef(
    PanResponder.create({
      onMoveShouldSetPanResponder: (_, gs) =>
        tabIndexRef.current >= 0 &&
        Math.abs(gs.dx) > 18 &&
        Math.abs(gs.dx) > Math.abs(gs.dy) * 2.2,
      onPanResponderMove: (_, gs) => {
        const idx = tabIndexRef.current;
        const canNext = idx < DASHBOARD_TAB_PATHS.length - 1;
        const canPrev = idx > 0;
        if ((gs.dx < 0 && canNext) || (gs.dx > 0 && canPrev)) {
          translateX.setValue(gs.dx * 0.22);
        }
      },
      onPanResponderRelease: (_, gs) => {
        const idx = tabIndexRef.current;
        const THRESHOLD = W * 0.22;
        if (gs.dx < -THRESHOLD && idx < DASHBOARD_TAB_PATHS.length - 1) {
          Animated.timing(translateX, {
            toValue: -W * 0.18, duration: 90, useNativeDriver: true,
          }).start(() => {
            translateX.setValue(0);
            router.navigate(DASHBOARD_TAB_PATHS[idx + 1] as never);
          });
        } else if (gs.dx > THRESHOLD && idx > 0) {
          Animated.timing(translateX, {
            toValue: W * 0.18, duration: 90, useNativeDriver: true,
          }).start(() => {
            translateX.setValue(0);
            router.navigate(DASHBOARD_TAB_PATHS[idx - 1] as never);
          });
        } else {
          Animated.spring(translateX, {
            toValue: 0, tension: 220, friction: 22, useNativeDriver: true,
          }).start();
        }
      },
    })
  ).current;

  const swipeEnabled = tabIndex >= 0;

  return {
    translateX,
    panHandlers: swipeEnabled ? panResponder.panHandlers : {},
    tabIndex,
    swipeEnabled,
  };
}

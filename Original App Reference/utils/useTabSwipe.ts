import { useRouter } from "expo-router";
import { useRef } from "react";
import { Animated, Dimensions, PanResponder } from "react-native";

const { width: W } = Dimensions.get("window");
const TABS = ["/", "/overview", "/plans", "/plates"] as const;

export function useTabSwipe(tabIndex: number) {
  const router = useRouter();
  const translateX = useRef(new Animated.Value(0)).current;

  const panResponder = useRef(
    PanResponder.create({
      onMoveShouldSetPanResponder: (_, gs) =>
        Math.abs(gs.dx) > 18 && Math.abs(gs.dx) > Math.abs(gs.dy) * 2.2,
      onPanResponderMove: (_, gs) => {
        const canNext = tabIndex < TABS.length - 1;
        const canPrev = tabIndex > 0;
        if ((gs.dx < 0 && canNext) || (gs.dx > 0 && canPrev)) {
          translateX.setValue(gs.dx * 0.22);
        }
      },
      onPanResponderRelease: (_, gs) => {
        const THRESHOLD = W * 0.22;
        if (gs.dx < -THRESHOLD && tabIndex < TABS.length - 1) {
          Animated.timing(translateX, {
            toValue: -W * 0.18, duration: 90, useNativeDriver: true,
          }).start(() => {
            translateX.setValue(0);
            router.navigate(TABS[tabIndex + 1]);
          });
        } else if (gs.dx > THRESHOLD && tabIndex > 0) {
          Animated.timing(translateX, {
            toValue: W * 0.18, duration: 90, useNativeDriver: true,
          }).start(() => {
            translateX.setValue(0);
            router.navigate(TABS[tabIndex - 1]);
          });
        } else {
          Animated.spring(translateX, {
            toValue: 0, tension: 220, friction: 22, useNativeDriver: true,
          }).start();
        }
      },
    })
  ).current;

  return { translateX, panHandlers: panResponder.panHandlers };
}
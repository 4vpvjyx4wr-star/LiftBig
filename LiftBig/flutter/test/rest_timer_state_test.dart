import 'package:flutter_test/flutter_test.dart';
import 'package:liftbig/rest/rest_timer_state.dart';

void main() {
  test('remaining seconds follow wall-clock end time', () {
    final now = DateTime(2026, 1, 1, 12, 0, 0);
    final endAt = now.add(const Duration(seconds: 90));
    expect(
      restTimerRemainingSeconds(
        now: now,
        active: true,
        paused: false,
        fullSeconds: 90,
        endAtEpochMs: endAt.millisecondsSinceEpoch,
      ),
      90,
    );
    expect(
      restTimerRemainingSeconds(
        now: now.add(const Duration(seconds: 30)),
        active: true,
        paused: false,
        fullSeconds: 90,
        endAtEpochMs: endAt.millisecondsSinceEpoch,
      ),
      60,
    );
    expect(
      restTimerRemainingSeconds(
        now: endAt.add(const Duration(seconds: 5)),
        active: true,
        paused: false,
        fullSeconds: 90,
        endAtEpochMs: endAt.millisecondsSinceEpoch,
      ),
      0,
    );
  });

  test('paused timer does not read as expired', () {
    final now = DateTime(2026, 6, 1, 8, 0, 0);
    final pastEnd = now.subtract(const Duration(minutes: 2)).millisecondsSinceEpoch;
    expect(
      restTimerIsExpired(
        now: now,
        active: true,
        paused: true,
        fullSeconds: 60,
        pausedRemainingSeconds: 45,
        endAtEpochMs: pastEnd,
      ),
      isFalse,
    );
    expect(
      restTimerRemainingSeconds(
        now: now,
        active: true,
        paused: true,
        fullSeconds: 60,
        pausedRemainingSeconds: 45,
        endAtEpochMs: pastEnd,
      ),
      45,
    );
  });
}

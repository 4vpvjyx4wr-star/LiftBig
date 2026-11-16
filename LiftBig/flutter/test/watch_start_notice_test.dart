import 'package:flutter_test/flutter_test.dart';
import 'package:liftbig/companion/companion_bridge.dart';
import 'package:liftbig/ui/day_page.dart';

void main() {
  test('watch notice names only the watches that started', () {
    expect(
      watchStartNotice(const WatchStartOutcome(appleStarted: true)),
      'Sent to your Apple Watch. This workout stays on your iPhone.',
    );
    expect(
      watchStartNotice(const WatchStartOutcome(garminStarted: true)),
      'Sent to your Garmin. This workout stays on your iPhone.',
    );
    expect(
      watchStartNotice(
        const WatchStartOutcome(appleStarted: true, garminStarted: true),
      ),
      'Sent to your Apple Watch and Garmin. This workout stays on your iPhone.',
    );
    expect(
      watchStartNotice(const WatchStartOutcome(garminNeedsChoice: true)),
      'Pick the watch in Garmin Connect.',
    );
    expect(
      watchStartNotice(
        const WatchStartOutcome(
          appleStarted: true,
          garminNeedsChoice: true,
        ),
      ),
      'Sent to your Apple Watch. Pick the watch in Garmin Connect. This workout stays on your iPhone.',
    );
    expect(
      watchStartNotice(const WatchStartOutcome()),
      'This workout stays on your iPhone.',
    );
    expect(
      WatchStartOutcome.fromChannel({
        'appleStarted': false,
        'garminStarted': true,
        'garminNeedsChoice': false,
      }),
      predicate<WatchStartOutcome>(
        (outcome) =>
            !outcome.appleStarted &&
            outcome.garminStarted &&
            !outcome.garminNeedsChoice,
      ),
    );
    expect(WatchStartOutcome.fromChannel(null).appleStarted, isFalse);
  });
}

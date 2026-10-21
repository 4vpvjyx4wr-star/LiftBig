import 'package:flutter_test/flutter_test.dart';
import 'package:liftbig/ui/chart_axis_labels.dart';

/// Date labels are wider than "+2". "Next" is the widest predicted label.
double labelWidth(int index, {required int sessionCount}) {
  if (index < sessionCount) return chartAxisLabelWidth('10/20');
  final future = index - sessionCount;
  if (future <= 0) return chartAxisLabelWidth('Next');
  return chartAxisLabelWidth('+${future + 1}');
}

void main() {
  test('short history shows every predicted label when they fit', () {
    const sessions = 4;
    const forecast = 5;
    final indices = chartAxisLabelIndices(
      sessionCount: sessions,
      forecastCount: forecast,
      pixelsPerIndex: 64,
      labelWidth: (index) => labelWidth(index, sessionCount: sessions),
    );

    expect(indices, [0, 1, 2, 3, 4, 5, 6, 7, 8]);
  });

  test('long history keeps predicted labels from stacking', () {
    const sessions = 40;
    const forecast = 5;
    // About a phone-width chart: 40 logged sessions plus 5 predictions.
    final pixelsPerIndex = chartPixelsPerIndex(axisWidth: 300, pointCount: 45);
    final indices = chartAxisLabelIndices(
      sessionCount: sessions,
      forecastCount: forecast,
      pixelsPerIndex: pixelsPerIndex,
      labelWidth: (index) => labelWidth(index, sessionCount: sessions),
    );

    final predicted = indices.where((index) => index >= sessions).toList();
    expect(predicted, isNotEmpty);
    expect(predicted.length, lessThan(forecast));
    expect(indices.contains(sessions - 1), isTrue);

    for (var i = 1; i < indices.length; i++) {
      final previous = indices[i - 1];
      final current = indices[i];
      final needed =
          labelWidth(previous, sessionCount: sessions) / 2 +
          labelWidth(current, sessionCount: sessions) / 2 +
          chartAxisLabelGap;
      expect((current - previous) * pixelsPerIndex, greaterThanOrEqualTo(needed));
    }
  });

  test('a squeezed prediction shows no orange label rather than a pile', () {
    const sessions = 80;
    final indices = chartAxisLabelIndices(
      sessionCount: sessions,
      forecastCount: 5,
      pixelsPerIndex: 3,
      labelWidth: (index) => labelWidth(index, sessionCount: sessions),
    );

    expect(indices.where((index) => index >= sessions), isEmpty);
    expect(indices.contains(sessions - 1), isTrue);
  });
}

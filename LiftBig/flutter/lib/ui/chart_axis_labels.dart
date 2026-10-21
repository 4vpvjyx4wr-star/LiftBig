/// Gap, in pixels, kept between the edges of two x-axis labels.
const double chartAxisLabelGap = 8;

/// Width of a 10px axis label. Close enough to the default UI font that
/// labels are spaced without laying out text.
double chartAxisLabelWidth(String text) {
  if (text.isEmpty) return 0;
  return text.length * 6.2 + 2;
}

/// Pixels between consecutive session indices on the exercise chart.
///
/// Matches the chart's 0.2 padding on each side of the data range.
/// An unmeasured axis uses a typical phone plot width so the first frame
/// does not stack every predicted label.
double chartPixelsPerIndex({
  required double axisWidth,
  required int pointCount,
}) {
  if (pointCount <= 1) return axisWidth > 0 ? axisWidth : 48;
  final span = (pointCount - 1) + 0.4;
  final width = axisWidth > 0 ? axisWidth : 280;
  return width / span;
}

/// Session indices whose x-axis labels have room to sit side by side.
///
/// Logged dates keep a short stride and always include the latest session.
/// Predicted sessions would otherwise label every tick ("Next", "+2", "+3"…),
/// which lands on the same few pixels once history is long. A label is kept
/// only when its center clears the previous kept label.
List<int> chartAxisLabelIndices({
  required int sessionCount,
  required int forecastCount,
  required double pixelsPerIndex,
  required double Function(int index) labelWidth,
  double minEdgeGap = chartAxisLabelGap,
}) {
  if (sessionCount < 0 || forecastCount < 0) {
    throw ArgumentError('counts must be non-negative');
  }
  final total = sessionCount + forecastCount;
  if (total == 0) return const [];

  bool fitsAfter(int previous, int index) {
    if (pixelsPerIndex <= 0 || index <= previous) return false;
    final gap = labelWidth(previous) / 2 + labelWidth(index) / 2 + minEdgeGap;
    return (index - previous) * pixelsPerIndex >= gap;
  }

  final chosen = <int>[];

  if (sessionCount > 0) {
    final step = sessionCount <= 4 ? 1 : (sessionCount / 3).ceil();
    for (var i = 0; i < sessionCount; i++) {
      final isLast = i == sessionCount - 1;
      if (!isLast && i % step != 0) continue;
      if (!isLast) {
        if (chosen.isEmpty || fitsAfter(chosen.last, i)) chosen.add(i);
        continue;
      }
      while (chosen.isNotEmpty && !fitsAfter(chosen.last, i)) {
        chosen.removeLast();
      }
      chosen.add(i);
    }
  }

  for (var i = 0; i < forecastCount; i++) {
    final index = sessionCount + i;
    if (chosen.isEmpty || fitsAfter(chosen.last, index)) {
      chosen.add(index);
    }
  }

  return chosen;
}

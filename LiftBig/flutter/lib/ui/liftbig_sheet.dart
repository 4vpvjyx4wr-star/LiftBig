import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// Gap between the status bar or Dynamic Island and the sheet's rounded top.
const double liftBigSheetTopGap = 12;

/// Height for a sheet body that already sits under the shared grabber.
double liftBigPreferredHeight(BuildContext context, double fraction) {
  final wanted = MediaQuery.sizeOf(context).height * fraction;
  final cap = liftBigSheetMaxHeight(context) - 36;
  if (wanted < cap) return wanted;
  return cap < 160 ? 160 : cap;
}

double liftBigSheetMaxHeight(BuildContext context) {
  final media = MediaQuery.of(context);
  final available = media.size.height - media.viewPadding.top - liftBigSheetTopGap;
  if (available < 120) return media.size.height;
  return available;
}

/// Light tick for opening a sheet, changing a tab, picking a row, or a slider step.
void liftBigSelectionHaptic() {
  HapticFeedback.selectionClick();
}

/// Slightly stronger tap for save and other confirms. Rest-complete stays separate.
void liftBigConfirmHaptic() {
  HapticFeedback.mediumImpact();
}

/// Bottom sheet that stays below the status bar.
///
/// The dimmed band above the sheet is the modal barrier, so a tap there
/// dismisses. Dragging the grabber dismisses, and pulling a list down from
/// the top dismisses too.
Future<T?> showLiftBigSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  Color? backgroundColor,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  liftBigSelectionHaptic();
  final colors = context.liftBig;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Padding(
        padding: const EdgeInsets.only(top: liftBigSheetTopGap),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Align(
              alignment: Alignment.bottomCenter,
              child: _PullDownToDismiss(
                enabled: isDismissible && enableDrag,
                child: Material(
                  color: backgroundColor ?? colors.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    side: BorderSide(color: colors.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: constraints.maxHeight),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 10),
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: sheetContext.liftBig.border,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        Flexible(child: builder(sheetContext)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    },
  );
}

/// Clamped lists do not hand a downward pull to the sheet. Close after a short pull from the top.
class _PullDownToDismiss extends StatefulWidget {
  const _PullDownToDismiss({required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  State<_PullDownToDismiss> createState() => _PullDownToDismissState();
}

class _PullDownToDismissState extends State<_PullDownToDismiss> {
  double _pulled = 0;
  bool _closing = false;

  void _close() {
    if (_closing || !mounted) return;
    _closing = true;
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (!widget.enabled || notification.metrics.axis != Axis.vertical) return false;
        if (notification is OverscrollNotification &&
            notification.overscroll < 0 &&
            notification.metrics.pixels <= 0) {
          _pulled += -notification.overscroll;
          if (_pulled > 48) {
            _pulled = 0;
            WidgetsBinding.instance.addPostFrameCallback((_) => _close());
          }
        } else if (notification is ScrollEndNotification) {
          _pulled = 0;
        }
        return false;
      },
      child: widget.child,
    );
  }
}

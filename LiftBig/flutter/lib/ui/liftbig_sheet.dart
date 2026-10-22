import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// Gap between the status bar or Dynamic Island and the sheet's rounded top.
const double liftBigSheetTopGap = 8;

/// Height for a sheet body that already sits under the shared grabber.
double liftBigPreferredHeight(BuildContext context, double fraction) {
  final wanted = MediaQuery.sizeOf(context).height * fraction;
  final cap = liftBigSheetMaxHeight(context) - 36;
  if (wanted < cap) return wanted;
  return cap < 160 ? 160 : cap;
}

double liftBigSheetMaxHeight(BuildContext context) {
  final media = MediaQuery.of(context);
  final available = media.size.height - media.padding.top - liftBigSheetTopGap;
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

/// Bottom sheet that stays below the status bar, with a grabber and rounded top.
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
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final media = MediaQuery.of(sheetContext);
      final top = media.padding.top + liftBigSheetTopGap;
      return Padding(
        padding: EdgeInsets.only(top: top),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: backgroundColor ?? colors.card,
            shape: RoundedRectangleBorder(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              side: BorderSide(color: colors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: liftBigSheetMaxHeight(sheetContext)),
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
  );
}

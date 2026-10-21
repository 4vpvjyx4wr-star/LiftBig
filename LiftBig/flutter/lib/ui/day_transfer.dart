import 'package:flutter/material.dart';

import '../date_key.dart';
import '../journal/journal_repository.dart';

/// Copies [fromKey] onto a day the user picks. Returns true when rows changed.
Future<bool> copyLoggedDay(
  BuildContext context,
  JournalRepository journal,
  String fromKey,
) async {
  final target = await _pickOtherDay(context, fromKey);
  if (target == null || !context.mounted) return false;
  final copied = await journal.copyDay(fromKey, target);
  if (!context.mounted) return copied;
  _toast(
    context,
    copied
        ? 'Copied to ${formatDisplayDate(target)}.'
        : 'Nothing to copy.',
  );
  return copied;
}

/// Moves [fromKey], or swaps when the target already has exercises.
Future<bool> moveLoggedDay(
  BuildContext context,
  JournalRepository journal,
  String fromKey,
) async {
  final target = await _pickOtherDay(context, fromKey);
  if (target == null || !context.mounted) return false;
  final existing = await journal.getDay(target);
  if (!context.mounted) return false;
  final swap = existing != null && existing.exercises.isNotEmpty;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(swap ? 'Swap days?' : 'Move day?'),
        content: Text(
          swap
              ? 'Swap this workout with ${formatDisplayDate(target)}.'
              : 'Move this workout to ${formatDisplayDate(target)}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(swap ? 'Swap' : 'Move'),
          ),
        ],
      );
    },
  );
  if (confirmed != true || !context.mounted) return false;
  final action = await journal.moveDay(fromKey, target);
  if (!context.mounted) return action != null;
  if (action == null) {
    _toast(context, 'Nothing to move.');
    return false;
  }
  _toast(
    context,
    action == 'swapped'
        ? 'Swapped with ${formatDisplayDate(target)}.'
        : 'Moved to ${formatDisplayDate(target)}.',
  );
  return true;
}

Future<String?> _pickOtherDay(BuildContext context, String fromKey) async {
  final picked = await showDatePicker(
    context: context,
    initialDate: parseDateKey(fromKey),
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
  );
  if (picked == null) return null;
  final key = toDateKey(picked);
  if (key == fromKey) {
    if (context.mounted) _toast(context, 'Pick a different day.');
    return null;
  }
  return key;
}

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

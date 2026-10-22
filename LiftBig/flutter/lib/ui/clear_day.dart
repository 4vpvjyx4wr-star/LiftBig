import 'package:flutter/material.dart';

/// Confirms before a whole day is removed from the journal.
Future<bool> confirmClearDay(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Clear this day?'),
        content: const Text(
          'This removes the workout and every exercise on this day.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear day'),
          ),
        ],
      );
    },
  );
  return confirmed == true;
}

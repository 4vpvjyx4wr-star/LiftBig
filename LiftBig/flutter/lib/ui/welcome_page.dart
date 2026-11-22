import 'package:flutter/material.dart';

import '../theme.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({
    super.key,
    required this.onQuiz,
    required this.onShuffle,
    required this.onPaste,
    required this.onContinue,
  });

  final VoidCallback onQuiz;
  final VoidCallback onShuffle;
  final VoidCallback onPaste;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.liftBig.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Start with a Plan',
                style: TextStyle(
                  color: context.liftBig.foreground,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Take the quiz and LiftBig will match one of its plans to your goal. Shuffle a workout from the equipment you have. Or paste a plan you already use.',
                style: TextStyle(
                  color: context.liftBig.muted,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: onQuiz,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                child: const Text('Take the Quiz'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: onShuffle,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  foregroundColor: context.liftBig.foreground,
                  side: BorderSide(color: context.liftBig.border),
                  textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                child: const Text('Shuffle a Workout'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: onPaste,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  foregroundColor: context.liftBig.foreground,
                  side: BorderSide(color: context.liftBig.border),
                  textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                child: const Text('Paste a Plan'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: onContinue,
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

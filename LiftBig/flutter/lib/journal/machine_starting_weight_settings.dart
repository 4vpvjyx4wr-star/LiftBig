import '../utils/variable_machine.dart';
import 'app_settings.dart';
import 'journal_repository.dart';

/// Persists each machine kind's unloaded/starting weight in pounds.
class MachineStartingWeightSettings {
  MachineStartingWeightSettings({required this.journal});

  final JournalRepository journal;

  Future<double?> storedLbs(VariableMachineKind kind) {
    return journal.storedMachineStartingWeightLbs(kind);
  }

  Future<void> saveLbs(VariableMachineKind kind, double? lbs) {
    if (lbs == null || lbs <= 0 || !lbs.isFinite) {
      return journal.clearMachineStartingWeightLbs(kind);
    }
    final sanitized = sanitizeBodyWeightLbs(lbs);
    if (sanitized == null) {
      return journal.clearMachineStartingWeightLbs(kind);
    }
    return journal.setMachineStartingWeightLbs(kind, sanitized);
  }
}

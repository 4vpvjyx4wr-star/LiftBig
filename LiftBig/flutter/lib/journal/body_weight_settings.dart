import 'app_settings.dart';
import 'journal_repository.dart';
import '../health/body_weight_health.dart';

class BodyWeightSaveResult {
  const BodyWeightSaveResult({
    required this.savedLocally,
    this.healthWriteSucceeded,
  });

  final bool savedLocally;
  final bool? healthWriteSucceeded;
}

/// Persists body weight locally and optionally mirrors to Apple Health.
class BodyWeightSettingsService {
  BodyWeightSettingsService({
    required this.journal,
    BodyWeightHealthSync? health,
  }) : _health = health ?? BodyWeightHealthSync();

  final JournalRepository journal;
  final BodyWeightHealthSync _health;

  Future<double?> storedLbs() => journal.storedBodyWeightLbs();

  /// When local height is unset and Health read is allowed, import once.
  Future<double?> importHeightIfEmpty() async {
    final current = await journal.storedHeightInches();
    if (current != null) return current;
    if (!await journal.appleHealthSyncEnabled()) return null;
    if (!await _health.hasReadAccess()) return null;
    final fromHealth = await _health.readHeightInches();
    if (fromHealth == null) return null;
    await journal.setHeightInches(fromHealth);
    return fromHealth;
  }

  Future<bool?> saveHeightInches(double? inches, {required bool tryHealthWrite}) async {
    if (inches == null || inches <= 0) {
      await journal.clearHeightInches();
      return null;
    }
    final sanitized = sanitizeHeightInches(inches);
    if (sanitized == null) {
      await journal.clearHeightInches();
      return null;
    }
    await journal.setHeightInches(sanitized);
    if (!tryHealthWrite || !await journal.appleHealthSyncEnabled()) return null;
    final granted = await _health.requestAccess();
    if (!granted) return false;
    return _health.writeHeightInches(sanitized);
  }

  /// When local weight is unset and Health read is allowed, import once.
  Future<double?> importFromHealthIfEmpty() async {
    final current = await journal.storedBodyWeightLbs();
    if (current != null) return current;
    if (!await journal.appleHealthSyncEnabled()) return null;
    if (!await _health.hasReadAccess()) return null;
    final fromHealth = await _health.readBodyWeightLbs();
    if (fromHealth == null) return null;
    await journal.setBodyWeightLbs(fromHealth);
    return fromHealth;
  }

  Future<BodyWeightSaveResult> saveBodyWeightLbs(
    double? lbs, {
    required bool tryHealthWrite,
  }) async {
    if (lbs == null || lbs <= 0) {
      await journal.clearBodyWeightLbs();
      return const BodyWeightSaveResult(savedLocally: true);
    }
    final sanitized = sanitizeBodyWeightLbs(lbs);
    if (sanitized == null) {
      await journal.clearBodyWeightLbs();
      return const BodyWeightSaveResult(savedLocally: true);
    }
    await journal.setBodyWeightLbs(sanitized);
    if (!tryHealthWrite || !await journal.appleHealthSyncEnabled()) {
      return const BodyWeightSaveResult(savedLocally: true);
    }
    final granted = await _health.requestAccess();
    if (!granted) {
      return const BodyWeightSaveResult(
        savedLocally: true,
        healthWriteSucceeded: false,
      );
    }
    final wrote = await _health.writeBodyWeightLbs(sanitized);
    return BodyWeightSaveResult(
      savedLocally: true,
      healthWriteSucceeded: wrote,
    );
  }

  Future<bool> setAppleHealthEnabled(bool enabled) async {
    await journal.setAppleHealthSyncEnabled(enabled);
    if (!enabled) return true;
    return _health.requestAccess();
  }
}

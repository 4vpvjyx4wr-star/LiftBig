import 'package:flutter/services.dart';

import '../journal/journal_repository.dart';

/// Temporary tester password. Not a promo-code system.
const testerUnlockCode = 'coffee';

/// StoreKit / Play Billing status, or the local tester unlock.
class ProStatus {
  ProStatus({MethodChannel? channel, TesterUnlockStore? unlockStore})
    : _channel = channel ?? const MethodChannel('liftbig/pro'),
      _unlockStore = unlockStore ?? const _EmptyTesterUnlockStore();

  final MethodChannel _channel;
  final TesterUnlockStore _unlockStore;
  var _storeActive = false;
  var _testerUnlock = false;

  /// True when the store entitlement is active or the tester unlock is stored.
  bool get isPro => _storeActive || _testerUnlock;

  bool get storeActive => _storeActive;

  Future<bool> refresh() async {
    _testerUnlock = await _unlockStore.read();
    _storeActive = await _read('getStatus');
    return isPro;
  }

  /// Persists the tester unlock only when [code] is exactly `coffee`, then
  /// always asks the store to restore. A missing plugin does not throw.
  Future<ProRestoreResult> restorePurchases(String code) async {
    final matched = code == testerUnlockCode;
    if (matched) {
      await _unlockStore.writeUnlocked();
      _testerUnlock = true;
    } else {
      _testerUnlock = await _unlockStore.read();
    }
    _storeActive = await _read('restore');
    return ProRestoreResult(
      storeActive: _storeActive,
      codeMatched: matched,
      isPro: isPro,
    );
  }

  Future<bool> _read(String method) async {
    try {
      final result = await _channel.invokeMethod<Object?>(method);
      if (result is Map) return result['active'] == true;
      return false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}

class ProRestoreResult {
  const ProRestoreResult({
    required this.storeActive,
    required this.codeMatched,
    required this.isPro,
  });

  final bool storeActive;
  final bool codeMatched;
  final bool isPro;
}

/// Local `pro_tester_unlock` flag. Writing only turns it on.
abstract class TesterUnlockStore {
  Future<bool> read();
  Future<void> writeUnlocked();
}

class JournalTesterUnlockStore implements TesterUnlockStore {
  JournalTesterUnlockStore(this._journal);

  final JournalRepository _journal;

  @override
  Future<bool> read() => _journal.proTesterUnlockEnabled();

  @override
  Future<void> writeUnlocked() => _journal.setProTesterUnlock();
}

class _EmptyTesterUnlockStore implements TesterUnlockStore {
  const _EmptyTesterUnlockStore();

  @override
  Future<bool> read() async => false;

  @override
  Future<void> writeUnlocked() async {}
}

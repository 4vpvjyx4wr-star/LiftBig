import 'package:flutter/services.dart';

import '../journal/journal_repository.dart';

/// Temporary tester password. Not a promo-code system.
const testerUnlockCode = 'coffee';

const proMonthlyProductId = 'liftbig.pro.monthly';
const proYearlyProductId = 'liftbig.pro.yearly';

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

  /// StoreKit / Play Billing purchase. A missing plugin does not throw.
  Future<ProPurchaseResult> purchase(String productId) async {
    final result = await _invoke('purchase', {'productId': productId});
    if (result == null) {
      return const ProPurchaseResult(
        active: false,
        message: 'Purchases are not available in this build.',
      );
    }
    if (result['active'] == true) _storeActive = true;
    final message = result['message'];
    return ProPurchaseResult(
      active: isPro,
      message: message is String && message.isNotEmpty ? message : null,
    );
  }

  Future<List<ProProduct>> loadProducts() async {
    final result = await _invoke('loadProducts');
    final raw = result?['products'];
    if (raw is! List) return const [];
    final products = <ProProduct>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final id = item['id'];
      if (id is! String || id.isEmpty) continue;
      final price = item['displayPrice'];
      products.add(
        ProProduct(
          id: id,
          displayPrice: price is String ? price : '',
        ),
      );
    }
    return products;
  }

  Future<bool> _read(String method) async {
    final result = await _invoke(method);
    return result?['active'] == true;
  }

  Future<Map<Object?, Object?>?> _invoke(
    String method, [
    Object? arguments,
  ]) async {
    try {
      final result = await _channel.invokeMethod<Object?>(method, arguments);
      if (result is Map) return Map<Object?, Object?>.from(result);
      return null;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}

class ProProduct {
  const ProProduct({required this.id, required this.displayPrice});

  final String id;
  final String displayPrice;
}

class ProPurchaseResult {
  const ProPurchaseResult({required this.active, this.message});

  final bool active;
  final String? message;
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

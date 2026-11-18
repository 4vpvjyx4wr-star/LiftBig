import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftbig/pro/pro_status.dart';

void main() {
  test('coffee unlocks Pro and a different string does not', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final store = _MemoryUnlockStore();
    final status = ProStatus(
      channel: const MethodChannel('liftbig/pro'),
      unlockStore: store,
    );

    final wrong = await status.restorePurchases('Coffee');
    expect(wrong.codeMatched, isFalse);
    expect(wrong.storeActive, isFalse);
    expect(wrong.isPro, isFalse);
    expect(store.unlocked, isFalse);
    expect(status.isPro, isFalse);

    final right = await status.restorePurchases('coffee');
    expect(right.codeMatched, isTrue);
    expect(right.storeActive, isFalse);
    expect(right.isPro, isTrue);
    expect(store.unlocked, isTrue);
    expect(status.isPro, isTrue);

    final reloaded = ProStatus(
      channel: const MethodChannel('liftbig/pro'),
      unlockStore: store,
    );
    expect(await reloaded.refresh(), isTrue);
    expect(reloaded.isPro, isTrue);
  });

  test('purchase and product prices come back from the store channel', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('liftbig/pro/test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'purchase') {
        return {'active': true};
      }
      if (call.method == 'loadProducts') {
        return {
          'products': [
            {'id': proYearlyProductId, 'displayPrice': r'$29.99'},
          ],
        };
      }
      return {'active': false};
    });
    final status = ProStatus(
      channel: channel,
      unlockStore: _MemoryUnlockStore(),
    );

    final products = await status.loadProducts();
    expect(products, hasLength(1));
    expect(products.single.id, proYearlyProductId);
    expect(products.single.displayPrice, r'$29.99');

    final bought = await status.purchase(proYearlyProductId);
    expect(bought.active, isTrue);
    expect(bought.message, isNull);
    expect(status.isPro, isTrue);
  });
}

class _MemoryUnlockStore implements TesterUnlockStore {
  var unlocked = false;

  @override
  Future<bool> read() async => unlocked;

  @override
  Future<void> writeUnlocked() async {
    unlocked = true;
  }
}

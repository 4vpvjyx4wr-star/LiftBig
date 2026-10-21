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

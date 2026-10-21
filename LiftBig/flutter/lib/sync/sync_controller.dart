import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../journal/journal_repository.dart';
import 'day_remote.dart';
import 'firestore_day_remote.dart';
import 'journal_sync.dart';

/// Sign-in and the settings switch. Sync does not run until both are on.
class SyncController extends ChangeNotifier {
  SyncController({
    required this.journal,
    required this.firebaseReady,
    this.remoteForUid,
  });

  final JournalRepository journal;
  final bool firebaseReady;
  final DayRemote Function(String uid)? remoteForUid;

  bool syncEnabled = false;
  bool busy = false;
  String? email;
  String? status;
  StreamSubscription<User?>? _authSub;

  bool get signedIn => email != null;

  Future<void> load() async {
    syncEnabled = await journal.isSyncEnabled();
    if (!firebaseReady) {
      status =
          'Sync is off. The journal stays on this phone until Firebase config is added.';
      notifyListeners();
      return;
    }
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) async {
      email = user?.email ?? user?.uid;
      notifyListeners();
      if (user != null && syncEnabled) {
        await syncNow();
      }
    });
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    syncEnabled = value;
    await journal.setSyncEnabled(value);
    if (!value) {
      status = 'Sync is off. Nothing is uploaded.';
      notifyListeners();
      return;
    }
    notifyListeners();
    if (signedIn) await syncNow();
  }

  Future<String?> signIn({
    required String emailAddress,
    required String password,
    required bool createAccount,
  }) async {
    if (!firebaseReady) {
      return 'Firebase is not configured. Add the files listed on this screen, then set kFirebaseEnabled to true.';
    }
    try {
      final auth = FirebaseAuth.instance;
      final trimmed = emailAddress.trim();
      if (createAccount) {
        await auth.createUserWithEmailAndPassword(
          email: trimmed,
          password: password,
        );
      } else {
        await auth.signInWithEmailAndPassword(
          email: trimmed,
          password: password,
        );
      }
      return null;
    } on FirebaseAuthException catch (error) {
      return error.message ?? error.code;
    }
  }

  Future<void> signOut() async {
    if (!firebaseReady) return;
    await FirebaseAuth.instance.signOut();
    email = null;
    status = 'Signed out. The journal is still on this phone.';
    notifyListeners();
  }

  Future<void> syncNow() async {
    if (!firebaseReady) {
      status = 'Sync did nothing. Firebase config is not in the app yet.';
      notifyListeners();
      return;
    }
    if (!syncEnabled) {
      status = 'Sync is off.';
      notifyListeners();
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      status = 'Sign in before syncing. Until then the journal stays on this phone.';
      notifyListeners();
      return;
    }
    busy = true;
    notifyListeners();
    try {
      final remote = remoteForUid?.call(user.uid) ?? FirestoreDayRemote(user.uid);
      final result = await JournalSync(journal: journal, remote: remote).sync();
      status =
          'Synced. ${result.uploaded} uploaded, ${result.downloaded} downloaded.';
    } catch (error) {
      status = 'Sync failed: $error';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    unawaited(_authSub?.cancel());
    super.dispose();
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/app_user.dart';
import '../../../data/repositories/auth_repository.dart';

/// Exposed as a provider so tests can override it with a fake in one line.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Everything downstream derives from this one stream, which is why signing
/// out empties every screen with no manual teardown.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// The profile for the signed-in account, or null when signed out.
final appUserProvider = StreamProvider<AppUser?>((ref) {
  final auth = ref.watch(authStateProvider).value;
  if (auth == null) return Stream.value(null);
  return ref.watch(authRepositoryProvider).watchProfile(auth.uid);
});

/// Decides what the UI draws. Firestore rules decide what is actually
/// allowed.
final isStaffProvider = Provider<bool>((ref) {
  return ref.watch(appUserProvider).value?.isStaff ?? false;
});

final currentUidProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).value?.uid;
});

/// Whether Firebase considers the current session's email verified.
final isEmailVerifiedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).value?.emailVerified ?? false;
});

/// Keeps try/catch and loading booleans out of the screens, which watch
/// `isLoading` and `hasError` on this instead.
class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.signIn(email: email, password: password),
    );
    return !state.hasError;
  }

  Future<bool> signUp({
    required String fullName,
    required String email,
    required String password,
    String? programme,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.signUp(
        fullName: fullName,
        email: email,
        password: password,
        programme: programme,
      ),
    );
    return !state.hasError;
  }

  Future<bool> resendVerification() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repository.sendEmailVerification);
    return !state.hasError;
  }

  /// On success the auth stream re-emits and the gate opens.
  Future<bool> checkVerification() async {
    final verified = await _repository.refreshEmailVerified();
    if (verified) {
      ref.invalidate(authStateProvider);
    }
    return verified;
  }

  Future<bool> sendPasswordReset(String email) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.sendPasswordReset(email));
    return !state.hasError;
  }

  Future<bool> updateProfile({
    required String uid,
    required String fullName,
    String? programme,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.updateProfile(
        uid: uid,
        fullName: fullName,
        programme: programme,
      ),
    );
    return !state.hasError;
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repository.signOut);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/constants/campus.dart';
import '../models/app_user.dart';

/// Firebase's own messages are developer-facing, so they are translated
/// once here rather than leaked into widgets.
class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

/// The only place that touches Firebase Auth and the `users` collection.
class AuthRepository {
  AuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// A stream rather than a one-off read, so a role change made in the
  /// Firebase console reaches the running app without a restart.
  Stream<AppUser?> watchProfile(String uid) {
    return _users.doc(uid).snapshots().map(
          (doc) => doc.exists ? AppUser.fromDoc(doc) : null,
        );
  }

  /// Derived from the email domain, which keeps provisioning zero-touch for
  /// a pilot. Production would invite staff explicitly and store the role in
  /// a custom auth claim.
  UserRole _roleForEmail(String email) {
    return email.toLowerCase().endsWith('@${Campus.staffEmailDomain}')
        ? UserRole.staff
        : UserRole.student;
  }

  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
    String? programme,
  }) async {
    final normalisedEmail = email.trim().toLowerCase();
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: normalisedEmail,
        password: password,
      );
      final uid = credential.user!.uid;

      final profile = AppUser(
        uid: uid,
        fullName: fullName.trim(),
        email: normalisedEmail,
        role: _roleForEmail(normalisedEmail),
        createdAt: DateTime.now(),
        programme: programme?.trim().isEmpty ?? true ? null : programme!.trim(),
      );

      await _users.doc(uid).set(profile.toCreateMap());
      await credential.user!.updateDisplayName(fullName.trim());
      await credential.user!.sendEmailVerification();
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_describe(error));
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_describe(error));
    }
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_describe(error));
    }
  }

  /// Firebase caches this flag locally, so the server has to be asked again
  /// after the student taps the link in their inbox.
    Future<bool> refreshEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    final refreshed = _auth.currentUser;
    if (refreshed != null && refreshed.emailVerified) {
      // Force a new ID token so Firestore rules see email_verified: true.
      await refreshed.getIdToken(true);
      return true;
    }
    return false;
  }
  
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_describe(error));
    }
  }

  Future<void> updateProfile({
    required String uid,
    required String fullName,
    String? programme,
  }) async {
    await _users.doc(uid).update({
      'fullName': fullName.trim(),
      'programme': programme?.trim(),
    });
    await _auth.currentUser?.updateDisplayName(fullName.trim());
  }

  String _describe(FirebaseAuthException error) {
    return switch (error.code) {
      'email-already-in-use' =>
        'That email already has an account. Sign in instead.',
      'invalid-email' => 'That email address is not valid.',
      'weak-password' => 'Choose a stronger password.',
      'user-disabled' => 'This account has been disabled. Contact the ICT desk.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' =>
        'Email or password is incorrect.',
      'too-many-requests' =>
        'Too many attempts. Wait a minute and try again.',
      'network-request-failed' =>
        'No connection. Check your network and try again.',
      _ => 'Something went wrong. Try again.',
    };
  }
}

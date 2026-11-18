import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth})
    : _firebaseAuthOverride = firebaseAuth;

  final FirebaseAuth? _firebaseAuthOverride;
  Future<void> Function(String? userId)? onUserChanged;

  FirebaseAuth get _firebaseAuth =>
      _firebaseAuthOverride ?? FirebaseAuth.instance;

  Stream<User?> get authStateChanges => Firebase.apps.isEmpty
      ? Stream<User?>.value(null)
      : _firebaseAuth.authStateChanges();
  User? get currentUser =>
      Firebase.apps.isEmpty ? null : _firebaseAuth.currentUser;

  Future<void> createAccount({
    required String username,
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.updateDisplayName(username.trim());
    await credential.user?.reload();
    await onUserChanged?.call(credential.user?.uid);
  }

  Future<void> signIn({required String email, required String password}) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await onUserChanged?.call(credential.user?.uid);
  }

  Future<void> sendPasswordResetEmail(String email) =>
      _firebaseAuth.sendPasswordResetEmail(email: email.trim());

  Future<void> signOut() async {
    try {
      await onUserChanged?.call(null);
    } finally {
      await _firebaseAuth.signOut();
    }
  }
}

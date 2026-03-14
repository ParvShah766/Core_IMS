import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';

class AuthResult {
  const AuthResult({required this.success, this.message});

  final bool success;
  final String? message;
}

class OtpRequestResult {
  const OtpRequestResult({required this.success, this.message});

  final bool success;
  final String? message;
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ================= SIGN UP =================
  Future<AuthResult> signUp({
    required String email,
    required String password,
  }) async {
    final String normalizedEmail = email.trim().toLowerCase();

    try {
      final UserCredential credential = await _auth
          .createUserWithEmailAndPassword(
            email: normalizedEmail,
            password: password,
          );

      final User? user = credential.user;

      if (user == null) {
        return const AuthResult(
          success: false,
          message: 'Account created but user session missing.',
        );
      }

      // Firestore write runs in background (so signup never blocks UI)
      _upsertUserProfile(
        uid: user.uid,
        email: normalizedEmail,
        fullName: _defaultNameFromEmail(normalizedEmail),
        role: UserRole.inventoryManager,
      ).catchError((_) {});

      return const AuthResult(success: true);
    } on FirebaseAuthException catch (error) {
      return AuthResult(success: false, message: _authErrorMessage(error));
    } catch (_) {
      return const AuthResult(
        success: false,
        message: 'Unable to create account. Try again.',
      );
    }
  }

  // ================= LOGIN =================
  Future<AppUser?> login({
    required String email,
    required String password,
  }) async {
    final String normalizedEmail = email.trim().toLowerCase();

    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final User? user = credential.user;

      if (user == null) {
        return null;
      }

      return _buildUserFromFirebase(user);
    } on FirebaseAuthException {
      return null;
    } catch (_) {
      return null;
    }
  }

  // ================= CURRENT USER =================
  Future<AppUser?> currentSignedInUser() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    return _buildUserFromFirebase(user);
  }

  // ================= SIGN OUT =================
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ================= PASSWORD RESET =================
  Future<OtpRequestResult> sendPasswordResetOtp({required String email}) async {
    final String normalizedEmail = email.trim().toLowerCase();

    try {
      await _auth.sendPasswordResetEmail(email: normalizedEmail);

      return const OtpRequestResult(
        success: true,
        message: 'Password reset email sent. Check your inbox.',
      );
    } on FirebaseAuthException catch (error) {
      return OtpRequestResult(
        success: false,
        message: _authErrorMessage(error),
      );
    } catch (_) {
      return const OtpRequestResult(
        success: false,
        message: 'Unable to send password reset email right now.',
      );
    }
  }

  Future<AuthResult> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    return const AuthResult(
      success: false,
      message: 'Use the password reset link sent to your email.',
    );
  }

  // ================= FIRESTORE PROFILE =================
  Future<void> _upsertUserProfile({
    required String uid,
    required String email,
    required String fullName,
    required UserRole role,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'role': role.name,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ================= BUILD USER =================
  Future<AppUser> _buildUserFromFirebase(User user) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 8));

      final data = snapshot.data();

      final String email = (user.email ?? (data?['email'] as String?) ?? '')
          .trim()
          .toLowerCase();

      final String fullName =
          ((data?['fullName'] as String?) ?? user.displayName ?? '').trim();

      final UserRole role = _parseRole((data?['role'] as String?) ?? '');

      final String resolvedName = fullName.isEmpty
          ? _defaultNameFromEmail(email)
          : fullName;

      if (data == null) {
        try {
          await _upsertUserProfile(
            uid: user.uid,
            email: email,
            fullName: resolvedName,
            role: role,
          );
        } catch (_) {}
      }

      return AppUser(
        fullName: resolvedName,
        email: email,
        password: '__firebase__',
        role: role,
      );
    } catch (_) {
      return _fallbackUserFromAuth(user);
    }
  }

  // ================= FALLBACK USER =================
  AppUser _fallbackUserFromAuth(User user) {
    final String email = (user.email ?? '').trim().toLowerCase();
    final String fullName = (user.displayName ?? '').trim();

    return AppUser(
      fullName: fullName.isEmpty ? _defaultNameFromEmail(email) : fullName,
      email: email,
      password: '__firebase__',
      role: UserRole.inventoryManager,
    );
  }

  // ================= ERROR MESSAGES =================
  String _authErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'Email is already registered.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'network-request-failed':
        return 'Network error. Check your internet and try again.';
      default:
        return error.message ?? 'Authentication failed.';
    }
  }

  // ================= ROLE PARSER =================
  UserRole _parseRole(String role) {
    switch (role) {
      case 'warehouseStaff':
        return UserRole.warehouseStaff;
      case 'inventoryManager':
      default:
        return UserRole.inventoryManager;
    }
  }

  // ================= NAME FROM EMAIL =================
  String _defaultNameFromEmail(String email) {
    final int atIndex = email.indexOf('@');

    if (atIndex <= 0) {
      return 'User';
    }

    final String raw = email.substring(0, atIndex).replaceAll('.', ' ').trim();

    if (raw.isEmpty) {
      return 'User';
    }

    return raw
        .split(RegExp(r'\s+'))
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }
}

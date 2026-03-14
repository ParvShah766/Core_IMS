import 'package:flutter/foundation.dart';

import '../features/auth/models/app_user.dart';
import '../features/auth/services/auth_service.dart';

class AppSession extends ChangeNotifier {
  AppSession({required AuthService authService}) : _authService = authService;

  final AuthService _authService;
  AppUser? _currentUser;

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  Future<AuthResult> signUp({
    required String email,
    required String password,
  }) async {
    final AuthResult result = await _authService.signUp(
      email: email,
      password: password,
    );

    if (result.success) {
      await _authService.signOut();
      _currentUser = null;
      notifyListeners();
    }

    return result;
  }

  Future<bool> login({required String email, required String password}) async {
    final AppUser? user = await _authService.login(
      email: email,
      password: password,
    );
    if (user == null) {
      return false;
    }

    _currentUser = user;
    notifyListeners();
    return true;
  }

  Future<OtpRequestResult> requestResetOtp({required String email}) {
    return _authService.sendPasswordResetOtp(email: email);
  }

  Future<AuthResult> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) {
    return _authService.resetPasswordWithOtp(
      email: email,
      otp: otp,
      newPassword: newPassword,
    );
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}

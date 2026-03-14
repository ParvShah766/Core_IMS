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
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final AuthResult result = await _authService.signUp(
      fullName: fullName,
      email: email,
      password: password,
      role: role,
    );

    if (result.success && result.user != null) {
      _currentUser = result.user;
      notifyListeners();
    }

    return result;
  }

  Future<AuthResult> login({required String email, required String password}) async {
    final AuthResult result = await _authService.login(
      email: email,
      password: password,
    );
    if (!result.success || result.user == null) {
      return result;
    }

    _currentUser = result.user;
    notifyListeners();
    return result;
  }

  OtpRequestResult requestResetOtp({required String email}) {
    return _authService.sendPasswordResetOtp(email: email);
  }

  AuthResult resetPasswordWithOtp({
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

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../app/api_config.dart';
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
  AppUser? _currentUser;

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Future<AuthResult> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final http.Response response = await http.post(
        _uri('/api/auth/signup'),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(<String, String>{
          'email': email.trim(),
          'password': password,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const AuthResult(success: true);
      }

      final Map<String, dynamic> body = _decodeBody(response.body);
      return AuthResult(
        success: false,
        message: (body['message'] as String?) ?? 'Failed to create account.',
      );
    } catch (_) {
      return const AuthResult(
        success: false,
        message: 'Unable to create account. Check backend connection.',
      );
    }
  }

  Future<AppUser?> login({
    required String email,
    required String password,
  }) async {
    try {
      final http.Response response = await http.post(
        _uri('/api/auth/login'),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(<String, String>{
          'email': email.trim(),
          'password': password,
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final Map<String, dynamic> body = _decodeBody(response.body);
      final Map<String, dynamic> userJson =
          (body['user'] as Map<String, dynamic>? ?? <String, dynamic>{});

      final String resolvedEmail = ((userJson['email'] as String?) ?? '')
          .trim()
          .toLowerCase();

      final AppUser user = AppUser(
        fullName: (userJson['fullName'] as String?)?.trim().isNotEmpty == true
            ? (userJson['fullName'] as String).trim()
            : _defaultNameFromEmail(resolvedEmail),
        email: resolvedEmail,
        password: '__backend__',
        role: _parseRole(userJson['role'] as String?),
      );

      _currentUser = user;
      return user;
    } catch (_) {
      return null;
    }
  }

  Future<AppUser?> currentSignedInUser() async {
    return _currentUser;
  }

  Future<void> signOut() async {
    _currentUser = null;
  }

  Future<OtpRequestResult> sendPasswordResetOtp({required String email}) async {
    return const OtpRequestResult(
      success: false,
      message: 'Password reset via backend is not enabled yet.',
    );
  }

  Future<AuthResult> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    return const AuthResult(
      success: false,
      message: 'Password reset via backend is not enabled yet.',
    );
  }

  UserRole _parseRole(String? role) {
    switch (role) {
      case 'warehouseStaff':
        return UserRole.warehouseStaff;
      case 'inventoryManager':
      default:
        return UserRole.inventoryManager;
    }
  }

  Map<String, dynamic> _decodeBody(String body) {
    if (body.isEmpty) {
      return <String, dynamic>{};
    }

    final dynamic decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return <String, dynamic>{};
  }

  String _defaultNameFromEmail(String email) {
    final String normalized = email.trim().toLowerCase();
    final int atIndex = normalized.indexOf('@');
    if (atIndex <= 0) {
      return 'User';
    }

    final String raw = normalized
        .substring(0, atIndex)
        .replaceAll('.', ' ')
        .trim();
    if (raw.isEmpty) {
      return 'User';
    }

    return raw
        .split(RegExp(r'\s+'))
        .map(
          (String part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }
}

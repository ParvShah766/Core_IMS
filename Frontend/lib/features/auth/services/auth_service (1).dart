import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/app_user.dart';

class AuthResult {
  const AuthResult({required this.success, this.message, this.user});

  final bool success;
  final String? message;
  final AppUser? user;
}

class OtpRequestResult {
  const OtpRequestResult({required this.success, this.message});

  final bool success;
  final String? message;
}

class AuthService {
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5000',
  );

  final http.Client _client;

  AuthService({http.Client? client}) : _client = client ?? http.Client();

  Future<AuthResult> signUp({
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    return _postAuthRequest(
      path: '/api/auth/signup',
      body: <String, dynamic>{
        'fullName': fullName.trim(),
        'email': email.trim(),
        'password': password,
        'role': role.name,
      },
    );
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    return _postAuthRequest(
      path: '/api/auth/login',
      body: <String, dynamic>{
        'email': email.trim(),
        'password': password,
      },
    );
  }

  OtpRequestResult sendPasswordResetOtp({required String email}) {
    return const OtpRequestResult(
      success: false,
      message: 'Password reset API is not connected yet.',
    );
  }

  AuthResult resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) {
    return const AuthResult(
      success: false,
      message: 'Password reset API is not connected yet.',
    );
  }

  Future<AuthResult> _postAuthRequest({
    required String path,
    required Map<String, dynamic> body,
  }) async {
    try {
      final http.Response response = await _client.post(
        Uri.parse('$_baseUrl$path'),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final Map<String, dynamic> payload = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return AuthResult(
          success: true,
          message: payload['message'] as String?,
          user: AppUser.fromJson(payload['user'] as Map<String, dynamic>),
        );
      }

      return AuthResult(
        success: false,
        message: (payload['error'] ?? payload['message'] ?? 'Request failed.') as String,
      );
    } catch (_) {
      return const AuthResult(
        success: false,
        message: 'Unable to reach the server. Check that the backend is running and API_BASE_URL is correct.',
      );
    }
  }
}

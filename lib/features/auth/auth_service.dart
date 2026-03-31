import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // ⚠️  Change this to your actual backend URL
  static const String baseUrl = 'https://your-kashio-backend.com';

  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ));

  static const _accessKey = 'kashio_access_token';
  static const _refreshKey = 'kashio_refresh_token';
  static const _emailKey = 'kashio_email';

  // ── token storage ─────────────────────────────────────────────────────────

  Future<void> saveTokens(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessKey, access);
    await prefs.setString(_refreshKey, refresh);
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessKey);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshKey);
  }

  Future<void> saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, email);
  }

  Future<String?> getSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
  }

  // ── API calls ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post('/api/v1/auth/login/', data: {
      'email': email,
      'password': password,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    required String deviceId,
  }) async {
    final response = await _dio.post('/api/v1/auth/register/', data: {
      'full_name': fullName,
      'email': email,
      'password': password,
      'device_id': deviceId,
      'agreeterms': true,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<String?> refreshAccessToken() async {
    final refresh = await getRefreshToken();
    if (refresh == null) return null;
    try {
      final response = await _dio.post(
        '/api/v1/auth/token/refresh/',
        data: {'refresh': refresh},
      );
      final data = response.data as Map<String, dynamic>;
      final newAccess = data['data']?['access'] as String?;
      if (newAccess != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_accessKey, newAccess);
      }
      return newAccess;
    } catch (_) {
      return null;
    }
  }
}
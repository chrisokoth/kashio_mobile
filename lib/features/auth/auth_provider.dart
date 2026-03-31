import 'package:flutter/material.dart';
import 'auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService authService;

  AuthStatus _status = AuthStatus.unknown;
  String? _error;
  bool _isLoading = false;

  AuthStatus get status => _status;
  String? get error => _error;
  bool get isLoading => _isLoading;

  AuthProvider({required this.authService}) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final loggedIn = await authService.isLoggedIn();
    _status = loggedIn ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await authService.login(email, password);
      final data = result['data'] as Map<String, dynamic>?;
      if (data != null) {
        await authService.saveTokens(
          data['access'] as String,
          data['refresh'] as String,
        );
        await authService.saveEmail(email);
        _status = AuthStatus.authenticated;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = _parseError(e);
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required String deviceId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await authService.register(
        fullName: fullName,
        email: email,
        password: password,
        deviceId: deviceId,
      );
      // Auto-login after register
      return login(email, password);
    } catch (e) {
      _error = _parseError(e);
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await authService.logout();
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  String _parseError(Object e) {
    if (e is Exception) return e.toString().replaceAll('Exception: ', '');
    return 'An error occurred';
  }
}
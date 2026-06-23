import 'package:flutter/material.dart';
import 'package:myapp/services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService;

  AuthProvider(this._apiService);

  bool get isAuthenticated => _apiService.isAuthenticated;
  String? get token => _apiService.accessToken;

  // ✅ LOGIN - delegates to ApiService
  Future<void> login(String email, String password) async {
    await _apiService.login(email, password);
  }

  // ✅ LOAD TOKEN - delegates to ApiService
  Future<void> loadUser() async {
    await _apiService.loadSession();
  }

  // ✅ LOGOUT - delegates to ApiService
  Future<void> logout() async {
    await _apiService.logout();
  }
}

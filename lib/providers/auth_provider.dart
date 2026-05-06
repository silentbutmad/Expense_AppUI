import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  String? _accessToken;
  String? _refreshToken;

  bool get isAuthenticated => _accessToken != null;
  String? get token => _accessToken;

  // ✅ LOGIN
  Future<void> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('https://expense-api-gateway.onrender.com/auth/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      _accessToken = data['accessToken'];
      _refreshToken = data['refreshToken'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessToken', _accessToken!);
      await prefs.setString('refreshToken', _refreshToken!);

      notifyListeners();
    } else {
      throw Exception(data['message'] ?? "Login failed");
    }
  }

  // ✅ LOAD TOKEN
  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('accessToken');
    _refreshToken = prefs.getString('refreshToken');
    notifyListeners();
  }

  // ✅ LOGOUT
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    _accessToken = null;
    _refreshToken = null;

    notifyListeners();
  }
}
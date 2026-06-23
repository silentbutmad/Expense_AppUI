import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService with ChangeNotifier {
  // ✅ SINGLE BASE URL (NO DUPLICATION ANYWHERE)
  static const String _baseUrl =
      'https://expense-api-gateway.onrender.com';

  String? _token;
  Map<String, dynamic>? _userData;

  String? get token => _token;
  Map<String, dynamic>? get userData => _userData;
  bool get isAuthenticated => _token != null;

  // =========================
  // AUTH APIs
  // =========================

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      _token = data['token'];
      _userData = data['user'];
      notifyListeners();
      return data;
    } else {
      throw Exception(data['message'] ?? 'Login failed');
    }
  }

  Future<Map<String, dynamic>> register(
      Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(userData),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      _token = data['token'];
      _userData = data['user'];
      notifyListeners();
      return data;
    } else {
      throw Exception(data['message'] ?? 'Registration failed');
    }
  }

  // =========================
  // TOKEN VALIDATION
  // =========================

  Future<bool> validateToken() async {
    if (_token == null) return false;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/validate'),
        headers: {
          'Authorization': 'Bearer $_token',
        },
      );

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // =========================
  // PERSONAL TRANSACTIONS
  // =========================

  Future<Map<String, dynamic>> addPersonalTransaction(
    Map<String, dynamic> transactionData,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/expenses/addpersonalTransaction'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode(transactionData),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to add transaction');
    }
  }

  Future<List<dynamic>> getAllPersonalTransactions() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/expenses/allPersonalTransactions'),
      headers: {
        'Authorization': 'Bearer $_token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      // supports both formats: list OR {transactions: []}
      return data is List
          ? data
          : List<dynamic>.from(data['transactions'] ?? []);
    } else {
      throw Exception(data['message'] ?? 'Failed to fetch transactions');
    }
  }

  // =========================
  // LOGOUT
  // =========================

  Future<void> logout() async {
    _token = null;
    _userData = null;
    notifyListeners();
  }
}
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:myapp/utils/token_manager.dart';

class ApiService with ChangeNotifier {
  // ✅ SINGLE BASE URL (NO DUPLICATION ANYWHERE)
  static const String _baseUrl =
      'https://expense-api-gateway.onrender.com';

  // Timeout configuration
  static const Duration _timeout = Duration(seconds: 30);

  // In-memory state
  String? _accessToken;
  String? _refreshToken;
  Map<String, dynamic>? _userData;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  Map<String, dynamic>? get userData => _userData;
  bool get isAuthenticated => _accessToken != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // =========================
  // INITIALIZATION & SESSION
  // =========================

  /// Load session from secure storage on app startup
  Future<bool> loadSession() async {
    try {
      _accessToken = await TokenManager.getAccessToken();
      _refreshToken = await TokenManager.getRefreshToken();
      _userData = await TokenManager.getUserData();

      notifyListeners();
      return _accessToken != null && _refreshToken != null;
    } catch (e) {
      debugPrint('Error loading session: $e');
      await clearSession();
      return false;
    }
  }

  /// Clear session (logout)
  Future<void> clearSession() async {
    _accessToken = null;
    _refreshToken = null;
    _userData = null;
    _errorMessage = null;
    await TokenManager.clearAll();
    notifyListeners();
  }

  // =========================
  // AUTH APIs
  // =========================

  Future<Map<String, dynamic>> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _post(
        '/auth/login',
        body: {'email': email, 'password': password},
        requiresAuth: false,
      );

      // Handle different response formats
      final accessToken = response['accessToken'] ?? response['token'];
      final refreshToken = response['refreshToken'] ?? response['refresh_token'];

      if (accessToken == null || refreshToken == null) {
        throw Exception('Invalid response: missing tokens');
      }

      _accessToken = accessToken;
      _refreshToken = refreshToken;
      _userData = response['user'] ?? response['userData'];

      // Save to secure storage
      await TokenManager.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        userData: _userData,
      );

      notifyListeners();
      return response;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _post(
        '/auth/start-register',
        body: userData,
        requiresAuth: false,
      );

      // Registration might not return tokens immediately (OTP flow)
      // Just return the response
      return response;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _post(
        '/auth/forgot-password',
        body: {'email': email},
        requiresAuth: false,
      );
      return response;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _post(
        '/auth/reset-password',
        body: {
          'email': email,
          'otp': otp,
          'newPassword': newPassword,
        },
        requiresAuth: false,
      );
      return response;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _post(
        '/auth/verify-otp',
        body: {'email': email, 'otp': otp},
        requiresAuth: false,
      );
      return response;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // =========================
  // TOKEN REFRESH
  // =========================

  /// Refresh access token using refresh token
  Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) {
      debugPrint('No refresh token available');
      return false;
    }

    try {
      debugPrint('Refreshing access token...');

      final response = await http.post(
        Uri.parse('$_baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': _refreshToken}),
      ).timeout(_timeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final newAccessToken = data['accessToken'] ?? data['access_token'];
        final newRefreshToken = data['refreshToken'] ?? data['refresh_token'];

        if (newAccessToken != null) {
          _accessToken = newAccessToken;
          if (newRefreshToken != null) {
            _refreshToken = newRefreshToken;
          }

          // Save to secure storage
          await TokenManager.saveTokens(
            accessToken: _accessToken!,
            refreshToken: _refreshToken!,
            userData: _userData,
          );

          debugPrint('Token refreshed successfully');
          notifyListeners();
          return true;
        }
      }

      debugPrint('Token refresh failed: ${data['message'] ?? response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('Error refreshing token: $e');
      return false;
    }
  }

  // =========================
  // CORE HTTP METHODS
  // =========================

  Future<dynamic> getRequest(String endpoint) async {
    return await _get(endpoint);
  }

  Future<dynamic> postRequest(String endpoint, Map<String, dynamic> body) async {
    return await _post(endpoint, body: body);
  }

  Future<dynamic> putRequest(String endpoint, Map<String, dynamic> body) async {
    return await _put(endpoint, body: body);
  }

  Future<dynamic> deleteRequest(String endpoint) async {
    return await _delete(endpoint);
  }

  // =========================
  // PRIVATE HTTP METHODS
  // =========================

  Future<dynamic> _get(
    String endpoint, {
    bool requiresAuth = true,
    Map<String, String>? headers,
  }) async {
    return await _makeRequestWithRetry(
      () async {
        final uri = Uri.parse('$_baseUrl$endpoint');
        final requestHeaders = _buildHeaders(requiresAuth, headers);

        debugPrint('GET: $uri');

        final response = await http.get(uri, headers: requestHeaders)
            .timeout(_timeout);

        return _handleResponse(response);
      },
      requiresAuth: requiresAuth,
    );
  }

  Future<dynamic> _post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
    Map<String, String>? headers,
  }) async {
    return await _makeRequestWithRetry(
      () async {
        final uri = Uri.parse('$_baseUrl$endpoint');
        final requestHeaders = _buildHeaders(requiresAuth, headers);

        debugPrint('POST: $uri');

        final response = await http.post(
          uri,
          headers: requestHeaders,
          body: body != null ? jsonEncode(body) : null,
        ).timeout(_timeout);

        return _handleResponse(response);
      },
      requiresAuth: requiresAuth,
    );
  }

  Future<dynamic> _put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
    Map<String, String>? headers,
  }) async {
    return await _makeRequestWithRetry(
      () async {
        final uri = Uri.parse('$_baseUrl$endpoint');
        final requestHeaders = _buildHeaders(requiresAuth, headers);

        debugPrint('PUT: $uri');

        final response = await http.put(
          uri,
          headers: requestHeaders,
          body: body != null ? jsonEncode(body) : null,
        ).timeout(_timeout);

        return _handleResponse(response);
      },
      requiresAuth: requiresAuth,
    );
  }

  Future<dynamic> _delete(
    String endpoint, {
    bool requiresAuth = true,
    Map<String, String>? headers,
  }) async {
    return await _makeRequestWithRetry(
      () async {
        final uri = Uri.parse('$_baseUrl$endpoint');
        final requestHeaders = _buildHeaders(requiresAuth, headers);

        debugPrint('DELETE: $uri');

        final response = await http.delete(uri, headers: requestHeaders)
            .timeout(_timeout);

        return _handleResponse(response);
      },
      requiresAuth: requiresAuth,
    );
  }

  // =========================
  // REQUEST HANDLING WITH RETRY
  // =========================

  Future<dynamic> _makeRequestWithRetry(
    Future<dynamic> Function() requestFn, {
    bool requiresAuth = true,
  }) async {
    try {
      return await requestFn();
    } on ApiUnauthorizedException catch (e) {
      // If 401 and we have a refresh token, try to refresh
      if (requiresAuth && _refreshToken != null && e.shouldRetry) {
        debugPrint('Got 401, attempting token refresh...');

        final refreshSuccess = await refreshAccessToken();

        if (refreshSuccess) {
          debugPrint('Token refreshed, retrying original request...');
          // Retry the original request with new token
          return await requestFn();
        } else {
          // Refresh failed, clear session and logout
          debugPrint('Token refresh failed, logging out...');
          await clearSession();
          _notifyLogout();
          throw Exception('Session expired. Please login again.');
        }
      } else {
        // No refresh token or refresh not allowed
        await clearSession();
        _notifyLogout();
        rethrow;
      }
    }
  }

  // =========================
  // RESPONSE HANDLING
  // =========================

  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final contentType = response.headers['content-type'] ?? '';

    debugPrint('Response status: $statusCode');

    // Try to parse JSON
    dynamic data;
    try {
      if (contentType.contains('application/json')) {
        data = jsonDecode(response.body);
      } else {
        data = response.body;
      }
    } catch (e) {
      debugPrint('Error parsing response: $e');
      data = response.body;
    }

    // Handle success responses
    if (statusCode >= 200 && statusCode < 300) {
      return data;
    }

    // Handle error responses
    String errorMessage;
    if (data is Map<String, dynamic>) {
      errorMessage = data['message'] ?? data['error'] ?? 'Request failed';
    } else {
      errorMessage = 'Request failed with status $statusCode';
    }

    // Handle unauthorized
    if (statusCode == 401) {
      throw ApiUnauthorizedException(errorMessage);
    }

    // Handle other errors
    throw Exception(errorMessage);
  }

  // =========================
  // HELPER METHODS
  // =========================

  Map<String, String> _buildHeaders(
    bool requiresAuth,
    Map<String, String>? additionalHeaders,
  ) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    // Add authorization header if required and token exists
    if (requiresAuth && _accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }

    // Add any additional headers
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void _notifyLogout() {
    // This will be handled by the UI listening to isAuthenticated
    notifyListeners();
  }

  // =========================
  // BUSINESS LOGIC APIs
  // =========================

  Future<Map<String, dynamic>> addPersonalTransaction(
    Map<String, dynamic> transactionData,
  ) async {
    final response = await _post(
      '/expenses/addpersonalTransaction',
      body: transactionData,
    );
    return response;
  }

  Future<List<dynamic>> getAllPersonalTransactions() async {
    final response = await _get('/expenses/allPersonalTransactions');
    if (response is List) {
      return response;
    } else if (response is Map<String, dynamic>) {
      return List<dynamic>.from(response['transactions'] ?? []);
    }
    return [];
  }

  Future<Map<String, dynamic>> addBusinessTransaction(
    Map<String, dynamic> transactionData,
  ) async {
    final response = await _post(
      '/expenses/addBusinessTransaction',
      body: transactionData,
    );
    return response;
  }

  Future<List<dynamic>> getAllBusinessTransactions() async {
    final response = await _get('/expenses/allBusinessTransactions');
    if (response is List) {
      return response;
    } else if (response is Map<String, dynamic>) {
      return List<dynamic>.from(response['transactions'] ?? []);
    }
    return [];
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
    final response = await _put('/user/profile', body: profileData);
    return response;
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _post(
      '/user/change-password',
      body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
    return response;
  }

  // =========================
  // LOGOUT
  // =========================

  Future<void> logout() async {
    try {
      // Call logout endpoint if available
      await _post('/auth/logout');
    } catch (e) {
      // Ignore errors, we're logging out anyway
      debugPrint('Logout endpoint error: $e');
    } finally {
      await clearSession();
    }
  }
}

// =========================
// CUSTOM EXCEPTIONS
// =========================

class ApiUnauthorizedException implements Exception {
  final String message;
  final bool shouldRetry;

  ApiUnauthorizedException(this.message, {this.shouldRetry = true});

  @override
  String toString() => 'ApiUnauthorizedException: $message';
}
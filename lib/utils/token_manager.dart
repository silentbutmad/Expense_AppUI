import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class TokenManager {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // Note: encryptedSharedPreferences is deprecated in flutter_secure_storage v10+
  // It will be automatically migrated to custom ciphers on first access.
  // The parameter is kept for backward compatibility but will be ignored.

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';

  /// Save tokens and user data securely
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    Map<String, dynamic>? userData,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    if (userData != null) {
      await _storage.write(key: _userDataKey, value: jsonEncode(userData));
    }
  }

  /// Get access token
  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  /// Get refresh token
  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  /// Get user data
  static Future<Map<String, dynamic>?> getUserData() async {
    final userDataString = await _storage.read(key: _userDataKey);
    if (userDataString != null) {
      try {
        // Parse the JSON string back to Map
        return Map<String, dynamic>.from(jsonDecode(userDataString));
      } catch (e) {
        debugPrint('Error parsing user data: $e');
        return null;
      }
    }
    return null;
  }

  /// Update access token only (after refresh)
  static Future<void> updateAccessToken(String accessToken) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
  }

  /// Clear all stored data (logout)
  static Future<void> clearAll() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userDataKey);
  }

  /// Check if user has valid session
  static Future<bool> hasValidSession() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();
    return accessToken != null && refreshToken != null;
  }

  /// Get user ID from stored user data
  static Future<String?> getUserId() async {
    final userData = await getUserData();
    if (userData == null) return null;
    
    // Try multiple possible field names for user ID
    return userData['id']?.toString() ?? 
           userData['userId']?.toString() ?? 
           userData['user_id']?.toString() ??
           userData['_id']?.toString();
  }
}

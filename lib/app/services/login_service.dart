import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio;
import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';

// Custom exception for login service errors
class LoginServiceException implements Exception {
  final String message;
  final int? statusCode;

  LoginServiceException(this.message, {this.statusCode});

  @override
  String toString() {
    if (statusCode != null) {
      return 'LoginServiceException: [Status $statusCode] $message';
    }
    return 'LoginServiceException: $message';
  }
}

class LoginService extends GetxService {
  // Inject the Dio instance, don't create it internally
  final dio.Dio _dio;
  final GetStorage box;

  // Constructor to receive the Dio instance and GetStorage box
  LoginService(this._dio, this.box);

  final String _baseUrl = 'https://mobiking-e-commerce-backend-prod.vercel.app/api/v1/users';

  void _log(String message) {
    print('[LoginService] $message');
  }

  // Enhanced Login Method
  Future<dio.Response> login(String phone) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/login',
        data: {
          'phoneNo': phone,
          'role': 'user',
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        _log('Login successful. Response data: ${response.data}');

        // ✅ Store tokens and creation time from login response
        if (response.data['data']?['accessToken'] != null) {
          await box.write('accessToken', response.data['data']['accessToken']);
        }
        if (response.data['data']?['refreshToken'] != null) {
          await box.write('refreshToken', response.data['data']['refreshToken']);
        }

        // Store token creation time for automatic refresh scheduling
        await box.write('tokenCreationTime', DateTime.now().millisecondsSinceEpoch);

        // ❌ REMOVED: No success snackbar shown to user

        return response;
      } else {
        final errorMessage = response.data?['message'] ?? 'Login failed. Please try again.';
        throw LoginServiceException(errorMessage, statusCode: response.statusCode);
      }
    } on dio.DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data?['message'] ?? 'Server error occurred.';
        _log('Dio error during login: ${e.response?.statusCode} - $errorMessage');
        throw LoginServiceException(errorMessage, statusCode: e.response?.statusCode);
      } else {
        _log('Network error during login: ${e.message}');
        throw LoginServiceException('Network error: ${e.message}');
      }
    } catch (e) {
      _log('Unexpected error during login: $e');
      throw LoginServiceException('An unexpected error occurred during login: $e');
    }
  }

  // Enhanced Logout Method
  Future<dio.Response> logout() async {
    try {
      final accessToken = box.read('accessToken');

      if (accessToken == null) {
        _log('No access token found for logout. User is already considered logged out locally.');
        throw LoginServiceException('Access token not found. User is not logged in locally.');
      }

      final response = await _dio.post(
        '$_baseUrl/logout',
        options: dio.Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      if (response.statusCode == 200) {
        _log('User logged out successfully from server.');

        // ❌ REMOVED: No success snackbar shown to user

        return response;
      } else {
        final errorMessage = response.data?['message'] ?? 'Logout failed on server.';
        throw LoginServiceException(errorMessage, statusCode: response.statusCode);
      }
    } on dio.DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data?['message'] ?? 'Server error during logout.';
        _log('Dio error during logout: ${e.response?.statusCode} - $errorMessage');
        throw LoginServiceException(errorMessage, statusCode: e.response?.statusCode);
      } else {
        _log('Network error during logout: ${e.message}');
        throw LoginServiceException('Network error during logout: ${e.message}');
      }
    } catch (e) {
      _log('Unexpected error during logout: $e');
      throw LoginServiceException('An unexpected error occurred during logout: $e');
    } finally {
      // Enhanced: Clear all token-related data
      _clearAllTokenData();
    }
  }

  // Comprehensive token data clearing
  void _clearAllTokenData() {
    box.remove('accessToken');
    box.remove('refreshToken');
    box.remove('tokenCreationTime');
    box.remove('accessTokenExpiry');
    box.remove('user');
    box.remove('cartId');
    _log('All authentication and user data cleared locally.');
  }

  // ✅ Enhanced: refreshToken method with proper token storage
  Future<dio.Response> refreshToken(String refreshToken) async {
    if (refreshToken.isEmpty) {
      _log('Refresh token is empty. Cannot refresh access token.');
      throw LoginServiceException('Refresh token missing. Please log in again.');
    }

    try {
      _log('Attempting to refresh access token...');

      final response = await _dio.post(
        '$_baseUrl/refresh-token',
        options: dio.Options(
          headers: {
            'Authorization': 'Bearer $refreshToken',
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
        data: {},
      );

      if (response.statusCode == 200 && response.data != null && response.data['success'] == true) {
        _log('Token refresh successful');

        // ✅ CRITICAL: Store the NEW access token from refresh response
        if (response.data['data']?['accessToken'] != null) {
          await box.write('accessToken', response.data['data']['accessToken']);
          _log('New access token stored successfully');
        }

        // ✅ Update refresh token if provided in response
        if (response.data['data']?['refreshToken'] != null) {
          await box.write('refreshToken', response.data['data']['refreshToken']);
          _log('New refresh token stored successfully');
        }

        // ✅ Update token creation time for new token
        await box.write('tokenCreationTime', DateTime.now().millisecondsSinceEpoch);

        // ❌ REMOVED: No success snackbar shown to user

        return response;
      } else {
        final errorMessage = response.data?['message'] ?? 'Failed to refresh token: Unknown server response.';
        _log('Error refreshing token: ${response.statusCode} - $errorMessage');
        throw LoginServiceException(errorMessage, statusCode: response.statusCode);
      }
    } on dio.DioException catch (e) {
      if (e.response != null) {
        final statusCode = e.response?.statusCode;
        final errorMessage = e.response?.data?['message'] ?? 'Server error during token refresh.';

        _log('Dio error refreshing token: $statusCode - $errorMessage');

        // Enhanced: Handle specific error codes
        if (statusCode == 401) {
          // Refresh token expired or invalid
          _clearAllTokenData();
          throw LoginServiceException('Refresh token expired. Please log in again.', statusCode: statusCode);
        } else if (statusCode == 403) {
          // Forbidden - refresh token might be revoked
          _clearAllTokenData();
          throw LoginServiceException('Access denied. Please log in again.', statusCode: statusCode);
        } else {
          throw LoginServiceException(errorMessage, statusCode: statusCode);
        }
      } else {
        // Network error
        _log('Network error during token refresh: ${e.message}');
        throw LoginServiceException('Network error during token refresh: ${e.message}');
      }
    } catch (e) {
      _log('Unexpected error during token refresh: $e');
      throw LoginServiceException('An unexpected error occurred during token refresh: $e');
    }
  }

  // ✅ NEW: Automatic token refresh method for 12-hour intervals
  Future<bool> autoRefreshTokenIfNeeded() async {
    try {
      if (!hasValidTokens()) {
        _log('No valid tokens found for auto-refresh');
        return false;
      }

      if (needsTokenRefresh()) {
        _log('Token needs refresh - attempting automatic refresh...');

        final currentRefreshToken = getCurrentRefreshToken();
        if (currentRefreshToken == null) {
          _log('No refresh token available for auto-refresh');
          return false;
        }

        await refreshToken(currentRefreshToken);
        _log('Automatic token refresh completed successfully');
        return true;
      }

      _log('Token is still valid - no refresh needed');
      return true;
    } catch (e) {
      _log('Error during automatic token refresh: $e');
      return false;
    }
  }

  // Check if tokens exist locally
  bool hasValidTokens() {
    final accessToken = box.read('accessToken');
    final refreshToken = box.read('refreshToken');
    final tokenCreationTime = box.read('tokenCreationTime');

    return accessToken != null &&
        refreshToken != null &&
        tokenCreationTime != null;
  }

  // Get token age in hours
  double getTokenAgeInHours() {
    final tokenCreationTime = box.read('tokenCreationTime');
    if (tokenCreationTime == null) return 25.0; // Return > 24 to indicate expired

    final now = DateTime.now().millisecondsSinceEpoch;
    final tokenAge = now - tokenCreationTime;
    return tokenAge / (1000 * 60 * 60); // Convert to hours
  }

  // ✅ UPDATED: Check if token needs refresh - Changed to 12 hours
  bool needsTokenRefresh() {
    return getTokenAgeInHours() >= 12.0; // ✅ Refresh after 12 hours
  }

  // Check if token is expired
  bool isTokenExpired() {
    return getTokenAgeInHours() >= 24.0; // Expire after 24 hours
  }

  // Get current access token
  String? getCurrentAccessToken() {
    return box.read('accessToken');
  }

  // Get current refresh token
  String? getCurrentRefreshToken() {
    return box.read('refreshToken');
  }

  // Validate token format (basic validation)
  bool isValidTokenFormat(String? token) {
    if (token == null || token.isEmpty) return false;

    // Basic JWT format check (header.payload.signature)
    final parts = token.split('.');
    return parts.length == 3 && parts.every((part) => part.isNotEmpty);
  }

  // ✅ UPDATED: Get token status information with 12-hour refresh logic
  Map<String, dynamic> getTokenStatus() {
    final accessToken = getCurrentAccessToken();
    final refreshToken = getCurrentRefreshToken();
    final ageInHours = getTokenAgeInHours();

    return {
      'hasAccessToken': accessToken != null,
      'hasRefreshToken': refreshToken != null,
      'isValidFormat': isValidTokenFormat(accessToken),
      'ageInHours': ageInHours,
      'needsRefresh': needsTokenRefresh(),
      'isExpired': isTokenExpired(),
      'creationTime': box.read('tokenCreationTime'),
      'willRefreshAt': '12 hours',
    };
  }

  // ✅ NEW: Method to get a valid access token (with auto-refresh)
  Future<String?> getValidAccessToken() async {
    if (!hasValidTokens()) {
      _log('No tokens available');
      return null;
    }

    if (isTokenExpired()) {
      _log('Tokens are expired - requiring re-login');
      _clearAllTokenData();
      return null;
    }

    if (needsTokenRefresh()) {
      _log('Token needs refresh - attempting refresh...');
      final refreshSuccess = await autoRefreshTokenIfNeeded();
      if (!refreshSuccess) {
        _log('Token refresh failed');
        return null;
      }
    }

    return getCurrentAccessToken();
  }

  // Emergency token cleanup (for extreme cases)
  Future<void> emergencyTokenCleanup() async {
    try {
      _log('Performing emergency token cleanup...');
      _clearAllTokenData();

      // Clear any cached data
      await box.remove('last_login_phone');
      await box.remove('user_preferences');

      _log('Emergency cleanup completed');
    } catch (e) {
      _log('Error during emergency cleanup: $e');
    }
  }

  // Health check method
  Future<bool> checkServiceHealth() async {
    try {
      final response = await _dio.get(
        '$_baseUrl/health',
        options: dio.Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      final isHealthy = response.statusCode == 200;
      _log('Service health check: ${isHealthy ? 'Healthy' : 'Unhealthy'} (Status: ${response.statusCode})');
      return isHealthy;
    } catch (e) {
      _log('Health check failed: $e');
      return false;
    }
  }
}

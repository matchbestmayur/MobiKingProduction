import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio;
import 'package:get_storage/get_storage.dart';

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

  // --- Enhanced Login Method ---
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
        print('Login successful. Response data: ${response.data}');

        // ✅ Store token creation time for automatic refresh scheduling
        await box.write('tokenCreationTime', DateTime.now().millisecondsSinceEpoch);

        return response;
      } else {
        final errorMessage = response.data?['message'] ?? 'Login failed. Please try again.';
        throw LoginServiceException(errorMessage, statusCode: response.statusCode);
      }
    } on dio.DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data?['message'] ?? 'Server error occurred.';
        throw LoginServiceException(errorMessage, statusCode: e.response?.statusCode);
      } else {
        throw LoginServiceException('Network error: ${e.message}');
      }
    } catch (e) {
      print('Unexpected error during login: $e');
      throw LoginServiceException('An unexpected error occurred during login: $e');
    }
  }

  // --- Enhanced Logout Method ---
  Future<dio.Response> logout() async {
    try {
      final accessToken = box.read('accessToken');

      if (accessToken == null) {
        print('No access token found for logout. User is already considered logged out locally.');
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
        print('User logged out successfully from server.');
        return response;
      } else {
        final errorMessage = response.data?['message'] ?? 'Logout failed on server.';
        throw LoginServiceException(errorMessage, statusCode: response.statusCode);
      }
    } on dio.DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data?['message'] ?? 'Server error during logout.';
        throw LoginServiceException(errorMessage, statusCode: e.response?.statusCode);
      } else {
        throw LoginServiceException('Network error during logout: ${e.message}');
      }
    } catch (e) {
      print('Unexpected error during logout: $e');
      throw LoginServiceException('An unexpected error occurred during logout: $e');
    } finally {
      // ✅ Enhanced: Clear all token-related data
      _clearAllTokenData();
    }
  }

  // ✅ New: Comprehensive token data clearing
  void _clearAllTokenData() {
    box.remove('accessToken');
    box.remove('refreshToken');
    box.remove('tokenCreationTime'); // ✅ Clear creation time
    box.remove('accessTokenExpiry'); // Clear expiry time if exists
    box.remove('user'); // Clear user data
    box.remove('cartId'); // Clear cart data
    print('All authentication and user data cleared locally.');
  }

  // ✅ Enhanced: refreshToken method (renamed from refreshAccessToken for consistency)
  Future<dio.Response> refreshToken(String refreshToken) async {
    if (refreshToken.isEmpty) {
      print('Refresh token is empty. Cannot refresh access token.');
      throw LoginServiceException('Refresh token missing. Please log in again.');
    }

    try {
      print('LoginService: Attempting to refresh access token...');

      final response = await _dio.post(
        '$_baseUrl/refresh-token',
        options: dio.Options(
          headers: {
            'Authorization': 'Bearer $refreshToken',
            'Content-Type': 'application/json',
          },
          // ✅ Add timeout for refresh requests
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
        // Empty data as per your curl command
        data: {},
      );

      if (response.statusCode == 200 && response.data != null && response.data['success'] == true) {
        print('LoginService: Token refresh successful');

        // ✅ Update token creation time for new token
        await box.write('tokenCreationTime', DateTime.now().millisecondsSinceEpoch);

        return response;
      } else {
        final errorMessage = response.data?['message'] ?? 'Failed to refresh token: Unknown server response.';
        print('Error refreshing token: ${response.statusCode} - $errorMessage');
        throw LoginServiceException(errorMessage, statusCode: response.statusCode);
      }
    } on dio.DioException catch (e) {
      if (e.response != null) {
        final statusCode = e.response?.statusCode;
        final errorMessage = e.response?.data?['message'] ?? 'Server error during token refresh.';

        print('Dio error refreshing token: $statusCode - $errorMessage');

        // ✅ Enhanced: Handle specific error codes
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
        throw LoginServiceException('Network error during token refresh: ${e.message}');
      }
    } catch (e) {
      print('Unexpected error during token refresh: $e');
      throw LoginServiceException('An unexpected error occurred during token refresh: $e');
    }
  }

  // ✅ New: Check if tokens exist locally
  bool hasValidTokens() {
    final accessToken = box.read('accessToken');
    final refreshToken = box.read('refreshToken');
    final tokenCreationTime = box.read('tokenCreationTime');

    return accessToken != null &&
        refreshToken != null &&
        tokenCreationTime != null;
  }

  // ✅ New: Get token age in hours
  double getTokenAgeInHours() {
    final tokenCreationTime = box.read('tokenCreationTime');
    if (tokenCreationTime == null) return 25.0; // Return > 24 to indicate expired

    final now = DateTime.now().millisecondsSinceEpoch;
    final tokenAge = now - tokenCreationTime;
    return tokenAge / (1000 * 60 * 60); // Convert to hours
  }

  // ✅ New: Check if token needs refresh
  bool needsTokenRefresh() {
    return getTokenAgeInHours() >= 20.0; // Refresh after 20 hours
  }

  // ✅ New: Check if token is expired
  bool isTokenExpired() {
    return getTokenAgeInHours() >= 24.0; // Expire after 24 hours
  }

  // ✅ New: Get current access token
  String? getCurrentAccessToken() {
    return box.read('accessToken');
  }

  // ✅ New: Get current refresh token
  String? getCurrentRefreshToken() {
    return box.read('refreshToken');
  }

  // ✅ New: Validate token format (basic validation)
  bool isValidTokenFormat(String? token) {
    if (token == null || token.isEmpty) return false;

    // Basic JWT format check (header.payload.signature)
    final parts = token.split('.');
    return parts.length == 3 && parts.every((part) => part.isNotEmpty);
  }

  // ✅ New: Get token status information
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
    };
  }

  // ✅ New: Emergency token cleanup (for extreme cases)
  Future<void> emergencyTokenCleanup() async {
    try {
      print('LoginService: Performing emergency token cleanup...');
      _clearAllTokenData();

      // Clear any cached data
      await box.remove('last_login_phone');
      await box.remove('user_preferences');

      print('LoginService: Emergency cleanup completed');
    } catch (e) {
      print('LoginService: Error during emergency cleanup: $e');
    }
  }

  // ✅ New: Health check method
  Future<bool> checkServiceHealth() async {
    try {
      final response = await _dio.get(
        '$_baseUrl/health',
        options: dio.Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('LoginService: Health check failed: $e');
      return false;
    }
  }
}

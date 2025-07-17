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

  final String _baseUrl = 'https://mobiking-e-commerce-backend-prod.vercel.app/api/v1/users'; // Base URL for user-related endpoints

  // --- Login Method ---
  // Returns Future<dio.Response> as per your original code, but with improved error handling.
  // The calling controller will be responsible for parsing response.data.
  Future<dio.Response> login(String phone) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/login',
        data: {
          'phoneNo': phone,
          'role': 'user',
        },
      );
      if (response.statusCode == 200) {
        // Original comment: "No need to store 'userData' here if LoginController handles individual keys."
        // We keep this as is, expecting the controller to extract and store.
        print('Login successful. Response data: ${response.data}'); // Keep this for debugging response data
        return response;
      } else {
        // Enhance error handling for non-200 responses
        final errorMessage = response.data?['message'] ?? 'Login failed. Please try again.';
        throw LoginServiceException(errorMessage, statusCode: response.statusCode);
      }
    } on dio.DioException catch (e) {
      // Dio-specific error handling (e.g., network issues, server errors)
      if (e.response != null) {
        final errorMessage = e.response?.data?['message'] ?? 'Server error occurred.';
        throw LoginServiceException(errorMessage, statusCode: e.response?.statusCode);
      } else {
        throw LoginServiceException('Network error: ${e.message}');
      }
    } catch (e) {
      // Catch any other unexpected errors
      print('Unexpected error during login: $e');
      throw LoginServiceException('An unexpected error occurred during login: $e');
    }
  }

  // --- Logout Method ---
  // Returns Future<dio.Response> as per your original code, but with improved error handling
  // and a crucial `finally` block to ensure local token clearing.
  Future<dio.Response> logout() async {
    try {
      final accessToken = box.read('accessToken'); // Read the accessToken directly from GetStorage

      if (accessToken == null) {
        // If there's no access token, the user isn't truly "logged in" from a token perspective.
        // We'll still throw here for consistency with original `throw Exception`, but indicate local state.
        print('No access token found for logout. User is already considered logged out locally.');
        throw LoginServiceException('Access token not found. User is not logged in locally.');
      }

      final response = await _dio.post(
        '$_baseUrl/logout',
        options: dio.Options(
          headers: {
            'Authorization': 'Bearer $accessToken', // Send the access token in the header
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
      // Crucial: Always clear local tokens regardless of server logout success/failure
      box.remove('accessToken');
      box.remove('refreshToken');
      box.remove('accessTokenExpiry'); // Clear expiry time (important for automation)
      // If you stored other user data, remove it here too, e.g.:
      // box.remove('userData');
      print('Local authentication tokens cleared during logout process.');
    }
  }

  // --- NEW METHOD: refreshAccessToken ---
  /// Refreshes the access token using the stored refresh token.
  /// Returns the `data` part of the backend response as a `Map<String, dynamic>`,
  /// which contains the new `accessToken` and `refreshToken`.
  /// Throws `LoginServiceException` if an error occurs, especially
  /// if the refresh token is invalid or expired, signaling a forced logout.
  Future<Map<String, dynamic>> refreshAccessToken() async {
    final refreshToken = box.read('refreshToken');

    if (refreshToken == null || refreshToken.isEmpty) {
      print('Refresh token not found. Cannot refresh access token. User needs to re-login.');
      throw LoginServiceException('Refresh token missing. Please log in again.');
    }

    try {
      final response = await _dio.post(
        '$_baseUrl/refresh-token',
        options: dio.Options(
          headers: {
            'Authorization': 'Bearer $refreshToken', // Send refresh token in header
            'Content-Type': 'application/json', // Backend might expect this even for empty body
          },
        ),
        // The curl command showed --data '', implying an empty body.
        // If your backend expects a specific JSON body, you'd add it here:
        // data: {},
      );

      if (response.statusCode == 200 && response.data != null && response.data['success'] == true) {
        final responseData = response.data['data'] as Map<String, dynamic>?;

        if (responseData != null && responseData['accessToken'] is String && (responseData['accessToken'] as String).isNotEmpty) {
          final newAccessToken = responseData['accessToken'] as String;
          final newRefreshToken = responseData['refreshToken'] as String?; // This might be null if backend doesn't rotate refresh tokens

          await box.write('accessToken', newAccessToken);
          if (newRefreshToken != null) { // Only update refresh token if a new one is provided
            await box.write('refreshToken', newRefreshToken);
          }

          // IMPORTANT: Your backend refresh-token response does NOT include 'expiresIn'.
          // We will *assume* a 24-hour validity for the new access token for proactive scheduling.
          // This timestamp will be used by the AuthController for scheduling the next refresh.
          final assumedAccessTokenExpiry = DateTime.now().add(const Duration(hours: 24));
          await box.write('accessTokenExpiry', assumedAccessTokenExpiry.toIso8601String());

          print('Access token refreshed successfully!');
          return responseData; // Return the 'data' part of the response
        } else {
          // Response was successful, but the 'data' structure was unexpected or missing accessToken
          throw LoginServiceException('Failed to get new access token from refresh response data.');
        }
      } else {
        // Server returned an error (e.g., status code not 200 or success: false)
        final errorMessage = response.data?['message'] ?? 'Failed to refresh token: Unknown server response.';
        print('Error refreshing token: ${response.statusCode} - $errorMessage');
        throw LoginServiceException(errorMessage, statusCode: response.statusCode);
      }
    } on dio.DioException catch (e) {
      // Dio-specific errors (network issues, timeout, etc.)
      if (e.response != null) {
        final errorMessage = e.response?.data?['message'] ?? 'Server error during token refresh.';
        print('Dio error refreshing token: ${e.response?.statusCode} - $errorMessage');
        throw LoginServiceException(errorMessage, statusCode: e.response?.statusCode);
      } else {
        throw LoginServiceException('Network error during token refresh: ${e.message}');
      }
    } catch (e) {
      // Catch any other unexpected errors
      print('Unexpected error during token refresh: $e');
      throw LoginServiceException('An unexpected error occurred during token refresh: $e');
    }
  }
}
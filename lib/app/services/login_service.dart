import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio;
import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';
import 'dart:math'; // Add this for OTP generation

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

  // UPDATED: SMS API Configuration for mylogin.co.in
  final String _smsApiBaseUrl = 'https://api.mylogin.co.in/api/v2';
  final String _smsApiKey = 'DmGRastE1TT0vCDJyjMJYMEi+peSX/vPuybBpFaCcZ8='; // Your actual API key
  final String _smsClientId = 'a87c4262-3525-46c3-9abd-bc98d2427fbf'; // Your actual client ID
  final String _smsSenderId = 'MOBIKING'; // Your registered sender ID

  void _log(String message) {
    print('[LoginService] $message');
  }

  // ADD: Generate random 6-digit OTP
  String generateOTP() {
    Random random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // CORRECTED: Send OTP via mylogin.co.in SMS API with proper formatting
  Future<Map<String, dynamic>> sendOtpViaSms(String phoneNumber, String otp) async {
    try {
      // FIXED: Format phone number to 10-digit only (no country code)
      String formattedPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

      // If it has country code (91 prefix), remove it
      if (formattedPhoneNumber.startsWith('91') && formattedPhoneNumber.length == 12) {
        formattedPhoneNumber = formattedPhoneNumber.substring(2); // Remove '91'
      }

      // If it starts with +91, remove it
      if (phoneNumber.startsWith('+91')) {
        formattedPhoneNumber = phoneNumber.substring(3);
      }

      // Ensure it's exactly 10 digits
      if (formattedPhoneNumber.length != 10) {
        throw Exception('Invalid phone number format. Expected 10 digits, got ${formattedPhoneNumber.length}');
      }

      _log('Sending OTP via mylogin.co.in SMS API to: $formattedPhoneNumber (original: $phoneNumber)');

      final message = 'Your OTP for Mobiking is: $otp. Valid for 5 minutes. Do not share this code.';

      // Using GET method as per API documentation
      final response = await _dio.get(
        '$_smsApiBaseUrl/SendSMS',
        queryParameters: {
          'ApiKey': _smsApiKey,
          'ClientId': _smsClientId,
          'SenderId': _smsSenderId,
          'Message': message,
          'MobileNumbers': formattedPhoneNumber, // FIXED: Correct parameter name and 10-digit format
          'Is_Flash': 'false', // Optional parameters
          'Is_Unicode': 'false',
        },
        options: dio.Options(
          headers: {
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      _log('API Response Status: ${response.statusCode}');
      _log('API Response Data: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data;

        if (responseData['ErrorCode'] == 0) {
          _log('SMS sent successfully via mylogin.co.in to $formattedPhoneNumber');

          // Extract MessageId from Data array
          String? messageId;
          if (responseData['Data'] != null && responseData['Data'] is List) {
            final dataList = responseData['Data'] as List;
            if (dataList.isNotEmpty) {
              messageId = dataList[0]['MessageId'];
            }
          }

          return {
            'success': true,
            'messageId': messageId,
            'message': 'OTP sent successfully',
          };
        } else {
          _log('SMS API returned error: Code ${responseData['ErrorCode']} - ${responseData['ErrorDescription']}');
          return {
            'success': false,
            'error': responseData['ErrorDescription'] ?? 'Unknown SMS API error',
          };
        }
      } else {
        _log('Failed to send SMS: Status ${response.statusCode}');
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: Failed to send SMS',
        };
      }
    } on dio.DioException catch (e) {
      _log('SMS sending failed - Dio error: ${e.message}');
      if (e.response != null) {
        _log('Error response: ${e.response?.data}');
      }
      return {
        'success': false,
        'error': 'Network error: ${e.message}',
      };
    } catch (e) {
      _log('SMS sending failed - Unexpected error: $e');
      return {
        'success': false,
        'error': 'Unexpected error: $e',
      };
    }
  }

  // UPDATED: Check SMS delivery status using mylogin.co.in API
  Future<String> checkSmsStatus(String messageId) async {
    try {
      _log('Checking SMS status for messageId: $messageId');

      final response = await _dio.get(
        '$_smsApiBaseUrl/MessageStatus',
        queryParameters: {
          'ApiKey': _smsApiKey,
          'ClientId': _smsClientId,
          'MessageId': messageId,
        },
        options: dio.Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data;

        if (responseData['ErrorCode'] == 0) {
          final status = responseData['Data']?['Status'] ?? 'UNKNOWN';
          _log('SMS status: $status');
          return status;
        } else {
          _log('Error getting SMS status: ${responseData['ErrorDescription']}');
          return 'ERROR';
        }
      } else {
        _log('Failed to get SMS status: Status ${response.statusCode}');
        return 'FAILED';
      }
    } catch (e) {
      _log('Error checking SMS status: $e');
      return 'ERROR';
    }
  }

  // UPDATED: Get SMS history using mylogin.co.in API
  Future<List<Map<String, dynamic>>> getSmsHistory({
    int start = 0,
    int length = 50,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      _log('Fetching SMS history');

      Map<String, dynamic> queryParams = {
        'ApiKey': _smsApiKey,
        'ClientId': _smsClientId,
        'start': start.toString(),
        'length': length.toString(),
      };

      if (fromDate != null) queryParams['fromdate'] = fromDate;
      if (toDate != null) queryParams['enddate'] = toDate;

      final response = await _dio.get(
        '$_smsApiBaseUrl/SMS',
        queryParameters: queryParams,
        options: dio.Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data;

        if (responseData['ErrorCode'] == 0) {
          final messages = responseData['Data']?['messages'] as List? ?? [];
          _log('Retrieved ${messages.length} SMS records');
          return messages.cast<Map<String, dynamic>>();
        } else {
          _log('Error getting SMS history: ${responseData['ErrorDescription']}');
          return [];
        }
      } else {
        _log('Failed to get SMS history: Status ${response.statusCode}');
        return [];
      }
    } catch (e) {
      _log('Error fetching SMS history: $e');
      return [];
    }
  }

  // UPDATED: Send OTP Method with improved error handling
  Future<dio.Response> sendOtp(String phoneNumber) async {
    try {
      _log('Initiating OTP send process for: $phoneNumber');

      // Generate OTP
      final otp = generateOTP();
      _log('Generated OTP: $otp'); // Remove this in production

      // Store OTP with expiry time (5 minutes)
      final otpData = {
        'otp': otp,
        'phoneNumber': phoneNumber,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'expiresAt': DateTime.now().add(const Duration(minutes: 5)).millisecondsSinceEpoch,
        'messageId': null, // Will be updated after SMS is sent
      };

      await box.write('currentOtpData', otpData);
      _log('OTP data stored locally');

      // Send OTP via SMS
      final smsResult = await sendOtpViaSms(phoneNumber, otp);

      if (smsResult['success'] == true) {
        _log('OTP sent successfully via SMS');

        // Update stored OTP data with messageId for status tracking
        if (smsResult['messageId'] != null) {
          otpData['messageId'] = smsResult['messageId'];
          await box.write('currentOtpData', otpData);
        }

        // Create a mock response for consistency
        final response = dio.Response(
          requestOptions: dio.RequestOptions(path: ''),
          statusCode: 200,
          data: {
            'success': true,
            'message': 'OTP sent successfully',
            'data': {
              'phoneNumber': phoneNumber,
              'otpSent': true,
              'messageId': smsResult['messageId'],
            },
          },
        );

        return response;
      } else {
        throw LoginServiceException('Failed to send OTP via SMS: ${smsResult['error']}');
      }

    } catch (e) {
      _log('Error in sendOtp: $e');
      if (e is LoginServiceException) {
        rethrow;
      }
      throw LoginServiceException('Failed to send OTP: $e');
    }
  }

  // UPDATED: Verify OTP Method with SMS status checking
  Future<dio.Response> verifyOtp(String phoneNumber, String enteredOtp) async {
    try {
      _log('Verifying OTP for: $phoneNumber');

      // Get stored OTP data
      final otpData = box.read('currentOtpData');

      if (otpData == null) {
        throw LoginServiceException('No OTP found. Please request a new OTP.');
      }

      final storedOtp = otpData['otp'] as String?;
      final storedPhoneNumber = otpData['phoneNumber'] as String?;
      final expiresAt = otpData['expiresAt'] as int?;
      final messageId = otpData['messageId'] as String?;

      // Validate OTP data
      if (storedOtp == null || storedPhoneNumber == null || expiresAt == null) {
        throw LoginServiceException('Invalid OTP data. Please request a new OTP.');
      }

      // Check if OTP is expired
      if (DateTime.now().millisecondsSinceEpoch > expiresAt) {
        await box.remove('currentOtpData');
        throw LoginServiceException('OTP has expired. Please request a new OTP.');
      }

      // Check if phone number matches
      if (storedPhoneNumber != phoneNumber) {
        throw LoginServiceException('Phone number mismatch. Please request a new OTP.');
      }

      // Optional: Check SMS delivery status before verifying
      if (messageId != null) {
        final smsStatus = await checkSmsStatus(messageId);
        _log('SMS delivery status: $smsStatus');
      }

      // Verify OTP
      if (storedOtp == enteredOtp) {
        _log('OTP verified successfully');

        // Clear OTP data after successful verification
        await box.remove('currentOtpData');

        // Now proceed with actual login to get tokens
        final loginResponse = await login(phoneNumber);

        _log('Login completed after OTP verification');
        return loginResponse;

      } else {
        throw LoginServiceException('Invalid OTP. Please check and try again.');
      }

    } catch (e) {
      _log('Error in verifyOtp: $e');
      if (e is LoginServiceException) {
        rethrow;
      }
      throw LoginServiceException('OTP verification failed: $e');
    }
  }

  // UPDATED: Enhanced OTP status with SMS tracking
  Map<String, dynamic> getOtpStatus() {
    final otpData = box.read('currentOtpData');

    if (otpData == null) {
      return {
        'hasOtp': false,
        'isExpired': true,
        'phoneNumber': null,
        'timeRemaining': 0,
        'messageId': null,
      };
    }

    final expiresAt = otpData['expiresAt'] as int;
    final now = DateTime.now().millisecondsSinceEpoch;
    final isExpired = now > expiresAt;
    final timeRemaining = isExpired ? 0 : ((expiresAt - now) / 1000).round();

    return {
      'hasOtp': true,
      'isExpired': isExpired,
      'phoneNumber': otpData['phoneNumber'],
      'timeRemaining': timeRemaining,
      'messageId': otpData['messageId'],
      'expiresAt': DateTime.fromMillisecondsSinceEpoch(expiresAt).toIso8601String(),
    };
  }

  // ADD: Method to check current OTP SMS status
  Future<String> getCurrentOtpSmsStatus() async {
    final otpData = box.read('currentOtpData');
    if (otpData == null || otpData['messageId'] == null) {
      return 'NO_OTP';
    }

    return await checkSmsStatus(otpData['messageId']);
  }

  // Resend OTP Method
  Future<dio.Response> resendOtp(String phoneNumber) async {
    try {
      _log('Resending OTP for: $phoneNumber');

      // Clear existing OTP data
      await box.remove('currentOtpData');

      // Send new OTP
      return await sendOtp(phoneNumber);

    } catch (e) {
      _log('Error in resendOtp: $e');
      throw LoginServiceException('Failed to resend OTP: $e');
    }
  }

  // Clear OTP data
  Future<void> clearOtpData() async {
    await box.remove('currentOtpData');
    _log('OTP data cleared');
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

        // Store tokens and creation time from login response
        if (response.data['data']?['accessToken'] != null) {
          await box.write('accessToken', response.data['data']['accessToken']);
        }
        if (response.data['data']?['refreshToken'] != null) {
          await box.write('refreshToken', response.data['data']['refreshToken']);
        }

        // Store token creation time for automatic refresh scheduling
        await box.write('tokenCreationTime', DateTime.now().millisecondsSinceEpoch);

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
      // Enhanced: Clear all token-related data including OTP
      _clearAllTokenData();
    }
  }

  // Comprehensive token data clearing (updated to include OTP data)
  void _clearAllTokenData() {
    box.remove('accessToken');
    box.remove('refreshToken');
    box.remove('tokenCreationTime');
    box.remove('accessTokenExpiry');
    box.remove('user');
    box.remove('cartId');
    box.remove('currentOtpData'); // Clear OTP data on logout
    _log('All authentication and user data cleared locally.');
  }

  // Enhanced: refreshToken method with proper token storage
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

        if (response.data['data']?['accessToken'] != null) {
          await box.write('accessToken', response.data['data']['accessToken']);
          _log('New access token stored successfully');
        }

        if (response.data['data']?['refreshToken'] != null) {
          await box.write('refreshToken', response.data['data']['refreshToken']);
          _log('New refresh token stored successfully');
        }

        await box.write('tokenCreationTime', DateTime.now().millisecondsSinceEpoch);

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

        if (statusCode == 401) {
          _clearAllTokenData();
          throw LoginServiceException('Refresh token expired. Please log in again.', statusCode: statusCode);
        } else if (statusCode == 403) {
          _clearAllTokenData();
          throw LoginServiceException('Access denied. Please log in again.', statusCode: statusCode);
        } else {
          throw LoginServiceException(errorMessage, statusCode: statusCode);
        }
      } else {
        _log('Network error during token refresh: ${e.message}');
        throw LoginServiceException('Network error during token refresh: ${e.message}');
      }
    } catch (e) {
      _log('Unexpected error during token refresh: $e');
      throw LoginServiceException('An unexpected error occurred during token refresh: $e');
    }
  }

  // Automatic token refresh method for 12-hour intervals
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

  // Check if token needs refresh - Changed to 12 hours
  bool needsTokenRefresh() {
    return getTokenAgeInHours() >= 12.0; // Refresh after 12 hours
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

  // Get token status information with 12-hour refresh logic
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

  // Method to get a valid access token (with auto-refresh)
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

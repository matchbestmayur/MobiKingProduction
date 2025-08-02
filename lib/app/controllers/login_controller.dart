// lib/app/controllers/login_controller.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dio/dio.dart' as dio;
import 'package:mobiking/app/modules/bottombar/Bottom_bar.dart';
import '../modules/login/login_screen.dart';
import '../services/login_service.dart';
import 'package:mobiking/app/controllers/connectivity_controller.dart';

class LoginController extends GetxController {
  final LoginService loginService = Get.find<LoginService>();
  final TextEditingController phoneController = TextEditingController();
  final box = GetStorage();
  RxBool isLoading = false.obs;

  // ADD: OTP related observables
  RxBool isOtpLoading = false.obs;
  RxBool isResendingOtp = false.obs;
  RxInt otpTimeRemaining = 0.obs;
  RxString currentOtpPhoneNumber = ''.obs;
  Timer? _otpTimer;

  Rx<Map<String, dynamic>?> currentUser = Rx<Map<String, dynamic>?>(null);

  final ConnectivityController _connectivityController = Get.find<ConnectivityController>();

  // ✅ Timer for automatic token refresh
  Timer? _tokenRefreshTimer;
  static const Duration _refreshInterval = Duration(hours: 20); // 20 hours
  static const Duration _tokenValidityPeriod = Duration(hours: 24); // 24 hours

  @override
  void onInit() {
    super.onInit();
    _loadCurrentUserFromStorage();
    checkLoginStatus();
    _startTokenRefreshTimer(); // ✅ Start automatic refresh timer
    _checkOtpStatus(); // ADD: Check OTP status on init

    ever(_connectivityController.isConnected, (bool isConnected) {
      if (isConnected) {
        _handleConnectionRestored();
      }
    });
  }

  @override
  void onClose() {
    phoneController.dispose();
    _tokenRefreshTimer?.cancel(); // ✅ Cancel timer on controller close
    _otpTimer?.cancel(); // ADD: Cancel OTP timer
    super.onClose();
  }

  // ADD: Check OTP status on controller init
  void _checkOtpStatus() {
    final otpStatus = loginService.getOtpStatus();
    if (otpStatus['hasOtp'] && !otpStatus['isExpired']) {
      currentOtpPhoneNumber.value = otpStatus['phoneNumber'] ?? '';
      otpTimeRemaining.value = otpStatus['timeRemaining'] ?? 0;
      _startOtpTimer();
    }
  }

  // ADD: Start OTP countdown timer
  void _startOtpTimer() {
    _otpTimer?.cancel();

    if (otpTimeRemaining.value <= 0) return;

    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (otpTimeRemaining.value > 0) {
        otpTimeRemaining.value--;
      } else {
        timer.cancel();
        _otpTimer = null;
      }
    });
  }

  // ADD: Send OTP method
  Future<bool> sendOtp(String phoneNumber) async {
    if (isOtpLoading.value) return false;

    isOtpLoading.value = true;
    try {
      print('LoginController: Sending OTP to $phoneNumber');

      final response = await loginService.sendOtp(phoneNumber);

      if (response.statusCode == 200 && response.data['success'] == true) {
        currentOtpPhoneNumber.value = phoneNumber;
        otpTimeRemaining.value = 300; // 5 minutes in seconds
        _startOtpTimer();

        Get.snackbar(
          'OTP Sent',
          'Verification code sent to $phoneNumber',
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Colors.white,
          icon: const Icon(Icons.check_circle_outline, color: Colors.white),
          duration: const Duration(seconds: 3),
        );

        print('LoginController: OTP sent successfully');
        return true;
      } else {
        throw Exception(response.data?['message'] ?? 'Failed to send OTP');
      }
    } catch (e) {
      print('LoginController: Error sending OTP: $e');

      Get.snackbar(
        'Error',
        'Failed to send OTP: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.error_outline, color: Colors.white),
        duration: const Duration(seconds: 4),
      );

      return false;
    } finally {
      isOtpLoading.value = false;
    }
  }

  // ADD: Verify OTP method
  Future<bool> verifyOtp(String phoneNumber, String otpCode) async {
    if (isOtpLoading.value) return false;

    isOtpLoading.value = true;
    try {
      print('LoginController: Verifying OTP for $phoneNumber');

      final response = await loginService.verifyOtp(phoneNumber, otpCode);

      if (response.statusCode == 200 && response.data['success'] == true) {
        // OTP verification successful - user is now logged in
        final responseData = response.data['data'];
        final user = responseData['user'];
        final accessToken = responseData['accessToken'];
        final refreshToken = responseData['refreshToken'];
        final Map<String, dynamic>? cart = user?['cart'];
        String? cartId = cart?['_id'];

        // Store tokens and user data
        await box.write('accessToken', accessToken);
        await box.write('refreshToken', refreshToken);
        await box.write('user', user);
        await box.write('cartId', cartId);
        await box.write('tokenCreationTime', DateTime.now().millisecondsSinceEpoch);

        currentUser.value = user;

        // Clear OTP related data
        _clearOtpData();

        // Start automatic token refresh timer
        _startTokenRefreshTimer();

        print('LoginController: OTP verified and user logged in successfully');
        print('Access Token: ${box.read('accessToken')}');
        print('User data: ${box.read('user')}');
        print('Cart ID: ${box.read('cartId')}');

        Get.snackbar(
          'Success',
          'Phone number verified successfully!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          icon: const Icon(Icons.check_circle, color: Colors.white),
          duration: const Duration(seconds: 2),
        );

        // Navigate to main app
        Get.offAll(() => MainContainerScreen());
        return true;
      } else {
        throw Exception(response.data?['message'] ?? 'OTP verification failed');
      }
    } catch (e) {
      print('LoginController: Error verifying OTP: $e');

      String errorMessage = 'OTP verification failed';
      if (e.toString().contains('expired')) {
        errorMessage = 'OTP has expired. Please request a new one.';
      } else if (e.toString().contains('Invalid OTP')) {
        errorMessage = 'Invalid OTP. Please check and try again.';
      }

      Get.snackbar(
        'Verification Failed',
        errorMessage,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.error_outline, color: Colors.white),
        duration: const Duration(seconds: 4),
      );

      return false;
    } finally {
      isOtpLoading.value = false;
    }
  }

  // ADD: Resend OTP method
  Future<bool> resendOtp() async {
    if (isResendingOtp.value || currentOtpPhoneNumber.value.isEmpty) return false;

    isResendingOtp.value = true;
    try {
      print('LoginController: Resending OTP to ${currentOtpPhoneNumber.value}');

      final response = await loginService.resendOtp(currentOtpPhoneNumber.value);

      if (response.statusCode == 200 && response.data['success'] == true) {
        otpTimeRemaining.value = 300; // Reset to 5 minutes
        _startOtpTimer();

        Get.snackbar(
          'OTP Resent',
          'New verification code sent to ${currentOtpPhoneNumber.value}',
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Colors.white,
          icon: const Icon(Icons.refresh, color: Colors.white),
          duration: const Duration(seconds: 3),
        );

        print('LoginController: OTP resent successfully');
        return true;
      } else {
        throw Exception(response.data?['message'] ?? 'Failed to resend OTP');
      }
    } catch (e) {
      print('LoginController: Error resending OTP: $e');

      Get.snackbar(
        'Error',
        'Failed to resend OTP: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.error_outline, color: Colors.white),
        duration: const Duration(seconds: 4),
      );

      return false;
    } finally {
      isResendingOtp.value = false;
    }
  }

  // ADD: Clear OTP related data
  void _clearOtpData() {
    _otpTimer?.cancel();
    _otpTimer = null;
    otpTimeRemaining.value = 0;
    currentOtpPhoneNumber.value = '';
    loginService.clearOtpData();
  }

  // ADD: Get OTP status
  Map<String, dynamic> getOtpStatus() {
    return loginService.getOtpStatus();
  }

  // ADD: Check if OTP can be resent
  bool canResendOtp() {
    return otpTimeRemaining.value == 0 && !isResendingOtp.value;
  }

  // ADD: Format time remaining for display
  String getFormattedTimeRemaining() {
    final minutes = (otpTimeRemaining.value / 60).floor();
    final seconds = otpTimeRemaining.value % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _handleConnectionRestored() async {
    print('LoginController: Internet connection restored. Attempting to refresh user data/session...');
    if (currentUser.value != null && box.read('accessToken') != null) {
      try {
        // Check if token needs refresh when connection is restored
        await _checkAndRefreshTokenIfNeeded();
        print('LoginController: User session or data re-validated/refreshed successfully.');
      } catch (e) {
        print('LoginController: Failed to refresh user data/session on reconnect: $e');
      }
    }
  }

  void _loadCurrentUserFromStorage() {
    final storedUser = box.read('user');
    if (storedUser != null && storedUser is Map<String, dynamic>) {
      currentUser.value = storedUser;
    } else {
      currentUser.value = null;
    }
  }

  /// ✅ Enhanced: Check token validity and refresh if needed
  void checkLoginStatus() async {
    final accessToken = box.read('accessToken');
    final refreshToken = box.read('refreshToken');
    final tokenCreationTime = box.read('tokenCreationTime');

    if (accessToken != null && refreshToken != null && tokenCreationTime != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final tokenAge = now - tokenCreationTime;
      final tokenAgeHours = tokenAge / (1000 * 60 * 60); // Convert to hours

      if (tokenAgeHours >= 24) {
        print('LoginController: Token expired (${tokenAgeHours.toStringAsFixed(1)} hours old). Logging out...');
        _clearLoginData();
      } else if (tokenAgeHours >= 20) {
        print('LoginController: Token needs refresh (${tokenAgeHours.toStringAsFixed(1)} hours old). Refreshing...');
        await _refreshToken();
      } else {
        print('LoginController: Access token is valid (${tokenAgeHours.toStringAsFixed(1)} hours old).');
      }
    } else {
      print('LoginController: No access token, refresh token, or creation time found.');
    }
  }

  /// ✅ New: Start automatic token refresh timer
  void _startTokenRefreshTimer() {
    _tokenRefreshTimer?.cancel(); // Cancel existing timer if any

    final tokenCreationTime = box.read('tokenCreationTime');
    if (tokenCreationTime == null || box.read('accessToken') == null) {
      return; // No token to refresh
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final tokenAge = now - tokenCreationTime;
    final nextRefreshTime = _refreshInterval.inMilliseconds - tokenAge;

    if (nextRefreshTime <= 0) {
      // Token should be refreshed immediately
      _refreshToken();
      return;
    }

    print('LoginController: Next token refresh scheduled in ${(nextRefreshTime / (1000 * 60 * 60)).toStringAsFixed(1)} hours');

    _tokenRefreshTimer = Timer(Duration(milliseconds: nextRefreshTime.toInt()), () {
      _refreshToken();
    });
  }

  /// ✅ New: Check and refresh token if needed
  Future<void> _checkAndRefreshTokenIfNeeded() async {
    final tokenCreationTime = box.read('tokenCreationTime');
    if (tokenCreationTime == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final tokenAge = now - tokenCreationTime;
    final tokenAgeHours = tokenAge / (1000 * 60 * 60);

    if (tokenAgeHours >= 20) {
      await _refreshToken();
    }
  }

  /// ✅ New: Refresh access token using refresh token
  Future<void> _refreshToken() async {
    final refreshToken = box.read('refreshToken');
    if (refreshToken == null) {
      print('LoginController: No refresh token available. Logging out...');
      _clearLoginData();
      return;
    }

    try {
      print('LoginController: Refreshing access token...');

      // Call your refresh token API endpoint
      dio.Response response = await loginService.refreshToken(refreshToken);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final responseData = response.data['data'];
        final newAccessToken = responseData['accessToken'];
        final newRefreshToken = responseData['refreshToken']; // Some APIs provide new refresh token
        final updatedUser = responseData['user']; // Some APIs provide updated user data

        // Store new tokens
        await box.write('accessToken', newAccessToken);
        await box.write('tokenCreationTime', DateTime.now().millisecondsSinceEpoch);

        if (newRefreshToken != null) {
          await box.write('refreshToken', newRefreshToken);
        }

        if (updatedUser != null) {
          await box.write('user', updatedUser);
          currentUser.value = updatedUser;
        }

        print('LoginController: Token refreshed successfully');

        // Restart the timer for next refresh
        _startTokenRefreshTimer();

      } else {
        print('LoginController: Token refresh failed. Response: ${response.data}');
        _clearLoginData();
        Get.offAll(() => PhoneAuthScreen());
      }
    } catch (e) {
      print('LoginController: Token refresh error: $e');

      // If refresh fails, try one more time after a delay
      if (e is dio.DioException && e.response?.statusCode == 401) {
        print('LoginController: Refresh token expired. Logging out...');
        _clearLoginData();
        Get.offAll(() => PhoneAuthScreen());
      } else {
        // Network error - retry after 5 minutes
        print('LoginController: Network error during refresh. Retrying in 5 minutes...');
        Timer(const Duration(minutes: 5), () => _refreshToken());
      }
    }
  }

  /// ✅ Enhanced: Clear login data and cancel timers
  void _clearLoginData() {
    _tokenRefreshTimer?.cancel();
    _clearOtpData(); // ADD: Clear OTP data as well
    box.remove('accessToken');
    box.remove('refreshToken');
    box.remove('user');
    box.remove('cartId');
    box.remove('tokenCreationTime');
    currentUser.value = null;
  }

  dynamic getUserData(String key) {
    if (currentUser.value != null && currentUser.value!.containsKey(key)) {
      return currentUser.value![key];
    }
    return null;
  }

  /// UPDATED: Login method now just sends OTP instead of direct login
  Future<void> login() async {
    String phone = phoneController.text.trim();
    if (phone.isEmpty) {
      Get.snackbar(
        'Invalid Input',
        'Please enter a valid phone number',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Validate phone number format
    if (phone.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(phone)) {
      Get.snackbar(
        'Invalid Phone Number',
        'Please enter a valid 10-digit phone number',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Send OTP instead of direct login
    await sendOtp(phone);
  }

  Future<void> logout() async {
    isLoading.value = true;
    try {
      dio.Response response = await loginService.logout();

      if (response.statusCode == 200 && response.data['success'] == true) {
        _clearLoginData(); // This will also cancel the timers and clear OTP data
        Get.snackbar(
          'Logged Out',
          'You have been logged out successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        Get.offAll(() => PhoneAuthScreen());
      } else {
        Get.snackbar(
          'Logout Failed',
          'Failed to logout. Please try again.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Logout failed: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      print('Logout Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// ✅ New: Manual token refresh method (if needed)
  Future<void> manualRefreshToken() async {
    if (isLoading.value) return; // Prevent multiple simultaneous refresh attempts

    isLoading.value = true;
    try {
      await _refreshToken();
    } finally {
      isLoading.value = false;
    }
  }

  /// ✅ New: Get token status information
  Map<String, dynamic> getTokenStatus() {
    final tokenCreationTime = box.read('tokenCreationTime');
    final accessToken = box.read('accessToken');

    if (tokenCreationTime == null || accessToken == null) {
      return {
        'hasToken': false,
        'ageHours': 0,
        'needsRefresh': false,
        'isExpired': true,
      };
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final tokenAge = now - tokenCreationTime;
    final tokenAgeHours = tokenAge / (1000 * 60 * 60);

    return {
      'hasToken': true,
      'ageHours': tokenAgeHours,
      'needsRefresh': tokenAgeHours >= 20,
      'isExpired': tokenAgeHours >= 24,
    };
  }
}

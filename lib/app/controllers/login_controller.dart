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
    super.onClose();
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

  /// ✅ Enhanced: Clear login data and cancel timer
  void _clearLoginData() {
    _tokenRefreshTimer?.cancel();
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

  /// ✅ Enhanced: Store token creation time on login
  Future<void> login() async {
    String phone = phoneController.text.trim();
    if (phone.isEmpty) {
      // Get.snackbar(...)
      return;
    }

    isLoading.value = true;
    try {
      dio.Response response = await loginService.login(phone);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final responseData = response.data['data'];
        final user = responseData['user'];
        final accessToken = responseData['accessToken'];
        final refreshToken = responseData['refreshToken'];
        final Map<String, dynamic>? cart = user?['cart'];
        String? cartId = cart?['_id'];

        // Store tokens and creation time
        await box.write('accessToken', accessToken);
        await box.write('refreshToken', refreshToken);
        await box.write('user', user);
        await box.write('cartId', cartId);
        await box.write('tokenCreationTime', DateTime.now().millisecondsSinceEpoch); // ✅ Store creation time

        currentUser.value = user;

        print('Access Token: ${box.read('accessToken')}');
        print('User data: ${box.read('user')}');
        print('Cart ID: ${box.read('cartId')}');
        print('User ID: ${getUserData('_id')}');

        // Start automatic token refresh timer
        _startTokenRefreshTimer();

        Get.offAll(() => MainContainerScreen());
      } else {
        // Get.snackbar(...)
      }
    } catch (e) {
      // Get.snackbar(...)
      print('Login Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    isLoading.value = true;
    try {
      dio.Response response = await loginService.logout();

      if (response.statusCode == 200 && response.data['success'] == true) {
        _clearLoginData(); // This will also cancel the timer
        // Get.snackbar(...)
        Get.offAll(() => PhoneAuthScreen());
      } else {
        // Get.snackbar(...)
      }
    } catch (e) {
      // Get.snackbar(...)
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

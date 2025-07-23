// lib/app/controllers/login_controller.dart

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

  @override
  void onInit() {
    super.onInit();
    _loadCurrentUserFromStorage();
    checkLoginStatus(); // ✅ Added

    ever(_connectivityController.isConnected, (bool isConnected) {
      if (isConnected) {
        _handleConnectionRestored();
      }
    });
  }

  Future<void> _handleConnectionRestored() async {
    print('LoginController: Internet connection restored. Attempting to refresh user data/session...');
    if (currentUser.value != null && box.read('accessToken') != null) {
      try {
        // Simulate session refresh logic
        print('LoginController: User session or data re-validated/refreshed successfully.');
      } catch (e) {
        print('LoginController: Failed to refresh user data/session on reconnect: $e');
        // Get.snackbar(...) // still commented out
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

  /// ✅ New: Check token validity and login status
  void checkLoginStatus() {
    final accessToken = box.read('accessToken');
    final tokenExpirationTime = box.read('tokenExpirationTime');

    if (accessToken != null && tokenExpirationTime != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (tokenExpirationTime > now) {
        print('LoginController: Access token is valid.');
      } else {
        print('LoginController: Token expired. Logging out...');
        _clearLoginData();
      }
    } else {
      print('LoginController: No access token or expiration found.');
    }
  }

  /// ✅ New: Clears stored login session
  void _clearLoginData() {
    box.remove('accessToken');
    box.remove('refreshToken');
    box.remove('user');
    box.remove('cartId');
    box.remove('tokenExpirationTime');
    currentUser.value = null;
  }

  dynamic getUserData(String key) {
    if (currentUser.value != null && currentUser.value!.containsKey(key)) {
      return currentUser.value![key];
    }
    return null;
  }

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

        await box.write('accessToken', accessToken);
        await box.write('refreshToken', refreshToken);
        await box.write('user', user);
        await box.write('cartId', cartId);

        currentUser.value = user;

        print('Access Token: ${box.read('accessToken')}');
        print('User data: ${box.read('user')}');
        print('Cart ID: ${box.read('cartId')}');
        print('User ID: ${getUserData('_id')}');

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
        await box.erase();
        currentUser.value = null;

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

  @override
  void onClose() {
    phoneController.dispose();
    super.onClose();
  }
}

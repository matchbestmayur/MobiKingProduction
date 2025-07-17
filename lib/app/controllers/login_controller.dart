// lib/app/controllers/login_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dio/dio.dart' as dio;
import 'package:mobiking/app/modules/bottombar/Bottom_bar.dart';

import '../modules/login/login_screen.dart'; // Ensure this path is correct for your LoginScreen
import '../services/login_service.dart';

import 'package:mobiking/app/controllers/connectivity_controller.dart'; // NEW: Import ConnectivityController

class LoginController extends GetxController {
  final LoginService loginService = Get.find<LoginService>();
  final TextEditingController phoneController = TextEditingController();
  final box = GetStorage();
  RxBool isLoading = false.obs;

  // Make the user data itself observable
  Rx<Map<String, dynamic>?> currentUser = Rx<Map<String, dynamic>?>(null);

  // NEW: Get the ConnectivityController instance
  final ConnectivityController _connectivityController = Get.find<ConnectivityController>();


  @override
  void onInit() {
    super.onInit();
    // Load user data from GetStorage when the controller is initialized
    // and set it to the observable.
    _loadCurrentUserFromStorage();

    // NEW: Listen for connectivity changes
    ever(_connectivityController.isConnected, (bool isConnected) {
      if (isConnected) {
        _handleConnectionRestored();
      }
    });
  }

  // NEW: Method to handle actions when connection is restored
  Future<void> _handleConnectionRestored() async {
    print('LoginController: Internet connection restored. Attempting to refresh user data/session...');
    // This is where you put logic to "reinitialize" or "refresh" the controller's state
    // For LoginController, this might mean:
    // 1. Re-fetching current user data to ensure it's up-to-date with the backend.
    // 2. Refreshing authentication token if it's managed separately and needs a fresh handshake.
    // 3. Silently attempting to log in again if session is based on simple token presence.

    // If there's an existing user (even if offline), try to refresh their session or data
    if (currentUser.value != null && box.read('accessToken') != null) {
      try {
        // --- IMPORTANT: Replace with your actual session/user data refresh logic ---
        // Example: If your LoginService has a method to validate/refresh the current session or fetch profile:
        // final refreshedUser = await loginService.fetchUserProfile();
        // currentUser.value = refreshedUser; // Update observable with fresh data
        print('LoginController: User session or data re-validated/refreshed successfully.');

        // Optionally, if the user was on the NoNetworkScreen and they come back online
        // and are authenticated, you might want to navigate them to the HomeDashboard
        // (though MyApp's Obx already handles the initial screen decision).
        // If they are deep in the app but lost connection, this won't change their route.
        // Get.offAll(() => HomeDashboard()); // Use with caution, might interrupt user flow.
      } catch (e) {
        print('LoginController: Failed to refresh user data/session on reconnect: $e');
        // Handle cases where re-validation fails (e.g., token expired while offline)
        // You might want to force a re-login if the session is truly invalid.
        // logout();
        Get.snackbar(
          'Session Warning',
          'Could not refresh your session. Please consider logging in again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade700,
          colorText: Colors.white,
          icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
        );
      }
    }
  }


  // New method to load user from GetStorage and update the observable
  void _loadCurrentUserFromStorage() {
    final storedUser = box.read('user');
    if (storedUser != null && storedUser is Map<String, dynamic>) {
      currentUser.value = storedUser;
    } else {
      currentUser.value = null; // No user logged in or data invalid
    }
  }

  @override
  void onClose() {
    phoneController.dispose();
    super.onClose();
  }

  /// Helper method to get a specific field from the stored user data.
  // This helper can now directly use the observable 'currentUser'
  dynamic getUserData(String key) {
    if (currentUser.value != null && currentUser.value!.containsKey(key)) {
      return currentUser.value![key];
    }
    return null;
  }

  /// Performs the user login.
  Future<void> login() async {
    String phone = phoneController.text.trim();
    if (phone.isEmpty) {
      Get.snackbar(
        'Input Required',
        'Please enter your phone number to log in.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.amber.withOpacity(0.8),
        colorText: Colors.white,
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
        margin: const EdgeInsets.all(10),
        borderRadius: 10,
        animationDuration: const Duration(milliseconds: 300),
        duration: const Duration(seconds: 2),
      );
      return;
    }

    isLoading.value = true;
    try {
      dio.Response response = await loginService.login(phone);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final responseData = response.data['data'];
        final user = responseData['user']; // This is the user object (Map)
        final accessToken = responseData['accessToken'];
        final refreshToken = responseData['refreshToken'];

        // Access the cart object from the 'user' object
        final Map<String, dynamic>? cart = user?['cart'];

        // Safely get the cart ID if the cart object exists
        String? cartId;
        if (cart != null && cart.containsKey('_id')) {
          cartId = cart['_id'];
        }

        await box.write('accessToken', accessToken);
        await box.write('refreshToken', refreshToken);
        await box.write('user', user); // Store the entire user object in GetStorage

        // Update the observable with the new user data
        currentUser.value = user; // <--- This is key for reactivity!

        // Store the extracted cartId
        await box.write('cartId', cartId);

        Get.snackbar(
          'Login Successful!',
          response.data['message'] ?? 'You have been logged in.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
          icon: const Icon(Icons.check_circle_outline, color: Colors.white),
          margin: const EdgeInsets.all(10),
          borderRadius: 10,
          animationDuration: const Duration(milliseconds: 300),
          duration: const Duration(seconds: 2),
        );

        print('Access Token: ${box.read('accessToken')}');
        print('User data: ${box.read('user')}');
        print('Cart ID: ${box.read('cartId')}');

        String? userId = getUserData('_id');
        print('User ID from helper: $userId');

        // You might want to navigate to another screen after successful login
        Get.offAll(() => MainContainerScreen()); // Example navigation to HomeDashboard

      } else {
        Get.snackbar(
          'Login Failed!',
          response.data['message'] ?? 'Please check your phone number and try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
          icon: const Icon(Icons.error_outline, color: Colors.white),
          margin: const EdgeInsets.all(10),
          borderRadius: 10,
          animationDuration: const Duration(milliseconds: 300),
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'An unexpected error occurred during login. Please try again later.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        icon: const Icon(Icons.cloud_off_outlined, color: Colors.white), // Network error icon
        margin: const EdgeInsets.all(10),
        borderRadius: 10,
        animationDuration: const Duration(milliseconds: 300),
        duration: const Duration(seconds: 3),
      );
      print('Login Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Performs the user logout.
  Future<void> logout() async {
    isLoading.value = true;
    try {
      dio.Response response = await loginService.logout();

      if (response.statusCode == 200 && response.data['success'] == true) {
        // This clears ALL stored data in GetStorage, including the cartId
        await box.erase();
        currentUser.value = null; // <--- Reset the observable on logout!

        Get.snackbar(
          'Logged Out',
          response.data['message'] ?? 'You have been successfully logged out.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
          icon: const Icon(Icons.exit_to_app, color: Colors.white),
          margin: const EdgeInsets.all(10),
          borderRadius: 10,
          animationDuration: const Duration(milliseconds: 300),
          duration: const Duration(seconds: 2),
        );

        // Navigate to the phone authentication screen and remove all previous routes
        Get.offAll(() => PhoneAuthScreen()); // Or your specific PhoneAuthScreen
      } else {
        Get.snackbar(
          'Logout Failed',
          response.data['message'] ?? 'Could not log out. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
          icon: const Icon(Icons.error_outline, color: Colors.white),
          margin: const EdgeInsets.all(10),
          borderRadius: 10,
          animationDuration: const Duration(milliseconds: 300),
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'An unexpected error occurred during logout. Please try again later.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        icon: const Icon(Icons.cloud_off_outlined, color: Colors.white),
        margin: const EdgeInsets.all(10),
        borderRadius: 10,
        animationDuration: const Duration(milliseconds: 300),
        duration: const Duration(seconds: 3),
      );
      print('Logout Error: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
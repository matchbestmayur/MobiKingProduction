import 'package:get/get.dart';
import 'package:flutter/material.dart'; // Import for Colors and Get.snackbar
import 'package:firebase_messaging/firebase_messaging.dart'; // To use AuthorizationStatus enum

// Import your FirebaseMessagingService.
// Make sure the path matches your project structure.

import '../services/firebase_messaging_service.dart';

class FcmController extends GetxController {
  // Access the singleton instance of your FCM service.
  // This service handles the direct interaction with Firebase Messaging APIs.
  final FirebaseMessagingService _firebaseMessagingService = FirebaseMessagingService();

  // Observable to store the FCM token for UI display.
  // It's initialized with a placeholder message.
  RxString fcmToken = 'Fetching token...'.obs;

  // Observable to store the notification permission status.
  // It's initialized to 'notDetermined' as a default state.
  Rx<AuthorizationStatus> notificationStatus = AuthorizationStatus.notDetermined.obs;

  @override
  void onInit() {
    super.onInit();
    // When the controller is initialized, immediately try to fetch the FCM token
    // and check the current notification permission status.
    _fetchAndDisplayFCMToken();
    _checkNotificationPermissionStatus();
  }

  /// Fetches the FCM token from the `FirebaseMessagingService`
  /// and updates the `fcmToken` observable.
  Future<void> _fetchAndDisplayFCMToken() async {
    String? token = await _firebaseMessagingService.getFCMToken();
    if (token != null) {
      fcmToken.value = token;
      print("FCM Token in FcmController: ${fcmToken.value}");
      // TODO: IMPORTANT!
      // This is the point where you would typically send this FCM token to your backend.
      // Your backend should associate this token with the currently logged-in user.
      // Example: YourApiRepository().sendFCMToken(token, currentUserId);
    } else {
      fcmToken.value = 'Token not available or permission denied.';
      print("FCM Token not available in FcmController.");
    }
  }

  /// Checks the current notification permission status from the `FirebaseMessagingService`
  /// and updates the `notificationStatus` observable.
  Future<void> _checkNotificationPermissionStatus() async {
    notificationStatus.value = await _firebaseMessagingService.getNotificationPermissionStatus();
    print("Notification Permission Status: ${notificationStatus.value}");
  }

  /// Requests notification permissions from the user via the `FirebaseMessagingService`.
  /// Updates the `notificationStatus` observable based on the user's response.
  Future<void> requestPermissions() async {
      notificationStatus.value = await _firebaseMessagingService.requestNotificationPermissions();
    if (notificationStatus.value == AuthorizationStatus.authorized) {
      // Get.snackbar(
      //   "Success",
      //   "Notification permissions granted!",
      //   snackPosition: SnackPosition.BOTTOM,
      //   backgroundColor: Colors.green,
      //   colorText: Colors.white,
      // );
      // Re-fetch token after permission, as it might become available after granting.
      _fetchAndDisplayFCMToken();
    } else {
      // Get.snackbar(
      //   "Denied",
      //   "Notification permissions denied or not determined.",
      //   snackPosition: SnackPosition.BOTTOM,
      //   backgroundColor: Colors.orange,
      //   colorText: Colors.white,
      // );
    }
  }

  /// Example method to simulate triggering a test notification.
  /// In a real application, this would involve making an API call to your backend
  /// which then uses the Firebase Admin SDK to send a test notification.
    void triggerTestNotification() {
    // Get.snackbar(
    //   "Test Notification",
    //   "Attempting to send a test notification via backend (if configured).",
    //   snackPosition: SnackPosition.BOTTOM,
    //   backgroundColor: Colors.blueAccent,
    //   colorText: Colors.white,
    // );
    // TODO: Implement actual backend call here, e.g.:
    // YourApiRepository().sendTestNotification(fcmToken.value);
  }

// You can add more methods here as your FCM management needs grow,
// such as:
// - Handling token refresh listener (though getToken() generally provides current token)
// - Unsubscribing from topics
// - Subscribing to topics
}
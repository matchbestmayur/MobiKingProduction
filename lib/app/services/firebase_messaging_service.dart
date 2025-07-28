import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:get/get.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

// Your specific imports for navigation
import 'package:mobiking/app/modules/bottombar/Bottom_bar.dart';
import 'package:mobiking/app/modules/home/home_screen.dart';
import 'package:mobiking/app/modules/orders/order_screen.dart';
import 'package:mobiking/app/themes/app_theme.dart';

class FirebaseMessagingService {
  static final FirebaseMessagingService _instance = FirebaseMessagingService._internal();

  factory FirebaseMessagingService() {
    return _instance;
  }

  FirebaseMessagingService._internal();

  late FirebaseMessaging _firebaseMessaging;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _log(String message) {
    print('[FirebaseMessagingService] $message');
  }

  Future<void> init() async {
    try {
      _firebaseMessaging = FirebaseMessaging.instance;
      await _configureFirebaseMessaging();
      _log('Firebase Messaging initialized successfully');
    } catch (e) {
      _log('Error initializing Firebase Messaging: $e');
    }
  }

  Future<void> _configureFirebaseMessaging() async {
    try {
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      _log('User granted permission: ${settings.authorizationStatus}');

      // Get the FCM token for the device
      String? token = await _firebaseMessaging.getToken();
      _log('Initial FCM Token obtained: ${token != null ? "Success" : "Failed"}');

      // Store the initial token
      if (token != null) {
        await _saveTokenToFirestore(token);
      }

      // Listen for token refreshes
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _log('FCM Token refreshed');
        _saveTokenToFirestore(newToken);
      });

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _log('Received message in foreground');
        _log('Message data: ${message.data}');

        if (message.notification != null) {
          _log('Message contained notification: ${message.notification!.title}');
          // Show notification to user (this is a positive user experience)
          Get.snackbar(
            message.notification!.title ?? "New Notification",
            message.notification!.body ?? "You have a new message.",
            snackPosition: SnackPosition.TOP,
            backgroundColor: AppColors.darkPurple,
            colorText: AppColors.white,
            duration: const Duration(seconds: 5),
          );
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _log('App opened from notification tap');
        _handleNotificationTap(jsonEncode(message.data));
      });
    } catch (e) {
      _log('Error configuring Firebase Messaging: $e');
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    String? userId; // Replace with actual user ID if you have one

    // Use a unique ID for the document
    String documentId = userId ?? token;

    try {
      await _firestore.collection('deviceTokens').doc(documentId).set(
        {
          'token': token,
          'platform': GetPlatform.isAndroid ? 'android' : (GetPlatform.isIOS ? 'ios' : 'web'),
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      _log('FCM token stored/updated successfully in Firestore for ID: $documentId');

      // Show success message for token registration (positive user feedback)
/*      Get.snackbar('Success', 'Notifications enabled successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade600,
          colorText: Colors.white);*/

    } catch (e) {
      _log('Error storing FCM token to Firestore: $e');
    }
  }

  void _handleNotificationTap(String? payload) {
    if (payload != null && payload.isNotEmpty) {
      try {
        Map<String, dynamic> data = jsonDecode(payload);
        String? screen = data['screen'];
        String? orderId = data['orderId'];

        _log('Handling notification tap for screen: $screen');

        if (screen == 'orders') {
          if (orderId != null) {
            Get.to(() => OrderHistoryScreen(), arguments: {'orderId': orderId});
          } else {
            Get.to(() => OrderHistoryScreen());
          }
        } else if (screen == 'products') {
          Get.to(() => MainContainerScreen());
        } else {
          Get.to(() => MainContainerScreen());
        }

        _log('Successfully navigated to screen: $screen');
      } catch (e) {
        _log('Error parsing notification payload: $e');
        // No error message shown to user - handled silently
      }
    } else {
      _log('Empty or null notification payload received');
    }
  }

  Future<String?> getFCMToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      _log('FCM token retrieved: ${token != null ? "Success" : "Failed"}');
      return token;
    } catch (e) {
      _log('Error getting FCM token: $e');
      return null;
    }
  }

  Future<AuthorizationStatus> getNotificationPermissionStatus() async {
    try {
      NotificationSettings settings = await _firebaseMessaging.getNotificationSettings();
      _log('Notification permission status: ${settings.authorizationStatus}');
      return settings.authorizationStatus;
    } catch (e) {
      _log('Error getting notification permission status: $e');
      return AuthorizationStatus.notDetermined;
    }
  }

  Future<AuthorizationStatus> requestNotificationPermissions() async {
    try {
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      _log('Notification permission requested: ${settings.authorizationStatus}');

      // Show success message if permissions were granted
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      /*  Get.snackbar('Success', 'Notification permissions granted!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade600,
            colorText: Colors.white);*/
      }

      return settings.authorizationStatus;
    } catch (e) {
      _log('Error requesting notification permissions: $e');
      return AuthorizationStatus.denied;
    }
  }
}

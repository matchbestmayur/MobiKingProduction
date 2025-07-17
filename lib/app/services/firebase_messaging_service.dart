import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'dart:convert';
// Import Firestore
import 'package:cloud_firestore/cloud_firestore.dart'; // Make sure you have cloud_firestore in your pubspec.yaml

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
  // Initialize Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // ADD THIS LINE

  Future<void> init() async {
    _firebaseMessaging = FirebaseMessaging.instance;
    await _configureFirebaseMessaging();
  }

  Future<void> _configureFirebaseMessaging() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');

    // Get the FCM token for the device
    String? token = await _firebaseMessaging.getToken();
    print('Initial FCM Token: $token');

    // ADD THIS BLOCK: Store the initial token
    if (token != null) {
      await _saveTokenToFirestore(token);
    }

    // ADD THIS BLOCK: Listen for token refreshes
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      print('FCM Token Refreshed: $newToken');
      _saveTokenToFirestore(newToken);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification!.title}');
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
      print('App opened from terminated state by a notification: ${message.data}');
      _handleNotificationTap(jsonEncode(message.data));
    });
  }

  // ADD THIS NEW METHOD:
  Future<void> _saveTokenToFirestore(String token) async {
    // You'll need a unique identifier for each device or user.
    // For now, let's use the token itself as the document ID, or a user ID if authenticated.
    // If you have user authentication, it's better to associate the token with the authenticated user's ID.
    String? userId; // Replace with actual user ID if you have one
    // Example: if you have a LoginController that provides current user ID
    // try {
    //   userId = Get.find<LoginController>().currentUserId;
    // } catch (e) {
    //   print("LoginController not found or user not logged in: $e");
    //   // Fallback to token or device ID if no user is logged in
    // }

    // Use a unique ID for the document. If you have user authentication,
    // use the user's ID. Otherwise, you can use the token itself or a device ID.
    // For this example, we'll use a placeholder 'guestUser' if no userId is available.
    // In a real app, ensure this ID is robustly unique for each device/user.
    String documentId = userId ?? token; // Simplistic: use token as doc ID if no user ID

    try {
      await _firestore.collection('deviceTokens').doc(documentId).set(
        {
          'token': token,
          'platform': GetPlatform.isAndroid ? 'android' : (GetPlatform.isIOS ? 'ios' : 'web'),
          'createdAt': FieldValue.serverTimestamp(), // Firestore generates timestamp on the server
        },
        SetOptions(merge: true), // Use merge: true to update existing fields without overwriting the whole document
      );
      print('FCM token stored/updated successfully in Firestore for ID: $documentId');
    } catch (e) {
      print('Error storing FCM token to Firestore: $e');
    }
  }

  void _handleNotificationTap(String? payload) {
    if (payload != null && payload.isNotEmpty) {
      try {
        Map<String, dynamic> data = jsonDecode(payload);
        String? screen = data['screen'];
        String? orderId = data['orderId'];

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
      } catch (e) {
        print('Error parsing notification payload: $e');
        Get.snackbar("Notification Error", "Could not process notification data.",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.danger,
            colorText: AppColors.white);
      }
    }
  }

  Future<String?> getFCMToken() async {
    return await _firebaseMessaging.getToken();
  }

  Future<AuthorizationStatus> getNotificationPermissionStatus() async {
    NotificationSettings settings = await _firebaseMessaging.getNotificationSettings();
    return settings.authorizationStatus;
  }

  Future<AuthorizationStatus> requestNotificationPermissions() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true, announcement: false, badge: true, carPlay: false,
      criticalAlert: false, provisional: false, sound: true,
    );
    return settings.authorizationStatus;
  }
}
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for SystemChrome and DeviceOrientation
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

// Firebase imports
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mobiking/app/controllers/product_controller.dart';
import 'package:mobiking/app/services/firebase_messaging_service.dart'; // Your FCM Service

// Correct import paths for new screens/controllers/services
// Ensure these paths are correct in your project structure
import 'package:mobiking/app/controllers/BottomNavController.dart';
import 'package:mobiking/app/controllers/address_controller.dart';
import 'package:mobiking/app/controllers/cart_controller.dart';
import 'package:mobiking/app/controllers/category_controller.dart';
import 'package:mobiking/app/controllers/order_controller.dart';
import 'package:mobiking/app/controllers/query_getx_controller.dart';
import 'package:mobiking/app/controllers/sub_category_controller.dart';
import 'package:mobiking/app/controllers/wishlist_controller.dart';
import 'package:mobiking/app/controllers/login_controller.dart';
import 'package:mobiking/app/services/AddressService.dart';
import 'package:mobiking/app/services/login_service.dart';
import 'package:mobiking/app/services/order_service.dart';
import 'package:mobiking/app/services/query_service.dart';
import 'package:mobiking/app/controllers/Home_controller.dart';
import 'package:mobiking/app/controllers/system_ui_controller.dart';
import 'package:mobiking/app/controllers/tab_controller_getx.dart';
import 'package:mobiking/app/modules/login/login_screen.dart'; // Assuming PhoneAuthScreen is here
import 'package:mobiking/app/services/Sound_Service.dart';
import 'package:mobiking/app/themes/app_theme.dart';
import 'package:mobiking/app/services/connectivity_service.dart';
import 'package:mobiking/app/controllers/connectivity_controller.dart';
import 'package:mobiking/app/modules/no_network/no_network_screen.dart';

import 'app/controllers/fcm_controller.dart';
import 'app/modules/bottombar/Bottom_bar.dart';
import 'firebase_options.dart';

// FCM Background Message Handler - MUST be a top-level function
// This handles messages when the app is in the background or terminated.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundMessagehandler(RemoteMessage message) async {
  // Ensure Firebase is initialized for background processing.
  // If you used FlutterFire CLI to generate 'firebase_options.dart',
  // uncomment the options line below and ensure it's imported.
  await Firebase.initializeApp(
    // options: DefaultFirebaseOptions.currentPlatform, // Uncomment if you have this file
  );
  print("Handling a background message: ${message.messageId}");
  print("Background message data: ${message.data}");
  // You can also show a local notification from here if desired,
  // but it would require creating a FlutterLocalNotificationsPlugin instance
  // and channel setup here again, or ensuring it's available via a service.
  // For simplicity, FirebaseMessagingService handles foreground/opened_app notifications.
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations to portrait mode only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await GetStorage.init(); // Initialize GetStorage for local storage

  // --- Firebase Initialization ---
  // This must happen before you use any Firebase services like FCM.
  // If you generated firebase_options.dart using FlutterFire CLI,
  // uncomment the options line below and ensure you import 'firebase_options.dart'.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // UNCOMMENT THIS LINE
  );

  // --- Core Services and Dependencies ---
  final dioInstance = dio.Dio(); // Single Dio instance
  final getStorageBox = GetStorage(); // Single GetStorage instance

  // Put your FirebaseMessagingService into GetX dependency injection
  // Initialize it immediately as it sets up listeners for FCM messages.
  Get.put(FirebaseMessagingService()).init(); // Call .init() immediately after putting

  // Put other services into GetX dependency injection
  Get.put(LoginService(dioInstance, getStorageBox));
  Get.put(OrderService());
  Get.put(AddressService(dioInstance, getStorageBox));
  Get.put(ConnectivityService());
  Get.put(SoundService());
  Get.put(QueryService());
  Get.put(CategoryController());

  // Controllers (in order of dependency if applicable)
  Get.put(ConnectivityController());
  Get.put(FcmController());
  Get.put(AddressController());
  Get.put(CartController());
  Get.put(HomeController());

  Get.put(SubCategoryController());
  Get.put(WishlistController());
  Get.put(LoginController());
  Get.put(TabControllerGetX());
  Get.put(SystemUiController());
  Get.put(QueryGetXController());
  Get.put(ProductController());

  // OrderController (depends on OrderService, CartController, AddressController)
  Get.put(OrderController());
  Get.put(BottomNavController());

  // You will also need to put FcmController if you want to use it
  // and its view (FcmView) in your app.
  // Get.put(FcmController()); // Uncomment this if you want to initialize FcmController globally

  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the ConnectivityController instance
    final ConnectivityController connectivityController = Get.find<ConnectivityController>();
    final LoginController loginController = Get.find<LoginController>();

    // Define your desired global padding/margin
    const EdgeInsets globalPadding = EdgeInsets.symmetric(vertical: 0); // Changed to 0 as padding usually applies inside the widget structure, not to GetMaterialApp content directly. Adjust if needed.

    return GetMaterialApp(
      title: 'Mobiking',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Obx(() {
        final isConnected = connectivityController.isConnected.value;
        final user = loginController.currentUser.value;

        Widget content;

        if (isConnected) {
          if (user != null) {
            // ✅ User is logged in and connected
            content = MainContainerScreen();
          } else {
            // ✅ Not logged in, show PhoneAuth
            content = PhoneAuthScreen();
          }
        } else {
          // ❌ No internet, show retry UI
          content = NoNetworkScreen(
            onRetry: () {
              connectivityController.retryConnection();
            },
          );
        }

        return Padding(
          padding: globalPadding,
          child: content,
        );
      }),

      // If you decide to use GetX routing (recommended), remove 'home:' and use 'initialRoute' and 'getPages'.
      // For example:
      // initialRoute: AppRoutes.LOGIN, // Assuming you have an AppRoutes class
      // getPages: AppPages.routes, // Assuming you have an AppPages class
    );
  }
}
// lib/app/modules/main_container/main_container_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobiking/app/themes/app_theme.dart';
import 'package:mobiking/app/controllers/system_ui_controller.dart';

// IMPORTANT: Ensure this import is correct based on where your CartScreen is located.
// If it was cart_bottom_dialoge.dart previously, and now it's CartScreen,
// adjust the path accordingly if needed. Assuming 'CartScreen' is now the name of the widget.

import 'package:mobiking/app/controllers/cart_controller.dart';
import 'package:mobiking/app/modules/home/widgets/FloatingCartButton.dart';

import '../../controllers/BottomNavController.dart';
import '../../widgets/CustomBottomBar.dart';
import '../cart/cart_bottom_dialoge.dart';

class MainContainerScreen extends StatefulWidget {
  const MainContainerScreen({super.key});

  @override
  State<MainContainerScreen> createState() => _MainContainerScreenState();
}

class _MainContainerScreenState extends State<MainContainerScreen> with WidgetsBindingObserver {
  final BottomNavController navController = Get.find<BottomNavController>();
  final CartController cartController = Get.find<CartController>();
  // Initialize SystemUiController here if it's the first place it's needed globally
  // or ensure it's put elsewhere (e.g., in your App's main binding)
  final SystemUIController systemUiController = Get.put(SystemUIController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize the system UI style based on the current systemUiController's value.
    // This value would have been set by BottomNavController's onInit based on selectedIndex.
    SystemChrome.setSystemUIOverlayStyle(systemUiController.currentUiStyle.value);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // When the main container disposes, revert to a clean default
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // When app resumes, reapply the *current* style from the controller
      SystemChrome.setSystemUIOverlayStyle(systemUiController.currentUiStyle.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    const double customBottomBarContentHeight = 65.0; // From CustomBottomBar
    final double bottomSafeAreaPadding = MediaQuery.of(context).padding.bottom;
    final double totalCustomBottomBarHeight = customBottomBarContentHeight + bottomSafeAreaPadding;

    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Obx(
              () => IndexedStack(
            index: navController.selectedIndex.value,
            children: navController.pages,
          ),
        ),
        bottomNavigationBar: const CustomBottomBar(),
        floatingActionButton: Obx(() {
          final currentTabIndex = navController.selectedIndex.value;
          const int profileTabIndex = 3;

          // Don't show FAB on the Profile tab
          if (currentTabIndex == profileTabIndex) {
            return const SizedBox.shrink();
          }

          // Don't show FAB if cart is empty
          final totalItemsInCart = cartController.totalCartItemsCount;
          if (totalItemsInCart == 0) {
            return const SizedBox.shrink();
          }

          // Get product images for the FAB
          final List<String> imageUrls = cartController.cartItems.take(3).map((item) {
            final product = item['productId'];
            String? imageUrl;

            if (product is Map) {
              final imagesData = product['images'];
              if (imagesData is List && imagesData.isNotEmpty) {
                final firstImage = imagesData[0];
                if (firstImage is String) {
                  imageUrl = firstImage;
                } else if (firstImage is Map) {
                  imageUrl = firstImage['url'] as String?;
                }
              } else if (imagesData is String) {
                imageUrl = imagesData;
              }
            }
            return imageUrl ?? 'https://placehold.co/50x50/cccccc/ffffff?text=No+Img';
          }).toList();

          // CORRECTED: Calculate fabBottomMargin to float above the bottom bar
          final double fabBottomMargin = 0.5 ; // 16px padding + bottom bar height

          return Container(
            margin: EdgeInsets.only(left: 16, right: 16, bottom: fabBottomMargin),
            child: FloatingCartButton(
              label: "View Cart",
              productImageUrls: imageUrls,
              itemCount: totalItemsInCart,
              onTap: () {
                // ✅ Navigate with custom transition
                Get.to(
                      () => CartScreen(),
                  transition: Transition.rightToLeft,
                  duration: const Duration(milliseconds: 300),
                );
              },
            ),
          );

        }),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
}
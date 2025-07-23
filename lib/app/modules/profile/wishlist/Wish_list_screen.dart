import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobiking/app/themes/app_theme.dart'; // Your AppColors and AppTheme

import '../../../controllers/wishlist_controller.dart';
import 'Wish_list_card.dart'; // Ensure this path is correct and it's the updated version

class WishlistScreen extends StatelessWidget {
  WishlistScreen({super.key});

  final controller = Get.find<WishlistController>();

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.neutralBackground, // Consistent background
      appBar: AppBar(
        elevation: 0.5, // Subtle elevation
        backgroundColor: AppColors.white, // White AppBar background (Blinkit style)
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark), // Dark back arrow
          onPressed: () => Get.back(),
        ),
        title: Text(
          'My Wishlist',
          style: textTheme.titleLarge?.copyWith( // Consistent title style
            fontWeight: FontWeight.w700,
            color: AppColors.textDark, // Dark text
          ),
        ),
        centerTitle: false, // Left-aligned title (more common in Blinkit)
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.primaryGreen), // Blinkit green loader
                const SizedBox(height: 16),
                Text(
                  'Loading your wishlist...',
                  style: textTheme.bodyLarge?.copyWith(color: AppColors.textMedium), // Softer text color
                ),
              ],
            ),
          );
        }

        if (controller.wishlist.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border_rounded,
                    size: 80,
                    color: AppColors.textLight.withOpacity(0.6),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Your Wishlist is Waiting!',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Add the products you love to your wishlist and keep track of them here. It’s the perfect way to save items for later!',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge?.copyWith(color: AppColors.textMedium),
                  ),
                ],
              ),
            ),
          );
        }


        // Use ListView.separated for consistent spacing with dividers if desired,
        // or just rely on item padding as implemented in WishlistCard.
        return ListView.builder(
          padding: const EdgeInsets.all(16), // Padding around the entire list
          itemCount: controller.wishlist.length,
          itemBuilder: (context, index) {
            final product = controller.wishlist[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12), // Consistent bottom padding for each card
              child: WishlistCard(
                product: product,
                onRemove: () {
                  // Show confirmation dialog before removing, good UX
                  Get.defaultDialog(
                    title: "Remove from Wishlist?",
                    middleText: "Are you sure you want to remove '${product.name}' from your wishlist?",
                    textConfirm: "Remove",
                    textCancel: "Cancel",
                    confirmTextColor: AppColors.white,
                    buttonColor: AppColors.danger,
                    cancelTextColor: AppColors.textDark,
                    onConfirm: () {
                      controller.removeFromWishlist(product.id);
                      Get.back(); // Close dialog
                    },
                  );
                },
                onAddToCart: () {
                  // TODO: Implement actual add to cart logic
                  Get.snackbar(
                    'Added to Cart!',
                    '${product.name} has been added to your cart.',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: AppColors.primaryGreen,
                    colorText: AppColors.white,
                    margin: const EdgeInsets.all(10),
                    borderRadius: 10,
                  );
                },
              ),
            );
          },
        );
      }),
    );
  }
}
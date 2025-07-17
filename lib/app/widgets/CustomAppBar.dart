import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart'; // Keep if you still need specific GoogleFonts calls outside the theme
import 'package:mobiking/app/controllers/sub_category_controller.dart';
import 'package:mobiking/app/themes/app_theme.dart';

import '../controllers/tab_controller_getx.dart';
import 'CategoryTab.dart'; // Assumed location of TabControllerGetX


class CustomAppBar extends StatelessWidget {
  CustomAppBar({super.key});

  // Ensure these controllers are initialized elsewhere (e.g., in a binding or main)
  // For a standalone snippet, you might use Get.put() if not already done.
  final tabController = Get.find<TabControllerGetX>();
  final subCategoryController = Get.find<SubCategoryController>(); // Get the CategoryController instance

  @override
  Widget build(BuildContext context) {
    // Get the TextTheme from the current context's theme
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Obx(() {
      // The backgroundImage logic is no longer used for the background itself,
      // but the selectedIndex logic might still be relevant for displaying the sub-category name.
      String? backgroundImage; // This variable will no longer be used for the background.
      final int selectedIndex = tabController.selectedIndex.value;

      // Safely attempt to get the background image from the selected sub-category
      // This block can be removed if 'backgroundImage' is not used for anything else.
      if (selectedIndex >= 0 && selectedIndex < subCategoryController.subCategories.length) {
        final currentSubCategory = subCategoryController.subCategories[selectedIndex];
        // Ensure upperBanner is not null or empty before trying to use it
        if (currentSubCategory.upperBanner != null && currentSubCategory.upperBanner!.isNotEmpty) {
          backgroundImage = currentSubCategory.upperBanner;
        }
      }

      return Container(
        padding: const EdgeInsets.only(top: 15),
        height: 80, // Give it a fixed height or use media query for responsiveness
        decoration: const BoxDecoration( // Changed to const as color is now fixed
          color: Colors.transparent, // MADE TRANSPARENT
          // The 'image' property has been removed entirely
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end, // Align content to the bottom
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.deepPurple,
                    child: Icon(Icons.storefront, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Mobiking Wholesale",
                          // Use a text style from your theme for main app bar title
                          style: textTheme.titleMedium?.copyWith(
                            color: Colors.black, // Changed to black for better visibility on a transparent background
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          // Display the name of the currently selected sub-category
                          selectedIndex >= 0 && selectedIndex < subCategoryController.subCategories.length
                              ? subCategoryController.subCategories[selectedIndex].name
                              : 'Select Category', // Default text if no category selected
                          // Use a smaller text style from your theme
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.black54, // Changed to darker color for better visibility
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobiking/app/data/sub_category_model.dart'; // Make sure this path is correct
import 'package:mobiking/app/modules/Categories/widgets/CategoryTile.dart';
import 'package:mobiking/app/themes/app_theme.dart';
import 'package:mobiking/app/modules/Product_page/product_page.dart';

import '../../home/widgets/AllProductsGridView.dart'; // If you want to navigate to products from subcategories

// You might still need Category if you want to display its name in the app bar
// import 'package:mobiking/app/data/Home_model.dart'; // Assuming your Category model is here

class CategoryProductsScreen extends StatelessWidget {
  final String categoryName; // To display the parent category name in the AppBar
  final List<SubCategory> subCategories; // Pass the list of subcategories

  const CategoryProductsScreen({
    super.key,
    required this.categoryName,
    required this.subCategories,
  });

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.neutralBackground,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textDark,
        elevation: 1,
        centerTitle: true,
        title: Text(
          categoryName, // Use the passed categoryName
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: subCategories.isEmpty
          ? _buildEmptyState(context)
          : GridView.builder(
        padding: const EdgeInsets.all(12.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // Display 3 columns for subcategories
          crossAxisSpacing: 12.0,
          mainAxisSpacing: 16.0,
          childAspectRatio: 0.75, // Adjust as needed for CategoryTile
        ),
        itemCount: subCategories.length,
        itemBuilder: (context, index) {
          final subCategory = subCategories[index];
          final String imageUrl = (subCategory.photos?.isNotEmpty ?? false)
              ? subCategory.photos![0]
              : "https://via.placeholder.com/150x150/E0E0E0/A0A0A0?text=No+Image";

          return CategoryTile(
            title: subCategory.name ?? 'Unknown Subcategory',
            imageUrl: imageUrl,
            onTap: () {
              // Check if subCategory.products is not null and not empty
              if (subCategory.products != null && subCategory.products!.isNotEmpty) {
                print('Products in ${subCategory.name}:');
                for (var product in subCategory.products!) {
                  print('- ${product.name}'); // Assuming your ProductModel has a 'name' field
                }
              } else {
                print('No products found for ${subCategory.name}');
              }

              Get.bottomSheet(
                // Wrap AllProductsGridView in a Container or ClipRRect
                // to give it rounded corners and a background, typical for bottom sheets
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16.0)),
                  child: Container(
                    color: AppColors.neutralBackground, // Or AppColors.white
                    height: Get.height * 0.85, // Occupy 85% of screen height
                    padding: EdgeInsets.only(top: 20),
                    child: AllProductsGridView(
                      showTitle: false,
                      products: subCategory.products!,

                      // Adjust padding if needed, or remove as AllProductsGridView has internal padding
                      // horizontalPadding: 0, // Set to 0 if AllProductsGridView handles its own padding
                    ),
                  ),
                ),
                isScrollControlled: true, // Allows the bottom sheet to take more than half screen
                // Optionally set background color
                backgroundColor: Colors.transparent, // Let the inner Container define the color
                enableDrag: true, // Allow user to drag down to close
              );
            },
          );
        },
      ),
    );
  }

  // --- Empty State ---
  Widget _buildEmptyState(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 80, color: AppColors.textLight.withOpacity(0.6)),
            const SizedBox(height: 16),
            Text(
              'No subcategories available in "$categoryName".',
              style: textTheme.headlineSmall?.copyWith(
                color: AppColors.textMedium,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please check back later or select another category!',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.arrow_back, color: AppColors.white),
              label: Text('Go Back', style: textTheme.labelLarge?.copyWith(color: AppColors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
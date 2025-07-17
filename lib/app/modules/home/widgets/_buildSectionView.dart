import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart'; // Keep if used for specific text styles, otherwise remove
import 'package:mobiking/app/modules/Product_page/product_page.dart';
import 'package:mobiking/app/modules/home/widgets/sub_category_screen.dart';
import 'package:mobiking/app/widgets/group_grid_section.dart'; // Assuming this widget exists and is uniform internally
import '../../../controllers/product_controller.dart';
import '../../../data/group_model.dart';
import '../../../data/product_model.dart';
import '../../../data/sub_category_model.dart';
import '../../../themes/app_theme.dart';
import '../../../widgets/buildProductList.dart'; // Assuming this widget exists and is uniform internally
import 'AllProductsGridView.dart';
import 'ProductCard.dart'; // Assuming this widget exists and provides ProductCard or similar
// import 'ProductBottomSheetContent.dart'; // No longer needed
// import 'sub_category_screen.dart'; // Keep if used elsewhere

// In your _buildSectionView.dart file

import 'package:flutter/material.dart';
import 'package:get/get.dart';
// ... other imports

Widget buildSectionView({
  required String bannerImageUrl,
  required List<SubCategory> subCategories,
  required List<SubCategory>? categoryGridItems,
  required List<GroupModel> groups,
  required int index,
  required ProductController productController,
}) {
  const double horizontalPadding = 16.0;

  return Builder(builder: (context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    // ✨ REINTRODUCE SingleChildScrollView HERE ✨
    return SingleChildScrollView(
      // It's crucial for buildSectionView to be scrollable if its content
      // can exceed the screen height.
      // The parent SliverToBoxAdapter in HomeScreen provides unbounded constraints,
      // and this SingleChildScrollView correctly consumes them.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Unified Category Banner
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            child: Container(
              height: 160,
              width: double.infinity,
              child: Image.network(
                bannerImageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accentNeon.withOpacity(0.7),
                      strokeWidth: 2,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.neutralBackground,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image, color: AppColors.textLight, size: 40),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Product Horizontal Scroll Section (Top Picks for You)
          if (subCategories.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Text(
                "Top Picks for You",
                style: textTheme.titleLarge?.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
            // AllProductsListView must have shrinkWrap: true and NeverScrollableScrollPhysics() internally
            AllProductsListView(
              subCategoryIndex: index,
              subCategories: subCategories,
              onProductTap: (product) {
                final String productHeroTag =
                    'product_image_sub_category_${product.id}';
                Get.to(
                      () => ProductPage(
                    product: product,
                    heroTag: productHeroTag,
                  ),
                );
              },
            ),
          ],

          // Group Sections with Products
          if (groups.isNotEmpty) ...[
            // GroupWithProductsSection must also handle its internal scrollable widgets (if any)
            // with shrinkWrap: true and NeverScrollableScrollPhysics()
            GroupWithProductsSection(groups: groups),
          ],
          Obx(() {
            final products = productController.allProducts;

            if (productController.isLoading.value && products.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: CircularProgressIndicator(),
                ),
              );
            } else if (products.isEmpty && !productController.isLoading.value) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text('No products available right now.'),
                ),
              );
            } else {
              // AllProductsGridView must have shrinkWrap: true and NeverScrollableScrollPhysics() internally
              return AllProductsGridView(products: products);
            }
          }),

          // Load More Products Button
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Obx(() {
                if (productController.isFetchingMore.value) {
                  return const CircularProgressIndicator();
                } else if (productController.hasMoreProducts.value) {
                  return ElevatedButton(
                    onPressed: productController.fetchMoreProducts,
                    child: Text("Load More"),
                  );
                } else {
                  return const Text("No more products");
                }
              }),
            ),
          ),
          // Bottom spacing
          const SizedBox(height: 32),
        ],
      ),
    );
  });
}
// showProductBottomSheet is commented out as it's no longer used
/*
void showProductBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.92,
      child: const ProductBottomSheetContent(),
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
  );
}
*/
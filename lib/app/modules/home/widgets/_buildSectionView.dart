import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobiking/app/modules/Product_page/product_page.dart';
import 'package:mobiking/app/modules/home/widgets/sub_category_screen.dart';
import 'package:mobiking/app/widgets/group_grid_section.dart';
import '../../../controllers/product_controller.dart';
import '../../../data/group_model.dart';
import '../../../data/sub_category_model.dart';
import '../../../themes/app_theme.dart';
import '../../../widgets/buildProductList.dart';
import 'AllProductsGridView.dart';

Widget buildSectionView({
  required String bannerImageUrl,
  required List<SubCategory> subCategories,
  required List<SubCategory>? categoryGridItems,
  required List<GroupModel> groups,
  required int index,
  required ProductController productController,
}) {
  const double horizontalPadding = 12.0;

  return Builder(builder: (context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔰 Banner Section
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            child: SizedBox(
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

          // 🧱 Group Sections (if available)
          if (groups.isNotEmpty) GroupWithProductsSection(groups: groups),

          // 📦 Products Grid Section
          Obx(() {
            final products = productController.allProducts;
            final isLoading = productController.isLoading.value;

            if (isLoading && products.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: CircularProgressIndicator(),
                ),
              );
            } else if (products.isEmpty && !isLoading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text(
                    'We couldn’t find any items at the moment.\nPlease check back later.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            } else {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: AllProductsGridView(products: products),
              );
            }
          }),

          // 🔁 Load More Button
          Obx(() {
            if (productController.isFetchingMore.value) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Center(child: CircularProgressIndicator()),
              );
            } else if (productController.hasMoreProducts.value) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: horizontalPadding, vertical: 12),
                  child: ElevatedButton(
                    onPressed: productController.fetchMoreProducts,
                    child: const Text("Load More"),
                  ),
                ),
              );
            } else {
              return const SizedBox.shrink();
            }
          }),

          const SizedBox(height: 32),
        ],
      ),
    );
  });
}

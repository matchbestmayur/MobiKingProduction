import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:mobiking/app/modules/Categories/widgets/CategoryProductsScreen.dart';
import 'package:shimmer/shimmer.dart'; // Keep shimmer for loading effect

import '../../controllers/category_controller.dart';
import '../../controllers/sub_category_controller.dart' show SubCategoryController;
import '../../themes/app_theme.dart'; // Import your AppTheme and AppColors
import 'widgets/CategoryTile.dart'; // Ensure CategoryTile is properly defined and imported

class CategorySectionScreen extends StatelessWidget {
  final CategoryController categoryController = Get.find<CategoryController>();
  final SubCategoryController subCategoryController = Get.find<SubCategoryController>();

  CategorySectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.neutralBackground,
      appBar: AppBar(
        title: Text(
          "Categories",
          style: textTheme.titleLarge?.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        backgroundColor: AppColors.white,
        elevation: 0.5,
        foregroundColor: AppColors.textDark,
        automaticallyImplyLeading: false,
      ),
      body: Obx(() {
        if (categoryController.isLoading.value) {
          return _buildLoadingState(context);
        } else {
          final allCategories = categoryController.categories;
          final availableSubCategories = subCategoryController.subCategories;

          final availableSubCatIds = availableSubCategories.map((e) => e.id).toSet();

          final filteredCategories = allCategories.where((category) {
            final subCatIdsInThisCategory = List<String>.from(category.subCategoryIds ?? []);
            return subCatIdsInThisCategory.any((id) => availableSubCatIds.contains(id));
          }).toList();

          if (filteredCategories.isEmpty) {
            return _buildEmptyState(context);
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredCategories.length,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (context, index) {
                    final category = filteredCategories[index];
                    final String title = category.name ?? "Unnamed Category";

                    final matchingSubCategories = availableSubCategories
                        .where((sub) => (category.subCategoryIds ?? []).contains(sub.id))
                        .toList();

                    if (matchingSubCategories.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section Header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                title,
                                style: textTheme.titleLarge?.copyWith(
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  // This is the CORRECTED part
                                  Get.to(() => CategoryProductsScreen(
                                    categoryName: title, // Pass the category name
                                    subCategories: matchingSubCategories, // Pass the list of matching subcategories
                                  ));
                                },

                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.success,
                                  textStyle: textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  minimumSize: Size.zero,
                                  padding: EdgeInsets.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  "See More",
                                  style: textTheme.labelLarge?.copyWith(
                                    color: AppColors.success,
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),

                        // Grid of Subcategories (3x2 max)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: matchingSubCategories.length > 6
                                ? 6
                                : matchingSubCategories.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.75,
                            ),
                            itemBuilder: (context, i) {
                              final sub = matchingSubCategories[i];
                              final image = (sub.photos?.isNotEmpty ?? false)
                                  ? sub.photos![0]
                                  : "https://via.placeholder.com/150x150/E0E0E0/A0A0A0?text=No+Image";

                              return CategoryTile(
                                title: sub.name ?? 'Unknown',
                                imageUrl: image,
                                onTap: () {
                                  // TODO: If you want to navigate to products of this *specific* sub-category,
                                  // you'll need another screen (e.g., SubCategoryDetailScreen or ProductListScreen)
                                  // and pass the sub-category ID to fetch its products.
                                  print('Tapped on sub-category: ${sub.name}');
                                  // Example: Get.to(() => ProductListScreen(subCategoryId: sub.id));
                                  // or Get.to(() => ProductsForSubCategoryScreen(subCategory: sub));
                                },
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),

                // Mobiking Branding
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Mobiking",
                        textAlign: TextAlign.left,
                        style: textTheme.displayLarge?.copyWith(
                          color: AppColors.textLight.withOpacity(0.5),
                          letterSpacing: -1.0,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Your Wholesale Partner",
                        textAlign: TextAlign.left,
                        style: textTheme.headlineSmall?.copyWith(
                          color: AppColors.textLight.withOpacity(0.6),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Buy in bulk, save big. Get the best deals on mobile phones and accessories, delivered directly to your doorstep.",
                        textAlign: TextAlign.left,
                        style: textTheme.bodyLarge?.copyWith(
                          color: AppColors.textLight.withOpacity(0.7),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      }),
    );
  }


  // --- Loading State ---
  Widget _buildLoadingState(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return ListView.builder(
      itemCount: 3, // Show 3 shimmer sections
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shimmer for section title
              Shimmer.fromColors(
                baseColor: Colors.grey[200]!, // Lighter base color
                highlightColor: Colors.grey[50]!, // Even lighter highlight
                child: Container(
                  width: 180, // Wider shimmer for title
                  height: textTheme.titleLarge?.fontSize ?? 22, // Use titleLarge font size
                  // White shimmer background
                  decoration: BoxDecoration(
                    color: AppColors.white,borderRadius: BorderRadius.circular(4),
                  ), // Slightly rounded corners
                ),
              ),
              const SizedBox(height: 16),
              // Shimmer for horizontal list
              SizedBox(
                height: 120, // Matches CategoryTile height
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 4,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    return Shimmer.fromColors(
                      baseColor: Colors.grey[200]!,
                      highlightColor: Colors.grey[50]!,
                      child: Container(
                        width: 90, // Matches CategoryTile width
                        height: 120, // Matches CategoryTile height
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(10), // Matches CategoryTile border radius
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
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
              'No categories available at the moment.',
              style: textTheme.headlineSmall?.copyWith(
                color: AppColors.textMedium, // Softer color for empty state message
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please check back later!',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => categoryController.fetchCategories(),
              icon: const Icon(Icons.refresh, color: AppColors.white),
              label: Text('Retry', style: textTheme.labelLarge?.copyWith(color: AppColors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success, // Blinkit green button
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
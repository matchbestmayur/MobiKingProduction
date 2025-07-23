import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobiking/app/modules/Categories/widgets/CategoryProductsScreen.dart';
import 'package:mobiking/app/modules/home/widgets/AllProductsGridView.dart';
import 'package:mobiking/app/modules/Categories/widgets/CategoryTile.dart';
import 'package:shimmer/shimmer.dart';

import '../../controllers/category_controller.dart';
import '../../controllers/sub_category_controller.dart';
import '../../themes/app_theme.dart';

class CategorySectionScreen extends StatelessWidget {
  final CategoryController categoryController = Get.find();
  final SubCategoryController subCategoryController = Get.find();

  CategorySectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.neutralBackground,
      appBar: AppBar(
        title: Text("Categories",
          style: textTheme.titleLarge?.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.white,
        centerTitle: false,
        elevation: 0.5,
        foregroundColor: AppColors.textDark,
        automaticallyImplyLeading: false,
      ),
      body: Obx(() {
        if (categoryController.isLoading.value) {
          return _buildLoadingState(context);
        }

        final allCategories = categoryController.categories;
        final availableSubCategories = subCategoryController.subCategories;
        final availableSubCatIds = availableSubCategories.map((e) => e.id).toSet();

        final filteredCategories = allCategories.where((cat) {
          return (cat.subCategoryIds ?? []).any(availableSubCatIds.contains);
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
                  final title = category.name ?? "Unnamed Category";

                  final matchingSubs = availableSubCategories
                      .where((sub) => (category.subCategoryIds ?? []).contains(sub.id))
                      .toList();

                  if (matchingSubs.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(title,
                              style: textTheme.titleLarge?.copyWith(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextButton(
                              onPressed: () => Get.to(() => CategoryProductsScreen(
                                categoryName: title,
                                subCategories: matchingSubs,
                              )),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.success,
                                textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text("See More", style: TextStyle(color: AppColors.success)),
                            ),
                          ],
                        ),
                      ),

                      // Grid of subcategories
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: matchingSubs.length > 6 ? 6 : matchingSubs.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.75,
                          ),
                          itemBuilder: (context, i) {
                            final sub = matchingSubs[i];
                            final image = (sub.photos?.isNotEmpty ?? false)
                                ? sub.photos!.first
                                : "https://via.placeholder.com/150x150/E0E0E0/A0A0A0?text=No+Image";

                            return CategoryTile(
                              title: sub.name ?? 'Unknown',
                              imageUrl: image,
                              onTap: () {
                                Get.bottomSheet(
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16.0)),
                                    child: Container(
                                      color: AppColors.neutralBackground,
                                      height: Get.height * 0.85,
                                      padding: const EdgeInsets.only(top: 10),
                                      child: AllProductsGridView(
                                        products: sub.products ?? [],
                                        showTitle: false,
                                      ),
                                    ),
                                  ),
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  enableDrag: true,
                                );
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

              const SizedBox(height: 40),
              _buildBrandingSection(textTheme),
            ],
          ),
        );
      }),
    );
  }

  // -----------------------
  // Loading State Shimmer
  Widget _buildLoadingState(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView.builder(
      itemCount: 3,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemBuilder: (_, __) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey[200]!,
                highlightColor: Colors.grey[50]!,
                child: Container(
                  width: 180,
                  height: textTheme.titleLarge?.fontSize ?? 22,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 4,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, __) => Shimmer.fromColors(
                    baseColor: Colors.grey[200]!,
                    highlightColor: Colors.grey[50]!,
                    child: Container(
                      width: 90,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // -----------------------
  // Empty State View
  Widget _buildEmptyState(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 80, color: AppColors.textLight.withOpacity(0.6)),
            const SizedBox(height: 16),
            Text('No categories available at the moment.',
              style: textTheme.headlineSmall?.copyWith(
                color: AppColors.textMedium,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text('Please check back later!',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => categoryController.fetchCategories(),
              icon: const Icon(Icons.refresh, color: AppColors.white),
              label: Text('Retry', style: textTheme.labelLarge?.copyWith(color: AppColors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
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

  // -----------------------
  // Branding Section
  Widget _buildBrandingSection(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Mobiking",
            style: textTheme.displayLarge?.copyWith(
              color: AppColors.textLight.withOpacity(0.5),
              letterSpacing: -1.0,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text("Your Wholesale Partner",
            style: textTheme.headlineSmall?.copyWith(
              color: AppColors.textLight.withOpacity(0.6),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Buy in bulk, save big. Get the best deals on mobile phones and accessories, delivered directly to your doorstep.",
            style: textTheme.bodyLarge?.copyWith(
              color: AppColors.textLight.withOpacity(0.7),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }
}

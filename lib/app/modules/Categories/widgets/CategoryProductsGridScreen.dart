import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobiking/app/data/sub_category_model.dart';
import 'package:mobiking/app/modules/home/widgets/AllProductGridCard.dart';

import '../../../data/product_model.dart';
import '../../../themes/app_theme.dart';


class CategoryProductsGridScreen extends StatefulWidget {
  final String categoryName;
  final List<SubCategory> subCategories;

  const CategoryProductsGridScreen({
    Key? key,
    required this.categoryName,
    required this.subCategories,
  }) : super(key: key);

  @override
  State<CategoryProductsGridScreen> createState() => _CategoryProductsGridScreenState();
}

class _CategoryProductsGridScreenState extends State<CategoryProductsGridScreen> {
  late RxInt selectedSubCategoryIndex;
  late RxList<ProductModel> displayedProducts;

  @override
  void initState() {
    super.initState();
    selectedSubCategoryIndex = 0.obs;

    // Initialize with first subcategory's products
    if (widget.subCategories.isNotEmpty) {
      displayedProducts = (widget.subCategories.first.products ?? []).obs;
    } else {
      displayedProducts = <ProductModel>[].obs;
    }
  }

  void _onSubCategorySelected(int index) {
    selectedSubCategoryIndex.value = index;
    displayedProducts.value = widget.subCategories[index].products ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          widget.categoryName,
          style: textTheme.titleLarge?.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0.5,
        centerTitle: false,
      ),
      body: Row(
        children: [
          // Left Side - Subcategories List
          Container(
            width: screenWidth * 0.30, // 35% of screen width
            decoration: BoxDecoration(
              color: AppColors.neutralBackground,
              border: Border(
                right: BorderSide(
                  color: AppColors.lightGreyBackground,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Categories',
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                // Subcategories List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: widget.subCategories.length,
                    itemBuilder: (context, index) {
                      final subCategory = widget.subCategories[index];

                      return Obx(() => _buildSubCategoryItem(
                        subCategory: subCategory,
                        index: index,
                        isSelected: selectedSubCategoryIndex.value == index,
                        onTap: () => _onSubCategorySelected(index),
                        textTheme: textTheme,
                      ));
                    },
                  ),
                ),
              ],
            ),
          ),

          // Right Side - Products Grid
          Expanded(
            child: Container(
              color: AppColors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Products Header
                  Obx(() {
                    final selectedSubCategory = selectedSubCategoryIndex.value < widget.subCategories.length
                        ? widget.subCategories[selectedSubCategoryIndex.value]
                        : null;

                    return Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.lightGreyBackground,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            selectedSubCategory?.name ?? 'Products',
                            style: textTheme.titleMedium?.copyWith(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Obx(() => Text(
                              '${displayedProducts.length}',
                              style: textTheme.labelSmall?.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            )),
                          ),
                        ],
                      ),
                    );
                  }),

                  // Products Grid
                  Expanded(
                    child: Obx(() {
                      if (displayedProducts.isEmpty) {
                        return _buildEmptyProductsState(textTheme);
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.45,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: displayedProducts.length,
                        itemBuilder: (context, index) {
                          final product = displayedProducts[index];
                          return AllProductGridCard(
                            product: product,
                            heroTag: 'category-product-${product.id}-$index',
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubCategoryItem({
    required SubCategory subCategory,
    required int index,
    required bool isSelected,
    required VoidCallback onTap,
    required TextTheme textTheme,
  }) {
    final productCount = subCategory.products?.length ?? 0;
    final hasImage = (subCategory.photos?.isNotEmpty ?? false);
    final imageUrl = hasImage ? subCategory.photos!.first : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.success.withOpacity(0.1) : AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.success : AppColors.lightGreyBackground,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Category Image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.neutralBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.lightGreyBackground,
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: hasImage
                        ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.category_outlined,
                        color: AppColors.textLight,
                        size: 30,
                      ),
                    )
                        : Icon(
                      Icons.category_outlined,
                      color: AppColors.textLight,
                      size: 30,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Category Name
                Text(
                  subCategory.name ?? 'Unknown',
                  style: textTheme.labelMedium?.copyWith(
                    color: isSelected ? AppColors.success : AppColors.textDark,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                // Product Count
                Text(
                  '$productCount items',
                  style: textTheme.labelSmall?.copyWith(
                    color: isSelected ? AppColors.success.withOpacity(0.8) : AppColors.textLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyProductsState(TextTheme textTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.neutralBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Products Available',
              style: textTheme.titleMedium?.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This category doesn\'t have any products yet.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart'; // Using material.dart for consistency
import 'package:get/get.dart';
import 'package:mobiking/app/modules/home/widgets/top_picks_card.dart';

import '../../../data/product_model.dart';
import '../../../data/sub_category_model.dart';
import '../../Product_page/product_page.dart';

class AllProductsListView extends StatelessWidget {
  final List<SubCategory> subCategories;
  final int subCategoryIndex;
  final Function(ProductModel)? onProductTap;

  const AllProductsListView({
    Key? key,
    required this.subCategories,
    required this.subCategoryIndex,
    this.onProductTap,
  }) : super(key: key);

  static const double _gridHorizontalPadding = 16.0;
  static const double _gridItemSpacing = 0;
  static const double _cardAspectRatio = 0.68;

  @override
  Widget build(BuildContext context) {
    if (subCategoryIndex < 0 || subCategoryIndex >= subCategories.length) {
      debugPrint('Error: subCategoryIndex $subCategoryIndex is out of bounds for subCategories list.');
      return const SizedBox.shrink();
    }

    final SubCategory selectedSubCategory = subCategories[subCategoryIndex];

    final List<ProductModel> productsToShow = selectedSubCategory.products
        .where((product) => product.sellingPrice.isNotEmpty)
        .take(6)
        .toList();

    if (productsToShow.isEmpty) {
      return const SizedBox.shrink();
    }

    // No need for explicit height calculations here because of shrinkWrap: true
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: _gridHorizontalPadding),
      physics: const NeverScrollableScrollPhysics(), // IMPORTANT: Defer scrolling to parent
      shrinkWrap: true, // IMPORTANT: Size itself to its children
      itemCount: productsToShow.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: _gridItemSpacing,
        mainAxisSpacing: _gridItemSpacing,
        childAspectRatio: _cardAspectRatio,
      ),
      itemBuilder: (context, index) {
        final product = productsToShow[index];
        final String productHeroTag =
            'product_image_sub_category_${product.id}';

        return TopPicksCard(
          product: product,
          heroTag: productHeroTag,
          onTap: (p0) {
            if (onProductTap != null) {
              onProductTap!(p0);
            } else {
              Get.to(
                    () => ProductPage(
                  product: p0,
                  heroTag: productHeroTag,
                ),
              );
            }
          },
        );
      },
    );
  }
}
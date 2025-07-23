import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobiking/app/modules/home/widgets/AllProductGridCard.dart';

import '../../../data/product_model.dart';
import '../../../themes/app_theme.dart';
import '../../Product_page/product_page.dart';

class AllProductsGridView extends StatelessWidget {
  final List<ProductModel> products;
  final double horizontalPadding;
  final String title;
  final bool showTitle;

  const AllProductsGridView({
    super.key,
    required this.products,
    this.horizontalPadding = 2.0,
    this.title = "All Products",
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (products.isEmpty) {
      return _buildEmptyState(context);
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTitle)
              Padding(
                padding: const EdgeInsets.only(left: 8.0,),
                child: Text(
                  title,
                  style: textTheme.titleLarge?.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
        
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 0,
                crossAxisSpacing: 0,
                childAspectRatio: 0.46,
              ),
              itemBuilder: (context, idx) {
                final product = products[idx];
                return GestureDetector(
                  onTap: () {
                    Get.to(ProductPage(
                      product: product,
                      heroTag: 'product_image_${product.id}_${product.name}_all_view',
                    ));
                  },
                  child: AllProductGridCard(
                    product: product,
                    heroTag: 'product_image_${product.id}_${product.name}_all_view',
                  ),
                );
              },
            ),
        
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.widgets_outlined,
                size: 80, color: AppColors.textLight.withOpacity(0.6)),
            const SizedBox(height: 16),
            Text(
              'No products found.',
              style: textTheme.headlineSmall?.copyWith(
                color: AppColors.textMedium,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'It seems there are no products available in this section yet.',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.arrow_back, color: AppColors.white),
              label: Text(
                'Go Back',
                style: textTheme.labelLarge?.copyWith(color: AppColors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

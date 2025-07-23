import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobiking/app/modules/home/widgets/AllProductGridCard.dart';
import 'package:mobiking/app/modules/home/widgets/ProductCard.dart';
import '../../../data/group_model.dart';
import '../../../themes/app_theme.dart';
import '../../Product_page/product_page.dart';

class GroupProductsScreen extends StatelessWidget {
  final GroupModel group;

  const GroupProductsScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.neutralBackground,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textDark,
        elevation: 1,
        centerTitle: true,
        title: Text(
          group.name,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: SafeArea(
        child: group.products.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_bag_outlined, size: 80, color: AppColors.textLight.withOpacity(0.6)),
              const SizedBox(height: 16),
              Text(
                'No products available for "${group.name}".',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please check back later!',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textLight.withOpacity(0.7),
                ),
              ),
            ],
          ),
        )
            : GridView.builder(
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.45,  // Lower ratio = taller cards; tweak this
          ),
          itemCount: group.products.length,
          itemBuilder: (context, index) {
            final product = group.products[index];
            final String productHeroTag = 'product_image_group_${group.id}_${product.id}_$index';

            return AllProductGridCard(
              product: product,
              heroTag: productHeroTag,
              onTap: (tappedProduct) {
                Get.to(
                      () => ProductPage(
                    product: tappedProduct,
                    heroTag: productHeroTag,
                  ),
                  transition: Transition.fadeIn,
                  duration: const Duration(milliseconds: 300),
                );
                debugPrint('Navigating to product page for: ${tappedProduct.name}');
              },
            );
          },
        ),
      ),
    );
  }
}

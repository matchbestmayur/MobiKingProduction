import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobiking/app/themes/app_theme.dart';

import '../data/group_model.dart';
import '../modules/Product_page/product_page.dart';
import '../modules/home/widgets/GroupProductsScreen.dart';
import '../modules/home/widgets/ProductCard.dart';

class GroupWithProductsSection extends StatelessWidget {
  final List<GroupModel> groups;

  const GroupWithProductsSection({super.key, required this.groups});

  static const double horizontalContentPadding = 16.0;
  static const double productCardUniformHeight = 200.0;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    if (groups.isEmpty) return const SizedBox.shrink();

    return ListView.builder(
      itemCount: groups.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final group = groups[index];

        if (group.products.isEmpty) return const SizedBox.shrink();

        // ✅ Background Color Logic
        Color? sectionBackgroundColor;
        if (group.isBackgroundColorVisible && group.backgroundColor != null) {
          final tempBgColorString = group.backgroundColor!.trim();

          if (tempBgColorString.isNotEmpty &&
              tempBgColorString.toLowerCase() != "#ffffff") {
            try {
              final hex = tempBgColorString.replaceAll("#", "");
              if (hex.length == 6) {
                sectionBackgroundColor =
                    Color(int.parse("FF$hex", radix: 16));
              }
            } catch (e) {
              sectionBackgroundColor = null;
            }
          }
        }

        return Container(
          color: sectionBackgroundColor,
          padding: EdgeInsets.symmetric(
              vertical: sectionBackgroundColor != null ? 12.0 : 0.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Group Banner
              if (group.banner != null && group.banner!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: horizontalContentPadding),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: Container(
                      height: 140,
                      width: double.infinity,
                      color: AppColors.neutralBackground,
                      child: Image.network(
                        group.banner!,
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
                          return Center(
                            child: Icon(Icons.broken_image,
                                color: AppColors.textLight, size: 40),
                          );
                        },
                      ),
                    ),
                  ),
                ),

              if (group.banner != null && group.banner!.isNotEmpty)
                const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: horizontalContentPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ Group Title + See More
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            group.name,
                            style: textTheme.titleLarge?.copyWith(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            Get.to(() => GroupProductsScreen(group: group));
                            print('Navigating to all products for group: ${group.name}');
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primaryPurple,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(
                                  color: AppColors.lightPurple, width: 1),
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            minimumSize: Size.zero,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'See More',
                                style: textTheme.labelSmall?.copyWith(
                                  color: AppColors.primaryPurple,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios,
                                  size: 12, color: AppColors.primaryPurple),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ✅ Product List
                    SizedBox(
                      height: productCardUniformHeight,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: group.products.length,
                        padding: EdgeInsets.zero,
                        separatorBuilder: (_, __) =>
                        const SizedBox(width: 0.5),
                        itemBuilder: (context, prodIndex) {
                          final product = group.products[prodIndex];
                          final String productHeroTag =
                              'product_image_group_section_${group.id}_${product.id}_$prodIndex';

                          return ProductCards(
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
                              print('Navigating to product page for: ${tappedProduct.name}');
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

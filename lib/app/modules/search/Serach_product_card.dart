import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:mobiking/app/themes/app_theme.dart';
import '../../data/product_model.dart';
import '../Product_page/product_page.dart';
import '../Product_page/widgets/app_star_rating.dart';

class SearchProductCard extends StatelessWidget {
  final ProductModel product;
  final String heroTag;

  const SearchProductCard({
    Key? key,
    required this.product,
    required this.heroTag,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    // Random rating generation
    final double randomRating = (Random().nextDouble() * 2.5) + 2.5; // 2.5 to 5.0
    final int randomRatingCount = Random().nextInt(200) + 20;

    final String productName = product.name ?? 'Unnamed Product';
    final bool isShortName = productName.length < 25;

    return InkWell(
      onTap: () {

        Get.to(ProductPage(product: product, heroTag: 'search-product-image-${product.id}'));

      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: heroTag,
              child: AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: product.images != null && product.images.isNotEmpty
                      ? Image.network(
                    product.images[0]!,
                    fit: BoxFit.fill,
                    errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image_outlined, size: 32),
                  )
                      : const Icon(Icons.image_not_supported_outlined, size: 32),
                ),
              ),
            ),
            const SizedBox(height: 6),

            /// Product Name (Max 3 lines)
            Text(
              productName,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            /// Description (only if name is short)
            if (isShortName && (product.description?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 4),
              Text(
                product.description!,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textLight,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 4),

            /// Rating
            AppStarRating(
              rating: double.parse(randomRating.toStringAsFixed(1)),
              ratingCount: randomRatingCount,
              starSize: 14,

            ),

            const SizedBox(height: 6),

            /// Price
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '₹${product.sellingPrice[0].price?.toStringAsFixed(0) ?? 'N/A'}',
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

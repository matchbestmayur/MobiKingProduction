import 'package:flutter/material.dart';
import 'package:mobiking/app/themes/app_theme.dart';

import '../../home/widgets/app_star_rating.dart';

class ProductTitleAndPrice extends StatelessWidget {
  final String title;
  final double originalPrice;
  final double discountedPrice;
  final double productRating; // <--- NEW PARAMETER
  final int reviewCount;     // <--- NEW PARAMETER

  const ProductTitleAndPrice({
    super.key,
    required this.title,
    required this.originalPrice,
    required this.discountedPrice,
    required this.productRating, // <--- ADDED
    required this.reviewCount,   // <--- ADDED
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Title
        Text(
          title,
          style: textTheme.titleLarge?.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 8), // Spacing between title and prices

        // Prices Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Discounted Price (Main Price)
            Text(
              '₹${discountedPrice.toStringAsFixed(0)}',
              style: textTheme.headlineSmall?.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),

            // Original Price (if different and higher than discounted)
            if (originalPrice > discountedPrice && originalPrice > 0)
              Text(
                '₹${originalPrice.toStringAsFixed(0)}',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textLight,
                  decoration: TextDecoration.lineThrough,
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8), // Spacing between prices and rating

        // Rating bar with reviews - MOVED HERE
        Row(
          children: [
            AppStarRating(
              rating: productRating,
              starSize: 18,
              ratingCount: reviewCount, // Pass reviewCount if AppStarRating uses it for logic/display
            ),
            const SizedBox(width: 8),
            Text(
              '${productRating.toStringAsFixed(1)} ⭐ from $reviewCount reviews',
              style: textTheme.bodySmall?.copyWith(color: AppColors.textMedium),
            ),
          ],
        ),
      ],
    );
  }
}
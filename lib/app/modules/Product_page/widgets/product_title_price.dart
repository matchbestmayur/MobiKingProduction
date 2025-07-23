import 'package:flutter/material.dart';
import 'package:mobiking/app/themes/app_theme.dart';

class ProductTitleAndPrice extends StatelessWidget {
  final String title;
  final double originalPrice;
  final double discountedPrice;

  const ProductTitleAndPrice({
    super.key,
    required this.title,
    required this.originalPrice,
    required this.discountedPrice,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🏷 Product Title
        Text(
          title,
          style: textTheme.titleSmall?.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.w600,
            fontSize: 16, // Blinkit usually uses compact font
            height: 1.3,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),

        // 💰 Prices
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Discounted Price
            Text(
              '₹${discountedPrice.toStringAsFixed(0)}',
              style: textTheme.titleMedium?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(width: 6),

            // Original Price with Strikethrough (if applicable)
            if (originalPrice > discountedPrice && originalPrice > 0)
              Text(
                '₹${originalPrice.toStringAsFixed(0)}',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textLight,
                  decoration: TextDecoration.lineThrough,
                  fontSize: 14,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

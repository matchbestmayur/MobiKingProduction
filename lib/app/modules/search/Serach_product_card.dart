import 'package:flutter/material.dart';
import 'package:mobiking/app/themes/app_theme.dart';
import '../../data/product_model.dart';

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

    return InkWell(
      onTap: () {
        // TODO: Navigate to product details
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.textDark.withOpacity(0.06),
              blurRadius: 6,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: AppColors.lightPurple.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: heroTag,
              child: AspectRatio(
                aspectRatio: 1.5,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: product.images != null && product.images.isNotEmpty
                      ? Image.network(
                    product.images[0]!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image_outlined, size: 32),
                  )
                      : const Icon(Icons.image_not_supported_outlined, size: 32),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              product.name ?? 'Unnamed Product',
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              product.description ?? '',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textLight,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '₹${product.sellingPrice[0].price?.toStringAsFixed(0) ?? 'N/A'}',
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryPurple,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

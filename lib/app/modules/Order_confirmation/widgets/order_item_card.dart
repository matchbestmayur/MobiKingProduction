import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

import '../../../data/order_model.dart';
import '../../../themes/app_theme.dart';

class OrderItemCard extends StatelessWidget {
  final OrderItemModel item;
  final TextTheme textTheme;

  const OrderItemCard({
    Key? key,
    required this.item,
    required this.textTheme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String imageUrl = item.productDetails?.images?.isNotEmpty == true
        ? item.productDetails!.images!.first
        : 'https://via.placeholder.com/100/E0E0E0/757575?text=No+Image';

    final double itemTotal = item.quantity * item.price;

    return Card(
      color: AppColors.neutralBackground,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                height: 65,
                width: 65,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 65,
                  width: 65,
                  decoration: BoxDecoration(
                    color: AppColors.lightGreyBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.broken_image, color: AppColors.textLight, size: 30),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productDetails?.fullName ?? item.productDetails?.name ?? 'Product Name',
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: AppColors.textDark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  if (item.variantName.isNotEmpty && item.variantName != 'Default')
                    Text(
                      item.variantName,
                      style: textTheme.bodySmall?.copyWith(
                        fontSize: 11.5,
                        color: AppColors.textMedium,
                      ),
                    ),
                  const SizedBox(height: 2),

                  Text(
                    "Qty: ${item.quantity} × ${NumberFormat.simpleCurrency(locale: 'en_IN').format(item.price)}",
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: 11.5,
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            ),

            // Total Price
            Text(
              NumberFormat.simpleCurrency(locale: 'en_IN').format(itemTotal),
              style: textTheme.bodyMedium?.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

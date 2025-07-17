// lib/widgets/summary_row.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../themes/app_theme.dart' show AppColors;

class SummaryRow extends StatelessWidget {
  final String title;
  final double value;
  final bool isTotal;
  final bool isDiscount;
  final TextTheme textTheme;

  const SummaryRow({
    Key? key,
    required this.title,
    required this.value,
    this.isTotal = false,
    this.isDiscount = false,
    required this.textTheme,
  }) : super(key: key);

  IconData _getIconForTitle(String title) {
    switch (title) {
      case "Subtotal":
        return Icons.shopping_bag_outlined;
      case "Delivery Fee":
        return Icons.delivery_dining;
      case "Discount":
        return Icons.percent;
      case "GST":
        return Icons.receipt_long;
      case "Grand Total":
        return Icons.payments_outlined;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = isTotal
        ? textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.textDark, fontSize: 24)
        : textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: AppColors.textDark);

    final valueColor = isDiscount ? AppColors.danger : (isTotal ? AppColors.primaryPurple : AppColors.textDark);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(_getIconForTitle(title), size: isTotal ? 28 : 22, color: AppColors.textMedium),
              const SizedBox(width: 12),
              Text(title, style: style),
            ],
          ),
          Text(
            NumberFormat.simpleCurrency(locale: 'en_IN', decimalDigits: 2).format(value),
            style: style?.copyWith(color: valueColor),
          ),
        ],
      ),
    );
  }
}
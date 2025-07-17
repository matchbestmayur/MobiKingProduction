import 'package:flutter/material.dart';
import '../../../data/order_model.dart';
import '../../../themes/app_theme.dart';
import 'summary_row.dart'; // Assuming you have this widget

class OrderSummaryCard extends StatelessWidget {
  final OrderModel order;
  final TextTheme textTheme;

  const OrderSummaryCard({
    Key? key,
    required this.order,
    required this.textTheme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double subtotal = order.subtotal ?? 0.0;
    final double discount = order.discount ?? 0.0;
    final double delivery = order.deliveryCharge;
    final double gst = double.tryParse(order.gst ?? '0.0') ?? 0.0;
    final double total = order.orderAmount;

    return Card(
      color: AppColors.neutralBackground,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRow("Subtotal", subtotal),
            if (discount > 0) _buildRow("Discount", -discount, isDiscount: true),
            _buildRow("Delivery Fee", delivery),
            _buildRow("GST", gst),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(thickness: 1.2, color: AppColors.lightGreyBackground),
            ),
            _buildRow("Grand Total", total, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String title, double value, {bool isDiscount = false, bool isTotal = false}) {
    final valueColor = isDiscount
        ? Colors.red
        : isTotal
        ? AppColors.textDark
        : AppColors.textMedium;

    final titleStyle = textTheme.bodySmall?.copyWith(
      color: AppColors.textMedium,
      fontSize: 12,
    );

    final valueStyle = textTheme.bodySmall?.copyWith(
      color: valueColor,
      fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
      fontSize: 12.5,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: titleStyle),
          Text("₹ ${value.toStringAsFixed(2)}", style: valueStyle),
        ],
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/order_model.dart';
import '../../../themes/app_theme.dart';

class ShippingDetailsCard extends StatefulWidget {
  final OrderModel order;
  const ShippingDetailsCard({Key? key, required this.order}) : super(key: key);

  @override
  State<ShippingDetailsCard> createState() => _ShippingDetailsCardState();
}

class _ShippingDetailsCardState extends State<ShippingDetailsCard> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final order = widget.order;

    return GestureDetector(
      onTap: () => setState(() => isExpanded = !isExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(20.0),
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.neutralBackground,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Title Row (Shipping Details)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Shipping Details',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 300),
                  turns: isExpanded ? 0.5 : 0.0,
                  child: const Icon(Icons.expand_more),
                ),
              ],
            ),

            /// Expandable content
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _detailRowWithIcon(
                    textTheme,
                    Icons.local_shipping_outlined,
                    'Shipping Status',
                    order.shippingStatus.capitalizeFirst ?? 'Pending',
                    AppColors.textDark,
                  ),
                  if (order.courierName != null && order.courierName!.isNotEmpty)
                    _detailRowWithIcon(
                      textTheme,
                      Icons.send_outlined,
                      'Courier Partner',
                      order.courierName!,
                      AppColors.textDark,
                    ),
                  if (order.awbCode != null && order.awbCode!.isNotEmpty)
                    _detailRowWithIcon(
                      textTheme,
                      Icons.numbers_outlined,
                      'Tracking ID',
                      order.awbCode!,
                      AppColors.textDark,
                    ),
                  if (order.expectedDeliveryDate != null && order.expectedDeliveryDate!.isNotEmpty)
                    _detailRowWithIcon(
                      textTheme,
                      Icons.calendar_today_outlined,
                      'Expected Delivery',
                      DateFormat('dd MMM, yyyy - hh:mm a').format(
                          DateTime.tryParse(order.expectedDeliveryDate!) ?? DateTime.now()),
                      AppColors.textDark,
                    ),
                  if (order.deliveredAt != null && order.deliveredAt!.isNotEmpty)
                    _detailRowWithIcon(
                      textTheme,
                      Icons.check_circle_outline,
                      'Delivered On',
                      DateFormat('dd MMM, yyyy - hh:mm a').format(
                          DateTime.tryParse(order.deliveredAt!) ?? DateTime.now()),
                      AppColors.textDark,
                    ),
                  _detailRowWithIcon(
                    textTheme,
                    Icons.payment_outlined,
                    'Payment Method',
                    order.method.capitalizeFirst ?? 'N/A',
                    AppColors.textDark,
                  ),
                  if (order.razorpayPaymentId != null && order.razorpayPaymentId!.isNotEmpty)
                    _detailRowWithIcon(
                      textTheme,
                      Icons.credit_card_outlined,
                      'Razorpay Transaction ID',
                      order.razorpayPaymentId!,
                      AppColors.textDark,
                    ),
                ],
              ),
              crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRowWithIcon(
      TextTheme textTheme,
      IconData icon,
      String title,
      String value,
      Color valueColor,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: AppColors.textMedium),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.bodySmall?.copyWith(color: AppColors.textMedium)),
                const SizedBox(height: 4),
                Text(value, style: textTheme.bodyMedium?.copyWith(color: valueColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

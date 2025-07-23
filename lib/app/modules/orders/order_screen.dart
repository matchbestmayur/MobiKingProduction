import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // Import for date formatting
import 'package:mobiking/app/modules/profile/query/Raise_query.dart'; // Ensure this is the correct path for RaiseQueryDialog
import 'package:flutter_svg/flutter_svg.dart'; // Import flutter_svg

import 'package:mobiking/app/modules/profile/query/query_screen.dart';

import '../../controllers/order_controller.dart'; // Adjust path if necessary
import '../../controllers/query_getx_controller.dart'; // Import QueryGetXController
import '../../data/order_model.dart'; // Ensure OrderModel and OrderItemModel are correctly defined here

import '../../themes/app_theme.dart'; // Your custom AppColors and AppTheme
import '../home/home_screen.dart'; // To navigate back to home - Adjust path if necessary
import '../profile/query/Query_Detail_Screen.dart';
import 'shipping_details_screen.dart'; // IMPORT THE NEW SCREEN HERE - Adjust path if necessary
// import '../profile/query/query_screen.dart'; // REMOVED: No longer navigating to a separate QueriesScreen

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final QueryGetXController queryController = Get.find<QueryGetXController>();
  final ScrollController _scrollController = ScrollController();
  final OrderController controller = Get.put(OrderController());

  Timer? _pollingTimer;
  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();
    controller.fetchOrderHistory(); // initial call shows loader
    _startPolling(); // silent background polling every 30s
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_isScrolling && mounted) {
        controller.fetchOrderHistory(isPoll: true); // 🔇 silent polling
      }
    });
  }

  void _pausePolling() => _isScrolling = true;

  void _resumePolling() {
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) _isScrolling = false;
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.neutralBackground,
      appBar: AppBar(
        title: Text(
          'My Orders',
          style: textTheme.titleLarge?.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.white,
        elevation: 0.5,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        actions: const [SizedBox(width: 8)],
      ),
      body: GetX<OrderController>(
        builder: (_) {
          if (controller.isLoadingOrderHistory.value) {
            return _buildLoadingView(textTheme);
          } else if (controller.orderHistoryErrorMessage.isNotEmpty) {
            return _buildErrorView(textTheme);
          } else if (controller.orderHistory.isEmpty) {
            return _buildEmptyView(textTheme);
          } else {
            return NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                if (scrollInfo is ScrollStartNotification) {
                  _pausePolling();
                } else if (scrollInfo is ScrollEndNotification) {
                  _resumePolling();
                }
                return false;
              },
              child: RefreshIndicator(
                onRefresh: () => controller.fetchOrderHistory(), // manual refresh
                color: AppColors.success,
                backgroundColor: AppColors.neutralBackground,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16.0),
                  itemCount: controller.orderHistory.length,
                  itemBuilder: (context, index) {
                    final order = controller.orderHistory[index];
                    return _OrderCard(
                      order: order,
                      controller: controller,
                      queryController: queryController,
                    );
                  },
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildLoadingView(TextTheme textTheme) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: AppColors.success),
        const SizedBox(height: 16),
        Text('Loading your orders...', style: textTheme.bodyLarge?.copyWith(color: AppColors.textMedium)),
      ],
    ),
  );

  Widget _buildErrorView(TextTheme textTheme) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 70, color: AppColors.danger),
          const SizedBox(height: 24),
          Text(
            'Oops! Failed to load orders.',
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            controller.orderHistoryErrorMessage.value,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textMedium),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => controller.fetchOrderHistory(),
            icon: const Icon(Icons.refresh_rounded, color: AppColors.white),
            label: Text(
              'Try Again',
              style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, color: AppColors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 2,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildEmptyView(TextTheme textTheme) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 80, color: AppColors.textLight.withOpacity(0.6)),
          const SizedBox(height: 24),
          Text(
            'No orders found yet!',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Looks like you haven\'t placed any orders. Start shopping to fill this space!',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textMedium),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Get.offAll(() => HomeScreen()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            child: Text(
              'Start Shopping Now',
              style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, color: AppColors.white),
            ),
          ),
        ],
      ),
    ),
  );
}


class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final OrderController controller;
  final QueryGetXController queryController; // Accept QueryGetXController

  const _OrderCard({
    required this.order,
    required this.controller,
    required this.queryController,
  });

  // Define the query raise limit in days as 3 days from delivered date
  static const int _QUERY_RAISE_DAYS_LIMIT_AFTER_DELIVERY = 3;

  // Helper to check if a query already exists for this order
  bool _hasExistingQuery(String? orderId) {
    if (orderId == null) return false;
    final bool exists = queryController.myQueries.any((query) => query.orderId == orderId);
    print('DEBUG: _hasExistingQuery for Order ID ${orderId}: $exists');
    return exists;
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    Color statusBadgeColor;
    Color statusTextColor;
    String orderMainStatusText = order.status.capitalizeFirst ?? 'Unknown';

    switch (order.status.toLowerCase()) {
      case 'new':
      case 'accepted':
        statusBadgeColor = AppColors.danger.withOpacity(0.15);
        statusTextColor = AppColors.danger;
        break;
      case 'shipped':
      case 'delivered':
        statusBadgeColor = AppColors.success.withOpacity(0.15);
        statusTextColor = AppColors.success;
        break;
      case 'cancelled':
      case 'rejected':
      case 'returned':
        statusBadgeColor = AppColors.textLight.withOpacity(0.1);
        statusTextColor = AppColors.textLight;
        break;
      case 'hold':
        statusBadgeColor = AppColors.accentOrange.withOpacity(0.15);
        statusTextColor = AppColors.accentOrange;
        break;
      default:
        statusBadgeColor = AppColors.textLight.withOpacity(0.1);
        statusTextColor = AppColors.textLight;
    }

    String orderDate = 'N/A';
    if (order.createdAt != null) {
      orderDate = DateFormat('dd MMM, hh:mm a').format(order.createdAt!.toLocal());
    }

    // --- MODIFIED LOGIC FOR canRaiseQuery ---
    bool canRaiseQuery = false;
    print('DEBUG: Order ID: ${order.id}, Status: ${order.status}');

    // Simple condition: only check if status is 'delivered' and order.id is not null
    if (order.status.toLowerCase() == 'delivered' && order.id != null) {
      canRaiseQuery = true;
      print('DEBUG: Status is "Delivered" and Order ID exists. canRaiseQuery set to TRUE.');
    } else {
      print('DEBUG: Status is not "Delivered" or Order ID is null. canRaiseQuery remains FALSE.');
    }
    print('DEBUG: Final canRaiseQuery value: $canRaiseQuery');
    // --- END MODIFIED LOGIC ---


    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.textDark.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Order Header: ID & Main Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Order ID: #${order.orderId}',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusBadgeColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    orderMainStatusText,
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: statusTextColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Placed: ${orderDate}',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textMedium,
              ),
            ),
            const Divider(height: 24, thickness: 1, color: AppColors.neutralBackground),

            /// Order Items List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: order.items.length,
              itemBuilder: (context, itemIndex) {
                final item = order.items[itemIndex];
                final String? imageUrl = item.productDetails?.images?.isNotEmpty == true ? item.productDetails!.images!.first : null;
                final String productName = item.productDetails?.fullName ?? 'N/A';
                final String variantText = (item.variantName != null && item.variantName.isNotEmpty && item.variantName != 'Default')
                    ? item.variantName
                    : '';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: imageUrl != null && imageUrl.isNotEmpty
                            ? Image.network(
                          imageUrl,
                          height: 60,
                          width: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 60,
                            width: 60,
                            color: AppColors.neutralBackground,
                            child: const Icon(Icons.broken_image_rounded, size: 30, color: AppColors.textLight),
                          ),
                        )
                            : Container(
                          height: 60,
                          width: 60,
                          color: AppColors.neutralBackground,
                          child: const Icon(Icons.image_not_supported_rounded, size: 30, color: AppColors.textLight),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              productName,
                              style: textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (variantText.isNotEmpty)
                              Text(
                                variantText,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textMedium,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            const SizedBox(height: 4),
                            Text(
                              'Qty: ${item.quantity}',
                              style: textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '₹${item.price.toStringAsFixed(0)}',
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const Divider(height: 24, thickness: 1, color: AppColors.neutralBackground),

            /// Order Summary
            _OrderCard.buildSummaryRow(context, 'Subtotal', '₹${order.subtotal?.toStringAsFixed(0) ?? '0'}'),
            _OrderCard.buildSummaryRow(context, 'Delivery Charge', '₹${order.deliveryCharge.toStringAsFixed(0)}'),
            _OrderCard.buildSummaryRow(context, 'GST', '₹${order.gst ?? '0'}'),
            const SizedBox(height: 12),

            // Total Amount row
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Grand Total',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    '₹${order.orderAmount.toStringAsFixed(0)}',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Shipping Details Section
            Text(
              'Shipping & Delivery Details',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            _OrderCard.buildDetailRow(context, 'Shipping Status', order.shippingStatus.capitalizeFirst ?? 'N/A'),
            if (order.courierName != null && order.courierName!.isNotEmpty)
              _OrderCard.buildDetailRow(context, 'Courier', order.courierName!),
            if (order.awbCode != null && order.awbCode!.isNotEmpty)
              _OrderCard.buildDetailRow(context, 'AWB Code', order.awbCode!),
            if (order.expectedDeliveryDate != null && order.expectedDeliveryDate!.isNotEmpty)
              _OrderCard.buildDetailRow(
                context,
                'Expected Delivery',
                DateFormat('dd MMM, hh:mm a').format(DateTime.tryParse(order.expectedDeliveryDate!) ?? DateTime.now()),
              ),
            if (order.deliveredAt != null && order.deliveredAt!.isNotEmpty)
              _OrderCard.buildDetailRow(
                context,
                'Delivered On',
                DateFormat('dd MMM, hh:mm a').format(DateTime.tryParse(order.deliveredAt!) ?? DateTime.now()),
              ),
            _OrderCard.buildDetailRow(context, 'Payment Method', order.method.capitalizeFirst ?? 'N/A'),
            if (order.razorpayPaymentId != null && order.razorpayPaymentId!.isNotEmpty)
              _OrderCard.buildDetailRow(context, 'Razorpay Payment ID', order.razorpayPaymentId!),
            const SizedBox(height: 16),


            // Row for Track Shipment and Payment Method
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Minimal "Track Shipment" button
                if (order.status == "Accepted")
                  OutlinedButton(
                    onPressed: () {
                      Get.to(() => ShippingDetailsScreen(order: order));
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.info),
                      foregroundColor: AppColors.info,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      'Track Shipment',
                      style: textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.info,
                      ),
                    ),
                  ),

                if (order.status == "Accepted") const SizedBox(width: 12),

                // Minimal "Paid via" tag
                if (order.status == "Accepted")
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.neutralBackground,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Paid via ${order.method.capitalizeFirst ?? 'N/A'}',
                      style: textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // --- Action Buttons for Query, Cancel, Warranty, Return ---
            if (order.id != null)
              Builder(
                  builder: (innerContext) {
                    bool showAnyActionButton = controller.showCancelButton(order) ||
                        controller.showReturnButton(order);

                    // Check for any active requests that are not rejected/resolved
                    final activeRequests = order.requests?.where((req) {
                      final String status = req.status.toLowerCase();
                      return status != 'rejected' && status != 'resolved';
                    }).toList() ?? [];

                    // Determine if "View Query" button should be visible (if any query, even resolved/rejected, existed)
                    // This is for displaying "View Query" if *any* query has been made for this order.
                    bool hasActiveOrResolvedQuery = order.requests?.any((req) => req.type.toLowerCase() == 'query' && (req.status.toLowerCase() != 'rejected' && req.status.toLowerCase() != 'cancelled')) ?? false;


                    // Check for any active requests that are queries and not rejected/resolved
                    final activeQueries = order.requests?.where((req) {
                      final String type = req.type.toLowerCase();
                      final String status = req.status.toLowerCase();
                      return type == 'query' && status != 'rejected' && status != 'resolved' && status != 'cancelled';
                    }).toList() ?? [];


                    if (!showAnyActionButton && activeRequests.isEmpty && !canRaiseQuery && !hasActiveOrResolvedQuery) {
                      print('DEBUG: No action buttons or query options to display. Hiding section.'); // LOG
                      return const SizedBox.shrink(); // Hide the whole section if no active buttons, requests, or query options
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start, // Align text to start
                      children: [
                        const Divider(height: 24, thickness: 1, color: AppColors.neutralBackground),
                        // Display active requests (other than queries, as queries will have a specific button)
                        if (activeRequests.isNotEmpty) ...[
                          Text(
                            'Active Requests:',
                            style: Theme.of(innerContext).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryPurple,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...activeRequests.map((req) {
                            final String type = req.type.capitalizeFirst!;
                            final String status = req.status.capitalizeFirst!;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Text(
                                '$type Request: $status',
                                style: Theme.of(innerContext).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textMedium,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            );
                          }).toList(),
                          const SizedBox(height: 12), // Spacing before action buttons if requests are present
                        ],

                        // Add a divider if active requests are shown AND there will be action buttons below
                        if (activeRequests.isNotEmpty && (showAnyActionButton || canRaiseQuery || hasActiveOrResolvedQuery))
                          const Divider(height: 24, thickness: 1, color: AppColors.neutralBackground),

                        // NEW: Conditionally display "Raise Query" or "View Query" button
                        if (order.id != null) // Ensure order ID exists for query logic
                          Obx(() { // Wrap with Obx to react to queryController.myQueries changes
                            final bool hasQueryForThisOrder = queryController.myQueries.any((query) => query.orderId == order.id);
                            print('DEBUG: Inside Obx for Query Button. hasQueryForThisOrder: $hasQueryForThisOrder, canRaiseQuery: $canRaiseQuery'); // LOG
                            print('DEBUG: queryController.myQueries: ${queryController.myQueries.map((q) => q.orderId).toList()}'); // LOG all order IDs in myQueries

                            if (hasQueryForThisOrder) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6.0),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Get.to(() => QueryDetailScreen(orderId: order.id));
                                    },
                                    icon: Icon(Icons.info_outline, size: 20, color: AppColors.white),
                                    label: Text(
                                      'View Query', // Changed label
                                      style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, color: AppColors.white),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.info, // Changed color
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      elevation: 2,
                                    ),
                                  ),
                                ),
                              );
                            } else if (canRaiseQuery) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6.0),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      // Open the RaiseQueryDialog and pass the order ID
                                      Get.dialog(
                                        RaiseQueryDialog(orderId: order.id),
                                      );
                                    },
                                    icon: Icon(Icons.chat_bubble_outline, size: 20, color: AppColors.white),
                                    label: Text(
                                      'Raise Query',
                                      style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, color: AppColors.white),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.darkPurple,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      elevation: 2,
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              return const SizedBox.shrink(); // Hide if no query raised and cannot raise
                            }
                          }),

                        // Existing Cancel, Warranty, Return buttons
                        if (controller.showCancelButton(order))
                          _OrderCard.buildActionButton(
                            innerContext,
                            label: 'Cancel Order',
                            icon: Icons.cancel_outlined,
                            color: AppColors.danger,
                            onPressed: () => controller.sendOrderRequest(order.id, 'Cancel'),
                            isLoadingObservable: controller.isLoading, // Assuming controller.isLoading for general processing
                          ),
                       /* if (controller.showWarrantyButton(order))
                          _OrderCard.buildActionButton(
                            innerContext,
                            label: 'Request Warranty',
                            icon: Icons.verified_user_outlined,
                            color: AppColors.primaryPurple,
                            onPressed: () => controller.sendOrderRequest(order.id, 'Warranty'),
                            isLoadingObservable: controller.isLoading,
                          ),*/
                        if (controller.showReturnButton(order))
                          _OrderCard.buildActionButton(
                            innerContext,
                            label: 'Request Return',
                            icon: Icons.keyboard_return_outlined,
                            color: AppColors.info,
                            onPressed: () => controller.sendOrderRequest(order.id, 'Return'),
                            isLoadingObservable: controller.isLoading,
                          ),
                      ],
                    );
                  }
              ),
          ],
        ),
      ),
    );
  }

  // Helper widget for summary rows
  static Widget buildSummaryRow(BuildContext context, String label, String value) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: textTheme.bodyMedium?.copyWith(
            color: AppColors.textMedium,
          )),
          Text(value, style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          )),
        ],
      ),
    );
  }

  // Helper widget for general detail rows (e.g., for shipping info)
  static Widget buildDetailRow(BuildContext context, String label, String value) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120, // Adjust width as needed for labels
            child: Text(
              '$label:',
              style: textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textMedium,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.w600, // Make values slightly bolder
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }


  // Helper widget for action buttons - NOW CONTAINS ITS OWN OBX
  static Widget buildActionButton(
      BuildContext context, {
        required String label,
        required IconData icon,
        required Color color,
        required VoidCallback onPressed,
        required RxBool isLoadingObservable, // Accept RxBool directly
      }) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: SizedBox(
        width: double.infinity,
        child: Obx(() {
          final bool isLoading = isLoadingObservable.value;
          return ElevatedButton.icon(
            onPressed: isLoading ? null : onPressed, // Disable button if loading
            icon: isLoading
                ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: AppColors.white,
                strokeWidth: 2,
              ),
            )
                : Icon(icon, size: 20, color: AppColors.white),
            label: Text(
              isLoading ? 'Processing...' : label,
              style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, color: AppColors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 2,
            ),
          );
        }),
      ),
    );
  }
}
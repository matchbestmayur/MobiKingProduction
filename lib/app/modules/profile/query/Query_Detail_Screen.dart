import 'dart:ui'; // Required for ImageFilter and BackdropFilter
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../controllers/order_controller.dart';
import '../../../controllers/query_getx_controller.dart';
import '../../../data/QueryModel.dart';
import '../../../data/order_model.dart';
import '../../../themes/app_theme.dart';
import '../../orders/shipping_details_screen.dart';

// --- NEW WIDGET FOR ANIMATED ATTACHMENT BUTTON ---
class AnimatedAttachmentButton extends StatefulWidget {
  final Function(String type) onAttachmentSelected; // Callback for selected attachment type

  const AnimatedAttachmentButton({Key? key, required this.onAttachmentSelected}) : super(key: key);

  @override
  _AnimatedAttachmentButtonState createState() => _AnimatedAttachmentButtonState();
}

class _AnimatedAttachmentButtonState extends State<AnimatedAttachmentButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotateAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Widget _buildMiniFab({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onPressed,
    // Removed 'delay' as it's not directly used for staggered animation in this setup
  }) {
    return Transform.scale(
      scale: _animationController.value,
      child: Opacity(
        opacity: _animationController.value,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: FloatingActionButton(
            heroTag: null, // Essential for multiple FloatingActionButtons
            mini: true,
            backgroundColor: color,
            onPressed: onPressed,
            tooltip: tooltip,
            child: Icon(icon, color: AppColors.white),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end, // Align the column to the right
      children: [
        // Using AnimatedBuilder to rebuild mini-FABs with animation values
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_isExpanded) ...[
                  _buildMiniFab(
                    icon: Icons.camera_alt_rounded,
                    tooltip: 'Camera',
                    color: Colors.pink.shade400, // Use a slightly different shade
                    onPressed: () {
                      _toggleExpansion();
                      widget.onAttachmentSelected('camera');
                    },
                  ),
                  _buildMiniFab(
                    icon: Icons.image_rounded,
                    tooltip: 'Gallery',
                    color: Colors.orange.shade400,
                    onPressed: () {
                      _toggleExpansion();
                      widget.onAttachmentSelected('gallery');
                    },
                  ),
                  _buildMiniFab(
                    icon: Icons.insert_drive_file_rounded,
                    tooltip: 'Document',
                    color: Colors.blue.shade400,
                    onPressed: () {
                      _toggleExpansion();
                      widget.onAttachmentSelected('document');
                    },
                  ),
                ],
              ],
            );
          },
        ),
        // Main attachment button
        Container(
          margin: const EdgeInsets.only(top: 8.0), // Space between mini-FABs and main button
          decoration: BoxDecoration(
            color: AppColors.primaryPurple, // Use primaryPurple for main button
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryPurple.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: RotationTransition(
            turns: _rotateAnimation,
            child: IconButton(
              icon: Icon(
                _isExpanded ? Icons.close_rounded : Icons.attach_file_rounded, // Rounded close icon
                color: AppColors.white, // Pure white for better contrast
                size: 24,
              ),
              onPressed: _toggleExpansion,
            ),
          ),
        ),
      ],
    );
  }
}

// QueryDetailScreen is now a GetView, giving direct access to the controller
class QueryDetailScreen extends GetView<QueryGetXController> {
  final String? orderId; // Accept orderId for navigation
  const QueryDetailScreen({super.key, this.orderId});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    // Local state for controlling the expansion of the query details card
    final RxBool isQueryDetailsExpanded = false.obs;
    final RxBool isOrderDetailsExpanded = false.obs;

    // Get controllers only once
    final OrderController orderController = Get.find<OrderController>();

    return Obx(() {
      // Fetch the query based on orderId when the screen initializes
      if (orderId != null) {
        final QueryModel? query = controller.getQueryByOrderId(orderId!);
        if (query != null) {
          controller.selectQuery(query); // Select the query for reactive updates
        }
      }

      final QueryModel? query = controller.selectedQuery;

      // NEW: Get the associated order from the OrderController's cache or fetch if not present
      final OrderModel? associatedOrder =
      query != null && query.orderId != null ? orderController.getOrderById(query.orderId!) : null;

      if (query == null && orderId != null) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Error', style: textTheme.titleLarge?.copyWith(color: AppColors.white)),
            backgroundColor: AppColors.darkPurple,
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 80, color: AppColors.danger),
                const SizedBox(height: 16),
                Text(
                  'No query found for this order.',
                  style: textTheme.bodyLarge?.copyWith(color: AppColors.textDark),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    'Go Back',
                    style: textTheme.labelLarge?.copyWith(color: AppColors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      final bool showChatInput = query?.status == 'open' || query?.status == 'in_progress';
      final bool showRatingOption = query?.status == 'resolved' && (query?.rating == null || query!.rating == 0);

      return Scaffold(
        backgroundColor: AppColors.neutralBackground,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.white),
            onPressed: () => Get.back(),
          ),
          title: Text(
            query?.title ?? 'Query Details',
            style: textTheme.headlineSmall?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.darkPurple, AppColors.primaryPurple],
              ),
            ),
          ),
          elevation: 4,
          actions: [
            if (showRatingOption)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: const Icon(Icons.star_rate_rounded, color: AppColors.accentNeon, size: 28),
                  tooltip: 'Rate this query',
                  onPressed: () => _showRatingReviewModal(context, query!.id),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: Expanded(
            child: SingleChildScrollView( // <--- Wrap the Column with SingleChildScrollView
              child: Column(
                children: [
                  // Query Details Card - Modernized Glassmorphic effect
                  GestureDetector(
                    onTap: () => isQueryDetailsExpanded.toggle(),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.primaryPurple.withOpacity(0.2), width: 1.0),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.textDark.withOpacity(0.08),
                                  blurRadius: 25,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(24.0),
                            child: AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title and Status always visible
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          query?.title ?? 'N/A',
                                          style: textTheme.titleLarge?.copyWith(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textDark,
                                          ),
                                          maxLines: isQueryDetailsExpanded.value ? null : 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: controller.getStatusColor(query?.status.toString() ?? '').withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          query?.status?.capitalizeFirst ?? 'N/A',
                                          style: textTheme.labelMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: controller.getStatusColor(query?.status.toString() ?? ''),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Hidden content wrapped in Obx for reactivity
                                  Obx(() {
                                    if (isQueryDetailsExpanded.value) {
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 15.0),
                                          Text(
                                            query?.message ?? 'No message available.',
                                            style: textTheme.bodyLarge?.copyWith(
                                              fontSize: 16,
                                              color: AppColors.textDark.withOpacity(0.8),
                                              height: 1.5,
                                            ),
                                          ),
                                          const SizedBox(height: 18.0),
                                          if (query?.rating != null && query!.rating! > 0)
                                            Padding(
                                              padding: const EdgeInsets.only(bottom: 8.0),
                                              child: Row(
                                                children: [
                                                  ...List.generate(
                                                    5,
                                                        (i) => Icon(
                                                      i < query.rating! ? Icons.star_rounded : Icons.star_border_rounded,
                                                      color: Colors.amber,
                                                      size: 20,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    '(${query.rating} / 5)',
                                                    style: textTheme.labelSmall?.copyWith(color: AppColors.textDark),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          Divider(
                                            height: 25,
                                            thickness: 1,
                                            color: AppColors.primaryPurple.withOpacity(0.2),
                                          ),
                                          _buildDetailRow(textTheme, 'Raised At', DateFormat('MMM d, yyyy - hh:mm a')
                                              .format(query?.raisedAt ?? query?.createdAt ?? DateTime.now())),
                                          if (query?.status == 'resolved' && query?.resolvedAt != null)
                                            _buildDetailRow(
                                              textTheme,
                                              'Resolved At',
                                              DateFormat('MMM d, yyyy - hh:mm a').format(query!.resolvedAt!),
                                            ),
                                          if (query?.rating != null &&
                                              query!.rating! > 0 &&
                                              query.review != null &&
                                              query.review!.isNotEmpty)
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const SizedBox(height: 12),
                                                Text(
                                                  'Your Review',
                                                  style: textTheme.titleSmall?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.textDark,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Container(
                                                  padding: const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.neutralBackground,
                                                    borderRadius: BorderRadius.circular(10),
                                                    border: Border.all(color: AppColors.textLight.withOpacity(0.1)),
                                                  ),
                                                  child: Text(
                                                    query.review!,
                                                    style: textTheme.bodyMedium?.copyWith(
                                                      color: AppColors.textDark.withOpacity(0.7),
                                                      fontStyle: FontStyle.italic,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      );
                                    } else {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 10.0),
                                        child: Row(
                                          children: [
                                            Text(
                                              'Tap for more details...',
                                              style: textTheme.bodySmall?.copyWith(
                                                color: AppColors.textMedium,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                            const Spacer(),
                                            Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMedium),
                                          ],
                                        ),
                                      );
                                    }
                                  }),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Associated Order Details Card
                  if (associatedOrder != null)
                    GestureDetector(
                      onTap: () => isOrderDetailsExpanded.toggle(),
                      child: Container(
                        // Keep margin consistent with the Query Details Card for uniform look
                        margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            // Slightly reduced blur for a cleaner, less "hazy" effect
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.all(24.0),
                              decoration: BoxDecoration(
                                // Slightly reduced opacity for a more subtle glass effect
                                color: AppColors.white.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(20),
                                // Use a more neutral or muted border color, or match primary purple
                                border: Border.all(color: AppColors.primaryPurple.withOpacity(0.15), width: 1.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.textDark.withOpacity(0.06), // Softer shadow
                                    blurRadius: 20, // Slightly less blur for a cleaner shadow
                                    offset: const Offset(0, 8), // Softer offset
                                  ),
                                ],
                              ),
                              child: AnimatedSize(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Associated Order: #${associatedOrder.orderId}',
                                            style: textTheme.titleLarge?.copyWith(
                                              fontSize: 20, // Slightly smaller for better hierarchy with query title
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textDark,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            // Use the status color directly, but maybe with a light background tint
                                            color: AppColors.success.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            associatedOrder.status.capitalizeFirst ?? 'N/A',
                                            style: textTheme.labelMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.success, // Keep text color as success
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Obx(() {
                                      if (isOrderDetailsExpanded.value) {
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 18.0), // Increased spacing for visual break
                                            _buildDetailRow(textTheme, 'Order Amount', '₹${associatedOrder.orderAmount.toStringAsFixed(0)}'),
                                            _buildDetailRow(
                                              textTheme,
                                              'Placed On',
                                              DateFormat('MMM d, yyyy - hh:mm a').format(associatedOrder.createdAt!.toLocal()),
                                            ),
                                            _buildDetailRow(
                                              textTheme,
                                              'Payment Method',
                                              associatedOrder.method.capitalizeFirst ?? 'N/A',
                                            ),
                                            if (associatedOrder.awbCode != null && associatedOrder.awbCode!.isNotEmpty)
                                              _buildDetailRow(textTheme, 'AWB Code', associatedOrder.awbCode!),
                                            if (associatedOrder.items.isNotEmpty) ...[
                                              const SizedBox(height: 16), // Increased spacing before items
                                              Text(
                                                'Ordered Items:',
                                                style: textTheme.titleSmall?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.textDark.withOpacity(0.85), // Slightly darker text
                                                ),
                                              ),
                                              const SizedBox(height: 10), // Increased spacing
                                              // Loop through associatedOrder.items to display each product
                                              ...associatedOrder.items.take(3).map((item) => Padding(
                                                padding: const EdgeInsets.only(bottom: 8.0), // More vertical spacing for items
                                                child: Row( // <-- New Row to include image
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    // Product Image
                                                    Container(
                                                      width: 48, // Fixed width for image
                                                      height: 48, // Fixed height for image
                                                      margin: const EdgeInsets.only(right: 12),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.neutralBackground, // Placeholder background
                                                        borderRadius: BorderRadius.circular(8),
                                                        border: Border.all(color: AppColors.textLight.withOpacity(0.1)),
                                                      ),
                                                      child: ClipRRect(
                                                        borderRadius: BorderRadius.circular(8),
                                                        child: (item.productDetails?.images != null && item.productDetails!.images!.isNotEmpty)
                                                            ? CachedNetworkImage( // Using CachedNetworkImage
                                                          imageUrl: item.productDetails!.images[0],
                                                          fit: BoxFit.cover,
                                                          placeholder: (context, url) => Center(
                                                            child: CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              color: AppColors.primaryPurple.withOpacity(0.5),
                                                            ),
                                                          ),
                                                          errorWidget: (context, url, error) => Icon(
                                                            Icons.broken_image,
                                                            color: AppColors.textMedium.withOpacity(0.5),
                                                            size: 24,
                                                          ),
                                                        )
                                                            : Icon( // Fallback icon if no image
                                                          Icons.shopping_bag_outlined,
                                                          color: AppColors.textMedium.withOpacity(0.5),
                                                          size: 24,
                                                        ),
                                                      ),
                                                    ),
                                                    // Product Details Text
                                                    Expanded( // Allows text to take available space
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            item.productDetails?.fullName ?? 'Product Name N/A',
                                                            style: textTheme.bodyMedium?.copyWith(
                                                              color: AppColors.textDark,
                                                              fontWeight: FontWeight.w500, // Make product name slightly bolder
                                                            ),
                                                            maxLines: 2,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                          Text(
                                                            'Qty: ${item.quantity}',
                                                            style: textTheme.bodySmall?.copyWith(
                                                              color: AppColors.textDark.withOpacity(0.6),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )).toList(),
                                              if (associatedOrder.items.length > 3)
                                                Padding( // Add padding to this line too for consistency
                                                  padding: const EdgeInsets.only(top: 4.0),
                                                  child: Text(
                                                    '+ ${associatedOrder.items.length - 3} more items',
                                                    style: textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: AppColors.textMedium),
                                                  ),
                                                ),
                                              const SizedBox(height: 16), // Increased spacing
                                            ],
                                            Divider(
                                              height: 25,
                                              thickness: 0.8, // Thinner divider
                                              color: AppColors.primaryPurple.withOpacity(0.15), // Muted color
                                            ),
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton.icon(
                                                onPressed: () {
                                                  Get.to(() => ShippingDetailsScreen(order: associatedOrder));
                                                },
                                                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: AppColors.info), // Changed icon to a forward arrow
                                                label: Text(
                                                  'View Full Order Details',
                                                  style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, color: AppColors.info),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppColors.info.withOpacity(0.1), // Slightly less opaque background
                                                  foregroundColor: AppColors.info,
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14), // Slightly more vertical padding
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Slightly more rounded
                                                  elevation: 0,
                                                  side: BorderSide(color: AppColors.info.withOpacity(0.2), width: 1.0), // Subtle border
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      } else {
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 10.0),
                                          child: Row(
                                            children: [
                                              Text(
                                                'Tap for order details...',
                                                style: textTheme.bodySmall?.copyWith(
                                                  color: AppColors.textMedium,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                              const Spacer(),
                                              // Changed icon to a more subtle chevron
                                              Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMedium.withOpacity(0.7), size: 20),
                                            ],
                                          ),
                                        );
                                      }
                                    }),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Replies Header
                  // ... (previous code)

// Replies Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24.0, 10.0, 24.0, 10.0),
                    child: Row( // Changed from Align to Row
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribute space
                      children: [
                        Text(
                          'Conversation History',
                          style: textTheme.titleMedium?.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        // --- New Warranty Button ---
                        Tooltip(
                          message: 'Ask for warranty card details', // Tooltip text
                          child: IconButton(
                            icon: Icon(Icons.receipt_long, color: AppColors.blinkitGreen, size: 28), // Icon for warranty
                            onPressed: () async {
                              // Check if a query is selected
                              if (query != null) {
                                final String warrantyMessage = "I want the warranty card details for this query/order.";

                                // Set the message in the input controller
                                controller.replyInputController.text = warrantyMessage;

                                // Immediately send the message
                                await controller.replyToQuery(
                                  queryId: query!.id,
                                  replyText: warrantyMessage,
                                );

                                // Clear the input after sending and unfocus keyboard
                                controller.replyInputController.clear();
                                FocusScope.of(context).unfocus();

                                Get.snackbar(
                                  'Message Sent',
                                  'Your request for warranty details has been sent.',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: AppColors.primaryGreen, // Use a success color
                                  colorText: AppColors.white,
                                );
                              } else {
                                Get.snackbar(
                                  'Error',
                                  'Please select a query first to ask for warranty details.',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: Colors.red,
                                  colorText: AppColors.white,
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

// ... (rest of the code)

                  // Replies List
                  // This Expanded widget within a SingleChildScrollView can cause issues
                  // If you need a scrollable list here, it should typically be
                  // within its own flexible container or directly use ListView.builder
                  // with a fixed height if the parent is also scrollable.
                  // For now, let's remove the Expanded here and let SingleChildScrollView handle it.
                  Container( // Removed Expanded, now it takes natural height within SingleChildScrollView
                    margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.primaryPurple.withOpacity(0.2),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.textDark.withOpacity(0.08),
                                blurRadius: 25,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Obx(() {
                            // It seems you intend to show replies for the 'selectedQuery' here.
                            // Access the selectedQuery's replies list.
                            final replies = controller.selectedQuery?.replies ?? [];


                            if (replies.isEmpty) {
                              return Center(
                                child: Text(
                                  controller.selectedQuery == null
                                      ? 'No query selected to show replies.'
                                      : 'No replies yet. Start the conversation!',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textDark.withOpacity(0.6),
                                  ),
                                ),
                              );
                            }

                            // To make ListView.builder scroll independently within the SingleChildScrollView,
                            // it needs a fixed height.
                            // Alternatively, you can use ShrinkWrap.
                            return SizedBox( // Provide a fixed height or use Flexible if within a Column with other widgets
                              height: 300, // Adjust this height as needed, or calculate dynamically
                              child: ListView.builder(
                                reverse: true,
                                padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                                itemCount: replies.length,
                                itemBuilder: (context, index) {
                                  final reply = replies[replies.length - 1 - index];
                                  final isUser = !reply.isAdmin;

                                  return Align(
                                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                      padding: const EdgeInsets.all(16),
                                      constraints: BoxConstraints(maxWidth: Get.width * 0.78),
                                      decoration: BoxDecoration(
                                        color: isUser ? AppColors.accentNeon : AppColors.neutralBackground,
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(18),
                                          topRight: const Radius.circular(18),
                                          bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(6),
                                          bottomRight: isUser ? const Radius.circular(6) : const Radius.circular(18),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: isUser
                                                ? AppColors.accentNeon.withOpacity(0.3)
                                                : AppColors.textDark.withOpacity(0.05),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                        isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            reply.replyText,
                                            style: textTheme.bodyMedium?.copyWith(
                                              fontSize: 16,
                                              color: isUser ? AppColors.white : AppColors.textDark,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            DateFormat('MMM d, hh:mm a').format(reply.timestamp),
                                            style: textTheme.labelSmall?.copyWith(
                                              fontSize: 11,
                                              color: isUser
                                                  ? AppColors.white.withOpacity(0.7)
                                                  : AppColors.textLight.withOpacity(0.8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),


                  // --- Conditional Message Input Field ---
                  if (showChatInput)
                    Container(
                      padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 16.0),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.textDark.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          AnimatedAttachmentButton(
                            onAttachmentSelected: (type) {
                              Get.snackbar(
                                'Attachment Selected',
                                'You selected to add a $type!',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: AppColors.primaryPurple,
                                colorText: AppColors.white,
                              );
                            },
                          ),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: TextField(
                              controller: controller.replyInputController,
                              cursorColor: AppColors.primaryPurple,
                              decoration: InputDecoration(
                                hintText: 'Type your message...',
                                hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textLight.withOpacity(0.7)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                  borderSide: BorderSide(color: AppColors.primaryPurple.withOpacity(0.2), width: 1.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                  borderSide: BorderSide(color: AppColors.accentNeon, width: 2.0),
                                ),
                                filled: true,
                                fillColor: AppColors.neutralBackground,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              ),
                              style: textTheme.bodyMedium?.copyWith(color: AppColors.textDark),
                              maxLines: 5,
                              minLines: 1,
                              keyboardType: TextInputType.multiline,
                              textCapitalization: TextCapitalization.sentences,
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          Obx(() => CircleAvatar(
                            radius: 26,
                            backgroundColor: controller.isLoading ? AppColors.textLight : AppColors.accentNeon,
                            child: IconButton(
                              icon: controller.isLoading
                                  ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2.5))
                                  : const Icon(Icons.send_rounded, color: AppColors.white, size: 26),
                              onPressed: controller.isLoading
                                  ? null
                                  : () async {
                                if (controller.replyInputController.text.trim().isNotEmpty) {
                                  await controller.replyToQuery(
                                    queryId: query!.id,
                                    replyText: controller.replyInputController.text.trim(),
                                  );
                                  FocusScope.of(context).unfocus();
                                }
                              },
                            ),
                          )),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        )
      );
    });
  }

  // --- Helper for displaying detail rows ---
  Widget _buildDetailRow(TextTheme textTheme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textDark.withOpacity(0.8),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textDark),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // --- Rating and Review Modal ---
  void _showRatingReviewModal(BuildContext context, String queryId) {
    final RxInt _selectedRating = 0.obs;
    final TextEditingController _reviewController = TextEditingController();

    Get.bottomSheet(
      Obx(() => SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 5,
                  width: 50,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.textLight.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              Text(
                'Rate Your Support Experience',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkPurple,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 25),
              Text(
                'How would you rate the support you received?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textDark),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _selectedRating.value ? Icons.star_rounded : Icons.star_border_rounded,
                      color: Colors.amber,
                      size: 40,
                    ),
                    onPressed: controller.isLoading ? null : () {
                      _selectedRating.value = index + 1;
                    },
                  );
                }),
              ),
              const SizedBox(height: 25),
              Text(
                'Share Your Feedback (Optional):',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textDark),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _reviewController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'What went well? What could be improved?',
                  hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textLight.withOpacity(0.7)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: AppColors.primaryPurple, width: 1.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: AppColors.primaryPurple.withOpacity(0.3), width: 1.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: AppColors.accentNeon, width: 2.0),
                  ),
                  filled: true,
                  fillColor: AppColors.neutralBackground,
                  contentPadding: const EdgeInsets.all(15),
                ),
                enabled: !controller.isLoading,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.isLoading
                      ? null
                      : () {
                    if (_selectedRating.value == 0) {
                      Get.snackbar(
                        'Rating Required',
                        'Please select a star rating before submitting.',
                        backgroundColor: Colors.red.shade400,
                        colorText: AppColors.white,
                        snackPosition: SnackPosition.TOP,
                      );
                      return;
                    }
                    Get.back();
                    controller.rateQuery(
                      queryId: queryId,
                      rating: _selectedRating.value,
                      review: _reviewController.text.trim().isNotEmpty ? _reviewController.text.trim() : null,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentNeon,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 5,
                  ),
                  child: controller.isLoading
                      ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2.5))
                      : Text(
                    'Submit Rating',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      )),
      isScrollControlled: true,
    );
  }
}
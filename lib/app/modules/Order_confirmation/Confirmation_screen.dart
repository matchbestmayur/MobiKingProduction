// lib/screens/order_confirmation_screen.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:get_storage/get_storage.dart';

// Import your updated theme
import '../../themes/app_theme.dart'; // Contains AppColors & AppTheme

// Assuming these paths are correct
import '../../data/order_model.dart';
import '../bottombar/Bottom_bar.dart';
import '../../services/order_service.dart';

class OrderConfirmationScreen extends StatefulWidget {
  const OrderConfirmationScreen({Key? key}) : super(key: key);

  @override
  State<OrderConfirmationScreen> createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> with SingleTickerProviderStateMixin {
  late final OrderService _orderService = Get.find<OrderService>();
  late AnimationController _lottieController;

  final RxBool _showLottie = true.obs;
  final RxBool _isLottiePlayedOnce = false.obs;

  final Rx<OrderModel?> _confirmedOrder = Rx<OrderModel?>(null);
  final RxBool _isLoadingOrderDetails = true.obs;
  final RxString _errorMessage = ''.obs;

  final GetStorage _box = GetStorage();
  static const String _lastOrderIdKey = 'lastOrderId';

  @override
  void initState() {
    super.initState();
    debugPrint('OrderConfirmationScreen initState called');
    _lottieController = AnimationController(vsync: this);
    _fetchOrderDetailsAndAnimate();
  }

  @override
  void dispose() {
    _lottieController.dispose();
    _showLottie.close();
    _isLottiePlayedOnce.close();
    _confirmedOrder.close();
    _isLoadingOrderDetails.close();
    _errorMessage.close();
    debugPrint('OrderConfirmationScreen dispose called');
    super.dispose();
  }

  Future<void> _fetchOrderDetailsAndAnimate() async {
    _showLottie.value = true;
    _isLottiePlayedOnce.value = false;
    _isLoadingOrderDetails.value = true;
    _errorMessage.value = '';
    _confirmedOrder.value = null;

    debugPrint('[_fetchOrderDetailsAndAnimate] Starting fetch. _showLottie: ${_showLottie.value}, _isLoadingOrderDetails: ${_isLoadingOrderDetails.value}');

    if (_lottieController.duration != null && !_lottieController.isAnimating) {
      _lottieController.forward(from: 0.0);
    }

    final Completer<void> dataFetchCompleter = Completer<void>();
    final String? lastStoredOrderId = _box.read(_lastOrderIdKey);

    debugPrint('[_fetchOrderDetailsAndAnimate] Fetched lastOrderId from GetStorage: $lastStoredOrderId');

    if (lastStoredOrderId == null || lastStoredOrderId.isEmpty) {
      _errorMessage.value = 'No recent order ID found. Please place an order first.';
      dataFetchCompleter.complete();
      debugPrint('[_fetchOrderDetailsAndAnimate] No order ID found, setting error and completing dataFetchCompleter.');
    } else {
      (() async {
        try {
          final fetchedOrder = await _orderService.getOrderDetails(orderId: lastStoredOrderId);
          _confirmedOrder.value = fetchedOrder;
          _errorMessage.value = '';
          debugPrint('[_fetchOrderDetailsAndAnimate] _orderService.getOrderDetails() completed successfully.');
        } catch (e) {
          _errorMessage.value = 'Unexpected error during order fetch: ${e.toString()}';
          debugPrint('[_fetchOrderDetailsAndAnimate] Unexpected error: $e');
        } finally {
          dataFetchCompleter.complete();
          debugPrint('[_fetchOrderDetailsAndAnimate] dataFetchCompleter completed.');
        }
      })();
    }

    try {
      await Future.wait([
        dataFetchCompleter.future,
        Future.delayed(const Duration(seconds: 3)),
      ]);
      debugPrint('[_fetchOrderDetailsAndAnimate] Data fetch and 3-second delay both completed.');
    } catch (e) {
      debugPrint('[_fetchOrderDetailsAndAnimate] Error during Future.wait: $e');
    } finally {
      _isLoadingOrderDetails.value = false;
      debugPrint('[_fetchOrderDetailsAndAnimate] _isLoadingOrderDetails set to false.');

      if (_lottieController.duration != null) {
        if (_lottieController.status == AnimationStatus.completed || _lottieController.value == 1.0) {
          _showLottie.value = false;
          _isLottiePlayedOnce.value = true;
          debugPrint('[_fetchOrderDetailsAndAnimate] Lottie already completed, hiding immediately.');
        } else {
          _lottieController.forward(from: _lottieController.value).then((_) {
            _showLottie.value = false;
            _isLottiePlayedOnce.value = true;
            debugPrint('[_fetchOrderDetailsAndAnimate] Lottie animation finished and hidden.');
          }).onError((error, stackTrace) {
            debugPrint('[_fetchOrderDetailsAndAnimate] Lottie animation completion error: $error');
            _showLottie.value = false;
            _isLottiePlayedOnce.value = true;
          });
        }
      } else {
        _showLottie.value = false;
        _isLottiePlayedOnce.value = true;
        debugPrint('[_fetchOrderDetailsAndAnimate] Lottie duration not available, hiding immediately as fallback.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the global text theme from your AppTheme
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.neutralBackground,
      body: Obx(() {
        debugPrint('--- BUILD TRIGGERED ---');
        debugPrint('Current _isLoadingOrderDetails: ${_isLoadingOrderDetails.value}');
        debugPrint('Current _showLottie: ${_showLottie.value}');
        debugPrint('Current _isLottiePlayedOnce: ${_isLottiePlayedOnce.value}');
        debugPrint('Current _errorMessage: ${_errorMessage.value}');
        debugPrint('Current _confirmedOrder is null: ${_confirmedOrder.value == null}');

        if (_showLottie.value || _isLoadingOrderDetails.value) {
          return _buildLottieAnimation(context, textTheme);
        } else if (_errorMessage.isNotEmpty) {
          return _buildError(context, textTheme);
        } else if (_confirmedOrder.value == null) {
          return _buildNoOrders(context, textTheme);
        } else {
          return _buildOrderDetails(context, textTheme, _confirmedOrder.value!);
        }
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Obx(() {
        if (_showLottie.value ||
            _isLoadingOrderDetails.value ||
            _confirmedOrder.value == null ||
            _errorMessage.isNotEmpty) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ElevatedButton.icon(
            onPressed: () {
              Get.offAll(() => MainContainerScreen());
            },
            icon: const Icon(Icons.shopping_bag_outlined, color: AppColors.white, size: 24),
            label: Text(
              "Continue Shopping",
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.white,
                fontSize: 18,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              minimumSize: const Size.fromHeight(60),
              elevation: 8,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildLottieAnimation(BuildContext context, TextTheme textTheme) {
    return Container(
      color: AppColors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/order.json',
              controller: _lottieController,
              onLoaded: (composition) {
                debugPrint('Lottie animation loaded. Duration: ${composition.duration}');
                if (_lottieController.duration != composition.duration) {
                  _lottieController.duration = composition.duration;
                }
                if (!_isLottiePlayedOnce.value && !_lottieController.isAnimating && _lottieController.status != AnimationStatus.completed) {
                  _lottieController.forward(from: 0.0);
                }
              },
              repeat: false,
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.width * 0.8,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Lottie asset loading error: $error');
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 50, color: AppColors.danger),
                    Text('Failed to load animation.', style: textTheme.bodyMedium?.copyWith(color: AppColors.danger)),
                    Text('Error: $error', style: textTheme.bodySmall?.copyWith(fontSize: 10, color: AppColors.textLight)),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            Obx(
                  () => Text(
                _isLoadingOrderDetails.value
                    ? 'Fetching your order details...'
                    : 'Confirming your order...',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ),
            if (_isLoadingOrderDetails.value)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: CircularProgressIndicator(color: AppColors.textDark, strokeWidth: 3),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, TextTheme textTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, size: 70, color: AppColors.danger),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong while fetching your order. ${_errorMessage.value}',
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(color: AppColors.textDark, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _lottieController.reset();
                _fetchOrderDetailsAndAnimate();
              },
              icon: const Icon(Icons.refresh_rounded, color: AppColors.white),
              label: Text('Retry', style: textTheme.labelLarge?.copyWith(color: AppColors.white, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildNoOrders(BuildContext context, TextTheme textTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_basket_outlined, size: 80, color: AppColors.textDark),
            const SizedBox(height: 24),
            Text(
              'No recent orders to show!',
              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 12),
            Text(
              'It looks like you haven\'t placed any orders yet. Let\'s get you started!',
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(color: AppColors.textLight),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Get.offAll(() => MainContainerScreen());
              },
              icon: const Icon(Icons.shopping_cart_outlined, color: AppColors.white),
              label: Text('Start Shopping', style: textTheme.labelLarge?.copyWith(color: AppColors.white, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetails(BuildContext context, TextTheme textTheme, OrderModel order) {
    final String deliveryAddressText = order.address ?? 'Address not available for this order.';
    final orderTime = order.createdAt != null
        ? DateFormat('dd MMM, HH:mm').format(order.createdAt!.toLocal())
        : 'N/A';

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.check_circle_outline, size: 70, color: AppColors.white),
                const SizedBox(height: 16),
                Text(
                  "Order Confirmed!",
                  style: textTheme.headlineMedium?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 32,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Your order #**${order.orderId ?? 'N/A'}** has been successfully placed.",
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(color: AppColors.white.withOpacity(0.9)),
                ),
                const SizedBox(height: 10),
                Text(
                  "A confirmation email has been sent to ${order.email ?? 'your registered email'}.",
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.white.withOpacity(0.8)),
                ),
                const SizedBox(height: 10),
                Text(
                  "Order placed at: $orderTime",
                  style: textTheme.bodySmall?.copyWith(color: AppColors.white.withOpacity(0.7)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                _sectionTitle(context, textTheme, 'Delivery Address', Icons.location_on_outlined),
                _buildAddressCard(context, textTheme, order),
                const SizedBox(height: 24),
                _sectionTitle(context, textTheme, 'Shipping Details', Icons.local_shipping_outlined),
                _buildShippingDetailsCard(context, textTheme, order),
                const SizedBox(height: 24),
                _sectionTitle(context, textTheme, 'Items in Your Order', Icons.shopping_bag_outlined),
                if (order.items.isNotEmpty)
                  ...order.items.map((item) => _buildOrderItemCard(context, textTheme, item)).toList()
                else
                  Card(
                    color: AppColors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'No items listed for this order.',
                        style: textTheme.bodyMedium?.copyWith(color: AppColors.textLight),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                _sectionTitle(context, textTheme, 'Payment Summary', Icons.summarize_outlined),
                _buildOrderSummary(context, textTheme, order),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, TextTheme textTheme, String title, IconData icon) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textDark, size: 28),
            const SizedBox(width: 10),
            Text(
              title,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
                fontSize: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context, TextTheme textTheme, OrderModel order) {
    final String addressText = (order.address ?? 'Address not available for this order.').toUpperCase();
    final theme = Theme.of(context);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      shadowColor: Colors.black12,
      color: AppColors.neutralBackground,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🏠 RECIPIENT
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.darkPurple.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.home_filled, color: AppColors.darkPurple, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'RECIPIENT: ${order.name?.toUpperCase() ?? 'N/A'}',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// 📍 ADDRESS
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_outlined, size: 20, color: AppColors.textMedium),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    addressText,
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      height: 1.4,
                      color: AppColors.textMedium,
                    ),
                  ),
                ),
              ],
            ),

            /// 📞 PHONE
            if (order.phoneNo != null && order.phoneNo!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.phone_outlined, size: 18, color: AppColors.textLight),
                  const SizedBox(width: 8),
                  Text(
                    order.phoneNo!.toUpperCase(),
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }


  Widget _buildShippingDetailsCard(BuildContext context, TextTheme textTheme, OrderModel order) {
    return Card(
      color: AppColors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRowWithIcon(
              textTheme,
              Icons.local_shipping_outlined,
              'SHIPPING STATUS',
              (order.shippingStatus?.toUpperCase() ?? 'N/A'),
            ),
            if (order.courierName != null && order.courierName!.isNotEmpty)
              _detailRowWithIcon(
                textTheme,
                Icons.send_outlined,
                'COURIER',
                order.courierName!.toUpperCase(),
              ),
            if (order.awbCode != null && order.awbCode!.isNotEmpty)
              _detailRowWithIcon(
                textTheme,
                Icons.numbers_outlined,
                'AWB CODE',
                order.awbCode!.toUpperCase(),
              ),
            if (order.expectedDeliveryDate != null && order.expectedDeliveryDate!.isNotEmpty)
              _detailRowWithIcon(
                textTheme,
                Icons.calendar_today_outlined,
                'EXPECTED DELIVERY',
                DateFormat('dd MMM yyyy').format(
                  DateTime.tryParse(order.expectedDeliveryDate!) ?? DateTime.now(),
                ).toUpperCase(),
              ),
            if (order.deliveredAt != null && order.deliveredAt!.isNotEmpty)
              _detailRowWithIcon(
                textTheme,
                Icons.check_circle_outline,
                'DELIVERED ON',
                DateFormat('dd MMM yyyy, hh:mm a').format(
                  DateTime.tryParse(order.deliveredAt!) ?? DateTime.now(),
                ).toUpperCase(),
              ),
            _detailRowWithIcon(
              textTheme,
              Icons.payment_outlined,
              'PAYMENT METHOD',
              (order.method?.toUpperCase() ?? 'N/A'),
            ),
            if (order.razorpayPaymentId != null && order.razorpayPaymentId!.isNotEmpty)
              _detailRowWithIcon(
                textTheme,
                Icons.credit_card_outlined,
                'RAZORPAY ID',
                order.razorpayPaymentId!.toUpperCase(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _detailRowWithIcon(TextTheme textTheme, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.textLight),
          const SizedBox(width: 10),
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
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
  Widget _buildOrderItemCard(BuildContext context, TextTheme textTheme, OrderItemModel item) {
    final String imageUrl = item.productDetails?.images?.isNotEmpty == true
        ? item.productDetails!.images!.first
        : 'https://via.placeholder.com/70/D1C4E9/757575?text=No+Image';

    return Card(
      color: AppColors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                height: 65,
                width: 65,
                fit: BoxFit.fill,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 65,
                  width: 65,
                  decoration: BoxDecoration(
                    color: AppColors.lightPurple.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.image_not_supported, color: AppColors.textLight, size: 30),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 🧾 Product Name
                  Text(
                    (item.productDetails?.fullName ?? item.productDetails?.name ?? 'PRODUCT NAME N/A').toUpperCase(),
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: AppColors.textDark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  /// 📦 Variant (if any)
                  if (item.variantName.isNotEmpty && item.variantName != 'Default')
                    Text(
                      item.variantName.toUpperCase(),
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.textMedium,
                        fontSize: 10,
                      ),
                    ),

                  /// 🔢 Quantity & Price
                  Text(
                    "QTY: ${item.quantity} x ${NumberFormat.simpleCurrency(locale: 'en_IN', decimalDigits: 2).format(item.price)}",
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.textMedium,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            /// 💰 Total Price
            Text(
              NumberFormat.simpleCurrency(locale: 'en_IN', decimalDigits: 2).format(item.price * item.quantity),
              style: textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 11.5,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(BuildContext context, TextTheme textTheme, OrderModel order) {
    return Card(
      color: AppColors.neutralBackground, // Soft neutral background
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ORDER SUMMARY',
              style: textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: AppColors.textDark,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),

            _buildSummaryRow(context, textTheme, "Subtotal", order.subtotal ?? 0.0),
            if ((order.discount ?? 0.0) > 0)
              _buildSummaryRow(context, textTheme, "Discount", -(order.discount ?? 0.0), isDiscount: true),
            _buildSummaryRow(context, textTheme, "Delivery Fee", order.deliveryCharge),
            _buildSummaryRow(context, textTheme, "GST", double.tryParse(order.gst ?? '0.0') ?? 0.0),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(thickness: 1, color: Color(0xFFE0E0E0)),
            ),

            _buildSummaryRow(context, textTheme, "Grand Total", order.orderAmount, isTotal: true),
          ],
        ),
      ),
    );
  }


  Widget _buildSummaryRow(BuildContext context, TextTheme textTheme, String title, double value,
      {bool isTotal = false, bool isDiscount = false}) {
    final formattedValue = NumberFormat.simpleCurrency(locale: 'en_IN', decimalDigits: 2).format(value);

    final style = textTheme.labelSmall?.copyWith(
      fontSize: isTotal ? 12.5 : 11,
      fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
      color: isDiscount
          ? AppColors.danger
          : isTotal
          ? AppColors.textDark
          : AppColors.textMedium,
    );

    IconData getIconForTitle(String title) {
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(getIconForTitle(title), size: isTotal ? 18 : 16, color: AppColors.textMedium),
              const SizedBox(width: 8),
              Text(title.toUpperCase(), style: style),
            ],
          ),
          Text(formattedValue, style: style),
        ],
      ),
    );
  }

}
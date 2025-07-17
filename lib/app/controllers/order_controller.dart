// app/controllers/order_controller.dart
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';
import 'package:mobiking/app/controllers/connectivity_controller.dart';
import 'package:mobiking/app/modules/Order_confirmation/Confirmation_screen.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
// Import your data models
import '../data/AddressModel.dart';
import '../data/Order_get_data.dart'; // Contains CreateOrderRequestModel
import '../data/order_model.dart'; // The full OrderModel (Response Model) - CRUCIAL to have 'requests' field
import '../data/razor_pay.dart'; // Contains RazorpayVerifyRequest
// Import your controllers and services
import '../controllers/cart_controller.dart';
import '../controllers/address_controller.dart';
import '../modules/bottombar/Bottom_bar.dart' show MainContainerScreen;
import '../modules/checkout/widget/user_info_dialog_content.dart';
import '../services/order_service.dart';
import '../themes/app_theme.dart';

// Helper function for themed snackbars
void _showModernSnackbar(String title, String message, {
  IconData? icon,
  Color? backgroundColor,
  Color? textColor,
  SnackPosition snackPosition = SnackPosition.TOP,
  Duration? duration,
  EdgeInsets? margin,
  double? borderRadius,
  bool isError = false,
}) {
  if (Get.isSnackbarOpen) Get.back();
  Get.snackbar(
    title,
    message,
    snackPosition: snackPosition,
    backgroundColor: backgroundColor ?? (isError ? AppColors.danger : AppColors.primaryPurple),
    colorText: textColor ?? Colors.white,
    icon: icon != null ? Icon(icon, color: textColor ?? Colors.white) : null,
    margin: margin ?? const EdgeInsets.all(16),
    borderRadius: borderRadius ?? 12,
    animationDuration: const Duration(milliseconds: 300),
    duration: duration ?? const Duration(seconds: 3),
    isDismissible: true,
    forwardAnimationCurve: Curves.easeOutBack,
    reverseAnimationCurve: Curves.easeInBack,
  );
}

class OrderController extends GetxController {
  final GetStorage _box = GetStorage();
  final OrderService _orderService = Get.find<OrderService>();
  final ConnectivityController _connectivityController = Get.find<ConnectivityController>();
  final CartController _cartController = Get.find<CartController>();
  final AddressController _addressController = Get.find<AddressController>();
  var isLoading = false.obs;
  var orderHistory = <OrderModel>[].obs;
  var isLoadingOrderHistory = false.obs;
  var orderHistoryErrorMessage = ''.obs;
  late Razorpay _razorpay;
  String? _currentBackendOrderId;
  String? _currentRazorpayOrderId;

  static const List<String> STATUS_PROGRESS = [
    "Picked Up",
    "IN TRANSIT",
    "Shipped",
    "Delivered",
    "Returned",
    "CANCELLED",
    "Cancelled",
  ];

  var selectedReasonForRequest = ''.obs;

  final List<String> predefinedReasons = [
    'Ordered wrong item',
    'Found cheaper price',
    'Delivery taking too long',
    'Need to change address',
    'Other (please specify)',
  ];

  @override
  void onInit() {
    super.onInit();
    fetchOrderHistory();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    print('Razorpay initialized and listeners registered.');

    ever(_connectivityController.isConnected, (bool isConnected) {
      if (isConnected) {
        _handleConnectionRestored();
      }
    });
  }

  Future<void> _handleConnectionRestored() async {
    print('OrderController: Internet connection restored. Re-fetching order history...');
    await fetchOrderHistory();
  }

  double _calculateSubtotal() {
    return _cartController.cartItems.fold(0.0, (sum, item) {
      final productData = item['productId'] as Map<String, dynamic>?;
      if (productData != null && productData.containsKey('sellingPrice') && productData['sellingPrice'] is List) {
        final List sellingPrices = productData['sellingPrice'];
        if (sellingPrices.isNotEmpty && sellingPrices[0] is Map<String, dynamic>) {
          final double price = (sellingPrices[0]['price'] as num?)?.toDouble() ?? 0.0;
          final int quantity = (item['quantity'] as num?)?.toInt() ?? 1;
          return sum + (price * quantity);
        }
      }
      return sum;
    });
  }

  @override
  void onClose() {
    _razorpay.clear();
    print('Razorpay listeners cleared.');
    super.onClose();
  }

  // --- Razorpay Payment Callbacks ---
  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    print('Razorpay Payment Success: ${response.paymentId}, ${response.orderId}, ${response.signature}');
    isLoading.value = true;
    try {
      if (_currentBackendOrderId == null || _currentRazorpayOrderId == null) {
        _showModernSnackbar(
          'Payment Success, but data missing!',
          'Could not retrieve backend order data for verification. Please contact support with Payment ID: ${response.paymentId}',
          isError: true,
          icon: Icons.error_outline,
          backgroundColor: Colors.orange.shade700,
        );
        return;
      }
      final verifyRequest = RazorpayVerifyRequest(
        razorpayPaymentId: response.paymentId!,
        razorpayOrderId: response.orderId!,
        razorpaySignature: response.signature!,
        orderId: _currentBackendOrderId!,
      );
      print('Calling backend for payment verification...');
      final verifiedOrder = await _orderService.verifyRazorpayPayment(verifyRequest);
      print('Backend verification successful for order: ${verifiedOrder.orderId}');
      await _box.write('last_placed_order', verifiedOrder.toJson());
      _cartController.clearCartData();
      _showModernSnackbar(
        'Order Placed!',
        'Your order ID ${verifiedOrder.orderId ?? 'N/A'} has been placed successfully!',
        isError: false,
        icon: Icons.receipt_long_outlined,
        backgroundColor: Colors.green.shade600,
        snackPosition: SnackPosition.TOP,
      );
      Get.offAll(() => OrderConfirmationScreen());
    } on OrderServiceException catch (e) {
      _showModernSnackbar(
        'Payment Verification Failed!',
        e.message,
        isError: true,
        icon: Icons.cancel_outlined,
        backgroundColor: Colors.red.shade400,
        snackPosition: SnackPosition.TOP,
      );
      print('Razorpay Verification Service Error: Status ${e.statusCode} - Message: ${e.message}');
    } catch (e) {
      _showModernSnackbar(
        'Payment Verification Error!',
        'An unexpected error occurred during payment verification: $e',
        isError: true,
        icon: Icons.cloud_off_outlined,
        backgroundColor: Colors.red.shade400,
        snackPosition: SnackPosition.TOP,
      );
      print('Razorpay Verification Unexpected Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print('Razorpay Payment Error: Code ${response.code} - Description: ${response.message}');
    isLoading.value = false;
    _showModernSnackbar(
      'Payment Failed!',
      'Code: ${response.code}\nDescription: ${response.message}',
      isError: true,
      icon: Icons.payments,
      backgroundColor: Colors.red.shade700,
      snackPosition: SnackPosition.TOP,
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print('External Wallet Selected: ${response.walletName}');
    _showModernSnackbar(
      'External Wallet Selected!',
      'Wallet: ${response.walletName ?? 'Unknown'}',
      isError: false,
      icon: Icons.account_balance_wallet_outlined,
      backgroundColor: Colors.blue.shade400,
      snackPosition: SnackPosition.TOP,
    );
  }

  // --- Main placeOrder method ---
  Future<void> placeOrder({required String method}) async {
    _currentBackendOrderId = null;
    _currentRazorpayOrderId = null;

    if (_cartController.cartItems.isEmpty) {
      _showModernSnackbar(
        'Cart Empty!',
        'Your cart is empty. Please add items before placing an order.',
        isError: true,
        icon: Icons.shopping_cart_outlined,
        backgroundColor: Colors.red.shade400,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    final AddressModel? address = _addressController.selectedAddress.value;
    if (address == null) {
      _showModernSnackbar(
        'Address Required!',
        'Please select a shipping address to proceed.',
        isError: true,
        icon: Icons.location_off_outlined,
        backgroundColor: Colors.amber.shade700,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    Map<String, dynamic> user = Map<String, dynamic>.from(_box.read('user') ?? {});
    String? userId = user['_id'];
    String? name = user['name'];
    String? email = user['email'];
    String? phone = user['phoneNo'] ?? user['phone'];

    bool userInfoIncomplete = [userId, name, email, phone].any((e) => e == null || e.toString().trim().isEmpty);
    if (userInfoIncomplete) {
      final bool detailsConfirmed = await _promptUserInfo();
      if (!detailsConfirmed) {
        _showModernSnackbar(
          'Details Not Saved',
          'User details were not updated. Please fill them out to proceed with your order.',
          icon: Icons.info_outline_rounded,
          backgroundColor: AppColors.textLight.withOpacity(0.8),
          isError: false,
          snackPosition: SnackPosition.TOP,
        );
        return;
      }
      user = Map<String, dynamic>.from(_box.read('user') ?? {});
      userId = user['_id'];
      name = user['name'];
      email = user['email'];
      phone = user['phoneNo'] ?? user['phone'];
      if ([userId, name, email, phone].any((e) => e == null || e.toString().trim().isEmpty)) {
        _showModernSnackbar(
          'User Info Incomplete!',
          'Despite confirming, some profile details are still missing. Please try again.',
          isError: true,
          icon: Icons.person_off_outlined,
          backgroundColor: Colors.red.shade400,
          snackPosition: SnackPosition.TOP,
        );
        return;
      }
    }

    final cartId = _cartController.cartData['_id'];
    if (cartId == null) {
      _showModernSnackbar(
        'Cart Error!',
        'Could not find your cart ID. Please try again or re-add items.',
        isError: true,
        icon: Icons.shopping_cart_checkout_outlined,
        backgroundColor: Colors.red.shade400,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    final CreateUserReferenceRequestModel userRefRequest = CreateUserReferenceRequestModel(
      id: userId!,
      email: email!,
      phoneNo: phone!,
    );

    final double subtotal = _calculateSubtotal();
    const double deliveryCharge = 45.0;
    final double gst = 0.0;
    final double total = subtotal + deliveryCharge;

    final List<CreateOrderItemRequestModel> orderItemsRequest = [];
    for (var cartItem in _cartController.cartItems) {
      final productData = cartItem['productId'] as Map<String, dynamic>?;
      final variantName = cartItem['variantName'] as String? ?? 'Default';
      final int quantity = (cartItem['quantity'] as num?)?.toInt() ?? 1;
      if (productData == null) {
        print('Error: Product data is null for cart item: $cartItem');
        continue;
      }
      final String productIdString = productData['_id'] as String? ?? '';
      if (productIdString.isEmpty) {
        print('Error: Product ID missing for cart item: $cartItem');
        continue;
      }
      double itemPrice = 0.0;
      if (productData.containsKey('sellingPrice') && productData['sellingPrice'] is List) {
        final List<dynamic> sellingPricesList = productData['sellingPrice'];
        if (sellingPricesList.isNotEmpty && sellingPricesList[0] is Map<String, dynamic>) {
          itemPrice = (sellingPricesList[0]['price'] as num?)?.toDouble() ?? 0.0;
        }
      }
      orderItemsRequest.add(CreateOrderItemRequestModel(
        productId: productIdString,
        variantName: variantName,
        quantity: quantity,
        price: itemPrice,
      ));
    }

    final AddressController addressController = Get.find<AddressController>();
    String? addressId;
    if (addressController.selectedAddress.value != null) {
      addressId = addressController.selectedAddress.value!.id;
    }

    final createOrderRequest = CreateOrderRequestModel(
      userId: userRefRequest,
      cartId: cartId,
      name: name!,
      email: email!,
      phoneNo: phone!,
      orderAmount: total,
      discount: 0,
      deliveryCharge: deliveryCharge,
      gst: gst,
      subtotal: subtotal,
      address: '${address.street}, ${address.city}, ${address.state}, ${address.pinCode}',
      method: method,
      items: orderItemsRequest,
      addressId: addressId,
    );

    try {
      isLoading.value = true;
      if (method == 'COD') {
        final createdOrder = await _orderService.placeCodOrder(createOrderRequest);
        await _box.write('last_placed_order', createdOrder.toJson());
        _cartController.clearCartData();

        _showModernSnackbar(
          'Order Placed! Awaiting Confirmation Call',
          'You will receive a call for confirmation shortly. If the call is not picked up, your order will be cancelled automatically.',
          isError: false,
          icon: Icons.phone_callback_outlined,
          backgroundColor: Colors.blueAccent.shade400,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 7),
        );

        Get.offAll(() => OrderConfirmationScreen());
      } else if (method == 'Online') {
        print('Initiating online payment with backend...');
        final Map<String, dynamic> initiateResponse = await _orderService.initiateOnlineOrder(createOrderRequest);
        print('Backend initiate response: $initiateResponse');

        final String? razorpayOrderId = initiateResponse['razorpayOrderId'] as String?;
        final int? amountInPaise = initiateResponse['amount'] as int?;
        final String? currency = initiateResponse['currency'] as String?;
        final String? razorpayKey = initiateResponse['key'] as String?;
        final String? newOrderId = initiateResponse['newOrderId'] as String?;

        if (razorpayOrderId == null || amountInPaise == null || currency == null || razorpayKey == null || newOrderId == null) {
          throw OrderServiceException(
            'Missing essential Razorpay initiation data from backend.',
            statusCode: 500,
          );
        }

        _currentBackendOrderId = newOrderId;
        _currentRazorpayOrderId = razorpayOrderId;

        final Map<String, dynamic> options = {
          'key': razorpayKey,
          'amount': amountInPaise,
          'name': 'MobiKing E-commerce',
          'description': 'Order from MobiKing',
          'order_id': _currentRazorpayOrderId,
          'currency': currency,
          'prefill': {
            'email': email,
            'contact': phone,
          },
          'external': {
            'wallets': ['paytm', 'google_pay'],
          },
          'theme': {
            'color': '#3399FF'
          },
        };

        print('Opening Razorpay checkout with options: $options');
        _razorpay.open(options);
      } else {
        isLoading.value = false;
        _showModernSnackbar(
          'Payment Method Invalid!',
          'The selected payment method is not currently supported.',
          isError: true,
          icon: Icons.not_interested_outlined,
          backgroundColor: Colors.red.shade400,
          snackPosition: SnackPosition.TOP,
        );
        return;
      }
    } on OrderServiceException catch (e) {
      _showModernSnackbar(
        'Order Failed!',
        e.message,
        isError: true,
        icon: Icons.cancel_outlined,
        backgroundColor: Colors.orange.shade700,
        snackPosition: SnackPosition.TOP,
      );
      print('Place Order Service Error: Status ${e.statusCode} - Message: ${e.message}');
      isLoading.value = false;
    } catch (e) {
      _showModernSnackbar(
        'Order Error!',
        'An unexpected client-side error occurred: $e. Please try again later.',
        isError: true,
        icon: Icons.cloud_off_outlined,
        backgroundColor: Colors.red.shade400,
        snackPosition: SnackPosition.TOP,
      );
      print('Place Order Unexpected Error: $e');
      isLoading.value = false;
    }
  }

  Future<void> fetchOrderHistory() async {
    isLoadingOrderHistory.value = true;
    orderHistoryErrorMessage.value = '';
    try {
      final List<OrderModel> fetchedOrders = await _orderService.getUserOrders();
      if (fetchedOrders.isNotEmpty) {
        fetchedOrders.sort((a, b) => b.createdAt?.compareTo(a.createdAt ?? DateTime(0)) ?? 0);
        orderHistory.assignAll(fetchedOrders);
        print('OrderController: Fetched ${orderHistory.length} orders successfully.');
      } else {
        orderHistory.clear();
        orderHistoryErrorMessage.value = 'No order history found.';
        _showModernSnackbar(
          'No Orders Yet',
          orderHistoryErrorMessage.value,
          isError: false,
          icon: Icons.shopping_bag_outlined,
          backgroundColor: Colors.blue.shade400,
          snackPosition: SnackPosition.TOP,
        );
      }
    } on OrderServiceException catch (e) {
      orderHistory.clear();
      orderHistoryErrorMessage.value = e.message;
      _showModernSnackbar(
        'Order History Failed!',
        e.message,
        isError: true,
        icon: e.statusCode == 401
            ? Icons.login_outlined
            : (e.statusCode == 0 ? Icons.cloud_off_outlined : Icons.history_toggle_off_outlined),
        backgroundColor: e.statusCode == 401
            ? Colors.orange.shade700
            : (e.statusCode == 0 ? Colors.red.shade700 : Colors.red.shade400),
        snackPosition: SnackPosition.TOP,
      );
      print('OrderController: Order History Service Error: Status ${e.statusCode} - Message: ${e.message}');
    } catch (e) {
      orderHistory.clear();
      orderHistoryErrorMessage.value = 'An unexpected error occurred while processing orders: $e';
      _showModernSnackbar(
        'Critical Error',
        'An unexpected client-side error occurred: $e',
        isError: true,
        icon: Icons.bug_report_outlined,
        backgroundColor: Colors.red.shade700,
        snackPosition: SnackPosition.TOP,
      );
      print('OrderController: Unexpected Exception in fetchOrderHistory: $e');
    } finally {
      isLoadingOrderHistory.value = false;
    }
  }

  OrderModel? getOrderById(String orderId) {
    return orderHistory.firstWhereOrNull((order) => order.id == orderId);
  }

  Future<bool> _promptUserInfo() async {
    final GetStorage _box = GetStorage();
    final user = _box.read('user') ?? {};
    final bool? result = await Get.to<bool?>(
          () => UserInfoScreen(initialUser: user),
      fullscreenDialog: true,
      transition: Transition.rightToLeft,
    );
    return result ?? false;
  }

  Future<void> sendOrderRequest(String orderId, String requestType) async {
    selectedReasonForRequest.value = '';
    final TextEditingController reasonController = TextEditingController();

    final bool? dialogResult = await Get.dialog<bool>(
      GestureDetector(
        onTap: () => FocusScope.of(Get.context!).unfocus(),
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: AppColors.white,
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 10, 0),
          contentPadding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${requestType.capitalizeFirst} Request',
                  style: Get.textTheme.titleMedium?.copyWith(color: AppColors.textDark, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: AppColors.textLight),
                onPressed: () => Get.back(result: false),
                splashRadius: 20,
              ),
            ],
          ),
          content: Obx(() => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text(
                    'Select a reason for your ${requestType.toLowerCase()}:',
                    style: Get.textTheme.bodyMedium?.copyWith(color: AppColors.textMedium, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 10),
                ...predefinedReasons.map((reasonOption) {
                  return RadioListTile<String>(
                    title: Text(
                      reasonOption,
                      style: Get.textTheme.bodyMedium?.copyWith(color: AppColors.textDark, fontWeight: FontWeight.w500),
                    ),
                    value: reasonOption,
                    groupValue: selectedReasonForRequest.value,
                    onChanged: (String? value) {
                      selectedReasonForRequest.value = value!;
                    },
                    activeColor: AppColors.primaryPurple,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10.0),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
                if (selectedReasonForRequest.value == 'Other (please specify)')
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: TextField(
                      controller: reasonController,
                      maxLines: 3,
                      minLines: 2,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      style: Get.textTheme.bodyLarge?.copyWith(color: AppColors.textDark),
                      decoration: InputDecoration(
                        hintText: 'Please specify your reason here...',
                        hintStyle: Get.textTheme.bodyMedium?.copyWith(color: AppColors.textLight, fontStyle: FontStyle.italic),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.neutralBackground),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.primaryPurple, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.white),
                        ),
                        filled: true,
                        fillColor: AppColors.neutralBackground,
                      ),
                    ),
                  ),
              ],
            ),
          )),
          actions: [
            Center(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    String currentReason = selectedReasonForRequest.value;
                    if (currentReason.isEmpty) {
                      _showModernSnackbar('Reason Required', 'Please select a reason.', isError: true, icon: Icons.info_outline, backgroundColor: Colors.orange);
                    } else if (currentReason == 'Other (please specify)' && (reasonController.text.trim().isEmpty || reasonController.text.trim().length < 10)) {
                      _showModernSnackbar(
                        'Reason Required',
                        reasonController.text.trim().isEmpty ? 'Please enter a reason for "Other (please specify)".' : 'Reason must be at least 10 characters long.',
                        isError: true,
                        icon: Icons.info_outline,
                        backgroundColor: Colors.orange,
                      );
                    } else {
                      Get.back(result: true);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 3,
                  ),
                  child: Text(
                    'Place Request',
                    style: Get.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, color: AppColors.white),
                  ),
                ),
              ),
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        ),
      ),
    );

    reasonController.dispose();
    if (dialogResult == null || !dialogResult) {
      print('$requestType request cancelled by user or no reason provided.');
      return;
    }

    String finalReasonToSend;
    if (selectedReasonForRequest.value == 'Other (please specify)') {
      finalReasonToSend = reasonController.text.trim();
    } else {
      finalReasonToSend = selectedReasonForRequest.value;
    }

    isLoading.value = true;
    try {
      Map<String, dynamic> response;
      String successMessage;
      switch (requestType) {
        case 'Cancel':
          response = await _orderService.requestCancel(orderId, finalReasonToSend);
          successMessage = 'Cancel request sent successfully!';
          break;
        case 'Return':
          response = await _orderService.requestReturn(orderId, finalReasonToSend);
          successMessage = 'Return request sent successfully!';
          break;
        default:
          throw Exception('Invalid request type: $requestType');
      }

      _showModernSnackbar('Success', successMessage, isError: false, icon: Icons.check_circle_outline, backgroundColor: Colors.green);
      await fetchOrderHistory();
    } on OrderServiceException catch (e) {
      _showModernSnackbar('Request Failed', e.message, isError: true, icon: Icons.error_outline, backgroundColor: Colors.red);
    } catch (e) {
      _showModernSnackbar('Error', 'An unexpected error occurred: $e', isError: true, icon: Icons.error_outline, backgroundColor: Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  bool _isSpecificRequestActive(OrderModel order, String type) {
    if (order.requests == null || order.requests!.isEmpty) return false;
    return order.requests!.any((r) {
      final requestType = r.type.toLowerCase();
      final status = r.status.toLowerCase();
      return requestType == type.toLowerCase() &&
          status != 'rejected' &&
          status != 'resolved' &&
          status != 'completed';
    });
  }

  bool showCancelButton(OrderModel order) {
    final bool isOrderCancellable = ['new', 'accepted'].contains(order.status.toLowerCase());
    final bool hasActiveCancelRequest = _isSpecificRequestActive(order, 'Cancel');
    return isOrderCancellable && !hasActiveCancelRequest;
  }

  bool showReturnButton(OrderModel order) {
    final bool isOrderDelivered = order.status.toLowerCase() == 'delivered';
    final bool withinReturnPeriod = isOrderDelivered && order.deliveredAt != null &&
        DateTime.now().difference(DateTime.tryParse(order.deliveredAt!) ?? DateTime(0)).inDays <= 7;
    final bool hasActiveReturnRequest = _isSpecificRequestActive(order, 'Return');
    return withinReturnPeriod && !hasActiveReturnRequest;
  }
}

class OrderServiceException implements Exception {
  final String message;
  final int? statusCode;
  OrderServiceException(this.message, {this.statusCode});
  @override
  String toString() => 'OrderServiceException: $message (Status: $statusCode)';
}
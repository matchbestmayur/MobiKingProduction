// app/controllers/order_controller.dart
import 'dart:async';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';
import 'package:mobiking/app/controllers/connectivity_controller.dart';
import 'package:mobiking/app/modules/Order_confirmation/Confirmation_screen.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

// Import your data models
import '../data/AddressModel.dart';
import '../data/Order_get_data.dart';
import '../data/order_model.dart';
import '../data/razor_pay.dart';

// Import your controllers and services
import '../controllers/cart_controller.dart';
import '../controllers/address_controller.dart';
import '../modules/address/AddressPage.dart';
import '../modules/bottombar/Bottom_bar.dart' show MainContainerScreen;
import '../modules/checkout/widget/user_info_dialog_content.dart';
import '../services/order_service.dart';
import '../themes/app_theme.dart';

// Helper classes for better organization
class UserInfo {
  final String userId;
  final String name;
  final String email;
  final String phone;

  UserInfo({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
  });
}

class OrderTotals {
  final double subtotal;
  final double deliveryCharge;
  final double gst;
  final double discount;
  final double total;

  OrderTotals({
    required this.subtotal,
    required this.deliveryCharge,
    required this.gst,
    required this.discount,
    required this.total,
  });
}

// Helper function for themed snackbars
void _showModernSnackbar(
    String title,
    String message, {
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
    '',
    '',
    titleText: Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: textColor ?? Colors.white,
      ),
    ),
    messageText: Text(
      message,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: textColor ?? Colors.white.withOpacity(0.9),
      ),
    ),
    icon: icon != null
        ? Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: textColor ?? Colors.white, size: 20),
    )
        : null,
    snackPosition: snackPosition,
    backgroundColor:
    backgroundColor ?? (isError ? const Color(0xFFB00020) : const Color(0xFF1E88E5)),
    colorText: textColor ?? Colors.white,
    margin: margin ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    borderRadius: borderRadius ?? 16,
    animationDuration: const Duration(milliseconds: 400),
    duration: duration ?? const Duration(seconds: 3),
    isDismissible: true,
    shouldIconPulse: false,
    forwardAnimationCurve: Curves.easeOutBack,
    reverseAnimationCurve: Curves.easeInBack,
    boxShadows: [
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
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
  var orderHistoryErrorMessage = ''.obs;
  late Razorpay _razorpay;
  String? _currentBackendOrderId;
  String? _currentRazorpayOrderId;
  Timer? _pollingTimer;
  final RxBool isInitialLoading = true.obs;
  final RxBool isLoadingOrderHistory = false.obs;

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

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    print('Razorpay Payment Success: ${response.paymentId}, ${response.orderId}, ${response.signature}');
    isLoading.value = true;

    try {
      if (_currentBackendOrderId == null || _currentRazorpayOrderId == null) {
        return;
      }

      final verifyRequest = RazorpayVerifyRequest(
        razorpayPaymentId: response.paymentId!,
        razorpayOrderId: response.orderId!,
        razorpaySignature: response.signature!,
        orderId: _currentBackendOrderId!,
      );

      print('Calling backend for payment verification... 🔄');

      final verifiedOrder = await _orderService.verifyRazorpayPayment(verifyRequest);
      print('Backend verification successful for order: ${verifiedOrder.orderId} ✅');

      await _completeOrderSuccess(verifiedOrder);

      _showSuccessSnackbar(
        'Order Placed! 🎉',
        'Your order ID ${verifiedOrder.orderId ?? 'N/A'} has been placed successfully!',
        Icons.receipt_long_outlined,
        backgroundColor: Colors.green.shade600,
      );

      Get.offAll(() => OrderConfirmationScreen());
    } on OrderServiceException catch (e) {
      print('OrderServiceException: Status ${e.statusCode} - ${e.message}');
    } catch (e) {
      print('Unexpected Exception: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print('Razorpay Payment Error: Code ${response.code} - Description: ${response.message}');
    isLoading.value = false;
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print('External Wallet Selected: ${response.walletName}');
    _showInfoSnackbar(
      'External Wallet Selected!',
      'Wallet: ${response.walletName ?? 'Unknown'}',
      Icons.account_balance_wallet_outlined,
    );
  }

  // Main placeOrder method - OPTIMIZED
  Future<void> placeOrder({required String method}) async {
    await _resetOrderState();

    debugPrint('--- placeOrder method called with method: $method ---');

    // Early validation checks
    if (!await _validateOrderPrerequisites()) return;

    // Get and validate user info
    final UserInfo? userInfo = await _validateAndGetUserInfo();
    if (userInfo == null) return;

    // Build order request
    final CreateOrderRequestModel? orderRequest = await _buildOrderRequest(
      userInfo: userInfo,
      method: method,
    );
    if (orderRequest == null) return;

    // Process order based on payment method
    await _processOrder(method: method, orderRequest: orderRequest);
  }

  // Reset order state
  Future<void> _resetOrderState() async {
    _currentBackendOrderId = null;
    _currentRazorpayOrderId = null;
    isLoading.value = false;
  }

  // Validate basic order prerequisites
  Future<bool> _validateOrderPrerequisites() async {
    if (_cartController.cartItems.isEmpty) {
      debugPrint('🛑 Cart is empty. Aborting order placement.');
      return false;
    }

    final AddressModel? address = _addressController.selectedAddress.value;
    if (address == null) {
      debugPrint('🛑 Address is null. Aborting order placement.');
      return false;
    }

    debugPrint('✅ Prerequisites validated - Cart: ${_cartController.cartItems.length} items, Address: ${address.street}');
    return true;
  }

  // Validate and get user info
  Future<UserInfo?> _validateAndGetUserInfo() async {
    Map<String, dynamic> user = Map<String, dynamic>.from(_box.read('user') ?? {});
    String? userId = user['_id'];
    String? name = user['name'];
    String? email = user['email'];
    String? phone = user['phoneNo'] ?? user['phone'];

    if (_isUserInfoIncomplete(userId, name, email, phone)) {
      debugPrint('⚠️ User info incomplete. Prompting...');

      isLoading.value = false; // ✅ Ensure loading is false for navigation

      final bool detailsConfirmed = await _promptUserInfo();
      if (!detailsConfirmed) {
        debugPrint('🛑 User info not confirmed. Aborting order placement.');
        _showInfoSnackbar(
          'Details Not Saved',
          'User details were not updated. Please fill them out to proceed with your order.',
          Icons.info_outline_rounded,
        );
        return null;
      }

      // Refresh user data after prompt
      user = Map<String, dynamic>.from(_box.read('user') ?? {});
      userId = user['_id'];
      name = user['name'];
      email = user['email'];
      phone = user['phoneNo'] ?? user['phone'];

      if (_isUserInfoIncomplete(userId, name, email, phone)) {
        debugPrint('🛑 User info still incomplete after prompt. Aborting.');
        return null;
      }
    }

    debugPrint('✅ User info verified: ID=$userId, Name=$name, Email=$email, Phone=$phone');

    return UserInfo(
      userId: userId!,
      name: name!,
      email: email!,
      phone: phone!,
    );
  }

  // Check if user info is incomplete
  bool _isUserInfoIncomplete(String? userId, String? name, String? email, String? phone) {
    return [userId, name, email, phone]
        .any((field) => field == null || field.trim().isEmpty);
  }

  // Build order request
  Future<CreateOrderRequestModel?> _buildOrderRequest({
    required UserInfo userInfo,
    required String method,
  }) async {
    final cartId = _cartController.cartData['_id'];
    if (cartId == null) {
      debugPrint('🛑 Cart ID is null. Aborting order placement.');
      return null;
    }

    final List<CreateOrderItemRequestModel> orderItems = _buildOrderItems();
    if (orderItems.isEmpty) {
      debugPrint('🛑 No valid order items found. Aborting.');
      return null;
    }

    final OrderTotals totals = _calculateOrderTotals();
    final AddressModel address = _addressController.selectedAddress.value!;
    final String? addressId = _addressController.selectedAddress.value?.id;

    debugPrint('✅ Order request built - Items: ${orderItems.length}, Total: ${totals.total}');

    return CreateOrderRequestModel(
      userId: CreateUserReferenceRequestModel(
        id: userInfo.userId,
        email: userInfo.email,
        phoneNo: userInfo.phone,
      ),
      cartId: cartId,
      name: userInfo.name,
      email: userInfo.email,
      phoneNo: userInfo.phone,
      orderAmount: totals.total,
      discount: totals.discount,
      deliveryCharge: totals.deliveryCharge,
      gst: totals.gst,
      subtotal: totals.subtotal,
      address: '${address.street}, ${address.city}, ${address.state}, ${address.pinCode}',
      method: method,
      items: orderItems,
      addressId: addressId,
    );
  }

  // Calculate order totals
  OrderTotals _calculateOrderTotals() {
    final double subtotal = _calculateSubtotal();
    const double deliveryCharge = 45.0;
    const double gst = 0.0;
    const double discount = 0.0;
    final double total = subtotal + deliveryCharge + gst - discount;

    return OrderTotals(
      subtotal: subtotal,
      deliveryCharge: deliveryCharge,
      gst: gst,
      discount: discount,
      total: total,
    );
  }

  // Build order items from cart
  List<CreateOrderItemRequestModel> _buildOrderItems() {
    final List<CreateOrderItemRequestModel> orderItems = [];

    for (var cartItem in _cartController.cartItems) {
      final productData = cartItem['productId'] as Map<String, dynamic>?;

      if (productData == null) {
        debugPrint('Warning: Product data is null for cart item: $cartItem');
        continue;
      }

      final String productId = productData['_id'] as String? ?? '';
      if (productId.isEmpty) {
        debugPrint('Warning: Product ID missing for cart item: $cartItem');
        continue;
      }

      final String variantName = cartItem['variantName'] as String? ?? 'Default';
      final int quantity = (cartItem['quantity'] as num?)?.toInt() ?? 1;
      final double itemPrice = _extractItemPrice(productData, productId);

      orderItems.add(CreateOrderItemRequestModel(
        productId: productId,
        variantName: variantName,
        quantity: quantity,
        price: itemPrice,
      ));
    }

    debugPrint('✅ Built ${orderItems.length} order items from ${_cartController.cartItems.length} cart items');
    return orderItems;
  }

  // Extract item price from product data
  double _extractItemPrice(Map<String, dynamic> productData, String productId) {
    if (productData.containsKey('sellingPrice') && productData['sellingPrice'] is List) {
      final List<dynamic> sellingPricesList = productData['sellingPrice'];
      if (sellingPricesList.isNotEmpty && sellingPricesList[0] is Map<String, dynamic>) {
        return (sellingPricesList[0]['price'] as num?)?.toDouble() ?? 0.0;
      }
    }

    debugPrint('Warning: Could not extract price for product: $productId');
    return 0.0;
  }

  // Process order based on payment method
  Future<void> _processOrder({
    required String method,
    required CreateOrderRequestModel orderRequest,
  }) async {
    try {
      isLoading.value = true;
      debugPrint('🚀 Processing $method order...');

      switch (method.toUpperCase()) {
        case 'COD':
          await _processCODOrder(orderRequest);
          break;
        case 'ONLINE':
          await _processOnlineOrder(orderRequest);
          break;
        default:
          throw OrderServiceException('Invalid payment method: $method', statusCode: 400);
      }
    } on OrderServiceException catch (e) {
      debugPrint('❌ OrderServiceException: Status ${e.statusCode} - ${e.message}');
    } catch (e) {
      debugPrint('❌ Unexpected Exception: $e');
    } finally {
      if (method.toUpperCase() != 'ONLINE') {
        isLoading.value = false;
      }
    }
  }

  // Process COD order
  Future<void> _processCODOrder(CreateOrderRequestModel orderRequest) async {
    if (orderRequest.orderAmount > 5000) {
      debugPrint('🛑 COD not allowed for orders above ₹5000. Total: ${orderRequest.orderAmount}');
      return;
    }

    final createdOrder = await _orderService.placeCodOrder(orderRequest);
    debugPrint('✅ COD order created: ${createdOrder.orderId}');

    if (createdOrder.orderId == null || createdOrder.orderId!.isEmpty) {
      throw OrderServiceException('COD Order placement failed: No Order ID returned from backend.', statusCode: 500);
    }

    if (createdOrder.items.isEmpty) {
      debugPrint('⚠️ Backend returned COD order with empty items list.');
    }

    await _completeOrderSuccess(createdOrder);

    _showSuccessSnackbar(
      'Order Placed! Awaiting Confirmation Call',
      'You will receive a call for confirmation shortly. If the call is not picked up, your order will be cancelled automatically.',
      Icons.phone_callback_outlined,
      backgroundColor: Colors.blueAccent.shade400,
      duration: const Duration(seconds: 7),
    );

    debugPrint('🎉 Navigating to OrderConfirmationScreen with orderId: ${createdOrder.orderId}');
    Get.offAll(() => OrderConfirmationScreen());
  }

  // Process online order
  Future<void> _processOnlineOrder(CreateOrderRequestModel orderRequest) async {
    final Map<String, dynamic> response = await _orderService.initiateOnlineOrder(orderRequest);
    debugPrint('✅ Online payment initiated: $response');

    final paymentData = _validateOnlinePaymentResponse(response);
    if (paymentData == null) return;

    _currentBackendOrderId = paymentData['newOrderId'];
    _currentRazorpayOrderId = paymentData['razorpayOrderId'];

    debugPrint('💳 Opening Razorpay with order IDs - Backend: $_currentBackendOrderId, Razorpay: $_currentRazorpayOrderId');

    final options = _buildRazorpayOptions(paymentData, orderRequest);
    isLoading.value = false;
    _razorpay.open(options);
  }

  // Validate online payment response
  Map<String, dynamic>? _validateOnlinePaymentResponse(Map<String, dynamic> response) {
    final requiredFields = ['razorpayOrderId', 'amount', 'currency', 'key', 'newOrderId'];

    for (String field in requiredFields) {
      if (response[field] == null) {
        debugPrint('🛑 Missing $field in payment response');
        return null;
      }
    }

    return response;
  }

  // Build Razorpay options
  Map<String, dynamic> _buildRazorpayOptions(
      Map<String, dynamic> paymentData,
      CreateOrderRequestModel orderRequest,
      ) {
    return {
      'key': paymentData['key'],
      'amount': paymentData['amount'],
      'name': 'MobiKing E-commerce',
      'description': 'Order from MobiKing',
      'order_id': paymentData['razorpayOrderId'],
      'currency': paymentData['currency'],
      'prefill': {
        'email': orderRequest.email,
        'contact': orderRequest.phoneNo,
      },
      'external': {
        'wallets': ['paytm', 'google_pay'],
      },
      'theme': {
        'color': '#3399FF'
      },
    };
  }

  // Complete order success operations
  Future<void> _completeOrderSuccess(dynamic createdOrder) async {
    await _box.write('last_placed_order', createdOrder.toJson());
    _cartController.clearCartData();
    debugPrint('✅ Order saved locally and cart cleared');
  }

  // Improved snackbar methods
  void _showSuccessSnackbar(String title, String message, IconData icon, {Color? backgroundColor, Duration? duration}) {
    _showModernSnackbar(
      title,
      message,
      isError: false,
      icon: icon,
      backgroundColor: backgroundColor ?? Colors.green.shade400,
      snackPosition: SnackPosition.TOP,
      duration: duration,
    );
  }

  void _showInfoSnackbar(String title, String message, IconData icon) {
    _showModernSnackbar(
      title,
      message,
      isError: false,
      icon: icon,
      backgroundColor: AppColors.textLight.withOpacity(0.8),
      snackPosition: SnackPosition.TOP,
    );
  }

  // Simplified _promptUserInfo method - Navigate to AddressPage
// ✅ FIXED _promptUserInfo method with better navigation handling
  Future<bool> _promptUserInfo() async {
    try {
      debugPrint('🚀 Opening AddressPage for user profile management...');

      // Ensure UI is not blocked
      isLoading.value = false;

      // Get current user data BEFORE navigation
      final Map<String, dynamic> userBeforeNavigation = Map<String, dynamic>.from(_box.read('user') ?? {});
      debugPrint('📱 Current user data before navigation: $userBeforeNavigation');

      // Check if Get context is available
      if (Get.context == null) {
        debugPrint('❌ Get context is null, cannot navigate');
        return false;
      }

      // Show informative snackbar to guide user
      _showModernSnackbar(
        'Complete Your Profile',
        'Please update your personal information in the "User Info" section.',
        isError: false,
        icon: Icons.person_outline,
        backgroundColor: AppColors.primaryGreen,
        duration: const Duration(seconds: 4),
      );

      // ✅ Navigate to AddressPage and wait for result
      final bool? navigationResult = await Get.to<bool>(
            () => AddressPage(initialUser: userBeforeNavigation),
        fullscreenDialog: true,
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 300),
        preventDuplicates: true,
      );

      debugPrint('🔙 AddressPage navigation completed with result: $navigationResult');

      // ✅ Get updated user data AFTER navigation
      final Map<String, dynamic> updatedUser = Map<String, dynamic>.from(_box.read('user') ?? {});
      debugPrint('📱 Updated user data after navigation: $updatedUser');

      // ✅ Check if user data was actually updated (compare before and after)
      final bool userDataChanged = _hasUserDataChanged(userBeforeNavigation, updatedUser);
      debugPrint('🔄 User data changed: $userDataChanged');

      // ✅ Check if all required fields are now present
      final bool hasRequiredFields = [
        updatedUser['_id'],
        updatedUser['name'],
        updatedUser['email'],
        updatedUser['phoneNo']
      ].every((field) => field != null && field.toString().trim().isNotEmpty);

      debugPrint('✅ Has required fields: $hasRequiredFields');

      // ✅ Determine success based on multiple criteria
      if (navigationResult == true && hasRequiredFields) {
        debugPrint('✅ Navigation result is true AND all required fields are present');
        return true;
      } else if (hasRequiredFields && userDataChanged) {
        debugPrint('✅ All required fields are present AND user data was changed (even if navigationResult is null)');
        return true;
      } else if (navigationResult == false) {
        debugPrint('❌ User explicitly cancelled (navigationResult is false)');
        return false;
      } else {
        debugPrint('⚠️ Navigation completed but required fields are still missing');
        return false;
      }

    } catch (e, stackTrace) {
      debugPrint('❌ Exception in _promptUserInfo: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

// ✅ Helper method to check if user data actually changed
  bool _hasUserDataChanged(Map<String, dynamic> before, Map<String, dynamic> after) {
    final fieldsToCheck = ['_id', 'name', 'email', 'phoneNo'];

    for (String field in fieldsToCheck) {
      final beforeValue = before[field]?.toString()?.trim() ?? '';
      final afterValue = after[field]?.toString()?.trim() ?? '';

      if (beforeValue != afterValue) {
        debugPrint('🔄 Field "$field" changed from "$beforeValue" to "$afterValue"');
        return true;
      }
    }

    return false;
  }

  // Existing methods remain unchanged
  Future<void> fetchOrderHistory({bool isPoll = false}) async {
    if (!isPoll) {
      isLoadingOrderHistory.value = true;
    }

    orderHistoryErrorMessage.value = '';
    try {
      final List<OrderModel> fetchedOrders = await _orderService.getUserOrders();
      if (fetchedOrders.isNotEmpty) {
        fetchedOrders.sort((a, b) => b.createdAt?.compareTo(a.createdAt ?? DateTime(0)) ?? 0);
        orderHistory.assignAll(fetchedOrders);
        if (!isPoll) {
          print('OrderController: Fetched ${orderHistory.length} orders successfully.');
        }
      } else {
        orderHistory.clear();
        orderHistoryErrorMessage.value = 'No order history found.';
        if (!isPoll) {
          _showModernSnackbar(
            'No Orders Yet',
            orderHistoryErrorMessage.value,
            isError: false,
            icon: Icons.shopping_bag_outlined,
            backgroundColor: Colors.blue.shade400,
            snackPosition: SnackPosition.TOP,
          );
        }
      }
    } on OrderServiceException catch (e) {
      orderHistory.clear();
      orderHistoryErrorMessage.value = e.message;
      if (!isPoll) {
        print('OrderController: Order History Service Error: Status ${e.statusCode} - Message: ${e.message}');
      }
    } catch (e) {
      orderHistory.clear();
      orderHistoryErrorMessage.value = 'An unexpected error occurred while processing orders: $e';
      if (!isPoll) {
        print('OrderController: Unexpected Exception in fetchOrderHistory: $e');
      }
    } finally {
      if (!isPoll) {
        isLoadingOrderHistory.value = false;
      }
    }
  }

  OrderModel? getOrderById(String orderId) {
    return orderHistory.firstWhereOrNull((order) => order.id == orderId);
  }

  Future<OrderModel?> OrderById(String orderId) async {
    OrderModel? order = orderHistory.firstWhereOrNull((o) => o.id == orderId);

    if (order != null) {
      print('OrderController: Order found in local cache: $orderId');
      return order;
    }

    isLoading.value = true;
    try {
      print('OrderController: Fetching order $orderId from backend...');
      order = await _orderService.getOrderDetails(orderId: orderId);
      if (order != null) {
        final int index = orderHistory.indexWhere((o) => o.id == order!.id);
        if (index != -1) {
          orderHistory[index] = order;
        } else {
          orderHistory.add(order);
        }
        orderHistory.sort((a, b) => b.createdAt?.compareTo(a.createdAt ?? DateTime(0)) ?? 0);
        print('OrderController: Order $orderId fetched from backend and updated/added to local cache.');
      } else {
        print('OrderController: Order $orderId not found on backend.');
      }
      return order;
    } on OrderServiceException catch (e) {
      print('OrderController: Error fetching order $orderId from backend: ${e.message}');
      return null;
    } catch (e) {
      print('OrderController: Unexpected error getting order $orderId: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
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
                      // Removed error snackbar
                    } else if (currentReason == 'Other (please specify)' && (reasonController.text.trim().isEmpty || reasonController.text.trim().length < 10)) {
                      // Removed error snackbar
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
      print('OrderServiceException: ${e.message}');
    } catch (e) {
      print('Unexpected error: $e');
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

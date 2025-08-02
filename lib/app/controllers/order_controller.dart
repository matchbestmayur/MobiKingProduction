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
import 'coupon_controller.dart';

class RazorpayErrorCodes {
  static const int PAYMENT_CANCELLED = 0;
  static const int NETWORK_ERROR = 1;
  static const int INVALID_CREDENTIALS = 2;
  static const int AMOUNT_LIMIT_EXCEEDED = 3;
  static const int BAD_REQUEST_ERROR = 4;
  static const int SERVER_ERROR = 5;
  static const int GATEWAY_ERROR = 6;
}

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

// FIXED: Helper function for themed snackbars with safe closing
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
  // FIXED: Safer way to close existing snackbar
  try {
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }
  } catch (e) {
    debugPrint('Warning: Error closing existing snackbar: $e');
    // Continue anyway, don't let this block the new snackbar
  }

  // Add a small delay to ensure previous snackbar is fully closed
  Future.delayed(const Duration(milliseconds: 100), () {
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
  });
}

class OrderController extends GetxController {
  final GetStorage _box = GetStorage();
  final OrderService _orderService = Get.find();
  final ConnectivityController _connectivityController = Get.find();
  final CartController _cartController = Get.find();
  final AddressController _addressController = Get.find();
  final CouponController _couponController = Get.find();

  var isLoading = false.obs;
  var orderHistory = [].obs;
  var orderHistoryErrorMessage = ''.obs;
  late Razorpay _razorpay;

  // FIXED: Store complete order data instead of just IDs
  String? _currentBackendOrderId;
  String? _currentRazorpayOrderId;
  Map? _currentOrderData;
  CreateOrderRequestModel? _currentOrderRequest;
  Timer? _pollingTimer;

  // ADDED: Store verified order ID directly from API response
  final RxString _verifiedOrderId = ''.obs;
  final RxMap<String, dynamic> _verifiedOrderData = <String, dynamic>{}.obs;

  final RxBool isInitialLoading = true.obs;
  final RxBool isLoadingOrderHistory = false.obs;

  static const List STATUS_PROGRESS = [
    "Picked Up",
    "IN TRANSIT",
    "Shipped",
    "Delivered",
    "Returned",
    "CANCELLED",
    "Cancelled",
  ];

  var selectedReasonForRequest = ''.obs;
  final List predefinedReasons = [
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
    _connectivityController.isConnected.listen((connected) {
      if (connected) {
        _handleConnectionRestored();
      }
    });
  }

  Future _handleConnectionRestored() async {
    print('OrderController: Internet connection restored. Re-fetching order history...');
    await fetchOrderHistory();
  }

  double _calculateSubtotal() {
    return _cartController.cartItems.fold(0.0, (sum, item) {
      final productData = item['productId'] as Map?;
      if (productData != null && productData.containsKey('sellingPrice') && productData['sellingPrice'] is List) {
        final List sellingPrices = productData['sellingPrice'];
        if (sellingPrices.isNotEmpty && sellingPrices[0] is Map) {
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
    _pollingTimer?.cancel();
    print('Razorpay listeners cleared.');
    super.onClose();
  }

  // ENHANCED: Handle payment success with direct order ID extraction from API response
  // SIMPLIFIED: Handle payment success - direct navigation without verification
  Future _handlePaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint('💚 === PAYMENT SUCCESS HANDLER STARTED ===');
    debugPrint('💚 PaymentID: ${response.paymentId}');
    debugPrint('💚 OrderID: ${response.orderId}');
    debugPrint('💚 Signature: ${response.signature}');

    isLoading.value = true;

    try {
      // ENHANCED: Validate that we have the required data
      if (_currentBackendOrderId == null ||
          _currentRazorpayOrderId == null ||
          _currentOrderRequest == null) {
        debugPrint('❌ CRITICAL: Missing required order data');
        throw OrderServiceException('Missing order data for payment verification', statusCode: 400);
      }

      // Validate Razorpay response
      if (response.paymentId == null || response.orderId == null || response.signature == null) {
        throw OrderServiceException('Incomplete payment response from Razorpay', statusCode: 400);
      }

      // Verify that the Razorpay order ID matches what we expect
      if (response.orderId != _currentRazorpayOrderId) {
        debugPrint('❌ Razorpay Order ID mismatch!');
        throw OrderServiceException('Order ID mismatch in payment response', statusCode: 400);
      }

      // Create verification request
      final verifyRequest = RazorpayVerifyRequest(
        razorpayPaymentId: response.paymentId!,
        razorpayOrderId: response.orderId!,
        razorpaySignature: response.signature!,
        orderId: _currentBackendOrderId!,
      );

      debugPrint('🔄 Verifying payment with backend...');

      // Verify payment with backend
      final verifiedOrder = await _orderService.verifyRazorpayPayment(verifyRequest);
      debugPrint('✅ Payment verification API response received');

      // SIMPLIFIED: Just use the backend order ID that we already have
      final extractedOrderId = _currentBackendOrderId!;
      debugPrint('✅ Using backend order ID for navigation: $extractedOrderId');

      // SIMPLIFIED: Create basic order data for confirmation screen
      final completeOrderData = {
        'orderId': extractedOrderId,
        '_id': extractedOrderId,
        'id': extractedOrderId,
        'paymentMethod': 'Online',
        'paymentStatus': 'Paid',
        'status': 'Pending',
        'orderAmount': _currentOrderRequest!.orderAmount,
        'subtotal': _currentOrderRequest!.subtotal,
        'deliveryCharge': _currentOrderRequest!.deliveryCharge,
        'gst': _currentOrderRequest!.gst,
        'discount': _currentOrderRequest!.discount,
        'customerName': _currentOrderRequest!.name,
        'customerEmail': _currentOrderRequest!.email,
        'customerPhone': _currentOrderRequest!.phoneNo,
        'shippingAddress': _currentOrderRequest!.address,
        'createdAt': DateTime.now().toIso8601String(),
        'items': _currentOrderRequest!.items.map((item) => item.toJson()).toList(),

        // Payment details
        'paymentDetails': {
          'razorpayPaymentId': response.paymentId,
          'razorpayOrderId': response.orderId,
          'razorpaySignature': response.signature,
          'paymentMethod': 'Online',
          'amount': _currentOrderRequest!.orderAmount,
          'currency': 'INR',
          'timestamp': DateTime.now().toIso8601String(),
        },
      };

      // Complete order success operations
      await _completeOrderSuccess(completeOrderData, 'Online');

      // Show success message
      _showModernSnackbar(
        'Payment Successful! 🎉',
        'Your order #$extractedOrderId has been placed successfully.',
        isError: false,
        icon: Icons.check_circle_outline,
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 5),
      );

      // SIMPLIFIED: Navigate directly to confirmation screen
      debugPrint('🎉 Navigating to OrderConfirmationScreen with orderId: $extractedOrderId');

      try {
        if (Get.context != null) {
          Get.offAll(() => OrderConfirmationScreen(
            orderId: extractedOrderId,
          ));
        } else {
          throw Exception('Navigation context unavailable');
        }
      } catch (navigationError) {
        debugPrint('❌ Navigation error: $navigationError');
        _showModernSnackbar(
          'Order Successful!',
          'Your order #$extractedOrderId has been placed. Check order history for details.',
          isError: false,
          icon: Icons.check_circle_outline,
          backgroundColor: Colors.green.shade600,
          duration: const Duration(seconds: 8),
        );
      }

    } on OrderServiceException catch (e) {
      debugPrint('❌ OrderServiceException during payment verification: Status ${e.statusCode} - ${e.message}');
      _showModernSnackbar(
        'Payment Verification Failed',
        'Payment was successful but verification failed. Please contact support with Payment ID: ${response.paymentId}',
        isError: true,
        icon: Icons.error_outline,
        backgroundColor: Colors.orange.shade600,
        duration: const Duration(seconds: 8),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Unexpected error during payment verification: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      _showModernSnackbar(
        'Payment Processing Error',
        'An error occurred while processing your payment. Please contact support.',
        isError: true,
        icon: Icons.error_outline,
        backgroundColor: Colors.red.shade600,
      );
    } finally {
      isLoading.value = false;
      _resetOrderState();
    }
  }

  // ADDED: Extract order ID directly from API response before model conversion
  String? _extractOrderIdFromApiResponse(dynamic apiResponse) {
    debugPrint('🔍 === EXTRACTING ORDER ID FROM API RESPONSE ===');

    try {
      // Handle different response types
      Map<String, dynamic>? responseData;

      if (apiResponse is Map<String, dynamic>) {
        responseData = apiResponse;
      } else if (apiResponse is Map) {
        responseData = apiResponse.cast<String, dynamic>();
      } else {
        debugPrint('❌ Invalid API response type: ${apiResponse.runtimeType}');
        return null;
      }

      debugPrint('🔍 API Response keys: ${responseData.keys.toList()}');

      // Check for order data in the response structure
      Map<String, dynamic>? orderData;

      // Check if response has data.order structure
      if (responseData.containsKey('data') && responseData['data'] is Map) {
        final data = responseData['data'] as Map<String, dynamic>;
        if (data.containsKey('order') && data['order'] is Map) {
          orderData = data['order'] as Map<String, dynamic>;
          debugPrint('✅ Found order data in data.order structure');
        }
      }

      // Check if response is directly an order object
      if (orderData == null && responseData.containsKey('_id')) {
        orderData = responseData;
        debugPrint('✅ Response is directly an order object');
      }

      if (orderData == null) {
        debugPrint('❌ No order data found in API response');
        return null;
      }

      debugPrint('🔍 Order data keys: ${orderData.keys.toList()}');
      debugPrint('🔍 Order data: $orderData');

      // Extract order ID from various possible fields
      final orderId = orderData['_id'] ??
          orderData['orderId'] ??
          orderData['id'];

      if (orderId != null && orderId.toString().trim().isNotEmpty) {
        final orderIdString = orderId.toString().trim();
        debugPrint('✅ Successfully extracted order ID: $orderIdString');
        return orderIdString;
      } else {
        debugPrint('❌ Order ID is null or empty in API response');
        debugPrint('❌ _id: ${orderData['_id']}');
        debugPrint('❌ orderId: ${orderData['orderId']}');
        debugPrint('❌ id: ${orderData['id']}');
      }

    } catch (e, stackTrace) {
      debugPrint('❌ Error extracting order ID from API response: $e');
      debugPrint('❌ Stack trace: $stackTrace');
    }

    return null;
  }

  // ADDED: Extract complete order data from API response
  Map<String, dynamic> _extractOrderDataFromApiResponse(dynamic apiResponse) {
    debugPrint('🔍 === EXTRACTING ORDER DATA FROM API RESPONSE ===');

    try {
      // Handle different response types
      Map<String, dynamic>? responseData;

      if (apiResponse is Map<String, dynamic>) {
        responseData = apiResponse;
      } else if (apiResponse is Map) {
        responseData = apiResponse.cast<String, dynamic>();
      } else {
        debugPrint('❌ Invalid API response type: ${apiResponse.runtimeType}');
        return {};
      }

      // Check for order data in the response structure
      Map<String, dynamic>? orderData;

      // Check if response has data.order structure
      if (responseData.containsKey('data') && responseData['data'] is Map) {
        final data = responseData['data'] as Map<String, dynamic>;
        if (data.containsKey('order') && data['order'] is Map) {
          orderData = data['order'] as Map<String, dynamic>;
          debugPrint('✅ Found order data in data.order structure');
        }
      }

      // Check if response is directly an order object
      if (orderData == null && responseData.containsKey('_id')) {
        orderData = responseData;
        debugPrint('✅ Response is directly an order object');
      }

      if (orderData != null) {
        debugPrint('✅ Successfully extracted order data with keys: ${orderData.keys.toList()}');
        return Map<String, dynamic>.from(orderData);
      } else {
        debugPrint('❌ No order data found in API response');
        return {};
      }

    } catch (e, stackTrace) {
      debugPrint('❌ Error extracting order data from API response: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      return {};
    }
  }

  // ENHANCED: Build complete order data from API response
  Future<Map<String, dynamic>> _buildCompleteOrderDataFromApiResponse({
    required dynamic apiResponse,
    required CreateOrderRequestModel orderRequest,
    required PaymentSuccessResponse paymentResponse,
    required String verifiedOrderId,
  }) async {
    try {
      debugPrint('🔧 === BUILDING COMPLETE ORDER DATA FROM API RESPONSE ===');

      // Get the verified order data
      Map<String, dynamic> orderData = _extractOrderDataFromApiResponse(apiResponse);

      // Ensure we have the verified order ID
      orderData['_id'] = verifiedOrderId;
      orderData['orderId'] = verifiedOrderId;
      orderData['id'] = verifiedOrderId;

      // ENHANCED: Add all necessary fields for confirmation screen
      orderData.addAll({
        'paymentMethod': 'Online',
        'paymentStatus': 'Paid',
        'status': orderData['status'] ?? 'Pending',
        'orderAmount': orderRequest.orderAmount,
        'subtotal': orderRequest.subtotal,
        'deliveryCharge': orderRequest.deliveryCharge,
        'gst': orderRequest.gst,
        'discount': orderRequest.discount,
        'customerName': orderRequest.name,
        'customerEmail': orderRequest.email,
        'customerPhone': orderRequest.phoneNo,
        'shippingAddress': orderRequest.address,
        'createdAt': orderData['createdAt'] ?? DateTime.now().toIso8601String(),
        'items': orderRequest.items.map((item) => item.toJson()).toList(),

        // Payment details
        'paymentDetails': {
          'razorpayPaymentId': paymentResponse.paymentId,
          'razorpayOrderId': paymentResponse.orderId,
          'razorpaySignature': paymentResponse.signature,
          'paymentMethod': 'Online',
          'amount': orderRequest.orderAmount,
          'currency': 'INR',
          'timestamp': DateTime.now().toIso8601String(),
        },

        // Order summary
        'orderSummary': {
          'itemCount': orderRequest.items.length,
          'totalItems': orderRequest.items.fold(0, (sum, item) => sum + item.quantity),
          'subtotal': orderRequest.subtotal,
          'deliveryCharge': orderRequest.deliveryCharge,
          'gst': orderRequest.gst,
          'discount': orderRequest.discount,
          'finalAmount': orderRequest.orderAmount,
        },
      });

      debugPrint('✅ Complete order data built successfully from API response');
      debugPrint('🔍 Order ID: ${orderData['orderId']}');
      debugPrint('🔍 Payment Method: ${orderData['paymentMethod']}');
      debugPrint('🔍 Order Amount: ${orderData['orderAmount']}');

      return orderData;
    } catch (e, stackTrace) {
      debugPrint('❌ Error building complete order data from API response: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      // Return minimal order data as fallback
      return {
        'orderId': verifiedOrderId,
        '_id': verifiedOrderId,
        'paymentMethod': 'Online',
        'status': 'Pending',
        'orderAmount': orderRequest.orderAmount,
        'createdAt': DateTime.now().toIso8601String(),
        'error': 'Partial data available',
      };
    }
  }

  // ADDED: Method to fetch order details using stored verified order ID
  Future<OrderModel?> fetchVerifiedOrderDetails() async {
    if (_verifiedOrderId.value.isEmpty) {
      debugPrint('❌ No verified order ID available');
      return null;
    }

    try {
      debugPrint('📞 Fetching order details for verified order ID: ${_verifiedOrderId.value}');
      final orderDetails = await _orderService.getOrderDetails(orderId: _verifiedOrderId.value);

      if (orderDetails != null) {
        debugPrint('✅ Successfully fetched order details');
        return orderDetails;
      } else {
        debugPrint('❌ No order details found for ID: ${_verifiedOrderId.value}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error fetching verified order details: $e');
      return null;
    }
  }

  // Getters for verified order data
  String get verifiedOrderId => _verifiedOrderId.value;
  Map<String, dynamic> get verifiedOrderData => _verifiedOrderData.value;

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('❌ === PAYMENT ERROR HANDLER ===');
    debugPrint('❌ Code: ${response.code}');
    debugPrint('❌ Message: ${response.message}');

    isLoading.value = false;
    _resetOrderState();

    String errorMessage = 'Payment failed. Please try again.';

    // FIXED: Use custom error codes instead of Razorpay constants
    switch (response.code) {
      case RazorpayErrorCodes.PAYMENT_CANCELLED:
        errorMessage = 'Payment was cancelled by user.';
        break;
      case RazorpayErrorCodes.NETWORK_ERROR:
        errorMessage = 'Network error. Please check your connection.';
        break;
      case RazorpayErrorCodes.INVALID_CREDENTIALS:
        errorMessage = 'Invalid payment credentials. Please contact support.';
        break;
      case RazorpayErrorCodes.AMOUNT_LIMIT_EXCEEDED:
        errorMessage = 'Payment amount exceeds limit.';
        break;
      case RazorpayErrorCodes.BAD_REQUEST_ERROR:
        errorMessage = 'Invalid payment request. Please try again.';
        break;
      case RazorpayErrorCodes.SERVER_ERROR:
        errorMessage = 'Payment server error. Please try again later.';
        break;
      case RazorpayErrorCodes.GATEWAY_ERROR:
        errorMessage = 'Payment gateway error. Please try again.';
        break;
      default:
        if (response.message != null && response.message!.isNotEmpty) {
          errorMessage = response.message!;
        }
    }

    _showModernSnackbar(
      'Payment Failed',
      errorMessage,
      isError: true,
      icon: Icons.error_outline,
      backgroundColor: Colors.red.shade600,
      duration: const Duration(seconds: 5),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('🪙 External Wallet Selected: ${response.walletName}');
    _showInfoSnackbar(
      'External Wallet Selected!',
      'Wallet: ${response.walletName ?? 'Unknown'}',
      Icons.account_balance_wallet_outlined,
    );
  }

  // Main placeOrder method - OPTIMIZED
  Future placeOrder({required String method}) async {
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

    // Store order request for later use
    _currentOrderRequest = orderRequest;

    // Process order based on payment method
    await _processOrder(method: method, orderRequest: orderRequest);
  }

  // FIXED: Reset order state
  Future _resetOrderState() async {
    _currentBackendOrderId = null;
    _currentRazorpayOrderId = null;
    _currentOrderData = null;
    _currentOrderRequest = null;
    _verifiedOrderId.value = '';
    _verifiedOrderData.clear();
    isLoading.value = false;
  }

  // Validate basic order prerequisites
  Future<bool> _validateOrderPrerequisites() async {
    if (_cartController.cartItems.isEmpty) {
      debugPrint('🛑 Cart is empty. Aborting order placement.');
      _showModernSnackbar(
        'Cart Empty',
        'Please add items to your cart before placing an order.',
        isError: true,
        icon: Icons.shopping_cart_outlined,
      );
      return false;
    }

    final AddressModel? address = _addressController.selectedAddress.value;
    if (address == null) {
      debugPrint('🛑 Address is null. Aborting order placement.');
      _showModernSnackbar(
        'Address Required',
        'Please select a delivery address.',
        isError: true,
        icon: Icons.location_on_outlined,
      );
      return false;
    }

    debugPrint('✅ Prerequisites validated - Cart: ${_cartController.cartItems.length} items, Address: ${address.street}');
    return true;
  }

  // Validate and get user info
  Future<UserInfo?> _validateAndGetUserInfo() async {
    Map user = Map.from(_box.read('user') ?? {});
    String? userId = user['_id'];
    String? name = user['name'];
    String? email = user['email'];
    String? phone = user['phoneNo'] ?? user['phone'];

    if (_isUserInfoIncomplete(userId, name, email, phone)) {
      debugPrint('⚠️ User info incomplete. Prompting...');
      isLoading.value = false;
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
      user = Map.from(_box.read('user') ?? {});
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
      _showModernSnackbar(
        'Cart Error',
        'Cart data is invalid. Please refresh and try again.',
        isError: true,
        icon: Icons.error_outline,
      );
      return null;
    }

    final List<CreateOrderItemRequestModel> orderItems = _buildOrderItems();
    if (orderItems.isEmpty) {
      debugPrint('🛑 No valid order items found. Aborting.');
      _showModernSnackbar(
        'Invalid Items',
        'No valid items found in cart.',
        isError: true,
        icon: Icons.error_outline,
      );
      return null;
    }

    final OrderTotals totals = _calculateOrderTotals();
    final AddressModel address = _addressController.selectedAddress.value!;
    final String? addressId = _addressController.selectedAddress.value?.id;
    final bool isCouponApplied = _couponController.isCouponApplied.value;
    final String? couponId = isCouponApplied ? _couponController.selectedCoupon.value?.id : null;

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
      couponId: couponId,
    );
  }

  // Calculate order totals
  OrderTotals _calculateOrderTotals() {
    final double subtotal = _calculateSubtotal();
    const double deliveryCharge = 45.0;
    const double gst = 0.0;
    final double discount = _couponController.isCouponApplied.value
        ? _couponController.discountAmount.value
        : 0.0;
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
      final productData = cartItem['productId'] as Map?;
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
  double _extractItemPrice(Map productData, String productId) {
    if (productData.containsKey('sellingPrice') && productData['sellingPrice'] is List) {
      final List sellingPricesList = productData['sellingPrice'];
      if (sellingPricesList.isNotEmpty && sellingPricesList[0] is Map) {
        return (sellingPricesList[0]['price'] as num?)?.toDouble() ?? 0.0;
      }
    }
    debugPrint('Warning: Could not extract price for product: $productId');
    return 0.0;
  }

  // Process order based on payment method
  Future _processOrder({
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
      _showModernSnackbar(
        'Order Error',
        e.message,
        isError: true,
        icon: Icons.error_outline,
      );
    } catch (e) {
      debugPrint('❌ Unexpected Exception: $e');
      _showModernSnackbar(
        'Unexpected Error',
        'An unexpected error occurred. Please try again.',
        isError: true,
        icon: Icons.error_outline,
      );
    } finally {
      if (method.toUpperCase() != 'ONLINE') {
        isLoading.value = false;
      }
    }
  }

  // FIXED: Process COD order with enhanced error handling
  Future _processCODOrder(CreateOrderRequestModel orderRequest) async {
    try {
      if (orderRequest.orderAmount > 5000) {
        debugPrint('🛑 COD not allowed for orders above ₹5000. Total: ${orderRequest.orderAmount}');
        _showModernSnackbar(
          'COD Not Allowed',
          'Orders above ₹5000 cannot use Cash on Delivery.',
          isError: true,
          icon: Icons.warning_outlined,
          backgroundColor: Colors.orange.shade600,
        );
        return;
      }

      debugPrint('🚀 Placing COD order...');
      final createdOrder = await _orderService.placeCodOrder(orderRequest);
      debugPrint('✅ COD order API response received');

      // ENHANCED: Validate order creation
      final extractedOrderId = _extractOrderId(createdOrder);
      if (extractedOrderId == null || extractedOrderId.isEmpty) {
        debugPrint('❌ CRITICAL: No order ID found in response');
        throw OrderServiceException('COD Order placement failed: No Order ID returned from backend.', statusCode: 500);
      }

      debugPrint('✅ COD order created successfully with ID: $extractedOrderId');

      // Build complete order data
      final completeOrderData = await _buildCompleteOrderDataForCOD(
        createdOrder: createdOrder,
        orderRequest: orderRequest,
      );

      // Complete order success operations
      await _completeOrderSuccess(completeOrderData, 'COD');

      // Show success message
      _showModernSnackbar(
        'Order Placed! Awaiting Confirmation Call',
        'Your order #$extractedOrderId has been placed successfully. You will receive a call for confirmation shortly.',
        isError: false,
        icon: Icons.phone_callback_outlined,
        backgroundColor: Colors.blueAccent.shade400,
        duration: const Duration(seconds: 7),
      );

      // FIXED: Navigate to confirmation screen with validated data
      debugPrint('🎉 Navigating to OrderConfirmationScreen with orderId: $extractedOrderId');

      // Wait a moment to ensure data is written
      await Future.delayed(const Duration(milliseconds: 500));

      Get.offAll(() => OrderConfirmationScreen(
        orderId: extractedOrderId,
      ));

    } catch (e, stackTrace) {
      debugPrint('❌ Error in _processCODOrder: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  // ADDED: Build complete order data for COD orders
  Future<Map<String, dynamic>> _buildCompleteOrderDataForCOD({
    required dynamic createdOrder,
    required CreateOrderRequestModel orderRequest,
  }) async {
    try {
      // Start with created order data
      Map<String, dynamic> orderData;
      if (createdOrder is Map<String, dynamic>) {
        orderData = createdOrder;
      } else if (createdOrder is Map) {
        orderData = createdOrder.cast<String, dynamic>();
      } else {
        try {
          orderData = createdOrder.toJson();
        } catch (e) {
          debugPrint('⚠️ Could not convert createdOrder to JSON: $e');
          orderData = <String, dynamic>{};
        }
      }

      // Extract order ID
      final orderId = _extractOrderId(createdOrder);

      // ENHANCED: Add missing fields that might be needed by confirmation screen
      orderData.addAll({
        'orderId': orderId,
        '_id': orderId,
        'id': orderId,
        'paymentMethod': 'COD',
        'paymentStatus': 'Pending',
        'status': orderData['status'] ?? 'Pending',
        'orderAmount': orderRequest.orderAmount,
        'subtotal': orderRequest.subtotal,
        'deliveryCharge': orderRequest.deliveryCharge,
        'gst': orderRequest.gst,
        'discount': orderRequest.discount,
        'customerName': orderRequest.name,
        'customerEmail': orderRequest.email,
        'customerPhone': orderRequest.phoneNo,
        'shippingAddress': orderRequest.address,
        'createdAt': orderData['createdAt'] ?? DateTime.now().toIso8601String(),
        'items': orderRequest.items.map((item) => item.toJson()).toList(),

        // COD specific details
        'paymentDetails': {
          'paymentMethod': 'COD',
          'amount': orderRequest.orderAmount,
          'currency': 'INR',
          'status': 'Pending',
          'timestamp': DateTime.now().toIso8601String(),
        },

        // Order summary
        'orderSummary': {
          'itemCount': orderRequest.items.length,
          'totalItems': orderRequest.items.fold(0, (sum, item) => sum + item.quantity),
          'subtotal': orderRequest.subtotal,
          'deliveryCharge': orderRequest.deliveryCharge,
          'gst': orderRequest.gst,
          'discount': orderRequest.discount,
          'finalAmount': orderRequest.orderAmount,
        },
      });

      debugPrint('✅ Complete COD order data built successfully');
      return orderData;
    } catch (e, stackTrace) {
      debugPrint('❌ Error building complete COD order data: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      // Return minimal order data as fallback
      return {
        'orderId': _extractOrderId(createdOrder),
        '_id': _extractOrderId(createdOrder),
        'paymentMethod': 'COD',
        'status': 'Pending',
        'orderAmount': orderRequest.orderAmount,
        'createdAt': DateTime.now().toIso8601String(),
        'error': 'Partial data available',
      };
    }
  }

  // FIXED: Process online order with better error handling
  Future _processOnlineOrder(CreateOrderRequestModel orderRequest) async {
    try {
      debugPrint('🚀 === INITIATING ONLINE ORDER ===');
      debugPrint('🚀 Order request: ${orderRequest.toJson()}');

      // Call the order service to create the order and get Razorpay details
      final dynamic rawResponse = await _orderService.initiateOnlineOrder(orderRequest);
      debugPrint('✅ Raw online payment response received');
      debugPrint('✅ Response type: ${rawResponse.runtimeType}');
      debugPrint('✅ Raw response: $rawResponse');

      // Handle different response types
      Map<String, dynamic> response;
      if (rawResponse is Map<String, dynamic>) {
        response = rawResponse;
      } else if (rawResponse is Map) {
        response = rawResponse.cast<String, dynamic>();
      } else {
        debugPrint('❌ Invalid response type: ${rawResponse.runtimeType}');
        throw OrderServiceException('Invalid response type from server', statusCode: 400);
      }

      // Store the complete response for debugging
      _currentOrderData = response;

      // Validate the response from backend
      final paymentData = _validateOnlinePaymentResponse(response);
      if (paymentData == null) {
        throw OrderServiceException('Invalid payment response from server', statusCode: 400);
      }

      // Extract and store order IDs
      _currentBackendOrderId = paymentData['orderId'] ??
          paymentData['newOrderId'] ??
          response['orderId'] ??
          response['newOrderId'];
      _currentRazorpayOrderId = paymentData['razorpayOrderId'];

      debugPrint('💳 Order IDs extracted and stored:');
      debugPrint('💳 Backend Order ID: $_currentBackendOrderId');
      debugPrint('💳 Razorpay Order ID: $_currentRazorpayOrderId');

      // Validate that we have the required IDs
      if (_currentBackendOrderId == null || _currentRazorpayOrderId == null) {
        debugPrint('❌ Missing IDs after extraction:');
        debugPrint('❌ Backend: $_currentBackendOrderId');
        debugPrint('❌ Razorpay: $_currentRazorpayOrderId');
        debugPrint('❌ Available keys in response: ${response.keys.toList()}');
        debugPrint('❌ Available keys in paymentData: ${paymentData.keys.toList()}');
        throw OrderServiceException('Missing order IDs in payment response', statusCode: 400);
      }

      // Build Razorpay options and open payment gateway
      final options = _buildRazorpayOptions(paymentData, orderRequest);
      debugPrint('💳 Razorpay options built successfully');
      debugPrint('💳 Key fields: key=${options['key']}, amount=${options['amount']}, order_id=${options['order_id']}');

      // Stop loading before opening Razorpay
      isLoading.value = false;
      debugPrint('💳 Opening Razorpay payment gateway...');

      // Open Razorpay payment gateway
      _razorpay.open(options);

    } catch (e, stackTrace) {
      debugPrint('❌ === ERROR IN ONLINE ORDER PROCESSING ===');
      debugPrint('❌ Error: $e');
      debugPrint('❌ Stack trace: $stackTrace');

      isLoading.value = false;
      _resetOrderState();

      String errorMessage = 'Failed to initiate online payment. Please try again.';
      if (e is OrderServiceException) {
        errorMessage = e.message;
      } else if (e.toString().contains('network') || e.toString().contains('connection')) {
        errorMessage = 'Network error. Please check your connection and try again.';
      }

      _showModernSnackbar(
        'Payment Error',
        errorMessage,
        isError: true,
        icon: Icons.error_outline,
        backgroundColor: Colors.red.shade600,
      );
      rethrow;
    }
  }

  // FIXED: Validate online payment response - handles your API structure
  Map<String, dynamic>? _validateOnlinePaymentResponse(Map<String, dynamic> response) {
    debugPrint('🔍 === VALIDATING PAYMENT RESPONSE ===');
    debugPrint('🔍 Response keys: ${response.keys.toList()}');
    debugPrint('🔍 Full response: $response');

    // Check if we have the essential Razorpay fields directly
    final List<String> requiredFields = ['razorpayOrderId', 'amount', 'currency', 'key'];
    Map<String, dynamic> validatedData = {};

    // Extract required fields directly from response
    for (String field in requiredFields) {
      if (response.containsKey(field) && response[field] != null) {
        validatedData[field] = response[field];
        debugPrint('✅ Found required field "$field": ${response[field]}');
      } else {
        debugPrint('🛑 Missing required field: $field in payment response');
        debugPrint('🛑 Available fields: ${response.keys.join(', ')}');
        _showModernSnackbar(
          'Payment Error',
          'Invalid payment response. Missing $field.',
          isError: true,
          icon: Icons.error_outline,
        );
        return null;
      }
    }

    // Extract order ID - your logs show 'newOrderId' exists
    String? orderId = response['newOrderId'] ??
        response['orderId'] ??
        response['_id'] ??
        response['id'];

    if (orderId != null && orderId.isNotEmpty) {
      validatedData['orderId'] = orderId;
      validatedData['newOrderId'] = orderId;
      debugPrint('✅ Found order ID: $orderId');
    } else {
      debugPrint('🛑 No order ID found in payment response');
      debugPrint('🛑 Checked fields: newOrderId, orderId, _id, id');
      debugPrint('🛑 Available fields: ${response.keys.join(', ')}');
      _showModernSnackbar(
        'Payment Error',
        'Order ID missing in payment response.',
        isError: true,
        icon: Icons.error_outline,
      );
      return null;
    }

    // Add user data if present
    if (response.containsKey('user')) {
      validatedData['user'] = response['user'];
      debugPrint('✅ Added user data to validated response');
    }

    // Add any additional data that might be useful
    for (String key in ['status', 'message', 'success']) {
      if (response.containsKey(key)) {
        validatedData[key] = response[key];
      }
    }

    debugPrint('✅ Payment response validated successfully');
    debugPrint('✅ Validated data keys: ${validatedData.keys.join(', ')}');
    debugPrint('✅ Order ID: $orderId');
    return validatedData;
  }

  // FIXED: Build Razorpay options with enhanced validation
  Map<String, dynamic> _buildRazorpayOptions(
      Map<String, dynamic> paymentData,
      CreateOrderRequestModel orderRequest,
      ) {
    debugPrint('🔧 === BUILDING RAZORPAY OPTIONS ===');
    debugPrint('🔧 Payment data keys: ${paymentData.keys.toList()}');
    debugPrint('🔧 Payment data: $paymentData');

    // Handle amount conversion properly
    final dynamic amountValue = paymentData['amount'];
    int amount;

    if (amountValue is int) {
      amount = amountValue;
    } else if (amountValue is double) {
      amount = amountValue.toInt();
    } else if (amountValue is String) {
      amount = int.tryParse(amountValue) ?? 0;
    } else {
      debugPrint('❌ Invalid amount type: ${amountValue.runtimeType}, value: $amountValue');
      throw OrderServiceException('Invalid amount in payment response: $amountValue');
    }

    debugPrint('💰 Razorpay amount: $amount paise (${amount/100} rupees)');

    final options = {
      'key': paymentData['key']?.toString() ?? '',
      'amount': amount,
      'name': 'MobiKing Wholesale',
      'description': 'Order Payment - MobiKing',
      'order_id': paymentData['razorpayOrderId']?.toString() ?? '',
      'currency': paymentData['currency']?.toString() ?? 'INR',
      'prefill': {
        'email': orderRequest.email,
        'contact': orderRequest.phoneNo,
        'name': orderRequest.name,
      },
      'external': {
        'wallets': ['paytm', 'googlepay', 'phonepe']
      },
      'theme': {
        'color': '#6C63FF'
      },
      'modal': {
        'backdropclose': false,
        'escape': false,
        'handleback': false,
      },
      'retry': {
        'enabled': true,
        'max_count': 3
      },
      'timeout': 300,
    };

    // Validation: Check all critical fields
    final Map<String, dynamic> criticalFields = {
      'key': options['key'],
      'amount': options['amount'],
      'order_id': options['order_id'],
      'currency': options['currency'],
    };

    for (String field in criticalFields.keys) {
      final value = criticalFields[field];
      if (value == null || value.toString().isEmpty || (field == 'amount' && value == 0)) {
        debugPrint('❌ Critical field "$field" is invalid: $value');
        throw OrderServiceException('Invalid payment configuration: $field missing, empty, or zero');
      }
    }

    debugPrint('✅ Razorpay options built and validated successfully');
    debugPrint('🔑 Key: ${options['key']}');
    debugPrint('💰 Amount: ${options['amount']} paise');
    debugPrint('🆔 Order ID: ${options['order_id']}');
    debugPrint('💱 Currency: ${options['currency']}');

    return options;
  }

  String? _extractOrderId(dynamic orderObject) {
    if (orderObject == null) {
      debugPrint('❌ Order object is null');
      return null;
    }

    debugPrint('🔍 Extracting order ID from object type: ${orderObject.runtimeType}');

    try {
      // Method 1: Handle OrderModel object first (most likely case)
      if (orderObject.runtimeType.toString().contains('OrderModel')) {
        try {
          // Try direct property access first
          if (orderObject.id != null && orderObject.id.toString().isNotEmpty) {
            debugPrint('✅ Found orderId via OrderModel.id: ${orderObject.id}');
            return orderObject.id.toString();
          }

          // Try orderId property
          if (orderObject.orderId != null && orderObject.orderId.toString().isNotEmpty) {
            debugPrint('✅ Found orderId via OrderModel.orderId: ${orderObject.orderId}');
            return orderObject.orderId.toString();
          }

          // Try converting to JSON
          final jsonData = orderObject.toJson();
          final orderId = jsonData['_id'] ?? jsonData['id'] ?? jsonData['orderId'];
          if (orderId != null && orderId.toString().isNotEmpty) {
            debugPrint('✅ Found orderId via OrderModel JSON: $orderId');
            return orderId.toString();
          }
        } catch (e) {
          debugPrint('⚠️ OrderModel direct access failed: $e');
        }
      }

      // Method 2: Handle Map directly
      if (orderObject is Map) {
        final orderId = orderObject['_id'] ?? orderObject['orderId'] ?? orderObject['id'];
        if (orderId != null && orderId.toString().isNotEmpty) {
          debugPrint('✅ Found orderId via map access: $orderId');
          return orderId.toString();
        }
      }

      // Method 3: Try dynamic property access (fallback)
      try {
        final dynamic orderIdValue = orderObject.id ?? orderObject.orderId ?? orderObject._id;
        if (orderIdValue != null && orderIdValue.toString().isNotEmpty) {
          debugPrint('✅ Found orderId via dynamic access: $orderIdValue');
          return orderIdValue.toString();
        }
      } catch (e) {
        debugPrint('⚠️ Dynamic access failed: $e');
      }

    } catch (e) {
      debugPrint('❌ Error extracting order ID: $e');
    }

    debugPrint('❌ Could not extract order ID from ${orderObject.runtimeType}');

    // Additional debugging - let's see what properties are available
    try {
      if (orderObject.runtimeType.toString().contains('OrderModel')) {
        debugPrint('🔍 OrderModel debug info:');
        final jsonData = orderObject.toJson();
        debugPrint('🔍 Available keys in OrderModel JSON: ${jsonData.keys.toList()}');
        debugPrint('🔍 Full OrderModel JSON: $jsonData');
      }
    } catch (e) {
      debugPrint('⚠️ Could not debug OrderModel: $e');
    }

    return null;
  }

  // FIXED: Complete order success operations with enhanced null safety
  Future _completeOrderSuccess(Map<String, dynamic> orderData, String paymentMethod) async {
    try {
      debugPrint('🔧 === STARTING ORDER DATA STORAGE ===');
      debugPrint('🔧 Payment Method: $paymentMethod');
      debugPrint('🔧 Order Data Keys: ${orderData.keys.toList()}');

      // Extract order ID from the complete order data
      String? orderId = orderData['orderId'] ??
          orderData['_id'] ??
          orderData['id'] ??
          orderData['newOrderId'];

      if (orderId == null || orderId.isEmpty) {
        debugPrint('❌ CRITICAL ERROR: Cannot extract order ID from order data');
        debugPrint('❌ Order data: $orderData');
        throw Exception('Order ID is null or empty - cannot complete order');
      }

      debugPrint('✅ Extracted Order ID: $orderId');

      // COMPREHENSIVE: Store order data in multiple keys and formats for maximum reliability
      await _box.write('last_placed_order', orderData);
      await _box.write('current_order_for_confirmation', orderData);
      await _box.write('recent_order_id', orderId);
      await _box.write('last_order_id', orderId);
      await _box.write('latest_order_id', orderId);
      await _box.write('lastOrderId', orderId); // Original key for backward compatibility

      // Store comprehensive order confirmation data with timestamp
      await _box.write('order_confirmation_data', {
        'orderId': orderId,
        'orderData': orderData,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'method': paymentMethod,
        'status': 'success',
      });

      // Additional storage for fallback
      await _box.write('order_success_data', {
        'id': orderId,
        'data': orderData,
        'createdAt': DateTime.now().toIso8601String(),
        'paymentMethod': paymentMethod,
      });

      debugPrint('✅ Order data stored in ALL possible keys');
      debugPrint('✅ Order ID for confirmation: $orderId');

      // Clear cart data
      _cartController.clearCartData();

      // Refresh order history
      fetchOrderHistory();

      debugPrint('✅ Order saved locally, cart cleared, and order history refreshed');
    } catch (e, stackTrace) {
      debugPrint('❌ CRITICAL ERROR in _completeOrderSuccess: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      rethrow;
    }
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

  // FIXED: _promptUserInfo method with better navigation handling
  Future<bool> _promptUserInfo() async {
    try {
      debugPrint('🚀 Opening AddressPage for user profile management...');
      isLoading.value = false;

      final Map userBeforeNavigation = Map.from(_box.read('user') ?? {});
      debugPrint('📱 Current user data before navigation: $userBeforeNavigation');

      if (Get.context == null) {
        debugPrint('❌ Get context is null, cannot navigate');
        return false;
      }

      _showModernSnackbar(
        'Complete Your Profile',
        'Please update your personal information in the "User Info" section.',
        isError: false,
        icon: Icons.person_outline,
        backgroundColor: AppColors.primaryGreen,
        duration: const Duration(seconds: 4),
      );

      final bool? navigationResult = await Get.to(
            () => AddressPage(),
        fullscreenDialog: true,
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 300),
        preventDuplicates: true,
      );

      debugPrint('🔙 AddressPage navigation completed with result: $navigationResult');

      final Map updatedUser = Map.from(_box.read('user') ?? {});
      debugPrint('📱 Updated user data after navigation: $updatedUser');

      final bool userDataChanged = _hasUserDataChanged(userBeforeNavigation, updatedUser);
      debugPrint('🔄 User data changed: $userDataChanged');

      final bool hasRequiredFields = [
        updatedUser['_id'],
        updatedUser['name'],
        updatedUser['email'],
        updatedUser['phoneNo']
      ].every((field) => field != null && field.toString().trim().isNotEmpty);

      debugPrint('✅ Has required fields: $hasRequiredFields');

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

  // Helper method to check if user data actually changed
  bool _hasUserDataChanged(Map before, Map after) {
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

  // Rest of the existing methods remain unchanged...
  Future fetchOrderHistory({bool isPoll = false}) async {
    if (!isPoll) {
      isLoadingOrderHistory.value = true;
    }

    orderHistoryErrorMessage.value = '';

    try {
      final List fetchedOrders = await _orderService.getUserOrders();

      if (fetchedOrders.isNotEmpty) {
        fetchedOrders.sort((a, b) => b.createdAt?.compareTo(a.createdAt ?? DateTime(0)) ?? 0);
        orderHistory.assignAll(fetchedOrders);
        if (!isPoll) {
          print('OrderController: Fetched ${orderHistory.length} orders successfully.');
        }
      } else {
        orderHistory.clear();
        orderHistoryErrorMessage.value = 'No order history found.';
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

  Future sendOrderRequest(String orderId, String requestType) async {
    selectedReasonForRequest.value = '';
    final TextEditingController reasonController = TextEditingController();

    final bool? dialogResult = await Get.dialog(
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
      Map response;
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

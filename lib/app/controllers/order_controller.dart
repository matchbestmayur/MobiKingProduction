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
    '', // hide default title & message placement
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
    backgroundColor ?? (isError ? const Color(0xFFB00020) : const Color(0xFF1E88E5)), // Apple red or blue
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

    // Connectivity check
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
  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    print('Razorpay Payment Success: ${response.paymentId}, ${response.orderId}, ${response.signature}');
    isLoading.value = true;
    try {
      // Check if necessary backend order IDs are available
      if (_currentBackendOrderId == null || _currentRazorpayOrderId == null) {
        _showModernSnackbar(
          'Payment Success, but data missing! ⚠️', // Added emoji
          'Could not retrieve backend order data for verification. Please contact support with Payment ID: ${response.paymentId}',
          isError: true,
          icon: Icons.error_outline,
          backgroundColor: Colors.orange.shade700,
        );
        return;
      }

      // Construct the verification request to send to your backend
      final verifyRequest = RazorpayVerifyRequest(
        razorpayPaymentId: response.paymentId!,
        razorpayOrderId: response.orderId!,
        razorpaySignature: response.signature!,
        orderId: _currentBackendOrderId!, // Use the backend's generated order ID
      );

      print('Calling backend for payment verification... 🔄'); // Added emoji
      // Verify the payment with your backend
      final verifiedOrder = await _orderService.verifyRazorpayPayment(verifyRequest);
      print('Backend verification successful for order: ${verifiedOrder.orderId} ✅'); // Added emoji

      // Store the last placed order locally
      await _box.write('last_placed_order', verifiedOrder.toJson());
      // Clear the user's cart as the order is placed
      _cartController.clearCartData();

      // Show a success message to the user
      _showModernSnackbar(
        'Order Placed! 🎉', // Added emoji
        'Your order ID ${verifiedOrder.orderId ?? 'N/A'} has been placed successfully!',
        isError: false,
        icon: Icons.receipt_long_outlined,
        backgroundColor: Colors.green.shade600,
        snackPosition: SnackPosition.TOP,
      );

      // Navigate to the OrderConfirmationScreen, passing only the backend order ID string
      // The OrderConfirmationScreen will then fetch its own full details using this ID.
      Get.offAll(() => OrderConfirmationScreen());
    } on OrderServiceException catch (e) {
      // Handle specific errors from your order service during verification
      _showModernSnackbar(
        'Payment Verification Failed! ❌', // Added emoji
        e.message,
        isError: true,
        icon: Icons.cancel_outlined,
        backgroundColor: Colors.red.shade400,
        snackPosition: SnackPosition.TOP,
      );
      print('Razorpay Verification Service Error: Status ${e.statusCode} - Message: ${e.message}');
    } catch (e) {
      // Catch any other unexpected errors during the process
      _showModernSnackbar(
        'Payment Verification Error! 🚨', // Added emoji
        'An unexpected error occurred during payment verification: $e',
        isError: true,
        icon: Icons.cloud_off_outlined,
        backgroundColor: Colors.red.shade400,
        snackPosition: SnackPosition.TOP,
      );
      print('Razorpay Verification Unexpected Error: $e');
    } finally {
      // Ensure loading indicator is hidden regardless of success or failure
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

    debugPrint('--- placeOrder method called with method: $method ---'); // Debug 1

    if (_cartController.cartItems.isEmpty) {
      debugPrint('🛑 Cart is empty. Aborting order placement.'); // Debug 2
      _showModernSnackbar(
        'Cart Empty!',
        'Your cart is empty. Please add items before placing an order.',
        isError: true,
        icon: Icons.shopping_cart_outlined,
        backgroundColor: Colors.red.shade400,
        snackPosition: SnackPosition.TOP,
      );
      isLoading.value = false;
      return;
    }

    final AddressModel? address = _addressController.selectedAddress.value;
    if (address == null) {
      debugPrint('🛑 Address is null. Aborting order placement.'); // Debug 3
      _showModernSnackbar(
        'Address Required!',
        'Please select a shipping address to proceed.',
        isError: true,
        icon: Icons.location_off_outlined,
        backgroundColor: Colors.amber.shade700,
        snackPosition: SnackPosition.TOP,
      );
      isLoading.value = false;
      return;
    }
    debugPrint('✅ Address selected: ${address.street}'); // Debug 4

    Map<String, dynamic> user = Map<String, dynamic>.from(_box.read('user') ?? {});
    String? userId = user['_id'];
    String? name = user['name'];
    String? email = user['email'];
    String? phone = user['phoneNo'] ?? user['phone'];

    bool userInfoIncomplete = [userId, name, email, phone].any((e) => e == null || e.toString().trim().isEmpty);
    if (userInfoIncomplete) {
      debugPrint('⚠️ User info incomplete. Prompting...'); // Debug 5
      isLoading.value = true;
      final bool detailsConfirmed = await _promptUserInfo();
      if (!detailsConfirmed) {
        debugPrint('🛑 User info not confirmed. Aborting order placement.'); // Debug 6
        _showModernSnackbar(
          'Details Not Saved',
          'User details were not updated. Please fill them out to proceed with your order.',
          icon: Icons.info_outline_rounded,
          backgroundColor: AppColors.textLight.withOpacity(0.8),
          isError: false,
          snackPosition: SnackPosition.TOP,
        );
        isLoading.value = false;
        return;
      }
      user = Map<String, dynamic>.from(_box.read('user') ?? {}); // Refresh user data after prompt
      userId = user['_id'];
      name = user['name'];
      email = user['email'];
      phone = user['phoneNo'] ?? user['phone'];
      if ([userId, name, email, phone].any((e) => e == null || e.toString().trim().isEmpty)) {
        debugPrint('🛑 User info still incomplete after prompt. Aborting.'); // Debug 7
        _showModernSnackbar(
          'User Info Incomplete!',
          'Despite confirming, some profile details are still missing. Please try again.',
          isError: true,
          icon: Icons.person_off_outlined,
          backgroundColor: Colors.red.shade400,
          snackPosition: SnackPosition.TOP,
        );
        isLoading.value = false;
        return;
      }
    }
    debugPrint('✅ User info verified: ID=$userId, Name=$name, Email=$email, Phone=$phone'); // Debug 8

    final cartId = _cartController.cartData['_id'];
    if (cartId == null) {
      debugPrint('🛑 Cart ID is null. Aborting order placement.'); // Debug 9
      _showModernSnackbar(
        'Cart Error!',
        'Could not find your cart ID. Please try again or re-add items.',
        isError: true,
        icon: Icons.shopping_cart_checkout_outlined,
        backgroundColor: Colors.red.shade400,
        snackPosition: SnackPosition.TOP,
      );
      isLoading.value = false;
      return;
    }
    debugPrint('✅ Cart ID: $cartId'); // Debug 10

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
        debugPrint('Error: Product data is null for cart item: $cartItem'); // Debug 11
        continue;
      }
      final String productIdString = productData['_id'] as String? ?? '';
      if (productIdString.isEmpty) {
        debugPrint('Error: Product ID missing for cart item: $cartItem'); // Debug 12
        continue;
      }
      double itemPrice = 0.0;
      if (productData.containsKey('sellingPrice') && productData['sellingPrice'] is List) {
        final List<dynamic> sellingPricesList = productData['sellingPrice'];
        if (sellingPricesList.isNotEmpty && sellingPricesList[0] is Map<String, dynamic>) {
          itemPrice = (sellingPricesList[0]['price'] as num?)?.toDouble() ?? 0.0;
        }
      } else {
        debugPrint('Warning: sellingPrice is not a List or is missing for product: $productIdString'); // Debug 13
      }
      orderItemsRequest.add(CreateOrderItemRequestModel(
        productId: productIdString,
        variantName: variantName,
        quantity: quantity,
        price: itemPrice,
      ));
    }
    debugPrint('✅ Items prepared for order request: ${orderItemsRequest.length}'); // Debug 14
    if (orderItemsRequest.isEmpty) {
      debugPrint('🛑 orderItemsRequest is EMPTY! No items will be sent to the backend.'); // Debug 15
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
      items: orderItemsRequest, // This is the list that gets passed
      addressId: addressId,
    );
    debugPrint('✅ CreateOrderRequestModel built. Total amount: $total'); // Debug 16

    try {
      isLoading.value = true;
      debugPrint('Loading indicator set to true.'); // Debug 17


      if (method == 'COD') {
        debugPrint('🚀 Attempting to place COD order...');
        if (total > 5000) {
          debugPrint('🛑 COD not allowed for orders above ₹5000. Total: $total');
          _showModernSnackbar(
            'COD Not Available!',
            'Cash on Delivery is not allowed for orders above ₹5000. Please choose online payment.',
            isError: true,
            icon: Icons.warning_amber_rounded,
            backgroundColor: Colors.deepOrange.shade400,
            snackPosition: SnackPosition.TOP,
          );
          isLoading.value = false;
          return;
        }



        final createdOrder = await _orderService.placeCodOrder(createOrderRequest);
        debugPrint('Received response from placeCodOrder. Order ID: ${createdOrder.orderId}, Items count: ${createdOrder.items.length}');

        // Check if the orderId from the backend response is null or empty
        if (createdOrder.orderId == null || createdOrder.orderId!.isEmpty) {
          debugPrint('🛑 Backend returned a COD order with a null or empty orderId. This indicates a problem.');
          throw OrderServiceException('COD Order placement failed: No Order ID returned from backend.', statusCode: 500);
        }
        if (createdOrder.items.isEmpty) {
          debugPrint('🛑 Backend returned a COD order with an EMPTY items list.');
        }

        await _box.write('last_placed_order', createdOrder.toJson());
        debugPrint('Last placed order written to local storage.');

        _cartController.clearCartData();
        debugPrint('Cart data cleared.');

        isLoading.value = false;
        debugPrint('Loading indicator set to false (COD success).');

        _showModernSnackbar(
          'Order Placed! Awaiting Confirmation Call',
          'You will receive a call for confirmation shortly. If the call is not picked up, your order will be cancelled automatically.',
          isError: false,
          icon: Icons.phone_callback_outlined,
          backgroundColor: Colors.blueAccent.shade400,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 7),
        );

        // --- CORRECTED LINE FOR COD ---
        // Pass the backend's 'orderId' string to the OrderConfirmationScreen
        debugPrint('Navigating to OrderConfirmationScreen with orderId: ${createdOrder.orderId}');
        Get.offAll(() => OrderConfirmationScreen());
      } else if (method == 'Online') {
        debugPrint('🚀 Initiating online payment with backend...'); // Debug 26
        final Map<String, dynamic> initiateResponse = await _orderService.initiateOnlineOrder(createOrderRequest);
        debugPrint('Backend initiate response: $initiateResponse'); // Debug 27

        final String? razorpayOrderId = initiateResponse['razorpayOrderId'] as String?;
        final int? amountInPaise = initiateResponse['amount'] as int?;
        final String? currency = initiateResponse['currency'] as String?;
        final String? razorpayKey = initiateResponse['key'] as String?;
        final String? newOrderId = initiateResponse['newOrderId'] as String?; // This is your backend's new order ID

        if (razorpayOrderId == null || amountInPaise == null || currency == null || razorpayKey == null || newOrderId == null) {
          debugPrint('🛑 Missing essential Razorpay initiation data from backend.'); // Debug 28
          throw OrderServiceException(
            'Missing essential Razorpay initiation data from backend.',
            statusCode: 500,
          );
        }

        _currentBackendOrderId = newOrderId; // Store the backend's order ID
        _currentRazorpayOrderId = razorpayOrderId;
        debugPrint('Razorpay order IDs set. Backend Order ID: $_currentBackendOrderId, Razorpay Order ID: $_currentRazorpayOrderId'); // Debug 29

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

        print('Opening Razorpay checkout with options: $options'); // Debug 30
        isLoading.value = false; // IMPORTANT: Set isLoading to false BEFORE opening Razorpay.
        debugPrint('Loading indicator set to false (before Razorpay).'); // Debug 31
        _razorpay.open(options);

        // For online payments, the navigation to OrderConfirmationScreen happens
        // in the Razorpay success callback (_handlePaymentSuccess)
        // where _currentBackendOrderId (which holds the ID from `newOrderId`)
        // should be used.
      } else {
        debugPrint('🛑 Invalid payment method: $method. Aborting.'); // Debug 32
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
      isLoading.value = false;
      debugPrint('❌ OrderServiceException caught: Status ${e.statusCode} - Message: ${e.message}'); // Debug 33
      _showModernSnackbar(
        'Order Failed!',
        e.message,
        isError: true,
        icon: Icons.cancel_outlined,
        backgroundColor: Colors.orange.shade700,
        snackPosition: SnackPosition.TOP,
      );
      print('Place Order Service Error: Status ${e.statusCode} - Message: ${e.message}');
    } catch (e) {
      isLoading.value = false;
      debugPrint('❌ Unexpected Exception caught: $e'); // Debug 34
      _showModernSnackbar(
        'Order Error!',
        'An unexpected client-side error occurred: $e. Please try again later.',
        isError: true,
        icon: Icons.cloud_off_outlined,
        backgroundColor: Colors.red.shade400,
        snackPosition: SnackPosition.TOP,
      );
      print('Place Order Unexpected Error: $e');
    }
  }
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
      }
      print('OrderController: Order History Service Error: Status ${e.statusCode} - Message: ${e.message}');
    } catch (e) {
      orderHistory.clear();
      orderHistoryErrorMessage.value = 'An unexpected error occurred while processing orders: $e';
      if (!isPoll) {
        _showModernSnackbar(
          'Critical Error',
          'An unexpected client-side error occurred: $e',
          isError: true,
          icon: Icons.bug_report_outlined,
          backgroundColor: Colors.red.shade700,
          snackPosition: SnackPosition.TOP,
        );
      }
      print('OrderController: Unexpected Exception in fetchOrderHistory: $e');
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
    // First, try to find the order in the locally cached history
    OrderModel? order = orderHistory.firstWhereOrNull((o) => o.id == orderId);

    if (order != null) {
      print('OrderController: Order found in local cache: $orderId');
      return order;
    }

    // If not found in local cache, try to fetch it from the backend
    isLoading.value = true; // Show loading indicator
    try {
      print('OrderController: Fetching order $orderId from backend...');
      // Calls the getOrderDetails method from OrderService
      order = await _orderService.getOrderDetails(orderId: orderId);
      if (order != null) {
        // Optionally, add/update this order in the local history
        final int index = orderHistory.indexWhere((o) => o.id == order!.id);
        if (index != -1) {
          orderHistory[index] = order; // Update existing
        } else {
          orderHistory.add(order); // Add new
        }
        orderHistory.sort((a, b) => b.createdAt?.compareTo(a.createdAt ?? DateTime(0)) ?? 0); // Keep sorted
        print('OrderController: Order $orderId fetched from backend and updated/added to local cache.');
      } else {
        print('OrderController: Order $orderId not found on backend.');
        _showModernSnackbar(
          'Order Not Found',
          'Could not find order with ID: $orderId',
          isError: true,
          icon: Icons.search_off_outlined,
          backgroundColor: Colors.amber.shade700,
        );
      }
      return order;
    } on OrderServiceException catch (e) {
      print('OrderController: Error fetching order $orderId from backend: ${e.message}');
      _showModernSnackbar(
        'Failed to Get Order Details',
        e.message,
        isError: true,
        icon: e.statusCode == 401 ? Icons.login_outlined : (e.statusCode == 0 ? Icons.cloud_off_outlined : Icons.error_outline),
        backgroundColor: e.statusCode == 401 ? Colors.orange.shade700 : (e.statusCode == 0 ? Colors.red.shade700 : Colors.red.shade400),
      );
      return null;
    } catch (e) {
      print('OrderController: Unexpected error getting order $orderId: $e');
      _showModernSnackbar(
        'Error',
        'An unexpected error occurred while fetching order details: $e',
        isError: true,
        icon: Icons.bug_report_outlined,
        backgroundColor: Colors.red.shade700,
      );
      return null;
    } finally {
      isLoading.value = false; // Hide loading indicator
    }
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

  /// Retrieves an order from the local history by ID.
  /// If not found locally, it attempts to fetch it from the backend.
  /// Returns the OrderModel if found, otherwise null.

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
  /// Retrieves an order from the local history by ID.
  /// If not found locally, it attempts to fetch it from the backend.
  /// Returns the OrderModel if found, otherwise null.


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
// controllers/coupon_controller.dart
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../data/coupon_model.dart';
import '../services/coupon_service.dart';

class CouponController extends GetxController {
  final CouponService _couponService = Get.find<CouponService>();

  // Observable variables
  final RxBool isLoading = false.obs;
  final Rx<CouponModel?> selectedCoupon = Rx<CouponModel?>(null);
  final RxList<CouponModel> availableCoupons = <CouponModel>[].obs;

  final RxString couponCode = ''.obs;
  final RxString errorMessage = ''.obs;
  final RxString successMessage = ''.obs;

  final RxBool isCouponApplied = false.obs;
  final RxDouble discountAmount = 0.0.obs;
  final RxDouble subtotal = 0.0.obs;

  // Text editing controller for coupon input
  final TextEditingController couponTextController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _setupListeners();
  }

  @override
  void onClose() {
    couponTextController.dispose();
    super.onClose();
  }

  void _setupListeners() {
    couponTextController.addListener(() {
      couponCode.value = couponTextController.text.trim().toUpperCase();
      if (errorMessage.value.isNotEmpty) {
        clearMessages();
      }
    });
  }

  // Clear all messages
  void clearMessages() {
    errorMessage.value = '';
    successMessage.value = '';
  }

  // Show error message
  void _showError(String message) {
    errorMessage.value = message;
    successMessage.value = '';
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade900,
      duration: const Duration(seconds: 3),
    );
  }

  // Show success message
  void _showSuccess(String message) {
    successMessage.value = message;
    errorMessage.value = '';
    Get.snackbar(
      'Success',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade900,
      duration: const Duration(seconds: 3),
    );
  }

  // ✅ MAIN METHOD: Validate coupon and calculate discount locally
  Future<void> validateAndApplyCoupon(String code) async {
    if (code.trim().isEmpty) {
      _showError('Please enter a coupon code');
      return;
    }

    try {
      isLoading.value = true;
      clearMessages();

      // Step 1: Validate coupon with API
      final response = await _couponService.validateCouponCode(code.trim().toUpperCase());

      if (response.success && response.data != null) {
        final coupon = response.data!;

        // Step 2: Check if coupon is currently valid (dates)
        if (!coupon.isValid) {
          if (coupon.isExpired) {
            _showError('This coupon has expired');
            return;
          } else if (coupon.isNotYetActive) {
            _showError('This coupon is not yet active');
            return;
          }
        }

        // Step 3: Calculate discount locally based on your business logic
        final calculatedDiscount = _calculateDiscountAmount(coupon);

        if (calculatedDiscount <= 0) {
          _showError('This coupon cannot be applied to your current order');
          return;
        }

        // Step 4: Apply coupon locally
        selectedCoupon.value = coupon;
        discountAmount.value = calculatedDiscount;
        isCouponApplied.value = true;

        _showSuccess('Coupon applied! You saved ₹${calculatedDiscount.toStringAsFixed(0)}');

      } else {
        _showError('Invalid coupon code');
      }
    } catch (e) {
      _showError(e.toString());
      _resetCouponState();
    } finally {
      isLoading.value = false;
    }
  }

  // ✅ LOCAL CALCULATION: Calculate discount based on your business rules
// ✅ UPDATED: Calculate discount based on MINIMUM of percentage vs value
  double _calculateDiscountAmount(CouponModel coupon) {
    if (subtotal.value <= 0) return 0.0;

    double percentageDiscount = 0.0;
    double valueDiscount = 0.0;

    // Step 1: Calculate percentage discount on subtotal
    if (coupon.discountPercent > 0) {
      percentageDiscount = (subtotal.value * coupon.discountPercent) / 100;
    }

    // Step 2: Get fixed value discount
    if (coupon.discountValue > 0) {
      valueDiscount = coupon.discountValue;
    }

    // Step 3: Take MINIMUM of percentage discount and value discount
    double finalDiscount = 0.0;

    if (percentageDiscount > 0 && valueDiscount > 0) {
      // ✅ YE HAI AAPKA MAIN LOGIC: Minimum of both
      finalDiscount = percentageDiscount < valueDiscount ? percentageDiscount : valueDiscount;
    } else if (percentageDiscount > 0) {
      // Only percentage available
      finalDiscount = percentageDiscount;
    } else if (valueDiscount > 0) {
      // Only value available
      finalDiscount = valueDiscount;
    }

    // Step 4: Ensure discount doesn't exceed subtotal
    if (finalDiscount > subtotal.value) {
      finalDiscount = subtotal.value;
    }

    return double.parse(finalDiscount.toStringAsFixed(2));
  }

  // Set subtotal for discount calculation
  void setSubtotal(double amount) {
    subtotal.value = amount;

    // Recalculate discount if coupon is applied
    if (isCouponApplied.value && selectedCoupon.value != null) {
      final newDiscount = _calculateDiscountAmount(selectedCoupon.value!);
      discountAmount.value = newDiscount;
    }
  }

  // Remove applied coupon
  void removeCoupon() {
    _resetCouponState();
    _showSuccess('Coupon removed');
  }

  // Reset coupon state
  void _resetCouponState() {
    selectedCoupon.value = null;
    isCouponApplied.value = false;
    discountAmount.value = 0.0;
    couponTextController.clear();
    couponCode.value = '';
    clearMessages();
  }

  // Get final total after discount
  double getFinalTotal(double deliveryCharge) {
    final subtotalWithDelivery = subtotal.value + deliveryCharge;
    if (!isCouponApplied.value) return subtotalWithDelivery;
    return subtotalWithDelivery - discountAmount.value;
  }

  // Fetch available coupons for display
  Future<void> fetchAvailableCoupons({bool refresh = false}) async {
    try {
      if (refresh || availableCoupons.isEmpty) {
        isLoading.value = true;
      }

      final response = await _couponService.getAllCoupons(page: 1, limit: 50);

      if (response.success) {
        // Filter only valid coupons
        final validCoupons = response.data.where((coupon) => coupon.isValid).toList();
        availableCoupons.value = validCoupons;
      }
    } catch (e) {
      print('Error fetching available coupons: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Select coupon from available list
  void selectCoupon(CouponModel coupon) {
    couponTextController.text = coupon.code;
    validateAndApplyCoupon(coupon.code);
  }

  // Get order data for placing order (includes coupon info)
  Map<String, dynamic> getOrderCouponData() {
    if (!isCouponApplied.value || selectedCoupon.value == null) {
      return {};
    }

    return {
      'couponId': selectedCoupon.value!.id,
      'couponCode': selectedCoupon.value!.code,
      'discountAmount': discountAmount.value,
      'discountType': selectedCoupon.value!.discountPercent > 0 ? 'percentage' : 'fixed',
    };
  }
}

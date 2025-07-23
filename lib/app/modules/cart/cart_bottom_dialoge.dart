import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:mobiking/app/controllers/cart_controller.dart';
import 'package:mobiking/app/modules/cart/widget/CartItemCard.dart';
import 'package:mobiking/app/modules/checkout/CheckoutScreen.dart';
import 'package:mobiking/app/themes/app_theme.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartController cartController = Get.find<CartController>();

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      cartController.fetchAndLoadCartData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.neutralBackground,
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: const Icon(Icons.arrow_back_ios, color: AppColors.textDark),
        ),
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: AppColors.white,
        title: Text(
          'My Cart',
          style: textTheme.titleLarge?.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Obx(() {
              if (cartController.cartItems.isEmpty) {
                return _buildEmptyCart(context);
              }

              return Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: cartController.cartItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final cartItem = cartController.cartItems[index];
                        final productId = cartItem['productId']?['_id'] ?? '';
                        final variantName = cartItem['variantName'] ?? '';

                        if (productId.isEmpty || variantName.isEmpty) {
                          return const SizedBox.shrink(); // Skip invalid items
                        }

                        return CartItemCard(
                          cartItem: cartItem,
                          onIncrement: cartController.isLoading.value
                              ? null
                              : () => cartController.addToCart(
                            productId: productId,
                            variantName: variantName,
                          ),
                          onDecrement: cartController.isLoading.value
                              ? null
                              : () => cartController.removeFromCart(
                            productId: productId,
                            variantName: variantName,
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1, thickness: 1, color: AppColors.neutralBackground),
                  _buildCartSummary(context),
                ],
              );
            }),
          ),
          Obx(() {
            if (!cartController.isLoading.value) return const SizedBox.shrink();
            return Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withOpacity(0.25),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primaryPurple),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: AppColors.textLight.withOpacity(0.6),
            ),
            const SizedBox(height: 24),
            Text(
              'Your Cart is Feeling Lonely',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Looks like you haven’t added anything yet.\nExplore our products and fill it up with your favorites!',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textMedium,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

          ],
        ),
      ),
    );
  }

  Widget _buildCartSummary(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Obx(() {
      final total = cartController.totalCartValue;
      final totalItems = cartController.totalCartItemsCount;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: AppColors.textDark.withOpacity(0.08),
              offset: const Offset(0, -4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtotal ($totalItems ${totalItems == 1 ? 'item' : 'items'}):',
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '₹${total.toStringAsFixed(2)}',
                  style: textTheme.titleLarge?.copyWith(
                    color: AppColors.primaryPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: cartController.isLoading.value || totalItems == 0
                    ? null
                    : () {
                  Get.to(() => CheckoutScreen());
                  print("Cart Products for Checkout: ${cartController.cartItems.length}");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                  disabledBackgroundColor: AppColors.lightPurple.withOpacity(0.5),
                ),
                child: Text(
                  "Proceed to Checkout",
                  style: textTheme.labelLarge?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

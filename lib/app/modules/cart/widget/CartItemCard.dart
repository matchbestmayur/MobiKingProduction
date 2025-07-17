import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobiking/app/themes/app_theme.dart'; // Import your AppTheme
import '../../../controllers/cart_controller.dart';
import '../../../data/product_model.dart'; // Assuming CartItemCard also uses ProductModel
import 'package:collection/collection.dart'; // For firstWhereOrNull if product.variants is used

class CartItemCard extends StatelessWidget {
  // CartItemCard receives a map, so we need to parse it to ProductModel
  final Map<String, dynamic> cartItem;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  const CartItemCard({
    Key? key,
    required this.cartItem,
    this.onIncrement,
    this.onDecrement,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final CartController cartController = Get.find<CartController>();

    // Safely parse product data and quantity from the cartItem map
    final productData = cartItem['productId'];
    final ProductModel product = productData is Map<String, dynamic>
        ? ProductModel.fromJson(productData)
        : ProductModel( // Fallback ProductModel
      id: '',
      name: 'Unnamed Product',
      fullName: 'Unnamed Product Full Name',
      slug: 'unnamed-product',
      description: 'This is a fallback product.',
      active: false,
      newArrival: false,
      liked: false,
      bestSeller: false,
      recommended: false,
      sellingPrice: [],
      categoryId: '',
      stockIds: [],
      orderIds: [],
      groupIds: [],
      totalStock: 0,
      variants: {},
      images: [], descriptionPoints: [], keyInformation: [],
    );
    final int quantity = cartItem['quantity'] as int? ?? 1;
    final String variantName = cartItem['variantName'] as String? ?? 'Default';

    // Determine the price and stock for the specific variant
    double displayPrice = 0.0;
    int? variantStock;

    // Price logic based on your current ProductModel (Map<String, int> variants)
    // If you ever change ProductModel.variants to include price, this logic needs update.
    if (product.sellingPrice.isNotEmpty) {
      displayPrice = product.sellingPrice.last.price!.toDouble();
    } else {
      displayPrice = 0.0; // Default price if no sellingPrice is found
    }

    // Stock for the selected variant
    variantStock = product.variants[variantName]; // This will be int?

    // Fallback to totalStock if specific variant stock isn't found or product has no explicit variants
    if (variantStock == null) {
      variantStock = product.totalStock;
    }


    String imageUrl = 'https://via.placeholder.com/100';
    if (product.images.isNotEmpty) {
      imageUrl = product.images[0];
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.symmetric(vertical: 4), // Small vertical margin to separate cards
      decoration: BoxDecoration(
        color: AppColors.white, // White background for the card
        borderRadius: BorderRadius.circular(12), // Consistent rounded corners for the card
        border: Border.all(color: AppColors.neutralBackground, width: 1), // Subtle border
        boxShadow: [ // Add a subtle shadow if you want it to lift from the background
          BoxShadow(
            color: AppColors.textDark.withOpacity(0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 80,
                    height: 80,
                    color: AppColors.neutralBackground,
                    child: Icon(
                      Icons.image_not_supported,
                      color: AppColors.textLight,
                      size: 30,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Product Details (Name, Variant, Price)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name ?? 'Unnamed Product',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      variantName,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMedium,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${displayPrice.toStringAsFixed(0)}',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),

                  ],
                ),
              ),

              // Quantity Selector
              Align(
                alignment: Alignment.bottomRight,
                child: Obx(
                      () {
                    final bool isLoading = cartController.isLoading.value;
                    // Allow decrement when quantity is 1 to trigger removal if onDecrement handles it
                    final bool isDecrementDisabled = isLoading; // Only disable if loading
                    final bool isIncrementDisabled = isLoading || (variantStock != null && quantity >= variantStock!);

                    return Container(
                      margin: EdgeInsets.symmetric(vertical: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success, // Light green background for quantity selector bar
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.success, width: 0.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Decrement Button
                          _buildQuantityButton(
                            context: context,
                            icon: Icons.remove,
                            onTap: isDecrementDisabled ? null : onDecrement, // Use passed callback
                            isDisabled: isDecrementDisabled,
                            isLoading: isLoading && quantity > 1, // Show loading when decrementing to 0 or more
                          ),
                          const SizedBox(width: 8),
                          // Quantity Text
                          Text(
                            '$quantity',
                            style: textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Increment Button
                          _buildQuantityButton(
                            context: context,
                            icon: Icons.add,
                            onTap: isIncrementDisabled ? null : onIncrement, // Use passed callback
                            isDisabled: isIncrementDisabled,
                            isLoading: isLoading && (variantStock == null || quantity < variantStock!),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method for quantity buttons - identical to the one in CartItemTile
  Widget _buildQuantityButton({
    required BuildContext context,
    required IconData icon,
    VoidCallback? onTap,
    required bool isDisabled,
    required bool isLoading,
  }) {
    final Color buttonColor =  AppColors.success;
    final Color iconColor = AppColors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isDisabled ? buttonColor.withOpacity(0.5) : buttonColor , // Adjust color if disabled
          shape: BoxShape.circle,
        ),
        child: isLoading
            ? SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(iconColor),
          ),
        )
            : Icon(
          icon,
          size: 18,
          color: isDisabled ? iconColor.withOpacity(0.5) : iconColor, // Adjust color if disabled
        ),
      ),
    );
  }
}
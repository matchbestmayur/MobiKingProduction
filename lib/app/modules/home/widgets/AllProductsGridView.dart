import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/product_model.dart';
import '../../../themes/app_theme.dart';
import '../../Product_page/product_page.dart';
import 'AllProductGridCard.dart';

class AllProductsGridView extends StatefulWidget {
  final List<ProductModel> products;
  final double horizontalPadding;
  final String title;
  final bool showTitle;
  final VoidCallback? onLoadMore;
  final bool isLoadingMore;
  final bool hasMoreProducts;

  const AllProductsGridView({
    super.key,
    required this.products,
    this.horizontalPadding = 2.0,
    this.title = "All Products",
    this.showTitle = true,
    this.onLoadMore,
    this.isLoadingMore = false,
    this.hasMoreProducts = true,
  });

  @override
  State<AllProductsGridView> createState() => _AllProductsGridViewState();
}

class _AllProductsGridViewState extends State<AllProductsGridView> {
  // ✅ Remove internal ScrollController - use parent scroll instead
  bool _isLoadingTriggered = false;

  @override
  void initState() {
    super.initState();
    // ✅ Listen to parent scroll controller instead
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attachToParentScroll();
    });
  }

  void _attachToParentScroll() {
    final ScrollController? parentController = PrimaryScrollController.of(context);
    if (parentController != null) {
      parentController.addListener(_onParentScroll);
    }
  }

  @override
  void dispose() {
    // ✅ Remove listener from parent scroll controller
    final ScrollController? parentController = PrimaryScrollController.of(context);
    if (parentController != null) {
      parentController.removeListener(_onParentScroll);
    }
    super.dispose();
  }

  void _onParentScroll() {
    final ScrollController? parentController = PrimaryScrollController.of(context);
    if (parentController == null || !parentController.hasClients) return;

    final maxScroll = parentController.position.maxScrollExtent;
    final currentScroll = parentController.position.pixels;

    print("📍 Parent Scroll: ${currentScroll.toStringAsFixed(1)} / ${maxScroll.toStringAsFixed(1)}");

    // Reset loading trigger when scroll position changes significantly
    if (currentScroll < maxScroll * 0.7) {
      _isLoadingTriggered = false;
    }

    // Trigger load more at 85% scroll
    if (currentScroll >= maxScroll * 0.85) {
      _triggerLoadMore();
    }
  }

  void _triggerLoadMore() {
    if (_isLoadingTriggered ||
        widget.isLoadingMore ||
        !widget.hasMoreProducts ||
        widget.onLoadMore == null) return;

    _isLoadingTriggered = true;
    print("🚀 Infinite scroll triggered from parent scroll");
    widget.onLoadMore!();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Filter in-stock products
    final inStockProducts = widget.products.where((product) {
      return product.variants.entries.any((variant) => variant.value > 0);
    }).toList();

    print("📦 Products: ${widget.products.length}, In-stock: ${inStockProducts.length}");

    if (inStockProducts.isEmpty && !widget.isLoadingMore) {
      return _buildEmptyState(context);
    }

    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // ✅ Important: Use min size
        children: [
          // Title Section
          if (widget.showTitle)
            Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 16.0),
              child: Row(
                children: [
                  Text(
                    widget.title,
                    style: textTheme.titleLarge?.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${inStockProducts.length}',
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.primaryPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ✅ Products Grid without Expanded - use shrinkWrap instead
          Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
            child: GridView.builder(
              // ✅ Remove controller - let parent handle scrolling
              shrinkWrap: true, // ✅ Important: Grid wraps to content size
              physics: const NeverScrollableScrollPhysics(), // ✅ Disable internal scrolling
              padding: const EdgeInsets.all(8.0),
              itemCount: inStockProducts.length + (widget.isLoadingMore ? 3 : 0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.46,
              ),
              itemBuilder: (context, index) {
                // Show loading shimmer
                if (index >= inStockProducts.length) {
                  return _buildShimmerCard();
                }

                final product = inStockProducts[index];
                return GestureDetector(
                  onTap: () => Get.to(ProductPage(
                    product: product,
                    heroTag: 'product_${product.id}_$index',
                  )),
                  child: AllProductGridCard(
                    product: product,
                    heroTag: 'product_${product.id}_$index',
                  ),
                );
              },
            ),
          ),

          // Loading Indicator
          if (widget.isLoadingMore)
            Container(
              padding: const EdgeInsets.all(16.0),
              alignment: Alignment.center,
              child: const CircularProgressIndicator(
                color: AppColors.primaryPurple,
                strokeWidth: 2,
              ),
            ),

          // End Message
          if (!widget.hasMoreProducts && inStockProducts.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16.0),
              alignment: Alignment.center,
              child: Text(
                '✨ You\'ve seen all products!',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textLight,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.neutralBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.textLight.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.textLight.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.textLight.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 6,
                    width: 50,
                    decoration: BoxDecoration(
                      color: AppColors.textLight.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      height: 400, // ✅ Fixed height for empty state
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  size: 48,
                  color: AppColors.primaryPurple,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Products Available',
                style: textTheme.headlineSmall?.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'All products are currently out of stock.\nCheck back later for new arrivals!',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textLight,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

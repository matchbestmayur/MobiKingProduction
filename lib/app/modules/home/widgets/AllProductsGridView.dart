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
  bool _isLoadingTriggered = false;

  @override
  void initState() {
    super.initState();
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

    if (currentScroll < maxScroll * 0.7) {
      _isLoadingTriggered = false;
    }

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

  List<ProductModel> _getProductsToShow() {
    if (widget.products.isEmpty) return [];

    // First, try to show in-stock products
    final inStockProducts = widget.products.where((product) {
      return product.variants.entries.any((variant) => variant.value > 0);
    }).toList();

    // If no in-stock products, show all products (including out of stock)
    if (inStockProducts.isEmpty) {
      return widget.products;
    }

    return inStockProducts;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final productsToShow = _getProductsToShow();

    print("📦 Total Products: ${widget.products.length}, Showing: ${productsToShow.length}");

    // Only show empty state if there are absolutely no products at all
    if (widget.products.isEmpty && !widget.isLoadingMore) {
      return _buildEmptyState(context);
    }

    // Show loading state if we're loading and have no products yet
    if (widget.products.isEmpty && widget.isLoadingMore) {
      return _buildLoadingState();
    }

    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
                      '${productsToShow.length}',
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.primaryPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Products Grid
          Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(8.0),
              itemCount: productsToShow.length + (widget.isLoadingMore ? 3 : 0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.46,
              ),
              itemBuilder: (context, index) {
                // Show loading shimmer
                if (index >= productsToShow.length) {
                  return _buildShimmerCard();
                }

                final product = productsToShow[index];
                final isOutOfStock = !product.variants.entries.any((variant) => variant.value > 0);

                return GestureDetector(
                  onTap: () => Get.to(ProductPage(
                    product: product,
                    heroTag: 'product_${product.id}_$index',
                  )),
                  child: Stack(
                    children: [
                      AllProductGridCard(
                        product: product,
                        heroTag: 'product_${product.id}_$index',
                      ),
                      // Out of stock overlay
                      if (isOutOfStock)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Out of Stock',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
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
          if (!widget.hasMoreProducts && productsToShow.isNotEmpty)
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

  Widget _buildLoadingState() {
    return Container(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: AppColors.primaryPurple,
              strokeWidth: 2,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading products...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
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
      height: 300, // Reduced height
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                size: 64,
                color: AppColors.textLight.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No Products Found',
                style: textTheme.titleMedium?.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Check back later for new products!',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

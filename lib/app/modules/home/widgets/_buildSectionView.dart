import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobiking/app/modules/Product_page/product_page.dart';
import 'package:mobiking/app/modules/home/widgets/sub_category_screen.dart';
import 'package:mobiking/app/widgets/group_grid_section.dart';
import '../../../controllers/product_controller.dart';
import '../../../data/group_model.dart';
import '../../../data/product_model.dart';
import '../../../data/sub_category_model.dart';
import '../../../themes/app_theme.dart';
import '../../../widgets/buildProductList.dart';
import '../loading/ShimmerBanner.dart';
import 'AllProductGridCard.dart';

class ProductGridViewSection extends StatefulWidget {
  final String bannerImageUrl;
  final List<SubCategory> subCategories;
  final List<SubCategory>? categoryGridItems;
  final List<GroupModel> groups;
  final int index;
  final ProductController productController;
  final String? categoryId;

  const ProductGridViewSection({
    super.key,
    required this.bannerImageUrl,
    required this.subCategories,
    this.categoryGridItems,
    required this.groups,
    required this.index,
    required this.productController,
    this.categoryId,
  });

  @override
  State<ProductGridViewSection> createState() => _ProductGridViewSectionState();
}

class _ProductGridViewSectionState extends State<ProductGridViewSection> {
  late ScrollController _scrollController;
  bool _isLoadingTriggered = false;
  double _lastScrollPosition = 0.0;
  bool _isScrollingUp = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    // ✅ Detect scroll direction
    _isScrollingUp = currentScroll > _lastScrollPosition;
    _lastScrollPosition = currentScroll;

    print("📍 Scroll: ${currentScroll.toStringAsFixed(1)} / ${maxScroll.toStringAsFixed(1)} (${(currentScroll/maxScroll*100).toStringAsFixed(1)}%)");
    print("🔄 Scrolling ${_isScrollingUp ? 'UP' : 'DOWN'}");

    // ✅ Reset loading trigger when user scrolls back significantly
    if (currentScroll < maxScroll * 0.6) {
      _isLoadingTriggered = false;
    }

    // ✅ Enhanced trigger condition: 75% scroll + scrolling up + user gesture
    if (currentScroll >= maxScroll * 0.75 && _isScrollingUp) {
      _triggerLoadMore();
    }
  }

  void _triggerLoadMore() {
    // ✅ Enhanced conditions for better UX
    if (_isLoadingTriggered ||
        widget.productController.isFetchingMore.value ||
        !widget.productController.hasMoreProducts.value ||
        !_isScrollingUp) { // Only trigger when scrolling up
      return;
    }

    _isLoadingTriggered = true;
    print("🚀 Infinite scroll triggered at 75% - User swiped up for category: ${widget.categoryId}");

    // ✅ Add a small delay to ensure smooth UX
    Future.delayed(const Duration(milliseconds: 100), () {
      widget.productController.fetchMoreProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        // ✅ Additional scroll detection for better responsiveness
        if (notification is ScrollUpdateNotification) {
          final ScrollMetrics metrics = notification.metrics;
          final double scrollPercentage = metrics.pixels / metrics.maxScrollExtent;

          // ✅ Trigger at 75% with smooth detection
          if (scrollPercentage >= 0.75 &&
              notification.scrollDelta! > 0 && // Positive delta = scrolling down/up
              !_isLoadingTriggered &&
              widget.productController.hasMoreProducts.value &&
              !widget.productController.isFetchingMore.value) {

            print("🎯 ScrollNotification triggered at ${(scrollPercentage * 100).toStringAsFixed(1)}%");
            _triggerLoadMore();
          }
        }
        return false; // Allow the notification to continue
      },
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(), // ✅ Better scroll feel
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Section
            if (widget.bannerImageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                child: SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: Image.network(
                    widget.bannerImageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const ShimmerBanner(
                        width: double.infinity,
                        height: 160,
                        borderRadius: 12,
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.neutralBackground,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.broken_image,
                          color: AppColors.textLight,
                          size: 40,
                        ),
                      );
                    },
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // Group Sections (if available)
            if (widget.groups.isNotEmpty)
              GroupWithProductsSection(groups: widget.groups),

            // ✅ Integrated Products Grid Section
            Obx(() {
              final products = widget.productController.allProducts;
              final isLoading = widget.productController.isLoading.value;
              final isLoadingMore = widget.productController.isFetchingMore.value;
              final hasMoreProducts = widget.productController.hasMoreProducts.value;

              if (isLoading && products.isEmpty) {
                return const SizedBox(
                  height: 300,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primaryPurple),
                  ),
                );
              } else if (products.isEmpty && !isLoading) {
                return const SizedBox(
                  height: 300,
                  child: Center(
                    child: Text(
                      'We couldn\'t find any items at the moment.\nPlease check back later.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              } else {
                // Filter in-stock products
                final inStockProducts = products.where((product) {
                  return product.variants.entries.any((variant) => variant.value > 0);
                }).toList();

                if (inStockProducts.isEmpty && !isLoadingMore) {
                  return _buildEmptyState(context, textTheme);
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Section with scroll progress indicator
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
                      child: Row(
                        children: [
                          Text(
                            "All Products",
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
                          const Spacer(),
                          // ✅ Add scroll hint when near trigger point
                          if (hasMoreProducts && !isLoadingMore)
                            AnimatedBuilder(
                              animation: _scrollController,
                              builder: (context, child) {
                                if (!_scrollController.hasClients) return const SizedBox.shrink();

                                final progress = _scrollController.position.pixels /
                                    _scrollController.position.maxScrollExtent;

                                if (progress >= 0.6 && progress < 0.75) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentNeon.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.keyboard_arrow_up,
                                          size: 12,
                                          color: AppColors.accentNeon,
                                        ),
                                        Text(
                                          'Swipe up',
                                          style: textTheme.labelSmall?.copyWith(
                                            color: AppColors.accentNeon,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                        ],
                      ),
                    ),

                    // ✅ Products Grid
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(8.0),
                        itemCount: inStockProducts.length + (isLoadingMore ? 3 : 0),
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

                    // ✅ Enhanced Loading Indicator with animation
                    if (isLoadingMore)
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            const CircularProgressIndicator(
                              color: AppColors.primaryPurple,
                              strokeWidth: 2,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Loading more products...',
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // ✅ Enhanced End Message
                    if (!hasMoreProducts && inStockProducts.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: AppColors.primaryPurple,
                              size: 24,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '✨ You\'ve seen all products!',
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.primaryPurple,
                                fontWeight: FontWeight.w600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              }
            }),
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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 1000),
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

  Widget _buildEmptyState(BuildContext context, TextTheme textTheme) {
    return Container(
      height: 400,
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

// ✅ Updated function to use the new integrated widget
Widget buildSectionView({
  required String bannerImageUrl,
  required List<SubCategory> subCategories,
  required List<SubCategory>? categoryGridItems,
  required List<GroupModel> groups,
  required int index,
  required ProductController productController,
  String? categoryId,
}) {
  return ProductGridViewSection(
    bannerImageUrl: bannerImageUrl,
    subCategories: subCategories,
    categoryGridItems: categoryGridItems,
    groups: groups,
    index: index,
    productController: productController,
    categoryId: categoryId,
  );
}

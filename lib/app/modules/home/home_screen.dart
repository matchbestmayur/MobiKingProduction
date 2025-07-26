import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:mobiking/app/modules/home/widgets/FloatingCartButton.dart';
import '../../controllers/cart_controller.dart' show CartController;
import '../../controllers/category_controller.dart';
import '../../controllers/sub_category_controller.dart';
import '../../controllers/tab_controller_getx.dart';
import '../../controllers/product_controller.dart'; // ✅ Add this import
import '../../themes/app_theme.dart';
import '../../widgets/CustomBottomBar.dart';
import '../../widgets/CategoryTab.dart';
import '../../widgets/CustomAppBar.dart';
import '../../widgets/SearchTabSliverAppBar.dart' show SearchTabSliverAppBar;
import '../cart/cart_bottom_dialoge.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CategoryController categoryController = Get.find<CategoryController>();
  final SubCategoryController subCategoryController = Get.find<SubCategoryController>();
  final TabControllerGetX tabController = Get.find<TabControllerGetX>();
  final ProductController productController = Get.find<ProductController>(); // ✅ Add this

  late ScrollController _scrollController;
  final RxBool _showScrollToTopButton = false.obs;
  bool _isLoadingTriggered = false; // ✅ Add infinite scroll state

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    // ✅ Scroll to top button logic
    if (_scrollController.offset >= 200 && !_showScrollToTopButton.value) {
      _showScrollToTopButton.value = true;
    } else if (_scrollController.offset < 200 && _showScrollToTopButton.value) {
      _showScrollToTopButton.value = false;
    }

    // ✅ Infinite scroll logic
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

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
        productController.isFetchingMore.value ||
        !productController.hasMoreProducts.value) return;

    _isLoadingTriggered = true;
    print("🚀 Infinite scroll triggered from HomeScreen");
    productController.fetchMoreProducts();
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: AppColors.neutralBackground,
      appBar: null,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController, // ✅ This controller now handles infinite scroll
            slivers: [
              // ✅ SearchTabSliverAppBar stays the same
              SearchTabSliverAppBar(
                onSearchChanged: (value) {
                  print('Search query: $value');
                },
              ),

              // ✅ CustomTabBarViewSection in SliverToBoxAdapter
              SliverToBoxAdapter(
                child: CustomTabBarViewSection(),
              ),

              // ✅ Add loading indicator at the bottom when fetching more
              Obx(() {
                if (productController.isFetchingMore.value) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryPurple,
                        ),
                      ),
                    ),
                  );
                }
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }),
            ],
          ),

          // ✅ Scroll to Top Button (unchanged)
          Positioned(
            top: MediaQuery.of(context).padding.top + 120.0,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.topCenter,
              child: Obx(() => AnimatedOpacity(
                opacity: _showScrollToTopButton.value ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: _showScrollToTopButton.value
                    ? FloatingActionButton(
                  mini: true,
                  backgroundColor: AppColors.darkPurple,
                  onPressed: _scrollToTop,
                  child: const Icon(Icons.arrow_upward, color: Colors.white),
                )
                    : const SizedBox.shrink(),
              )),
            ),
          ),
        ],
      ),
    );
  }
}

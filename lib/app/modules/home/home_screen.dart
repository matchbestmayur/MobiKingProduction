import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart'; // Keep if used elsewhere or for specific cases

// Assuming these are your local paths
import 'package:mobiking/app/modules/home/widgets/FloatingCartButton.dart'; // Assuming this widget exists
import '../../controllers/cart_controller.dart' show CartController; // Assuming this controller exists
import '../../controllers/category_controller.dart'; // Assuming this controller exists
import '../../controllers/sub_category_controller.dart';
import '../../controllers/tab_controller_getx.dart';
import '../../themes/app_theme.dart'; // Make sure this import is correct
import '../../widgets/CustomBottomBar.dart'; // Assuming this widget exists
import '../../widgets/CategoryTab.dart'; // Assuming this widget exists
import '../../widgets/CustomAppBar.dart';
import '../../widgets/SearchTabSliverAppBar.dart' show SearchTabSliverAppBar;
import '../cart/cart_bottom_dialoge.dart'; // Assuming this widget exists


class HomeScreen extends StatefulWidget {
  HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Controllers should ideally be initialized here once
  final CategoryController categoryController = Get.find<CategoryController>();
  final SubCategoryController subCategoryController = Get.find<SubCategoryController>();
  // Assuming TabControllerGetX is always available via Get.find()
  final TabControllerGetX tabController = Get.find<TabControllerGetX>();


  late ScrollController _scrollController;
  final RxBool _showScrollToTopButton = false.obs;

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
    if (_scrollController.offset >= 200 && !_showScrollToTopButton.value) {
      _showScrollToTopButton.value = true;
    } else if (_scrollController.offset < 200 && _showScrollToTopButton.value) {
      _showScrollToTopButton.value = false;
    }
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
    // Get the TextTheme from the current context
    final TextTheme textTheme = Theme.of(context).textTheme;

    // Removed redundant backgroundImage and selectedIndex logic
    // as CustomAppBar and SearchTabSliverAppBar handle their own backgrounds.

    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: AppColors.neutralBackground, // Use AppColors for background
      appBar: null,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
           /*   // CustomAppBar is a regular Widget (RenderBox). It needs SliverToBoxAdapter.
              SliverToBoxAdapter(
                child: CustomAppBar(),
              ),*/
              // SearchTabSliverAppBar returns a SliverPersistentHeader (it IS a sliver).
              // It MUST be a direct child of the CustomScrollView's slivers list.
              // DO NOT wrap it in Column, Container, or another SliverToBoxAdapter.
              SearchTabSliverAppBar(
                onSearchChanged: (value) {
                  print('Search query: $value');
                },
              ),
              // Assuming CustomTabBarViewSection is a regular Widget (RenderBox).
              // It needs SliverToBoxAdapter.
              SliverToBoxAdapter(
                child: CustomTabBarViewSection(),
              ),
              // The main content area is a regular Widget (RenderBox).
              // It needs SliverToBoxAdapter.
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12.0, 0.0, 24.0, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Mobiking",
                        textAlign: TextAlign.left,
                        style: textTheme.displayLarge?.copyWith(
                          color: AppColors.textLight, // Use AppColors for consistent grey
                          letterSpacing: -2.0,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Your Wholesale Partner",
                        textAlign: TextAlign.left,
                        style: textTheme.headlineMedium?.copyWith(
                          color: AppColors.textLight, // Use AppColors for consistent grey
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Buy in bulk, save big. Get the best deals on mobile phones and accessories, delivered directly to your doorstep.",
                        textAlign: TextAlign.left,
                        style: textTheme.bodyLarge?.copyWith(
                          color: AppColors.textLight, // Use AppColors for consistent grey
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // --- Scroll to Top Button (Top Center) ---
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
                  backgroundColor: AppColors.darkPurple, // Use AppColors
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
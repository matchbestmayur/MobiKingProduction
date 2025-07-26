import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobiking/app/controllers/sub_category_controller.dart';
import 'package:mobiking/app/modules/search/SearchPage.dart';
import 'package:mobiking/app/themes/app_theme.dart';
import '../controllers/tab_controller_getx.dart';
import '../controllers/Home_controller.dart';
import 'CategoryTab.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SearchTabSliverAppBar extends StatefulWidget {
  final TextEditingController? searchController;
  final void Function(String)? onSearchChanged;

  const SearchTabSliverAppBar({
    Key? key,
    this.searchController,
    this.onSearchChanged,
  }) : super(key: key);

  @override
  _SearchTabSliverAppBarState createState() => _SearchTabSliverAppBarState();
}

class _SearchTabSliverAppBarState extends State<SearchTabSliverAppBar> {
  final List<String> _hintTexts = [
    'Search "20w bulb"',
    'Search "LED strip lights"',
    'Search "solar panel"',
    'Search "smart plug"',
    'Search "rechargeable battery"',
  ];

  late final RxInt _currentHintIndex;
  Timer? _hintTextTimer;

  final TabControllerGetX tabController = Get.put(TabControllerGetX());
  final SubCategoryController subCategoryController = Get.put(SubCategoryController());
  final HomeController homeController = Get.find<HomeController>();

  @override
  void initState() {
    super.initState();
    _currentHintIndex = 0.obs;
    _startHintTextAnimation();
  }

  void _startHintTextAnimation() {
    _hintTextTimer?.cancel();
    _hintTextTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _currentHintIndex.value = (_currentHintIndex.value + 1) % _hintTexts.length;
    });
  }

  @override
  void dispose() {
    _hintTextTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _StickySearchAndTabBarDelegate(
        searchController: widget.searchController,
        onSearchChanged: widget.onSearchChanged,
        hintTexts: _hintTexts,
        currentHintIndex: _currentHintIndex,
        tabController: tabController,
        subCategoryController: subCategoryController,
        homeController: homeController,
      ),
    );
  }
}

class _StickySearchAndTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TextEditingController? searchController;
  final void Function(String)? onSearchChanged;
  final List<String> hintTexts;
  final RxInt currentHintIndex;
  final TabControllerGetX tabController;
  final SubCategoryController subCategoryController;
  final HomeController homeController;

  _StickySearchAndTabBarDelegate({
    required this.searchController,
    required this.onSearchChanged,
    required this.hintTexts,
    required this.currentHintIndex,
    required this.tabController,
    required this.subCategoryController,
    required this.homeController,
  });

  @override
  double get maxExtent => 200;

  @override
  double get minExtent => 156;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final collapsePercent = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final bool isCollapsed = collapsePercent >= 1.0;
    final TextStyle? appThemeHintStyle = Theme.of(context).inputDecorationTheme.hintStyle;

    String? backgroundImage;
    final int selectedTabIndex = tabController.selectedIndex.value;
    final homeLayout = homeController.homeData;

    if (homeLayout != null &&
        homeLayout.categories.length > selectedTabIndex &&
        homeLayout.categories[selectedTabIndex].upperBanner != null &&
        homeLayout.categories[selectedTabIndex].upperBanner!.isNotEmpty) {
      backgroundImage = homeLayout.categories[selectedTabIndex].upperBanner!;
    }

    return Container(
      padding: const EdgeInsets.only(top: 18),
      decoration: BoxDecoration(
        color: isCollapsed ? Colors.black45 : null,
        image: backgroundImage != null
            ? DecorationImage(
          image: CachedNetworkImageProvider(backgroundImage),
          fit: BoxFit.cover,
          colorFilter: isCollapsed
              ? const ColorFilter.mode(Colors.black45, BlendMode.darken)
              : null,
        )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isCollapsed)
            SizedBox(
              height: (1 - collapsePercent) * 60,
              child: Opacity(
                opacity: (1 - collapsePercent),
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Text(
                    'Mobiking Wholesale',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

          // --- Search Bar ---
          Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: isCollapsed ? 16.0 : 4.0,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => Get.to(() => const SearchPage()),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: isCollapsed ? Colors.black : AppColors.textMedium,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Obx(() {
                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          transitionBuilder: (child, animation) {
                            final offsetAnimation = Tween<Offset>(
                              begin: const Offset(0, 1),
                              end: Offset.zero,
                            ).animate(animation);
                            return ClipRect(
                              child: SlideTransition(
                                position: offsetAnimation,
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              ),
                            );
                          },
                          child: Text(
                            hintTexts[currentHintIndex.value],
                            key: ValueKey<int>(currentHintIndex.value),
                            style: appThemeHintStyle,
                          ),
                        );
                      }),
                    ),
                    Icon(
                      Icons.mic_none,
                      color: isCollapsed ? Colors.black : AppColors.textMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 7),
          // 🟢 Category Tab Section
          CustomTabBarSection(),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true; // Always rebuild when sliver scrolls
  }
}

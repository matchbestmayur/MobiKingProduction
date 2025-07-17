import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobiking/app/controllers/sub_category_controller.dart';
import 'package:mobiking/app/modules/search/SearchPage.dart';
import 'package:mobiking/app/themes/app_theme.dart';
import '../controllers/tab_controller_getx.dart';
import '../controllers/Home_controller.dart'; // Import HomeController
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
    final String? homeUpperBanner = homeController.homeData.value?.categories[tabController.selectedIndex.value].upperBanner;
    if (homeUpperBanner != null && homeUpperBanner.isNotEmpty) {
      backgroundImage = homeUpperBanner;
    }

    return Container(
      padding: const EdgeInsets.only(top: 16),
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
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Mobiking Wholesale',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // --- Search Bar ---
          Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: isCollapsed ? 16.0 : 4.0, // Dynamic top padding
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  onTap: () {
                    Get.to(() => const SearchPage(),
                        transition: Transition.rightToLeft,
                        duration: const Duration(milliseconds: 300));
                  },
                  readOnly: true,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textDark) ??
                      GoogleFonts.poppins(fontSize: 15, color: AppColors.textDark),
                  cursorColor: AppColors.primaryGreen,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hint: Obx(() {
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
                    prefixIcon: Icon(
                      Icons.search,
                      color: isCollapsed ? Colors.black : AppColors.textMedium,
                    ),
                    suffixIcon: Icon(
                      Icons.mic_none,
                      color: isCollapsed ? Colors.black : AppColors.textMedium,
                    ),
                    contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 7),
           CustomTabBarSection(),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return oldDelegate != this ||
        (oldDelegate as _StickySearchAndTabBarDelegate)
            .homeController
            .homeData
            .value !=
            homeController.homeData.value;
  }
}

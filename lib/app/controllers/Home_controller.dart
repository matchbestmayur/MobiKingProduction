import 'package:get/get.dart';
import '../data/Home_model.dart';
import '../data/group_model.dart';
import '../services/home_service.dart';
import 'package:mobiking/app/controllers/connectivity_controller.dart';

class HomeController extends GetxController {
  final HomeService _service = HomeService();
  final ConnectivityController _connectivityController = Get.find();

  /// Only expose loading state when needed for UI
  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  /// Expose final home data
  final Rxn<HomeLayoutModel> _homeData = Rxn<HomeLayoutModel>();
  HomeLayoutModel? get homeData => _homeData.value;

  /// Store groups per category only once (non-reactive)
  final Map<String, List<GroupModel>> _categoryGroups = {};
  Map<String, List<GroupModel>> get categoryGroups => _categoryGroups;

  /// ✅ Add loading state tracking for individual category groups
  final RxMap<String, bool> _isLoadingGroups = <String, bool>{}.obs;
  Map<String, bool> get isLoadingGroups => _isLoadingGroups;

  /// ✅ Add error state tracking for category groups
  final RxMap<String, String?> _groupErrors = <String, String?>{}.obs;
  Map<String, String?> get groupErrors => _groupErrors;

  /// ✅ Add method to check if any groups are currently loading
  bool get isAnyGroupLoading => _isLoadingGroups.values.any((loading) => loading == true);

  @override
  void onInit() {
    super.onInit();
    fetchHomeLayout();

    // Only refetch on reconnection
    ever<bool>(_connectivityController.isConnected, (isConnected) {
      if (isConnected) _handleConnectionRestored();
    });
  }

  Future<void> _handleConnectionRestored() async {
    print('[HomeController] ✅ Internet reconnected. Re-fetching home layout...');
    await fetchHomeLayout();

    // ✅ Also refresh any previously loaded groups
    final loadedCategories = _categoryGroups.keys.toList();
    for (String categoryId in loadedCategories) {
      await fetchGroupsByCategory(categoryId, forceRefresh: true);
    }
  }

  Future<void> fetchHomeLayout() async {
    try {
      _isLoading.value = true;
      final result = await _service.getHomeLayout();
      print("📥 Home layout fetched: $result");
      _homeData.value = result;
    } catch (e) {
      print("❌ Error fetching home layout: $e");
    } finally {
      _isLoading.value = false;
    }
  }

  /// ✅ Enhanced fetchGroupsByCategory with proper loading states
  Future<void> fetchGroupsByCategory(String categoryId, {bool forceRefresh = false}) async {
    // Skip if already loaded and not forcing refresh
    if (_categoryGroups.containsKey(categoryId) && !forceRefresh) {
      print("📦 Groups already loaded for category: $categoryId");
      return;
    }

    // Skip if already loading
    if (_isLoadingGroups[categoryId] == true) {
      print("⏳ Groups already being fetched for category: $categoryId");
      return;
    }

    try {
      print("🚀 Starting to fetch groups for category: $categoryId");

      // ✅ Set loading state
      _isLoadingGroups[categoryId] = true;
      _groupErrors[categoryId] = null; // Clear previous errors

      final groups = await _service.getGroupsByCategory(categoryId);

      // ✅ Store the fetched groups
      _categoryGroups[categoryId] = groups;
      print("✅ Groups fetched for category $categoryId: ${groups.length}");

    } catch (e) {
      print("❌ Error fetching groups for category $categoryId: $e");

      // ✅ Store error state
      _groupErrors[categoryId] = e.toString();

      // ✅ Set empty list on error to prevent infinite loading
      _categoryGroups[categoryId] = [];

    } finally {
      // ✅ Always clear loading state
      _isLoadingGroups[categoryId] = false;
    }
  }

  /// ✅ Add method to check if a specific category is loading
  bool isCategoryLoading(String categoryId) {
    return _isLoadingGroups[categoryId] == true;
  }

  /// ✅ Add method to check if a specific category has an error
  String? getCategoryError(String categoryId) {
    return _groupErrors[categoryId];
  }

  /// ✅ Add method to retry loading groups for a category
  Future<void> retryGroupsForCategory(String categoryId) async {
    _groupErrors[categoryId] = null;
    _categoryGroups.remove(categoryId); // Remove cached data
    await fetchGroupsByCategory(categoryId, forceRefresh: true);
  }

  /// ✅ Add method to clear all group data (useful for refresh)
  void clearAllGroups() {
    _categoryGroups.clear();
    _isLoadingGroups.clear();
    _groupErrors.clear();
  }

  /// ✅ Add method to refresh all data
  Future<void> refreshAllData() async {
    clearAllGroups();
    await fetchHomeLayout();
  }
}

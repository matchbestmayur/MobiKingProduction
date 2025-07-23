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

  Future<void> fetchGroupsByCategory(String categoryId) async {
    if (_categoryGroups.containsKey(categoryId)) {
      print("📦 Groups already loaded for category: $categoryId");
      return;
    }

    try {
      final groups = await _service.getGroupsByCategory(categoryId);
      _categoryGroups[categoryId] = groups;
      print("✅ Groups fetched for category $categoryId: ${groups.length}");
    } catch (e) {
      print("❌ Error fetching groups for category $categoryId: $e");
    }
  }
}

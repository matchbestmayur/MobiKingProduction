import 'package:get/get.dart';

import '../data/Home_model.dart';
import '../services/home_service.dart';
import 'package:mobiking/app/controllers/connectivity_controller.dart'; // NEW: Import ConnectivityController

class HomeController extends GetxController {
  final HomeService _service = HomeService();
  var isLoading = false.obs;
  var homeData = Rxn<HomeLayoutModel>();

  // NEW: Get the ConnectivityController instance
  final ConnectivityController _connectivityController = Get.find<ConnectivityController>();

  @override
  void onInit() {
    super.onInit();
    fetchHomeLayout(); // Initial fetch

    // NEW: Listen for connectivity changes
    ever(_connectivityController.isConnected, (bool isConnected) {
      if (isConnected) {
        _handleConnectionRestored();
      }
    });
  }

  // NEW: Method to handle actions when connection is restored
  Future<void> _handleConnectionRestored() async {
    print('HomeController: Internet connection restored. Re-fetching home layout...');
    await fetchHomeLayout(); // Re-fetch home layout data
  }


  Future<void> fetchHomeLayout() async {
    try {
      isLoading.value = true;
      final result = await _service.getHomeLayout();
      print("Fetched result from service: $result");
      homeData.value = result;
      print("homeData set to: ${homeData.value}");
    } catch (e) {
      print("\n \n \n Error fetching home layout: $e");
    } finally {
      isLoading.value = false;
    }
  }

}
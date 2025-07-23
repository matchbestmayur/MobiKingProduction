import 'package:get/get.dart';
import '../data/login_model.dart';
import '../services/user_service.dart';

class UserController extends GetxController {
  final UserService _userService = UserService();
  var user = UserModel().obs;
  var isLoading = false.obs;

  Future<void> createUser(UserModel newUser) async {
    try {
      isLoading.value = true;
      final createdUser = await _userService.createUser(newUser);
      user.value = createdUser;
    } catch (e) {
      // Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchUser(String id) async {
    try {
      isLoading.value = true;
      final fetchedUser = await _userService.getUserById(id);
      user.value = fetchedUser;
    } catch (e) {
      // Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}

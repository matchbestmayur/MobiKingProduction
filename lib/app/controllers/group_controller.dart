import 'package:get/get.dart';
import '../data/group_model.dart';
import '../services/group_service.dart';

class GroupController extends GetxController {
  final GroupService _groupService = GroupService();
  var groupList = <GroupModel>[].obs;
  var isLoading = false.obs;

  Future<void> fetchGroups() async {
    try {
      isLoading.value = true;
      final groups = await _groupService.getAllGroups();
      groupList.assignAll(groups);
    } catch (e) {
      // Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addGroup(GroupModel group) async {
    try {
      isLoading.value = true;
      final newGroup = await _groupService.createGroup(group);
      groupList.add(newGroup);
    } catch (e) {
      // Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}

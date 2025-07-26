import 'package:get/get.dart';
import '../data/category_model.dart';
import '../services/category_service.dart';

class CategoryController extends GetxController {

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
  }

  final CategoryService _service = CategoryService();

  var categories = <CategoryModel>[].obs;
  var selectedCategory = Rxn<CategoryModel>();
  var isLoading = false.obs;


  Future<void> fetchCategories() async {
    try {
      isLoading.value = true;
      print('Fetching categories...');
      final List<CategoryModel> response = await _service.getCategories();
      print('Fetched categories count: ${response.length}');
      categories.assignAll(response);
    } catch (e) {
      print('Error in fetchCategories: $e');
    } finally {
      isLoading.value = false;
    }
  }


  Future<void> fetchCategoryDetails(String slug) async {
    try {
      isLoading.value = true;
      final response = await CategoryService.getCategoryDetails(slug);
      selectedCategory.value = response['category'] as CategoryModel;


    } catch (e) {
      print('Error in fetchCategoryDetails: $e');
    } finally {
      isLoading.value = false;
    }
  }
}

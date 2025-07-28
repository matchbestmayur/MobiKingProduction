import 'package:get/get.dart';
import '../data/sub_category_model.dart';
import '../data/product_model.dart';
import '../services/sub_category_service.dart';

class SubCategoryController extends GetxController {
  final SubCategoryService _service = SubCategoryService();

  var subCategories = <SubCategory>[].obs;
  // allProducts variable removed
  var isLoading = false.obs;

  // New: Holds the currently selected sub-category
  var selectedSubCategory = Rx<SubCategory?>(null);

  // New: Products belonging to the selected sub-category
  var productsForSelectedSubCategory = <ProductModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadSubCategories();

    // React to changes in selectedSubCategory to update productsForSelectedSubCategory
    // This replaces the old 'ever(subCategories, (_)' for 'allProducts'
    ever(selectedSubCategory, (_) {
      _updateProductsForSelectedSubCategory();
    });
  }

  Future<void> loadSubCategories() async {
    try {
      isLoading.value = true;
      final data = await _service.fetchSubCategories();
      print("Fetched data count: ${data.length}");

      subCategories.assignAll(data);
      // Removed _updateAllProducts() call here

      // Auto-select the first sub-category if available after loading
      if (data.isNotEmpty) {
        selectedSubCategory.value = data.first;
      }

      print("Subcategories fetched:");
      for (var sub in data) {
        print(" - ${sub.name} (${sub.id})");
      }
    } catch (e, stackTrace) {
      print('❌ Error fetching subcategories: $e');
      print(stackTrace);
    /*  Get.snackbar('Error', 'Failed to fetch subcategories: ${e.toString()}');*/
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addSubCategory(SubCategory model) async {
    try {
      isLoading.value = true;
      final newItem = await _service.createSubCategory(model);
      subCategories.add(newItem);

      // If you want to automatically select a newly added sub-category, uncomment:
      // if (selectedSubCategory.value == null) { // or some other logic
      //   selectedSubCategory.value = newItem;
      // }

      // Removed _updateAllProducts() call here
      // print("Total products: ${allProducts.length}"); // This line also removed

      print("✅ Subcategory added: ${newItem.name} (${newItem.id})");
    } catch (e) {
/*      Get.snackbar('Error', 'Failed to add subcategory: ${e.toString()}');*/
      print('❌ Error adding subcategory: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // New: Method to set the currently selected sub-category
  void selectSubCategory(SubCategory? subCategory) {
    selectedSubCategory.value = subCategory;
  }

  // New: Updates the products based on the selected sub-category
  void _updateProductsForSelectedSubCategory() {
    if (selectedSubCategory.value != null) {
      productsForSelectedSubCategory.assignAll(selectedSubCategory.value!.products);
      print('🔄 Updated productsForSelectedSubCategory with ${productsForSelectedSubCategory.length} products from ${selectedSubCategory.value!.name}');
    } else {
      productsForSelectedSubCategory.clear();
      print('🔄 Cleared productsForSelectedSubCategory as no sub-category is selected.');
    }
  }
}
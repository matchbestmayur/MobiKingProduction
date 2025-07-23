import 'package:get/get.dart';
import '../data/product_model.dart';
import '../services/product_service.dart';

class ProductController extends GetxController {
  final ProductService _productService = ProductService();

  var allProducts = <ProductModel>[].obs;
  var isLoading = false.obs;
  var selectedProduct = Rxn<ProductModel>();
  var searchResults = <ProductModel>[].obs;

  // Pagination states
  var isFetchingMore = false.obs;
  var hasMoreProducts = true.obs;

  final int _productsPerPage = 9;
  int _currentPage = 1;

  // Date range filters
  final String _startDate = '2025-01-01';
  final String _endDate = '2025-12-31';

  @override
  void onInit() {
    super.onInit();
    fetchInitialProducts();

  }

  /// 🔰 Fetch first page of products
  Future<void> fetchInitialProducts() async {
    try {
      isLoading.value = true;
      _currentPage = 1;

      final products = await _productService.getAllProducts(
        page: _currentPage,
        limit: _productsPerPage,
      );

      allProducts.assignAll(products);
      hasMoreProducts.value = products.length == _productsPerPage;
    } catch (e) {
      Get.snackbar('Error fetching products', e.toString(), snackPosition: SnackPosition.BOTTOM);
      print('Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// ➕ Fetch next page of products
  Future<void> fetchMoreProducts() async {
    if (isFetchingMore.value || !hasMoreProducts.value) return;

    print("🚀 Loading more products...");

    try {
      isFetchingMore.value = true;
      _currentPage++;

      final newProducts = await _productService.getAllProducts(
        page: _currentPage,
        limit: _productsPerPage,
      );

      print("✅ Fetched ${newProducts.length} products");

      if (newProducts.isEmpty) {
        hasMoreProducts.value = false;
      } else {
        allProducts.addAll(newProducts);
        hasMoreProducts.value = newProducts.length == _productsPerPage;
      }
    } catch (e) {
      Get.snackbar('Error loading more products', e.toString(),
          snackPosition: SnackPosition.BOTTOM);
      print('❌ Error: $e');
    } finally {
      isFetchingMore.value = false;
      print("⬇ Done loading page $_currentPage");
    }
  }


  /// 🆕 Add new product
  Future<void> addProduct(ProductModel product) async {
    try {
      isLoading.value = true;
      final newProduct = await _productService.createProduct(product);
      allProducts.insert(0, newProduct);
      Get.snackbar('Success', 'Product added successfully!', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error adding product', e.toString(), snackPosition: SnackPosition.BOTTOM);
      print('Error adding product: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 🔍 Fetch a product by slug
  Future<void> fetchProductBySlug(String slug) async {
    try {
      isLoading.value = true;
      selectedProduct.value = null;

      final product = await _productService.fetchProductBySlug(slug);
      selectedProduct.value = product;
    } catch (e) {
      Get.snackbar('Error fetching product', e.toString(), snackPosition: SnackPosition.BOTTOM);
      print('Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 🔍 Search products by name using API
  Future<void> searchProducts(String query) async {
    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty || trimmedQuery.length < 2) {
      searchResults.clear();
      return;
    }

    try {
      isLoading.value = true;

      final results = await _productService.searchProducts(
        trimmedQuery.toString(),
      );

      searchResults.assignAll(results);
    } catch (e) {
      Get.snackbar('Error searching products', e.toString(), snackPosition: SnackPosition.BOTTOM);
      print('Search error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  List<ProductModel> getProductsInSameParentCategory(String currentProductId, String? parentCategory) {
    // If no parent category is provided or it's empty, there's nothing to filter by.
    if (parentCategory == null || parentCategory.isEmpty) {
      return [];
    }

    // Filter the 'allProducts' list
    return allProducts
        .where((product) =>
    product.id != currentProductId && // Exclude the current product by its ID
        product.categoryId.contains(parentCategory)) // Check if the product's categories list contains the specified parentCategory
        .toList(); // Convert the filtered iterable to a List
  }
}


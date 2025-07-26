import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../services/cart_service.dart';
import 'package:mobiking/app/controllers/connectivity_controller.dart';

class CartController extends GetxController {
  RxMap<String, dynamic> cartData = <String, dynamic>{}.obs;
  var isLoading = false.obs;
  final box = GetStorage();

  final ConnectivityController _connectivityController = Get.find<ConnectivityController>();

  // ✅ NEW: Observable map to store pre-calculated quantities
  // Key: "productId_variantName", Value: quantity
  RxMap<String, int> productVariantQuantities = <String, int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAndLoadCartData();

    ever(_connectivityController.isConnected, (bool isConnected) {
      if (isConnected) {
        _handleConnectionRestored();
      }
    });

    // ✅ NEW: React to changes in cartData to update pre-calculated quantities
    ever(cartData, (_) {
      _updateProductVariantQuantities();
    });
  }

  // ✅ NEW: Method to update the pre-calculated quantities map
  void _updateProductVariantQuantities() {
    print('🛒 CartController: Recalculating product variant quantities...');
    final Map<String, int> newQuantities = {};
    for (var item in cartItems) {
      final itemProductId = item['productId']?['_id'];
      final itemVariantName = item['variantName'];
      final int quantity = item['quantity'] as int? ?? 0;

      if (itemProductId != null && itemVariantName != null) {
        final key = '${itemProductId}_$itemVariantName';
        newQuantities[key] = quantity;
      }
    }
    productVariantQuantities.value = newQuantities; // Update the observable map
    print('🛒 CartController: Finished recalculating product variant quantities. Total unique variants: ${productVariantQuantities.length}');
  }


  // Centralized method to fetch from service/storage and update observable
  Future<void> fetchAndLoadCartData() async {
    print('🛒 CartController: Attempting to fetch and load cart data...');
    isLoading.value = true;

    try {
      final String? userId = box.read('user')?['_id'];
      if (userId == null) {
        print('🛒 CartController: User ID not found, cannot fetch cart from backend. Loading from local storage fallback.');
        _loadCartDataFromLocalStorage();
        return;
      }

      final apiResponse = await CartService().fetchCart(cartId: cartData.value['_id']);
      print('🛒 CartController: Fetched cart from backend: $apiResponse');

      if (apiResponse != null && apiResponse['success'] == true && apiResponse['data']?['cart'] is Map) {
        final Map<String, dynamic> fetchedCart = Map<String, dynamic>.from(apiResponse['data']['cart']);
        cartData.value = fetchedCart; // This will trigger _updateProductVariantQuantities via `ever`
        var userInStorage = box.read('user') as Map<String, dynamic>?;
        if (userInStorage != null) {
          userInStorage['cart'] = fetchedCart;
          await box.write('user', userInStorage);
        }
        print('🛒 CartController: Cart data updated from backend: ${cartData.value}');
      } else {
        print('🛒 CartController: Backend cart fetch failed or returned invalid data. Loading from local storage fallback.');
        _loadCartDataFromLocalStorage();
      }
    } catch (e) {
      print('🛒 CartController: Error fetching cart from backend: $e. Loading from local storage fallback.');
      _loadCartDataFromLocalStorage();
    } finally {
      isLoading.value = false;
      print('🛒 CartController: Current totalCartItemsCount after _fetchAndLoadCartData: ${totalCartItemsCount}');
    }
  }

  // Helper method to load cart data from GetStorage
  void _loadCartDataFromLocalStorage() {
    print('🛒 CartController: Loading cart data from local storage (fallback)...');
    try {
      final Map<String, dynamic>? user = box.read('user');

      if (user != null && user.containsKey('cart') && user['cart'] is Map) {
        cartData.value = Map<String, dynamic>.from(user['cart']); // This will trigger _updateProductVariantQuantities
        print('🛒 CartController: Cart data loaded from local storage: ${cartData.value}');
      } else {
        cartData.value = {
          'items': [],
          'totalCartValue': 0.0,
        }; // This will trigger _updateProductVariantQuantities
        print('🛒 CartController: No valid cart data found in stored user object locally, initializing to empty structure.');
      }
    } catch (e) {
      print('🛒 CartController: Error loading cart data from local storage: $e');
      cartData.value = {
        'items': [],
        'totalCartValue': 0.0,
      }; // This will trigger _updateProductVariantQuantities
    }
  }

  // Method to handle actions when internet connection is restored
  Future<void> _handleConnectionRestored() async {
    print('🛒 CartController: Internet connection restored. Re-fetching cart data...');
    await fetchAndLoadCartData();
  }


  // --- Getters for Cart Data ---
  List<Map<String, dynamic>> get cartItems {
    try {
      if (cartData.containsKey('items') && cartData['items'] is List) {
        return (cartData['items'] as List).map((item) => Map<String, dynamic>.from(item)).toList();
      }
      return [];
    } catch (e) {
      print('🛒 CartController: Error getting cartItems: $e');
      return [];
    }
  }

  // You can keep these if you need them for other purposes,
  // but for quantity display in ListView, the new method is better.
  Map<String, int> getCartItemsForProduct({required String productId}) {
    final Map<String, int> productVariantsInCart = {};
    for (var item in cartItems) {
      final itemProductId = item['productId']?['_id'];
      if (itemProductId == productId) {
        final itemVariantName = item['variantName'] as String? ?? 'Default';
        final int quantity = item['quantity'] as int? ?? 0;
        if (quantity > 0) {
          productVariantsInCart[itemVariantName] = quantity;
        }
      }
    }
    print('🛒 CartController: Variants in cart for product $productId: $productVariantsInCart');
    return productVariantsInCart;
  }

  // ✅ MODIFIED: Now reads from the pre-calculated map
  int getVariantQuantity({required String productId, required String variantName}) {
    final key = '${productId}_$variantName';
    final quantity = productVariantQuantities[key] ?? 0;
    // print('🛒 CartController: Getting quantity from pre-calculated map for $key -> $quantity'); // Disable for less spam
    return quantity;
  }

  int getTotalQuantityForProduct({required String productId}) {
    int totalQuantity = 0;
    for (var item in cartItems) {
      final itemProductId = item['productId']?['_id'];
      if (itemProductId == productId) {
        totalQuantity += item['quantity'] as int? ?? 0;
      }
    }
    print('🛒 CartController: Calculated total quantity for product $productId -> $totalQuantity');
    return totalQuantity;
  }

  int get totalCartItemsCount {
    int totalCount = 0;
    for (var item in cartItems) {
      totalCount += item['quantity'] as int? ?? 0;
    }
    print('🛒 CartController: Calculating totalCartItemsCount: $totalCount');
    return totalCount;
  }

  double get totalCartValue {
    double total = 0.0;
    for (var item in cartItems) {
      final itemPrice = (item['price'] as num?)?.toDouble() ?? 0.0;
      final int itemQuantity = item['quantity'] as int? ?? 0;
      total += itemPrice * itemQuantity;
    }
    print('🛒 CartController: Calculating totalCartValue: $total');
    return total;
  }

  // --- Cart Operations ---
  Future<bool> addToCart({
    required String productId,
    required String variantName,
  }) async {
    final cartId = box.read('cartId');
    if (cartId == null) {
      return false;
    }
    print('🛒 CartController: Adding to cart: productId=$productId, variantName=$variantName, cartId=$cartId');

    isLoading.value = true;
    try {
      final response = await CartService().addToCart(
        productId: productId,
        cartId: cartId,
        variantName: variantName,
      );

      if (response['success'] == true) {
        await _updateStorageAndCartData(response); // This will trigger cartData update, then quantity recalculation
        _showSnackbar('Added to Cart', 'Product quantity increased successfully!', Colors.green, Icons.add_shopping_cart_outlined);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("🛒 CartController: Add to cart error: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> removeFromCart({
    required String productId,
    required String variantName,
  }) async {
    final cartId = box.read('cartId');
    if (cartId == null) {
      return;
    }
    print('🛒 CartController: Removing from cart: productId=$productId, variantName=$variantName, cartId=$cartId');

    isLoading.value = true;
    try {
      final response = await CartService().removeFromCart(
        productId: productId,
        cartId: cartId,
        variantName: variantName,
      );

      if (response['success'] == true) {
        await _updateStorageAndCartData(response); // This will trigger cartData update, then quantity recalculation
        _showSnackbar('Removed from Cart', 'Product quantity decreased successfully!', Colors.blueGrey, Icons.remove_shopping_cart_outlined);
      }
    } catch (e) {
      print("🛒 CartController: Remove from cart error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _updateStorageAndCartData(Map<String, dynamic> apiResponse) async {
    print('🛒 CartController: Starting _updateStorageAndCartData...');
    print('🛒 CartController: Full API Response for cart update: $apiResponse');

    final updatedUser = apiResponse['data']?['user'];
    print('🛒 CartController: Extracted updatedUser from response: $updatedUser');

    if (updatedUser != null && updatedUser is Map) {
      await box.write('user', updatedUser);
      print('🛒 CartController: Stored updated user object directly to "user" key in GetStorage.');

      final updatedCart = updatedUser['cart'];
      if (updatedCart != null && updatedCart is Map) {
        cartData.value = Map<String, dynamic>.from(updatedCart); // This line is crucial for reactivity
        print('🛒 CartController: Updated cartData.value observable with latest cart: ${cartData.value}');
      } else {
        _resetLocalCartData();
        print('🛒 CartController: Warning: Updated user object from API did not contain a valid "cart". Local cartData reset.');
      }
    } else {
      _resetLocalCartData();
      print('🛒 CartController: Warning: No updated user data (apiResponse[\'data\'][\'user\']) in cart response. Local cartData reset.');
    }
  }

  void _resetLocalCartData() {
    cartData.value = {
      'items': [],
      'totalCartValue': 0.0,
    };
  }

  void clearCartData() async {
    print('🛒 CartController: Clearing cart data...');

    var userInStorage = box.read('user');
    if (userInStorage != null && userInStorage is Map) {
      userInStorage['cart'] = {'items': [], 'totalCartValue': 0.0};
      await box.write('user', userInStorage);
      print('🛒 CartController: Stored user object in GetStorage updated with cleared cart.');
    } else {
      await box.write('user', {'cart': {'items': [], 'totalCartValue': 0.0}});
      print('🛒 CartController: No existing user/cart in storage, set to empty cart in storage.');
    }

    _resetLocalCartData();
    print('🛒 CartController: Local cartData observable cleared.');

    _showSnackbar('Cart Cleared', 'All items have been removed from your cart.', Colors.blue, Icons.delete_sweep_outlined);
  }

  // --- UI Feedback ---
  void _showSnackbar(String title, String message, Color color, IconData icon) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: color.withOpacity(0.8),
      colorText: Colors.white,
      icon: Icon(icon, color: Colors.white),
      margin: const EdgeInsets.all(10),
      borderRadius: 10,
      animationDuration: const Duration(milliseconds: 300),
      duration: const Duration(seconds: 2),
    );
  }
}

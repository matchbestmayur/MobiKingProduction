import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class CartService {
  final String baseUrl = 'https://mobiking-e-commerce-backend-prod.vercel.app/api/v1';
  final box = GetStorage();

  void _log(String message) {
    print('[CartService] $message');
  }

  // Helper to get common headers with error handling
  Map<String, String>? _getHeaders() {
    try {
      String? accessToken = box.read('accessToken');

      _log('Access Token Status: ${accessToken != null && accessToken.isNotEmpty ? "Present" : "Missing"}');

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (accessToken != null && accessToken.isNotEmpty) {
        // Basic token validation
        if (accessToken.trim().split('.').length == 3) {
          headers['Authorization'] = 'Bearer $accessToken';
        } else {
          _log('Warning: Invalid token format detected');
          return null;
        }
      } else {
        _log('Warning: No access token found');
        return null;
      }

      return headers;
    } catch (e) {
      _log('Error preparing headers: $e');
      return null;
    }
  }

  // Add to cart with comprehensive error handling
  Future<Map<String, dynamic>> addToCart({
    required String productId,
    required String cartId,
    required String variantName,
  }) async {
    // Input validation
    if (productId.trim().isEmpty) {
      _log('Error: Product ID is required');
      return {'success': false, 'message': 'Product ID is required.'};
    }

    if (cartId.trim().isEmpty) {
      _log('Error: Cart ID is missing or invalid');
      return {'success': false, 'message': 'Cart ID is missing or invalid.'};
    }

    if (variantName.trim().isEmpty) {
      _log('Error: Variant name is required');
      return {'success': false, 'message': 'Variant name is required.'};
    }

    try {
      final url = Uri.parse('$baseUrl/cart/add');
      _log('Adding to cart - Product: $productId, Cart: $cartId, Variant: $variantName');

      final headers = _getHeaders();
      if (headers == null) {
        _log('Failed to prepare headers for add to cart');
        return {
          'success': false,
          'message': 'Authentication required. Please log in again.',
        };
      }

      final body = jsonEncode({
        'productId': productId.trim(),
        'cartId': cartId.trim(),
        'variantName': variantName.trim(),
        'quantity': 1,
      });

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _log('Request timeout while adding to cart');
          return http.Response('Request timeout', 408);
        },
      );

      _log('Add to Cart Response Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = jsonDecode(response.body);
          _log('Successfully added to cart');

          // Show success message to user
          /*Get.snackbar('Success', 'Item added to cart successfully!',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green.shade600,
              colorText: Colors.white);*/

          return responseData;
        } catch (jsonError) {
          _log('JSON parsing error in addToCart: $jsonError');
          return {
            'success': false,
            'message': 'Invalid response format from server.',
          };
        }
      } else if (response.statusCode == 401) {
        _log('Authentication failed during add to cart');
        return {
          'success': false,
          'message': 'Authentication failed. Please log in again.',
        };
      } else if (response.statusCode == 404) {
        _log('Product or cart not found');
        return {
          'success': false,
          'message': 'Product or cart not found.',
        };
      } else if (response.statusCode == 400) {
        _log('Bad request during add to cart');
        String errorMessage = 'Invalid request. Please check your input.';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = errorBody['message'];
          }
        } catch (e) {
          _log('Failed to parse error response: $e');
        }
        return {
          'success': false,
          'message': errorMessage,
        };
      } else {
        _log('Add to cart failed with status: ${response.statusCode}');
        String errorMessage = 'Failed to add item to cart.';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = errorBody['message'];
          }
        } catch (e) {
          _log('Failed to parse error response: $e');
        }
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } catch (e) {
      _log('Exception in addToCart: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred while adding to cart.',
      };
    }
  }

  // Remove from cart with comprehensive error handling
  Future<Map<String, dynamic>> removeFromCart({
    required String productId,
    required String cartId,
    required String variantName,
  }) async {
    // Input validation
    if (productId.trim().isEmpty) {
      _log('Error: Product ID is required');
      return {'success': false, 'message': 'Product ID is required.'};
    }

    if (cartId.trim().isEmpty) {
      _log('Error: Cart ID is missing or invalid');
      return {'success': false, 'message': 'Cart ID is missing or invalid.'};
    }

    if (variantName.trim().isEmpty) {
      _log('Error: Variant name is required');
      return {'success': false, 'message': 'Variant name is required.'};
    }

    try {
      final url = Uri.parse('$baseUrl/cart/remove');
      _log('Removing from cart - Product: $productId, Cart: $cartId, Variant: $variantName');

      final headers = _getHeaders();
      if (headers == null) {
        _log('Failed to prepare headers for remove from cart');
        return {
          'success': false,
          'message': 'Authentication required. Please log in again.',
        };
      }

      final request = http.Request('DELETE', url);
      request.headers.addAll(headers);
      request.body = jsonEncode({
        'productId': productId.trim(),
        'cartId': cartId.trim(),
        'variantName': variantName.trim(),
      });

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _log('Request timeout while removing from cart');
          throw TimeoutException('Request timeout', const Duration(seconds: 30));
        },
      );

      final response = await http.Response.fromStream(streamedResponse);
      _log('Remove from Cart Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          _log('Successfully removed from cart');

          // Show success message to user
         /* Get.snackbar('Success', 'Item removed from cart successfully!',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green.shade600,
              colorText: Colors.white);
*/
          return responseData;
        } catch (jsonError) {
          _log('JSON parsing error in removeFromCart: $jsonError');
          return {
            'success': false,
            'message': 'Invalid response format from server.',
          };
        }
      } else if (response.statusCode == 401) {
        _log('Authentication failed during remove from cart');
        return {
          'success': false,
          'message': 'Authentication failed. Please log in again.',
        };
      } else if (response.statusCode == 404) {
        _log('Product or cart not found for removal');
        return {
          'success': false,
          'message': 'Product not found in cart.',
        };
      } else if (response.statusCode == 400) {
        _log('Bad request during remove from cart');
        String errorMessage = 'Invalid request. Please check your input.';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = errorBody['message'];
          }
        } catch (e) {
          _log('Failed to parse error response: $e');
        }
        return {
          'success': false,
          'message': errorMessage,
        };
      } else {
        _log('Remove from cart failed with status: ${response.statusCode}');
        String errorMessage = 'Failed to remove item from cart.';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = errorBody['message'];
          }
        } catch (e) {
          _log('Failed to parse error response: $e');
        }
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } catch (e) {
      _log('Exception in removeFromCart: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred while removing from cart.',
      };
    }
  }

  // Fetch cart with comprehensive error handling
  Future<Map<String, dynamic>> fetchCart({required String cartId}) async {
    // Input validation
    if (cartId.trim().isEmpty) {
      _log('Error: Cart ID is missing for fetch');
      return {'success': false, 'message': 'Cart ID is missing for fetch.'};
    }

    try {
      final url = Uri.parse('$baseUrl/carts/${cartId.trim()}');
      _log('Fetching cart: $cartId');

      final headers = _getHeaders();
      if (headers == null) {
        _log('Failed to prepare headers for fetch cart');
        return {
          'success': false,
          'message': 'Authentication required. Please log in again.',
        };
      }

      final response = await http.get(
        url,
        headers: headers,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _log('Request timeout while fetching cart');
          return http.Response('Request timeout', 408);
        },
      );

      _log('Fetch Cart Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          _log('Successfully fetched cart');
          return responseData;
        } catch (jsonError) {
          _log('JSON parsing error in fetchCart: $jsonError');
          return {
            'success': false,
            'message': 'Invalid response format from server.',
          };
        }
      } else if (response.statusCode == 401) {
        _log('Authentication failed during fetch cart');
        return {
          'success': false,
          'message': 'Authentication failed. Please log in again.',
        };
      } else if (response.statusCode == 404) {
        _log('Cart not found');
        return {
          'success': false,
          'message': 'Cart not found.',
        };
      } else {
        _log('Fetch cart failed with status: ${response.statusCode}');
        String errorMessage = 'Failed to fetch cart.';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = errorBody['message'];
          }
        } catch (e) {
          _log('Failed to parse error response: $e');
        }
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } catch (e) {
      _log('Exception in fetchCart: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred during cart fetch.',
      };
    }
  }

  // Update cart item quantity
  Future<Map<String, dynamic>> updateCartItemQuantity({
    required String productId,
    required String cartId,
    required String variantName,
    required int quantity,
  }) async {
    // Input validation
    if (productId.trim().isEmpty) {
      _log('Error: Product ID is required');
      return {'success': false, 'message': 'Product ID is required.'};
    }

    if (cartId.trim().isEmpty) {
      _log('Error: Cart ID is missing or invalid');
      return {'success': false, 'message': 'Cart ID is missing or invalid.'};
    }

    if (variantName.trim().isEmpty) {
      _log('Error: Variant name is required');
      return {'success': false, 'message': 'Variant name is required.'};
    }

    if (quantity < 0) {
      _log('Error: Quantity cannot be negative');
      return {'success': false, 'message': 'Quantity cannot be negative.'};
    }

    try {
      final url = Uri.parse('$baseUrl/cart/update');
      _log('Updating cart quantity - Product: $productId, Cart: $cartId, Quantity: $quantity');

      final headers = _getHeaders();
      if (headers == null) {
        _log('Failed to prepare headers for update cart');
        return {
          'success': false,
          'message': 'Authentication required. Please log in again.',
        };
      }

      final body = jsonEncode({
        'productId': productId.trim(),
        'cartId': cartId.trim(),
        'variantName': variantName.trim(),
        'quantity': quantity,
      });

      final response = await http.put(
        url,
        headers: headers,
        body: body,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _log('Request timeout while updating cart');
          return http.Response('Request timeout', 408);
        },
      );

      _log('Update Cart Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          _log('Successfully updated cart quantity');
/*
          // Show success message to user
          Get.snackbar('Success', 'Cart updated successfully!',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green.shade600,
              colorText: Colors.white);*/

          return responseData;
        } catch (jsonError) {
          _log('JSON parsing error in updateCartItemQuantity: $jsonError');
          return {
            'success': false,
            'message': 'Invalid response format from server.',
          };
        }
      } else {
        _log('Update cart failed with status: ${response.statusCode}');
        String errorMessage = 'Failed to update cart item quantity.';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = errorBody['message'];
          }
        } catch (e) {
          _log('Failed to parse error response: $e');
        }
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } catch (e) {
      _log('Exception in updateCartItemQuantity: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred while updating cart.',
      };
    }
  }

  // Clear entire cart
  Future<Map<String, dynamic>> clearCart({required String cartId}) async {
    if (cartId.trim().isEmpty) {
      _log('Error: Cart ID is missing for clear');
      return {'success': false, 'message': 'Cart ID is missing for clear.'};
    }

    try {
      final url = Uri.parse('$baseUrl/cart/clear');
      _log('Clearing cart: $cartId');

      final headers = _getHeaders();
      if (headers == null) {
        _log('Failed to prepare headers for clear cart');
        return {
          'success': false,
          'message': 'Authentication required. Please log in again.',
        };
      }

      final response = await http.delete(
        url,
        headers: headers,
        body: jsonEncode({'cartId': cartId.trim()}),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _log('Request timeout while clearing cart');
          return http.Response('Request timeout', 408);
        },
      );

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          _log('Successfully cleared cart');

          // Show success message to user
          Get.snackbar('Success', 'Cart cleared successfully!',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green.shade600,
              colorText: Colors.white);

          return responseData;
        } catch (jsonError) {
          _log('JSON parsing error in clearCart: $jsonError');
          return {
            'success': false,
            'message': 'Invalid response format from server.',
          };
        }
      } else {
        _log('Clear cart failed with status: ${response.statusCode}');
        String errorMessage = 'Failed to clear cart.';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = errorBody['message'];
          }
        } catch (e) {
          _log('Failed to parse error response: $e');
        }
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } catch (e) {
      _log('Exception in clearCart: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred while clearing cart.',
      };
    }
  }

  // Health check method
  Future<bool> checkServiceHealth() async {
    try {
      _log('Performing health check...');

      // Try to fetch a cart with a test ID to check if service is responsive
      final headers = _getHeaders();
      if (headers == null) {
        _log('Cannot perform health check: No valid headers');
        return false;
      }

      final url = Uri.parse('$baseUrl/cart/health'); // Assuming health endpoint
      final response = await http.get(url, headers: headers).timeout(
        const Duration(seconds: 10),
        onTimeout: () => http.Response('Timeout', 408),
      );

      final isHealthy = response.statusCode == 200;
      _log('Service health check: ${isHealthy ? 'Healthy' : 'Unhealthy'} (Status: ${response.statusCode})');
      return isHealthy;
    } catch (e) {
      _log('Health check failed: $e');
      return false;
    }
  }

  // Get cart ID from storage
  String? getCartId() {
    try {
      return box.read('cartId');
    } catch (e) {
      _log('Error reading cart ID: $e');
      return null;
    }
  }

  // Store cart ID
  Future<bool> storeCartId(String cartId) async {
    try {
      await box.write('cartId', cartId);
      _log('Cart ID stored successfully');
      return true;
    } catch (e) {
      _log('Error storing cart ID: $e');
      return false;
    }
  }

  // Clear stored cart ID
  Future<bool> clearStoredCartId() async {
    try {
      await box.remove('cartId');
      _log('Cart ID cleared successfully');
      return true;
    } catch (e) {
      _log('Error clearing cart ID: $e');
      return false;
    }
  }
}

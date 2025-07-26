import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/foundation.dart'; // Required for kDebugMode

class WishlistService {
  static const String baseUrl =
      'https://mobiking-e-commerce-backend-prod.vercel.app/api/v1/users/wishlist';

  static const String userProfileUrl =
      'https://mobiking-e-commerce-backend-prod.vercel.app/api/v1/users/me';

  final GetStorage _box = GetStorage();

  GetStorage get box => _box;

  void _log(String message) {
    if (kDebugMode) {
      print('[WishlistService] $message');
    }
  }

  String _getAccessToken() {
    try {
      return _box.read('accessToken') ?? '';
    } catch (e) {
      _log('Error reading access token: $e');
      return '';
    }
  }

  Map<String, String> _getHeaders() {
    final token = _getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ✅ ENHANCED: Better error handling for local storage operations
  void _updateLocalWishlistData(List<dynamic> updatedWishlistData) {
    try {
      final Map<String, dynamic>? currentUserData = _box.read('user') as Map<String, dynamic>?;

      if (currentUserData != null) {
        final Map<String, dynamic> userToUpdate = Map.from(currentUserData);
        userToUpdate['wishlist'] = updatedWishlistData;
        _box.write('user', userToUpdate);
        _log('Local user data: wishlist field updated with ${updatedWishlistData.length} items.');
      } else {
        _log('Warning: No existing user data found to update wishlist locally.');
        // ✅ Create minimal user object with wishlist if none exists
        _box.write('user', {'wishlist': updatedWishlistData});
        _log('Created new user object with wishlist data.');
      }
    } catch (e) {
      _log('Error updating local wishlist data: $e');
      // ✅ Silent failure - don't throw, just log
    }
  }

  // ✅ ENHANCED: Better error handling and type safety
  Future<List<dynamic>> getLocalWishlistData() async {
    try {
      final dynamic userData = _box.read('user');

      if (userData == null) {
        _log('No user data found locally in GetStorage. Wishlist is empty.');
        return [];
      }

      if (userData is! Map<String, dynamic>) {
        _log('User data is not in expected format. Type: ${userData.runtimeType}');
        return [];
      }

      final Map<String, dynamic> userProfileData = userData;
      final dynamic wishlistField = userProfileData['wishlist'];

      if (wishlistField == null) {
        _log('No "wishlist" field found in local user data.');
        return [];
      }

      if (wishlistField is! List) {
        _log('Wishlist field is not a list. Type: ${wishlistField.runtimeType}');
        return [];
      }

      final List<dynamic> wishlistData = wishlistField;
      _log('Local wishlist data retrieved. Items: ${wishlistData.length}');
      return wishlistData;

    } catch (e) {
      _log('Error reading local wishlist data: $e');
      return [];
    }
  }

  // ✅ ENHANCED: Better error handling and network timeout
  Future<bool> addToWishlist(String productId) async {
    if (productId.isEmpty) {
      _log('Error: Product ID is empty. Cannot add to wishlist.');
      return false;
    }

    final token = _getAccessToken();
    if (token.isEmpty) {
      _log('Error: Access token not found. Cannot add to wishlist.');
      return false;
    }

    try {
      _log('Adding product $productId to wishlist...');

      final url = Uri.parse('$baseUrl/add');
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({'productId': productId}),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _log('Request timeout while adding to wishlist');
          return http.Response('Request timeout', 408);
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final data = jsonDecode(response.body);

          if (data == null || data['data'] == null) {
            _log('Warning: Empty or invalid response data structure');
            return true; // Still return true as the HTTP status was successful
          }

          final Map<String, dynamic>? updatedUserFromResponse =
          data['data']?['user'] as Map<String, dynamic>?;

          if (updatedUserFromResponse != null &&
              updatedUserFromResponse.containsKey('wishlist')) {
            final dynamic wishlistData = updatedUserFromResponse['wishlist'];

            if (wishlistData is List) {
              _updateLocalWishlistData(wishlistData);
              _log('Successfully added to wishlist & local wishlist updated.');
            } else {
              _log('Warning: Wishlist data is not a list in response');
            }
          } else {
            _log('Warning: Backend response did not contain updated user or wishlist.');
          }

          return true;
        } catch (jsonError) {
          _log('Error parsing response JSON: $jsonError');
          return true; // HTTP was successful, just parsing failed
        }
      } else {
        _log('Failed to add to wishlist. Status: ${response.statusCode}');
        if (response.body.isNotEmpty) {
          try {
            final errorData = jsonDecode(response.body);
            _log('Error details: ${errorData['message'] ?? errorData['error'] ?? 'Unknown error'}');
          } catch (e) {
            _log('Response body: ${response.body}');
          }
        }
        return false;
      }
    } catch (e) {
      _log('Exception adding to wishlist: $e');
      return false;
    }
  }

  // ✅ ENHANCED: Better error handling and network timeout
  Future<bool> removeFromWishlist(String productId) async {
    if (productId.isEmpty) {
      _log('Error: Product ID is empty. Cannot remove from wishlist.');
      return false;
    }

    final token = _getAccessToken();
    if (token.isEmpty) {
      _log('Error: Access token not found. Cannot remove from wishlist.');
      return false;
    }

    try {
      _log('Removing product $productId from wishlist...');

      final url = Uri.parse('$baseUrl/remove');
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({'productId': productId}),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _log('Request timeout while removing from wishlist');
          return http.Response('Request timeout', 408);
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final data = jsonDecode(response.body);

          if (data == null || data['data'] == null) {
            _log('Warning: Empty or invalid response data structure');
            return true; // Still return true as the HTTP status was successful
          }

          final Map<String, dynamic>? updatedUserFromResponse =
          data['data']?['user'] as Map<String, dynamic>?;

          if (updatedUserFromResponse != null &&
              updatedUserFromResponse.containsKey('wishlist')) {
            final dynamic wishlistData = updatedUserFromResponse['wishlist'];

            if (wishlistData is List) {
              _updateLocalWishlistData(wishlistData);
              _log('Successfully removed from wishlist & local wishlist updated.');
            } else {
              _log('Warning: Wishlist data is not a list in response');
            }
          } else {
            _log('Warning: Backend response did not contain updated user or wishlist.');
          }

          return true;
        } catch (jsonError) {
          _log('Error parsing response JSON: $jsonError');
          return true; // HTTP was successful, just parsing failed
        }
      } else {
        _log('Failed to remove from wishlist. Status: ${response.statusCode}');
        if (response.body.isNotEmpty) {
          try {
            final errorData = jsonDecode(response.body);
            _log('Error details: ${errorData['message'] ?? errorData['error'] ?? 'Unknown error'}');
          } catch (e) {
            _log('Response body: ${response.body}');
          }
        }
        return false;
      }
    } catch (e) {
      _log('Exception removing from wishlist: $e');
      return false;
    }
  }

  // ✅ NEW: Health check method
  Future<bool> checkServiceHealth() async {
    try {
      final token = _getAccessToken();
      if (token.isEmpty) {
        _log('Cannot perform health check: No access token');
        return false;
      }

      final url = Uri.parse(userProfileUrl);
      final response = await http.get(
        url,
        headers: _getHeaders(),
      ).timeout(
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

  // ✅ NEW: Clear local wishlist data
  Future<void> clearLocalWishlistData() async {
    try {
      final Map<String, dynamic>? currentUserData = _box.read('user') as Map<String, dynamic>?;

      if (currentUserData != null) {
        final Map<String, dynamic> userToUpdate = Map.from(currentUserData);
        userToUpdate['wishlist'] = <dynamic>[];
        _box.write('user', userToUpdate);
        _log('Local wishlist data cleared.');
      }
    } catch (e) {
      _log('Error clearing local wishlist data: $e');
    }
  }
}

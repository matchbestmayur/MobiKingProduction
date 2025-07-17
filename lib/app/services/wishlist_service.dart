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
    return _box.read('accessToken') ?? '';
  }

  Map<String, String> _getHeaders() {
    final token = _getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ✅ NEW METHOD: Updates ONLY the 'wishlist' field within the locally stored user data.
  // This method should be called when your backend's add/remove response gives you
  // the updated user object (from which you extract the wishlist).
  void _updateLocalWishlistData(List<dynamic> updatedWishlistData) {
    final Map<String, dynamic>? currentUserData = _box.read('user') as Map<String, dynamic>?;

    if (currentUserData != null) {
      final Map<String, dynamic> userToUpdate = Map.from(currentUserData);
      userToUpdate['wishlist'] = updatedWishlistData;
      _box.write('user', userToUpdate);
      _log('Local user data: wishlist field updated.');
    } else {
      _log('Warning: No existing user data found to update wishlist locally. This should ideally not happen if user is logged in.');
      // If no user data exists, consider if a full user profile fetch might be needed
      // upon app start or login to establish a base 'user' object in GetStorage.
    }
  }

  // ✅ MODIFIED: This method now reads the wishlist directly from the local 'user' object
  // in GetStorage, without making a network request.
  // It's meant to be called by the WishlistController's loadWishlistFromLocal().
  Future<List<dynamic>> getLocalWishlistData() async {
    final Map<String, dynamic>? userProfileData = _box.read('user') as Map<String, dynamic>?;

    if (userProfileData != null) {
      final List<dynamic>? wishlistData = userProfileData['wishlist'];
      if (wishlistData != null) {
        _log('Local wishlist data retrieved. Items: ${wishlistData.length}');
        return wishlistData;
      } else {
        _log('No "wishlist" field found in local user data.');
        return [];
      }
    } else {
      _log('No user data found locally in GetStorage. Wishlist is empty.');
      return [];
    }
  }

  Future<bool> addToWishlist(String productId) async {
    final url = Uri.parse('$baseUrl/add');
    final token = _getAccessToken();

    if (token.isEmpty) {
      _log('Error: Access token not found. Cannot add to wishlist.');
      return false;
    }

    try {
      _log('Adding product $productId to wishlist...');
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({'productId': productId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final Map<String, dynamic>? updatedUserFromResponse = data['data']?['user'] as Map<String, dynamic>?;

        if (updatedUserFromResponse != null && updatedUserFromResponse.containsKey('wishlist')) {
          // ✅ Use the new method to update only the wishlist part locally
          _updateLocalWishlistData(updatedUserFromResponse['wishlist'] as List<dynamic>);
          _log('Successfully added to wishlist & local wishlist updated.');
        } else {
          _log('Warning: Backend response for addToWishlist did not contain updated user or wishlist. Local state might be inconsistent.');
        }
        return true;
      } else {
        _log('Failed to add to wishlist. Status Code: ${response.statusCode}');
        _log('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      _log('Error adding to wishlist: $e');
      return false;
    }
  }

  Future<bool> removeFromWishlist(String productId) async {
    final url = Uri.parse('$baseUrl/remove');
    final token = _getAccessToken();

    if (token.isEmpty) {
      _log('Error: Access token not found. Cannot remove from wishlist.');
      return false;
    }

    try {
      _log('Removing product $productId from wishlist...');
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({'productId': productId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final Map<String, dynamic>? updatedUserFromResponse = data['data']?['user'] as Map<String, dynamic>?;

        if (updatedUserFromResponse != null && updatedUserFromResponse.containsKey('wishlist')) {
          // ✅ Use the new method to update only the wishlist part locally
          _updateLocalWishlistData(updatedUserFromResponse['wishlist'] as List<dynamic>);
          _log('Successfully removed from wishlist & local wishlist updated.');
        } else {
          _log('Warning: Backend response for removeFromWishlist did not contain updated user or wishlist. Local state might be inconsistent.');
        }
        return true;
      } else {
        _log('Failed to remove from wishlist. Status Code: ${response.statusCode}');
        _log('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      _log('Error removing from wishlist: $e');
      return false;
    }
  }
}
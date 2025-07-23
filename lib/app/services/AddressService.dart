import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart' as dio;
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';

import '../data/AddressModel.dart';

// Custom exception for AddressService errors, consistent with LoginServiceException
class AddressServiceException implements Exception {
  final String message;
  final int? statusCode;

  AddressServiceException(this.message, {this.statusCode});

  @override
  String toString() {
    if (statusCode != null) {
      return 'AddressServiceException: [Status $statusCode] $message';
    }
    return 'AddressServiceException: $message';
  }
}

class AddressService extends GetxService {
  final GetStorage _box;
  final dio.Dio _dio;

  AddressService(this._dio, this._box);
/*

  final String _addUrl = 'https://mobiking-e-commerce-backend.vercel.app/api/v1/users/address/add';
  final String _viewUrl = 'https://mobiking-e-commerce-backend.vercel.app/api/v1/users/address/view';
  final String _deleteBaseUrl = 'https://mobiking-e-commerce-backend.vercel.app/api/v1/users/address/';
  // New base URL for update operations (PUT request)
  final String _updateBaseUrl = 'https://mobiking-e-commerce-backend.vercel.app/api/v1/users/address/';
*/

  final String _addUrl = 'https://mobiking-e-commerce-backend-prod.vercel.app/api/v1/users/address/add';
  final String _viewUrl = 'https://mobiking-e-commerce-backend-prod.vercel.app/api/v1/users/address/view';
  final String _deleteBaseUrl = 'https://mobiking-e-commerce-backend-prod.vercel.app/api/v1/users/address/';
  final String _updateBaseUrl = 'https://mobiking-e-commerce-backend-prod.vercel.app/api/v1/users/address/';


  String? _getAccessToken() {
    final token = _box.read('accessToken');
    if (token == null) {
      print('AddressService: Authorization token not found in GetStorage.');
    }
    return token;
  }

  Future<List<AddressModel>> fetchUserAddresses() async {
    final token = _getAccessToken();
    if (token == null) {
      _showError('Authentication Error', 'Please log in to view addresses.');
      throw AddressServiceException('Authentication token missing.');
    }

    try {
      final response = await _dio.get(
        _viewUrl,
        options: dio.Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      print('AddressService: GET Status: ${response.statusCode}');
      final body = response.data;

      print('AddressService: FETCH ADDRESSES RESPONSE BODY: $body');

      if (response.statusCode == 200 && body['success'] == true) {
        if (body['data'] is List) {
          final List dataList = body['data'];
          print('AddressService: Fetched ${dataList.length} addresses.');
          return dataList.map((e) => AddressModel.fromJson(e)).toList();
        } else {
          print('AddressService: "data" field is not a List as expected: $body');
          _showError('Error', 'Failed to parse address data: unexpected format.');
          throw AddressServiceException('Unexpected data format for addresses.');
        }
      } else {
        final errorMsg = body['message'] ?? 'Failed to fetch addresses.';
        _showError('Error', errorMsg);
        throw AddressServiceException(errorMsg, statusCode: response.statusCode);
      }
    } on dio.DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data?['message'] ?? 'Server error during address fetch.';
        print('AddressService: DioError during fetch: ${e.response?.statusCode} - $errorMessage');
        _showError('Server Error', errorMessage);
        throw AddressServiceException(errorMessage, statusCode: e.response?.statusCode);
      } else {
        print('AddressService: Network error during fetch: ${e.message}');
        _showError('Network Error', 'Unable to connect to server. Please check your internet connection.');
        throw AddressServiceException('Network error: ${e.message}');
      }
    } catch (e) {
      print('AddressService: Unexpected exception during fetch: $e');
      _showError('Error', 'An unexpected error occurred while fetching addresses.');
      throw AddressServiceException('An unexpected error occurred: $e');
    }
  }

  void _showError(String title, String message) {
    // Get.snackbar(
    //   title,
    //   message,
    //   snackPosition: SnackPosition.BOTTOM,
    //   backgroundColor: Colors.red.shade600,
    //   colorText: Colors.white,
    // );
  }

  Future<AddressModel?> addAddress(AddressModel address) async {
    final token = _getAccessToken();
    if (token == null) {
      Get.snackbar('Authentication Error', 'Please log in to add address.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade600,
          colorText: Colors.white);
      throw AddressServiceException('Authentication token missing.');
    }

    try {
      final response = await _dio.post(
        _addUrl,
        options: dio.Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: jsonEncode(address.toJson()),
      );

      print('AddressService: POST Status ${response.statusCode}');
      final body = response.data;

      print('AddressService: Raw response body on add: $body');

      if ((response.statusCode == 200 || response.statusCode == 201) && body['success'] == true) {
        final userData = body['data'] as Map<String, dynamic>?;

        if (userData != null && userData['address'] is List && userData['address'].isNotEmpty) {
          final List addressList = userData['address'];
          final newAddressJson = addressList.last as Map<String, dynamic>;
          Get.snackbar('Success', 'Address added successfully!',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green.shade600,
              colorText: Colors.white);
          print('AddressService: Address added successfully (parsed from list): ${newAddressJson['_id']}');
          return AddressModel.fromJson(newAddressJson);
        } else {
          print('AddressService: Add response data missing address list or empty: $body');
          _showError('Error', 'Address added but details not returned correctly.');
          throw AddressServiceException('Address added but response data format unexpected.');
        }
      } else {
        String errorMessage = 'Failed to add address';
        if (body != null && body['message'] != null) {
          errorMessage = body['message'];
        }
        print('AddressService: Failed to add address. Status ${response.statusCode}, Body: $body');
        _showError('Error', errorMessage);
        throw AddressServiceException(errorMessage, statusCode: response.statusCode);
      }
    } on dio.DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data?['message'] ?? 'Server error during address add.';
        print('AddressService: DioError during add: ${e.response?.statusCode} - $errorMessage');
        _showError('Server Error', errorMessage);
        throw AddressServiceException(errorMessage, statusCode: e.response?.statusCode);
      } else {
        print('AddressService: Network error during add: ${e.message}');
        _showError('Network Error', 'Failed to connect to server. Please check your internet connection.');
        throw AddressServiceException('Network error: ${e.message}');
      }
    } catch (e) {
      print('AddressService: Unexpected exception in POST (addAddress): $e');
      _showError('Error', 'An unexpected error occurred while adding address.');
      throw AddressServiceException('An unexpected error occurred: $e');
    }
  }

  /// Updates an existing user address by its ID.
  /// Returns the updated `AddressModel` if successful, or `null` if the update fails.
  Future<AddressModel?> updateAddress(String addressId, AddressModel updatedAddress) async {
    final token = _getAccessToken();
    if (token == null) {
      Get.snackbar('Authentication Error', 'Please log in to update address.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade600,
          colorText: Colors.white);
      throw AddressServiceException('Authentication token missing.');
    }

    try {
      final String updateUrl = '$_updateBaseUrl$addressId';
      print('AddressService: Updating address at $updateUrl with data: ${updatedAddress.toJson()}');

      final response = await _dio.put( // Use PUT for updating
        updateUrl,
        options: dio.Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: jsonEncode(updatedAddress.toJson()), // Send the full updated address object
      );

      print('AddressService: PUT Status: ${response.statusCode}');
      final body = response.data;

      print('AddressService: UPDATE ADDRESS RESPONSE BODY: $body');

      if (response.statusCode == 200 && body['success'] == true) {
        // --- MODIFIED LOGIC HERE ---
        // The 'data' field directly contains the updated address object, not a list.
        final Map<String, dynamic>? updatedAddressJson = body['data'] as Map<String, dynamic>?;

        if (updatedAddressJson != null) {
          Get.snackbar('Success', body['message'] ?? 'Address updated successfully!',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green.shade600,
              colorText: Colors.white);
          return AddressModel.fromJson(updatedAddressJson);
        } else {
          print('AddressService: Updated address data is null or not a Map: $body');
          _showError('Error', 'Address updated but details not returned correctly.');
          throw AddressServiceException('Updated address data missing or incorrect format from response.');
        }
      } else {
        String errorMessage = 'Failed to update address.';
        if (body != null && body['message'] != null) {
          errorMessage = body['message'];
        }
        print('AddressService: Failed to update address. Status ${response.statusCode}, Body: $body');
        _showError('Error', errorMessage);
        throw AddressServiceException(errorMessage, statusCode: response.statusCode);
      }
    } on dio.DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data?['message'] ?? 'Server error during address update.';
        print('AddressService: DioError during update: ${e.response?.statusCode} - $errorMessage');
        _showError('Server Error', errorMessage);
        throw AddressServiceException(errorMessage, statusCode: e.response?.statusCode);
      } else {
        print('AddressService: Network error during update: ${e.message}');
        _showError('Network Error', 'Unable to connect to server. Please check your internet connection.');
        throw AddressServiceException('Network error: ${e.message}');
      }
    } catch (e) {
      print('AddressService: Unexpected exception during update: $e');
      _showError('Error', 'An unexpected error occurred while updating address.');
      throw AddressServiceException('An unexpected error occurred: $e');
    }
  }

  /// Deletes a user address by its ID.
  /// Returns `true` if the address was successfully deleted, `false` otherwise.
  Future<bool> deleteAddress(String addressId) async {
    final token = _getAccessToken();
    if (token == null) {
      _showError('Authentication Error', 'Please log in to delete address.');
      throw AddressServiceException('Authentication token missing.');
    }

    try {
      final String deleteUrl = '$_deleteBaseUrl$addressId';
      print('AddressService: Deleting address at $deleteUrl');

      final response = await _dio.delete(
        deleteUrl,
        options: dio.Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      print('AddressService: DELETE Status: ${response.statusCode}');
      final body = response.data; // Dio decodes JSON automatically

      print('AddressService: DELETE ADDRESS RESPONSE BODY: $body');

      if (response.statusCode == 200 && body['success'] == true) {
        Get.snackbar('Success', body['message'] ?? 'Address deleted successfully!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade600,
            colorText: Colors.white);
        return true;
      } else {
        String errorMessage = 'Failed to delete address.';
        if (body != null && body['message'] != null) {
          errorMessage = body['message'];
        }
        print('AddressService: Failed to delete address. Status ${response.statusCode}, Body: $body');
        _showError('Error', errorMessage);
        throw AddressServiceException(errorMessage, statusCode: response.statusCode);
      }
    } on dio.DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data?['message'] ?? 'Server error during address deletion.';
        print('AddressService: DioError during delete: ${e.response?.statusCode} - $errorMessage');
        _showError('Server Error', errorMessage);
        throw AddressServiceException(errorMessage, statusCode: e.response?.statusCode);
      } else {
        print('AddressService: Network error during delete: ${e.message}');
        _showError('Network Error', 'Unable to connect to server. Please check your internet connection.');
        throw AddressServiceException('Network error: ${e.message}');
      }
    } catch (e) {
      print('AddressService: Unexpected exception during delete: $e');
      _showError('Error', 'An unexpected error occurred while deleting address.');
      throw AddressServiceException('An unexpected error occurred: $e');
    }
  }
}
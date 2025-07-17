import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/AddressModel.dart';
import '../services/AddressService.dart';
import 'package:collection/collection.dart'; // For firstWhereOrNull

class AddressController extends GetxController {
  final AddressService _addressService = Get.find<AddressService>();

  final RxList<AddressModel> addresses = <AddressModel>[].obs;
  final Rx<AddressModel?> selectedAddress = Rx<AddressModel?>(null);

  // Form State management
  final RxBool _isAddingAddress = false.obs; // True when form is open for ADD
  final RxBool _isEditing = false.obs; // True when form is open for EDIT
  final Rx<AddressModel?> _addressBeingEdited = Rx<AddressModel?>(null); // Holds the address being edited

  // Combined form visibility state
  bool get isFormOpen => _isAddingAddress.value || _isEditing.value;
  // Expose specific states for UI decisions if needed
  bool get isAddingMode => _isAddingAddress.value;
  bool get isEditingMode => _isEditing.value;

  final RxBool isLoading = false.obs;
  final RxString addressErrorMessage = ''.obs;

  final TextEditingController streetController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController pinCodeController = TextEditingController();
  final TextEditingController customLabelController = TextEditingController();

  final RxString selectedLabel = 'Home'.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAddresses();
  }

  @override
  void onClose() {
    streetController.dispose();
    cityController.dispose();
    stateController.dispose();
    pinCodeController.dispose();
    customLabelController.dispose();
    // Removed _refreshTokenTimer?.cancel(); as it's not present in this controller anymore
    super.onClose();
  }

  void selectAddress(AddressModel address) {
    selectedAddress.value = address;
  }

  Future<void> fetchAddresses() async {
    isLoading.value = true;
    addressErrorMessage.value = '';
    try {
      final fetchedList = await _addressService.fetchUserAddresses();
      addresses.assignAll(fetchedList);
      if (addresses.isNotEmpty) {
        // If no address is selected or the previously selected address was deleted
        if (selectedAddress.value == null || !addresses.contains(selectedAddress.value)) {
          selectedAddress.value = addresses.first;
        }
      } else {
        selectedAddress.value = null; // No addresses, so clear selection
      }
    } on AddressServiceException catch (e) {
      print('AddressController: Error fetching addresses: $e');
      addressErrorMessage.value = e.message;
      _showSnackbar(
        'Fetch Failed',
        e.message,
        Colors.red,
        Icons.cloud_off_outlined,
      );
    } catch (e) {
      print('AddressController: Unexpected error fetching addresses: $e');
      addressErrorMessage.value = 'An unexpected error occurred while fetching addresses.';
      _showSnackbar(
        'Error',
        'An unexpected error occurred while fetching addresses.',
        Colors.red,
        Icons.cloud_off_outlined,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // New method to initiate editing an address
  void startEditingAddress(AddressModel address) {
    _isEditing.value = true;
    _isAddingAddress.value = false; // Ensure adding mode is off
    _addressBeingEdited.value = address;

    // Populate form fields with existing address data
    streetController.text = address.street;
    cityController.text = address.city;
    stateController.text = address.state;
    pinCodeController.text = address.pinCode;

    // Set selectedLabel based on address label
    if (['Home', 'Work'].contains(address.label)) {
      selectedLabel.value = address.label;
      customLabelController.clear(); // Clear custom label if standard
    } else {
      selectedLabel.value = 'Other';
      customLabelController.text = address.label; // Populate custom label
    }
  }

  // Method to handle saving (both add and update)
  Future<bool> saveAddress() async {
    isLoading.value = true;
    addressErrorMessage.value = '';
    try {
      String finalLabel = selectedLabel.value;
      if (selectedLabel.value == 'Other') {
        finalLabel = customLabelController.text.trim();
      }

      // --- Validation Checks ---
      if (finalLabel.isEmpty) {
        _showSnackbar(
          'Input Required',
          'Please provide a label for the address (e.g., Home, Work, Other).',
          Colors.amber,
          Icons.label_important_outline,
        );
        isLoading.value = false;
        return false;
      }

      if (streetController.text.trim().isEmpty ||
          cityController.text.trim().isEmpty ||
          stateController.text.trim().isEmpty ||
          pinCodeController.text.trim().isEmpty) {
        _showSnackbar(
          'Input Required',
          'Please fill in all address fields (Street, City, State, Pincode).',
          Colors.amber,
          Icons.edit_road_outlined,
        );
        isLoading.value = false;
        return false;
      }

      final AddressModel addressToSave = AddressModel(
        id: _addressBeingEdited.value?.id, // Include ID if editing
        label: finalLabel,
        street: streetController.text.trim(),
        city: cityController.text.trim(),
        state: stateController.text.trim(),
        pinCode: pinCodeController.text.trim(),
      );

      AddressModel? resultAddress;
      if (_isEditing.value) {
        // Perform update
        if (addressToSave.id == null) {
          throw AddressServiceException('Address ID is missing for update operation.');
        }
        resultAddress = await _addressService.updateAddress(addressToSave.id!, addressToSave);
      } else {
        // Perform add
        resultAddress = await _addressService.addAddress(addressToSave);
      }

      if (resultAddress != null) {
        // Update the observable list. For update, replace; for add, add.
        if (_isEditing.value) {
          final int index = addresses.indexWhere((addr) => addr.id == resultAddress!.id);
          if (index != -1) {
            addresses[index] = resultAddress;
          }
          // If the updated address was selected, ensure selectedAddress points to the new object
          if (selectedAddress.value?.id == resultAddress.id) {
            selectedAddress.value = resultAddress;
          }
          _showSnackbar(
            'Success!',
            'Address "${resultAddress.label}" updated successfully.',
            Colors.green,
            Icons.check_circle_outline,
          );
        } else {
          addresses.add(resultAddress);
          _showSnackbar(
            'Success!',
            'Your new address "${resultAddress.label}" has been added.',
            Colors.green,
            Icons.location_on_outlined,
          );
          // Select newly added address if it's the first or user preference
          if (addresses.length == 1 && selectedAddress.value == null) {
            selectedAddress.value = resultAddress;
          }
        }
        cancelEditing(); // Reset form state
        return true;
      } else {
        addressErrorMessage.value = 'Operation failed due to unexpected response.';
        return false;
      }
    } on AddressServiceException catch (e) {
      print('AddressController: Error saving address: $e');
      addressErrorMessage.value = e.message;
      _showSnackbar(
        _isEditing.value ? 'Update Failed' : 'Add Failed',
        e.message,
        Colors.red,
        Icons.error_outline,
      );
      return false;
    } catch (e) {
      print('AddressController: Unexpected error saving address: $e');
      addressErrorMessage.value = 'An unexpected error occurred. Please try again later.';
      _showSnackbar(
        'Error',
        'An unexpected error occurred. Please try again later.',
        Colors.red,
        Icons.cloud_off_outlined,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Deletes an address from the user's list and the backend.
  /// Returns `true` if deletion was successful, `false` otherwise.
  Future<bool> deleteAddress(String addressId) async {
    isLoading.value = true;
    addressErrorMessage.value = ''; // Clear previous errors
    try {
      final bool success = await _addressService.deleteAddress(addressId);

      if (success) {
        // Remove the address from the local RxList
        addresses.removeWhere((address) => address.id == addressId);

        // If the deleted address was the currently selected one,
        // clear the selection or select another address.
        if (selectedAddress.value?.id == addressId) {
          selectedAddress.value = addresses.isNotEmpty ? addresses.first : null;
        }

        _showSnackbar(
          'Deleted!',
          'Address removed successfully.',
          Colors.green,
          Icons.delete_forever_outlined,
        );
        return true;
      }
      return false; // Should not be reached if success is true, but good practice
    } on AddressServiceException catch (e) { // Catch specific service exceptions first
      print('AddressController: Error deleting address: $e');
      addressErrorMessage.value = e.message;
      _showSnackbar(
        'Deletion Failed',
        e.message,
        Colors.red,
        Icons.error_outline,
      );
      return false;
    } catch (e) { // Catch any other unexpected exceptions
      print('AddressController: Unexpected error deleting address: $e');
      addressErrorMessage.value = 'An unexpected error occurred while deleting address.';
      _showSnackbar(
        'Error',
        'An unexpected error occurred while deleting address.',
        Colors.red,
        Icons.cloud_off_outlined,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Method to open the add form (sets _isAddingAddress to true)
  void startAddingAddress() {
    clearForm(); // Clear form for new entry
    _isAddingAddress.value = true;
    _isEditing.value = false;
    _addressBeingEdited.value = null;
  }

  // Method to cancel editing/adding and go back to list view
  void cancelEditing() {
    _isAddingAddress.value = false;
    _isEditing.value = false;
    _addressBeingEdited.value = null;
    clearForm();
  }

  void clearForm() {
    streetController.clear();
    cityController.clear();
    stateController.clear();
    pinCodeController.clear();
    customLabelController.clear();
    selectedLabel.value = 'Home';
  }

  // Helper method for consistency
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
      duration: const Duration(seconds: 3),
    );
  }
}
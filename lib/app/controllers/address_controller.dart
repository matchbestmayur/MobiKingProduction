import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

import '../data/AddressModel.dart';
import '../services/AddressService.dart';

import 'package:collection/collection.dart';
import 'package:mobiking/app/controllers/connectivity_controller.dart';

import '../services/PincodeService.dart';

class AddressController extends GetxController {
  final AddressService _addressService = Get.find<AddressService>();
  final ConnectivityController _connectivityController = Get.find<ConnectivityController>();

  final RxList<AddressModel> addresses = <AddressModel>[].obs;
  final Rx<AddressModel?> selectedAddress = Rx<AddressModel?>(null);

  final RxBool _isAddingAddress = false.obs;
  final RxBool _isEditing = false.obs;
  final Rx<AddressModel?> _addressBeingEdited = Rx<AddressModel?>(null);

  bool get isFormOpen => _isAddingAddress.value || _isEditing.value;
  bool get isAddingMode => _isAddingAddress.value;
  bool get isEditingMode => _isEditing.value;

  final RxBool isLoading = false.obs;
  final RxString addressErrorMessage = ''.obs;

  // ✅ Add new reactive variables for PIN code detection
  final RxBool isDetectingLocation = false.obs;
  final RxString detectionError = ''.obs;

  final TextEditingController streetController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController pinCodeController = TextEditingController();
  final TextEditingController customLabelController = TextEditingController();

  final RxString selectedLabel = 'Home'.obs;

  // ✅ Add timer for debouncing PIN code input
  Timer? _pinCodeDebounceTimer;

  @override
  void onInit() {
    super.onInit();
    fetchAddresses();

    // ✅ Add listener to PIN code controller for auto-detection
    pinCodeController.addListener(_onPinCodeChanged);

    ever(_connectivityController.isConnected, (bool isConnected) {
      if (isConnected) {
        _handleConnectionRestored();
      }
    });
  }

  // ✅ Handle PIN code changes with debouncing
  void _onPinCodeChanged() {
    final pincode = pinCodeController.text.trim();

    // Cancel previous timer
    _pinCodeDebounceTimer?.cancel();

    // Clear previous detection error
    detectionError.value = '';

    // Only proceed if we have a 6-digit PIN code
    if (pincode.length == 6 && RegExp(r'^\d{6}$').hasMatch(pincode)) {
      // Debounce the API call by 500ms
      _pinCodeDebounceTimer = Timer(const Duration(milliseconds: 500), () {
        // Double-check the PIN code hasn't changed during the delay
        if (pinCodeController.text.trim() == pincode) {
          detectLocationFromPincode(pincode);
        }
      });
    }
  }

  // ✅ Detect location from PIN code
  Future<void> detectLocationFromPincode(String pincode) async {
    print('AddressController: Detecting location for PIN code: $pincode');

    isDetectingLocation.value = true;
    detectionError.value = '';

    try {
      final locationData = await PincodeService.getLocationByPincode(pincode);

      if (locationData != null && locationData['city']!.isNotEmpty && locationData['state']!.isNotEmpty) {
        // Auto-fill city and state
        cityController.text = locationData['city']!;
        stateController.text = locationData['state']!;

        print('AddressController: Location detected - City: ${locationData['city']}, State: ${locationData['state']}');

        // Show success message
        _showSnackbar(
          'Location Detected',
          'City and state auto-filled based on PIN code',
          Colors.green,
          Icons.location_on,
        );
      } else {
        detectionError.value = 'Could not detect location for this PIN code';
        print('AddressController: Could not detect location for PIN code: $pincode');

        _showSnackbar(
          'Detection Failed',
          'Could not auto-detect city and state. Please enter manually.',
          Colors.orange,
          Icons.location_off,
        );
      }
    } catch (e) {
      detectionError.value = 'Network error while detecting location';
      print('AddressController: Error detecting location for PIN code $pincode: $e');

      _showSnackbar(
        'Network Error',
        'Please check your internet connection and try again',
        Colors.red,
        Icons.signal_wifi_off,
      );
    } finally {
      isDetectingLocation.value = false;
    }
  }

  Future<void> _handleConnectionRestored() async {
    print('AddressController: Internet connection restored. Re-fetching addresses...');
    await fetchAddresses();
  }

  @override
  void onClose() {
    streetController.dispose();
    cityController.dispose();
    stateController.dispose();
    pinCodeController.dispose();
    customLabelController.dispose();
    _pinCodeDebounceTimer?.cancel(); // ✅ Clean up timer
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
        if (selectedAddress.value == null || !addresses.contains(selectedAddress.value)) {
          selectedAddress.value = addresses.first;
        }
      } else {
        selectedAddress.value = null;
      }
    } on AddressServiceException catch (e) {
      print('AddressController: Error fetching addresses: $e');
      addressErrorMessage.value = e.message;
     /* _showSnackbar('Fetch Failed', e.message, Colors.red, Icons.cloud_off_outlined);*/
    } catch (e) {
      print('AddressController: Unexpected error fetching addresses: $e');
      addressErrorMessage.value = 'An unexpected error occurred while fetching addresses.';
     /* _showSnackbar('Error', 'An unexpected error occurred while fetching addresses.', Colors.red, Icons.cloud_off_outlined);*/
    } finally {
      isLoading.value = false;
    }
  }

  void startEditingAddress(AddressModel address) {
    _isEditing.value = true;
    _isAddingAddress.value = false;
    _addressBeingEdited.value = address;

    streetController.text = address.street;
    cityController.text = address.city;
    stateController.text = address.state;
    pinCodeController.text = address.pinCode;

    if (['Home', 'Work'].contains(address.label)) {
      selectedLabel.value = address.label;
      customLabelController.clear();
    } else {
      selectedLabel.value = 'Other';
      customLabelController.text = address.label;
    }
  }

  Future<bool> saveAddress() async {
    isLoading.value = true;
    addressErrorMessage.value = '';
    try {
      String finalLabel = selectedLabel.value;
      if (selectedLabel.value == 'Other') {
        finalLabel = customLabelController.text.trim();
      }

      if (finalLabel.isEmpty) {
        _showSnackbar('Input Required', 'Please provide a label for the address.', Colors.amber, Icons.label_important_outline);
        isLoading.value = false;
        return false;
      }

      if (streetController.text.trim().isEmpty ||
          cityController.text.trim().isEmpty ||
          stateController.text.trim().isEmpty ||
          pinCodeController.text.trim().isEmpty) {
        _showSnackbar('Input Required', 'Please fill in all address fields.', Colors.amber, Icons.edit_road_outlined);
        isLoading.value = false;
        return false;
      }

      // ✅ Enhanced PIN code validation
      final pinCode = pinCodeController.text.trim();
      if (!RegExp(r'^\d{6}$').hasMatch(pinCode)) {
        _showSnackbar('Invalid PIN Code', 'Please enter a valid 6-digit PIN code.', Colors.amber, Icons.pin_drop);
        isLoading.value = false;
        return false;
      }

      final AddressModel addressToSave = AddressModel(
        id: _addressBeingEdited.value?.id,
        label: finalLabel,
        street: streetController.text.trim(),
        city: cityController.text.trim(),
        state: stateController.text.trim(),
        pinCode: pinCode,
      );

      AddressModel? resultAddress;
      if (_isEditing.value) {
        if (addressToSave.id == null) {
          throw AddressServiceException('Address ID is missing for update operation.');
        }
        resultAddress = await _addressService.updateAddress(addressToSave.id!, addressToSave);
      } else {
        resultAddress = await _addressService.addAddress(addressToSave);
      }

      if (resultAddress != null) {
        if (_isEditing.value) {
          final int index = addresses.indexWhere((addr) => addr.id == resultAddress!.id);
          if (index != -1) {
            addresses[index] = resultAddress;
          }
          if (selectedAddress.value?.id == resultAddress.id) {
            selectedAddress.value = resultAddress;
          }
          _showSnackbar('Success!', 'Address updated successfully.', Colors.green, Icons.check_circle_outline);
        } else {
          addresses.add(resultAddress);
          _showSnackbar('Success!', 'Your new address has been added.', Colors.green, Icons.location_on_outlined);
          if (addresses.length == 1 && selectedAddress.value == null) {
            selectedAddress.value = resultAddress;
          }
        }
        cancelEditing();
        return true;
      } else {
        addressErrorMessage.value = 'Operation failed due to unexpected response.';
        return false;
      }
    } on AddressServiceException catch (e) {
      print('AddressController: Error saving address: $e');
      addressErrorMessage.value = e.message;
     /* _showSnackbar(_isEditing.value ? 'Update Failed' : 'Add Failed', e.message, Colors.red, Icons.error_outline);*/
      return false;
    } catch (e) {
      print('AddressController: Unexpected error saving address: $e');
      addressErrorMessage.value = 'An unexpected error occurred. Please try again later.';
  /*    _showSnackbar('Error', 'An unexpected error occurred. Please try again later.', Colors.red, Icons.cloud_off_outlined);*/
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteAddress(String addressId) async {
    isLoading.value = true;
    addressErrorMessage.value = '';
    try {
      final bool success = await _addressService.deleteAddress(addressId);

      if (success) {
        addresses.removeWhere((address) => address.id == addressId);
        if (selectedAddress.value?.id == addressId) {
          selectedAddress.value = addresses.isNotEmpty ? addresses.first : null;
        }
        _showSnackbar('Deleted!', 'Address removed successfully.', Colors.green, Icons.delete_forever_outlined);
        return true;
      }
      return false;
    } on AddressServiceException catch (e) {
      print('AddressController: Error deleting address: $e');
      addressErrorMessage.value = e.message;
     /* _showSnackbar('Deletion Failed', e.message, Colors.red, Icons.error_outline);*/
      return false;
    } catch (e) {
      print('AddressController: Unexpected error deleting address: $e');
      addressErrorMessage.value = 'An unexpected error occurred while deleting address.';
     /* _showSnackbar('Error', 'An unexpected error occurred while deleting address.', Colors.red, Icons.cloud_off_outlined);*/
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void startAddingAddress() {
    clearForm();
    _isAddingAddress.value = true;
    _isEditing.value = false;
    _addressBeingEdited.value = null;

    // ✅ Clear detection states when starting new address
    isDetectingLocation.value = false;
    detectionError.value = '';
  }

  void cancelEditing() {
    _isAddingAddress.value = false;
    _isEditing.value = false;
    _addressBeingEdited.value = null;
    clearForm();

    // ✅ Clear detection states when canceling
    isDetectingLocation.value = false;
    detectionError.value = '';
    _pinCodeDebounceTimer?.cancel();
  }

  void clearForm() {
    streetController.clear();
    cityController.clear();
    stateController.clear();
    pinCodeController.clear();
    customLabelController.clear();
    selectedLabel.value = 'Home';
  }

  // ✅ Enhanced snackbar with better positioning and styling
  void _showSnackbar(String title, String message, Color color, IconData icon) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: color.withOpacity(0.9),
      colorText: Colors.white,
      icon: Icon(icon, color: Colors.white),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      animationDuration: const Duration(milliseconds: 300),
      duration: const Duration(seconds: 3),
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInBack,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobiking/app/themes/app_theme.dart';
import '../../controllers/address_controller.dart';
import '../../data/AddressModel.dart';
import 'address_card_painter.dart';

class AddressPage extends StatefulWidget {
  final Map<String, dynamic>? initialUser;

  AddressPage({Key? key, this.initialUser}) : super(key: key) {
    if (!Get.isRegistered<AddressController>()) {
      Get.put(AddressController());
    }
  }

  @override
  State<AddressPage> createState() => _AddressPageState();
}

class _AddressPageState extends State<AddressPage> {
  final AddressController controller = Get.find<AddressController>();
  final _formKey = GlobalKey<FormState>();
  final _userFormKey = GlobalKey<FormState>();
  final _storage = GetStorage();

  // ✅ User Info Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  // ✅ User Info Focus Nodes
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();

  // ✅ User Info State Management
  final RxBool _isUserLoading = false.obs;
  final RxBool _hasUserChanges = false.obs;
  final RxBool _showUserSection = true.obs;

  // ✅ Location State Management
  final RxBool _isLoadingLocation = false.obs;
  final RxBool _showLocationOptions = false.obs;

  @override
  void initState() {
    super.initState();
    _initializeUserControllers();
    _setupUserChangeListener();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  // ✅ Location Methods
  Future<bool> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Get.snackbar(
          'Permission Denied',
          'Location permission is required to fetch your current location',
          backgroundColor: AppColors.danger,
          colorText: AppColors.white,
          icon: Icon(Icons.location_off, color: AppColors.white),
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Get.dialog(
        AlertDialog(
          title: Text('Location Permission Required'),
          content: Text('Please enable location permission in settings to use this feature.'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Get.back();
                openAppSettings();
              },
              child: Text('Settings'),
            ),
          ],
        ),
      );
      return false;
    }

    return true;
  }

  Future<void> _getCurrentLocation() async {
    try {
      _isLoadingLocation.value = true;

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar(
          'Location Services Disabled',
          'Please enable location services and try again',
          backgroundColor: AppColors.danger,
          colorText: AppColors.white,
          icon: Icon(Icons.location_off, color: AppColors.white),
        );
        return;
      }

      // Check permissions
      if (!await _checkLocationPermission()) return;

      // Get current position with high accuracy
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      );

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;

        // Fill the form fields with the fetched location
        controller.streetController.text = _buildStreetAddress(place);
        controller.cityController.text = place.locality ?? place.subAdministrativeArea ?? '';
        controller.stateController.text = place.administrativeArea ?? '';
        controller.pinCodeController.text = place.postalCode ?? '';

        Get.snackbar(
          'Location Found',
          'Current location has been filled in the form. You can edit if needed.',
          backgroundColor: AppColors.success,
          colorText: AppColors.white,
          icon: Icon(Icons.location_on, color: AppColors.white),
          duration: Duration(seconds: 3),
        );

        _showLocationOptions.value = false;
      }
    }  catch (e) {
      Get.snackbar(
        'Location Error',
        'Failed to get current location: ${e.toString()}',
        backgroundColor: AppColors.danger,
        colorText: AppColors.white,
      );
    } finally {
      _isLoadingLocation.value = false;
    }
  }

  String _buildStreetAddress(Placemark place) {
    List<String> addressParts = [];

    if (place.subThoroughfare != null && place.subThoroughfare!.isNotEmpty) {
      addressParts.add(place.subThoroughfare!);
    }
    if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
      addressParts.add(place.thoroughfare!);
    }
    if (place.subLocality != null && place.subLocality!.isNotEmpty) {
      addressParts.add(place.subLocality!);
    }

    return addressParts.join(', ');
  }

  void _showLocationDialog() {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.location_on, color: AppColors.primaryGreen),
            SizedBox(width: 8),
            Text('Get Location'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Choose how you want to add your location:'),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.my_location, color: AppColors.primaryGreen),
              title: Text('Use Current Location'),
              subtitle: Text('Automatically fill address using GPS'),
              onTap: () {
                Get.back();
                _getCurrentLocation();
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.edit_location, color: AppColors.textMedium),
              title: Text('Enter Manually'),
              subtitle: Text('Type your address manually'),
              onTap: () {
                Get.back();
                // Focus on the first field
                FocusScope.of(context).requestFocus(
                  FocusNode()..requestFocus(),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // ✅ User Info Helper Methods
  String _safeStringExtract(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is List && value.isNotEmpty) {
      return value.first?.toString() ?? '';
    }
    return value.toString();
  }

  void _initializeUserControllers() {
    final userInfo = widget.initialUser ?? _storage.read('user') ?? {};
    _nameController = TextEditingController(text: _safeStringExtract(userInfo['name']));
    _emailController = TextEditingController(text: _safeStringExtract(userInfo['email']));
    _phoneController = TextEditingController(text: _safeStringExtract(userInfo['phoneNo']));
  }

  void _setupUserChangeListener() {
    for (var c in [_nameController, _emailController, _phoneController]) {
      c.addListener(() {
        _hasUserChanges.value = _checkForUserChanges();
      });
    }
  }

  bool _checkForUserChanges() {
    final userInfo = widget.initialUser ?? _storage.read('user') ?? {};
    return _nameController.text != _safeStringExtract(userInfo['name']) ||
        _emailController.text != _safeStringExtract(userInfo['email']) ||
        _phoneController.text != _safeStringExtract(userInfo['phoneNo']);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.neutralBackground,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Get.back(result: false),
          icon: const Icon(Icons.arrow_back),
          color: AppColors.textDark,
        ),
        automaticallyImplyLeading: false,
        title: Obx(() => Text(
          controller.isEditingMode
              ? 'Edit Address'
              : 'Profile & Addresses',
          style: textTheme.titleLarge?.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
          ),
        )),
        backgroundColor: AppColors.white,
        elevation: 0.5,
        actions: [
          Obx(() => _hasUserChanges.value && _showUserSection.value
              ? TextButton(
            onPressed: _isUserLoading.value ? null : _saveUserInfoQuick,
            child: _isUserLoading.value
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryGreen,
              ),
            )
                : Text(
              'Save',
              style: textTheme.labelLarge?.copyWith(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
              : const SizedBox.shrink()),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Obx(() {
        if (!controller.isFormOpen && !controller.isLoading.value && !_showUserSection.value) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {
                  controller.startAddingAddress();
                },
                icon: const Icon(Icons.add, color: AppColors.white),
                label: Text(
                  'Add New Address',
                  style: textTheme.labelLarge?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              ),
            ),
          );
        } else {
          return const SizedBox.shrink();
        }
      }),
      body: Obx(() {
        if (controller.isFormOpen) {
          return _buildAddressForm(context);
        } else {
          return _buildMainContent(context);
        }
      }),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showUserSection.value = true,
                  icon: Icon(
                    Icons.person_outline,
                    color: _showUserSection.value ? AppColors.white : AppColors.primaryGreen,
                  ),
                  label: Text(
                    'User Info',
                    style: textTheme.labelLarge?.copyWith(
                      color: _showUserSection.value ? AppColors.white : AppColors.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _showUserSection.value ? AppColors.primaryGreen : AppColors.white,
                    foregroundColor: _showUserSection.value ? AppColors.white : AppColors.primaryGreen,
                    side: BorderSide(color: AppColors.primaryGreen),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showUserSection.value = false,
                  icon: Icon(
                    Icons.location_on_outlined,
                    color: !_showUserSection.value ? AppColors.white : AppColors.primaryGreen,
                  ),
                  label: Text(
                    'Addresses',
                    style: textTheme.labelLarge?.copyWith(
                      color: !_showUserSection.value ? AppColors.white : AppColors.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !_showUserSection.value ? AppColors.primaryGreen : AppColors.white,
                    foregroundColor: !_showUserSection.value ? AppColors.white : AppColors.primaryGreen,
                    side: BorderSide(color: AppColors.primaryGreen),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            if (_showUserSection.value) {
              return _buildUserInfoSection(context);
            } else {
              return _buildAddressListSection(context);
            }
          }),
        ),
      ],
    );
  }

  Widget _buildUserInfoSection(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Form(
      key: _userFormKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Personal Information', Icons.person_outline, textTheme),
            const SizedBox(height: 16),
            _buildInfoCard([
              _buildUserTextField(
                controller: _nameController,
                focusNode: _nameFocus,
                nextFocus: _emailFocus,
                label: 'Full Name',
                hint: 'Enter your full name',
                icon: Icons.person_outline,
                validator: (v) => _validateRequired(v, 'Full name'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              // ✅ IMPROVED EMAIL FIELD WITH OPTIONAL HANDLING
              /*_buildEmailFieldWithHelper(),*/
              const SizedBox(height: 16),
              _buildUserTextField(
                controller: _phoneController,
                focusNode: _phoneFocus,
                label: 'Phone Number',
                hint: 'Enter your phone number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: _validatePhone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
              ),
            ]),
            const SizedBox(height: 32),
            Obx(() => SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _hasUserChanges.value && !_isUserLoading.value ? _saveUserInfoAndNavigateBack : null,
                icon: _isUserLoading.value
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.white,
                  ),
                )
                    : const Icon(Icons.save_outlined, color: AppColors.white),
                label: Text(
                  _isUserLoading.value ? 'Saving...' : 'Save & Continue to Checkout',
                  style: textTheme.labelLarge?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  disabledBackgroundColor: AppColors.primaryGreen.withOpacity(0.6),
                ),
              ),
            )),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // ✅ NEW: Email field with clear optional indication
  Widget _buildEmailFieldWithHelper() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildUserTextField(
          controller: _emailController,
          focusNode: _emailFocus,
          nextFocus: _phoneFocus,
          label: 'Email Address',
          hint: 'Enter your email (optional - leave empty to skip)',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: _validateEmail,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 14,
              color: AppColors.textLight,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Optional field - You can leave this empty if you prefer not to provide an email',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textLight,
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddressListSection(BuildContext context) {
    if (controller.isLoading.value && controller.addresses.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primaryGreen),
      );
    } else if (controller.addresses.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          await controller.fetchAddresses();
        },
        color: AppColors.primaryGreen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_off_outlined,
                    size: 60,
                    color: AppColors.textLight.withOpacity(0.6),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No addresses found.',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(color: AppColors.textMedium),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap "Add New Address" below to get started!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppColors.textLight),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      return _buildAddressList(context);
    }
  }

  Widget _buildAddressList(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    const double fabTotalHeight = 54.0 + (8.0 * 2);
    const double extraBottomPadding = 20.0;
    const double totalBottomPadding = fabTotalHeight + extraBottomPadding;

    return RefreshIndicator(
      onRefresh: () async {
        await controller.fetchAddresses();
      },
      color: AppColors.primaryGreen,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, totalBottomPadding),
        itemCount: controller.addresses.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) {
          final AddressModel addr = controller.addresses[index];
          final bool isSelected = controller.selectedAddress.value?.id == addr.id;

          return InkWell(
            onTap: () {
              controller.selectAddress(addr);
              Get.back(result: true);
            },
            borderRadius: BorderRadius.circular(16),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(14),
                  topRight: Radius.circular(14)
              ),
              child: CustomPaint(
                painter: AddressCardPainter(
                  backgroundColor: AppColors.white,
                  accentColor: AppColors.primaryGreen,
                  isSelected: isSelected,
                ),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.textDark.withOpacity(isSelected ? 0.1 : 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_getEmojiForLabel(addr.label)} ${addr.label}',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            addr.street,
                            style: textTheme.bodyLarge
                                ?.copyWith(color: AppColors.textMedium, height: 1.4),
                          ),
                          Text(
                            '${addr.city}, ${addr.state} - ${addr.pinCode}',
                            style: textTheme.bodyLarge
                                ?.copyWith(color: AppColors.textMedium, height: 1.4),
                          ),
                        ],
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: AppColors.primaryGreen, size: 20),
                              onPressed: () {
                                controller.startEditingAddress(addr);
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                              splashRadius: 20,
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: AppColors.danger, size: 20),
                              onPressed: () async {
                                if (addr.id != null) {
                                  final bool confirmed = await Get.dialog<bool>(
                                    AlertDialog(
                                      title: Text('Delete Address',
                                          style: textTheme.titleLarge),
                                      content: Text(
                                          'Are you sure you want to delete this address?',
                                          style: textTheme.bodyMedium),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Get.back(result: false),
                                          child: Text('Cancel',
                                              style: textTheme.labelLarge?.copyWith(
                                                  color: AppColors.textMedium)),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Get.back(result: true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.danger,
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8)),
                                          ),
                                          child: Text('Delete',
                                              style: textTheme.labelLarge?.copyWith(
                                                  color: AppColors.white)),
                                        ),
                                      ],
                                    ),
                                  ) ?? false;
                                  if (confirmed) {
                                    await controller.deleteAddress(addr.id!);
                                  }
                                } else {
                                  Get.snackbar('Error', 'Address ID is missing, cannot delete.',
                                      snackPosition: SnackPosition.BOTTOM,
                                      backgroundColor: AppColors.danger);
                                }
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                              splashRadius: 20,
                            ),
                            if (isSelected)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Icon(Icons.check_circle_rounded,
                                    color: AppColors.primaryGreen, size: 24),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _getEmojiForLabel(String label) {
    switch (label.toLowerCase()) {
      case 'home':
        return '🏠';
      case 'work':
      case 'office':
        return '🏢';
      default:
        return '📍';
    }
  }

  Widget _buildAddressForm(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // ✅ Location Button - NEW FEATURE
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: 20),
              child: Obx(() => ElevatedButton.icon(
                onPressed: _isLoadingLocation.value ? null : _showLocationDialog,
                icon: _isLoadingLocation.value
                    ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.white,
                  ),
                )
                    : Icon(Icons.my_location, color: AppColors.white),
                label: Text(
                  _isLoadingLocation.value ? 'Getting Location...' : 'Use Current Location',
                  style: textTheme.labelLarge?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              )),
            ),

            // ✅ Manual Entry Hint
            Container(
              padding: EdgeInsets.all(12),
              margin: EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primaryGreen, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Use the location button above or fill the form manually. You can edit GPS-filled data if needed.',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            _buildTextField(
              context: context,
              label: "Street Address, House No.",
              controller: controller.streetController,
              validator: (val) =>
              val == null || val.trim().isEmpty ? 'Street address is required' : null,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              context: context,
              label: "PIN Code",
              controller: controller.pinCodeController,
              keyboardType: TextInputType.number,
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'PIN code is required';
                if (!RegExp(r'^\d{4,10}$').hasMatch(val.trim()))
                  return 'Invalid PIN code (4-10 digits)';
                return null;
              },
            ),
            const SizedBox(height: 16),

            _buildTextField(
              context: context,
              label: "City",
              controller: controller.cityController,
              validator: (val) => val == null || val.trim().isEmpty ? 'City is required' : null,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              context: context,
              label: "State / Province",
              controller: controller.stateController,
              validator: (val) => val == null || val.trim().isEmpty ? 'State is required' : null,
            ),
            const SizedBox(height: 24),

            Obx(() {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      'Address Type',
                      style: textTheme.bodyLarge?.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ['Home', 'Work', 'Other'].map((label) {
                      final isSelected = controller.selectedLabel.value == label;
                      return ChoiceChip(
                        label: Text(label),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) controller.selectedLabel.value = label;
                        },
                        labelStyle: textTheme.labelMedium?.copyWith(
                            color: isSelected ? AppColors.white : AppColors.textDark,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500),
                        backgroundColor: AppColors.neutralBackground,
                        selectedColor: AppColors.primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primaryGreen
                                : AppColors.textLight.withOpacity(0.5),
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        elevation: 0,
                        pressElevation: 0,
                      );
                    }).toList(),
                  ),
                  if (controller.selectedLabel.value == 'Other') ...[
                    const SizedBox(height: 16),
                    _buildTextField(
                      context: context,
                      label: 'Custom Label (e.g., "Friend\'s House")',
                      controller: controller.customLabelController,
                      validator: (val) =>
                      val == null || val.trim().isEmpty ? 'A custom label is required' : null,
                    ),
                  ],
                ],
              );
            }),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: Obx(() => ElevatedButton.icon(
                icon: controller.isLoading.value
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: AppColors.white,
                    strokeWidth: 2,
                  ),
                )
                    : Icon(
                  controller.isEditingMode ? Icons.update : Icons.save,
                  color: AppColors.white,
                ),
                onPressed: controller.isLoading.value
                    ? null
                    : () async {
                  if (_formKey.currentState!.validate()) {
                    final success = await controller.saveAddress();
                    if (success) {
                      Get.back(result: true);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  disabledBackgroundColor: AppColors.lightGreen.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                label: Text(
                  controller.isLoading.value
                      ? (controller.isEditingMode ? "Updating..." : "Saving...")
                      : (controller.isEditingMode ? "Update Address" : "Save Address"),
                  style: textTheme.labelLarge?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: controller.isLoading.value
                  ? null
                  : () {
                controller.cancelEditing();
              },
              child: Text(
                'Cancel',
                style: textTheme.labelLarge?.copyWith(
                    color: AppColors.textMedium, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, TextTheme textTheme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primaryGreen, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGreyBackground, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.textDark.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildUserTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocus,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          onFieldSubmitted: (_) {
            if (nextFocus != null) {
              FocusScope.of(context).requestFocus(nextFocus);
            } else {
              focusNode.unfocus();
            }
          },
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.textLight, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.lightGreyBackground),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.lightGreyBackground),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primaryGreen, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.danger),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.danger, width: 2),
            ),
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            hintStyle: TextStyle(color: AppColors.textLight, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: textTheme.bodyLarge?.copyWith(color: AppColors.textDark),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: AppColors.textMedium,
        ),
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.neutralBackground),
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.neutralBackground),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.primaryGreen, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.danger, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.danger, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // ✅ IMPROVED EMAIL VALIDATION - Better handling for optional field
  String? _validateEmail(String? value) {
    // If email field is empty or null, it's valid (since it's optional)
    if (value == null || value.trim().isEmpty) {
      return null; // No validation error for empty optional field
    }

    // Only validate if user has entered something
    final trimmedValue = value.trim();
    if (!GetUtils.isEmail(trimmedValue)) {
      return 'Please enter a valid email address or leave empty';
    }

    return null; // Valid email
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone number is required';
    if (!GetUtils.isPhoneNumber(value.trim()) || value.trim().length != 10)
      return 'Please enter a valid 10-digit phone number';
    return null;
  }

  Future<void> _saveUserInfoQuick() async {
    if (!_userFormKey.currentState!.validate()) return;
    _isUserLoading.value = true;

    try {
      await _saveUserDataToStorage();

      Get.snackbar(
        'Saved',
        'User information saved successfully',
        backgroundColor: AppColors.success,
        colorText: AppColors.white,
        icon: Icon(Icons.check_circle, color: AppColors.white),
        duration: const Duration(seconds: 1),
      );

    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save user information',
        backgroundColor: AppColors.danger,
        colorText: AppColors.white,
        icon: Icon(Icons.error, color: AppColors.white),
        duration: const Duration(seconds: 2),
      );
    } finally {
      _isUserLoading.value = false;
    }
  }

  Future<void> _saveUserInfoAndNavigateBack() async {
    if (!_userFormKey.currentState!.validate()) return;
    _isUserLoading.value = true;

    try {
      await _saveUserDataToStorage();

      Get.snackbar(
        'Profile Updated',
        'Returning to checkout...',
        backgroundColor: AppColors.success,
        colorText: AppColors.white,
        icon: Icon(Icons.check_circle, color: AppColors.white),
        duration: const Duration(seconds: 1),
      );

      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        Get.back(result: true);
      }

    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update user information. Please try again.',
        backgroundColor: AppColors.danger,
        colorText: AppColors.white,
        icon: Icon(Icons.error, color: AppColors.white),
        duration: const Duration(seconds: 3),
      );
    } finally {
      _isUserLoading.value = false;
    }
  }

  Future<void> _saveUserDataToStorage() async {
    final existingUser = widget.initialUser ?? _storage.read('user') ?? {};

    final userInfo = {
      '_id': _safeStringExtract(existingUser['_id']),
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phoneNo': _phoneController.text.trim(),
      'address': _safeStringExtract(existingUser['address']),
      'city': _safeStringExtract(existingUser['city']),
      'state': _safeStringExtract(existingUser['state']),
      'pincode': _safeStringExtract(existingUser['pincode']),
    };

    await _storage.write('user', userInfo);
    _hasUserChanges.value = false;
  }
}

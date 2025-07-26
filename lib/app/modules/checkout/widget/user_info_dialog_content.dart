/*
// lib/app/modules/checkout/views/user_info_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../themes/app_theme.dart';

class UserInfoScreen extends StatefulWidget {
  final Map<String, dynamic> initialUser;

  const UserInfoScreen({Key? key, required this.initialUser}) : super(key: key);

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storage = GetStorage();

  // Form controllers - only personal info
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  // Focus nodes - only personal info
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();

  final RxBool _isLoading = false.obs;
  final RxBool _hasChanges = false.obs;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupChangeListener();
  }

  // Safely extract a string from dynamic (handles List, null, etc.)
  String _safeStringExtract(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is List && value.isNotEmpty) {
      return value.first?.toString() ?? '';
    }
    return value.toString();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: _safeStringExtract(widget.initialUser['name']));
    _emailController = TextEditingController(text: _safeStringExtract(widget.initialUser['email']));
    _phoneController = TextEditingController(text: _safeStringExtract(widget.initialUser['phoneNo']));
  }

  void _setupChangeListener() {
    for (var c in [_nameController, _emailController, _phoneController]) {
      c.addListener(() {
        _hasChanges.value = _checkForChanges();
      });
    }
  }

  bool _checkForChanges() {
    return _nameController.text != _safeStringExtract(widget.initialUser['name']) ||
        _emailController.text != _safeStringExtract(widget.initialUser['email']) ||
        _phoneController.text != _safeStringExtract(widget.initialUser['phoneNo']);
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.neutralBackground,
      appBar: AppBar(
        title: Text(
          'User Information',
          style: textTheme.titleLarge?.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0.5,
        actions: [
          Obx(() => _hasChanges.value
              ? TextButton(
            onPressed: _saveUserInfo,
            child: Text(
              'Save',
              style: textTheme.labelLarge?.copyWith(
                color: AppColors.primaryPurple,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
              : const SizedBox.shrink()),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Personal Information Section
              _buildSectionHeader('Personal Information', Icons.person_outline, textTheme),
              const SizedBox(height: 16),
              _buildInfoCard([
                _buildTextField(
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
                _buildTextField(
                  controller: _emailController,
                  focusNode: _emailFocus,
                  nextFocus: _phoneFocus,
                  label: 'Email Address (Optional)', // ✅ Updated label to indicate optional
                  hint: 'Enter your email address (optional)',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _buildTextField(
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

              // Save Button
              Obx(() => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _hasChanges.value ? _saveUserInfo : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading.value
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                      : Text(
                    'Save Information',
                    style: textTheme.labelLarge?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )),
              const SizedBox(height: 16),
            ],
          ),
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
            color: AppColors.primaryPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primaryPurple, size: 20),
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

  Widget _buildTextField({
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
              borderSide: BorderSide(color: AppColors.primaryPurple, width: 2),
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

  // Validation methods
  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // ✅ Updated: Email validation now allows empty values
  String? _validateEmail(String? value) {
    // If email is empty, it's valid (optional field)
    if (value == null || value.trim().isEmpty) {
      return null; // No error for empty email
    }

    // If email is provided, validate its format
    if (!GetUtils.isEmail(value.trim())) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone number is required';
    if (!GetUtils.isPhoneNumber(value.trim()) || value.trim().length != 10)
      return 'Please enter a valid 10-digit phone number';
    return null;
  }

  // Save user info - only personal details
  Future<void> _saveUserInfo() async {
    if (!_formKey.currentState!.validate()) return;
    _isLoading.value = true;

    try {
      final userInfo = {
        '_id': _safeStringExtract(widget.initialUser['_id']),
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(), // ✅ Can be empty now
        'phoneNo': _phoneController.text.trim(),
        // Preserve existing address data if it exists
        'address': _safeStringExtract(widget.initialUser['address']),
        'city': _safeStringExtract(widget.initialUser['city']),
        'state': _safeStringExtract(widget.initialUser['state']),
        'pincode': _safeStringExtract(widget.initialUser['pincode']),
      };

      await _storage.write('user', userInfo);
      _hasChanges.value = false;

      Get.snackbar(
        'Success',
        'User information updated successfully',
        backgroundColor: AppColors.success,
        colorText: AppColors.white,
        icon: Icon(Icons.check_circle, color: AppColors.white),
        duration: const Duration(seconds: 2),
      );

      Get.back(result: true); // returns boolean true
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
      _isLoading.value = false;
    }
  }
}
*/

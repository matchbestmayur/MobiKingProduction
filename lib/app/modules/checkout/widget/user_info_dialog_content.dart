// lib/app/modules/checkout/views/user_info_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../themes/app_theme.dart'; // Make sure to import AppColors and AppTheme

class UserInfoScreen extends StatefulWidget {
  final Map<String, dynamic> initialUser;

  const UserInfoScreen({Key? key, required this.initialUser}) : super(key: key);

  @override
  _UserInfoScreenState createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _gstController;
  late RxString _orderFor; // Reactive for UI updates
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GetStorage _box = GetStorage();

  @override
  void initState() {
    super.initState();
    // Initialize _orderFor based on existing data or default to 'Self'
    _orderFor = (widget.initialUser['orderFor'] as String? ?? 'Self').obs;

    // Initialize controllers with initial data or clear if 'Other'
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _gstController = TextEditingController();

    _updateControllersBasedOnOrderFor(_orderFor.value); // Set initial values

    // Add listener to update name/phone/email/gst when orderFor changes
    _orderFor.listen((value) {
      _updateControllersBasedOnOrderFor(value);
    });
  }

  void _updateControllersBasedOnOrderFor(String orderForValue) {
    if (orderForValue == 'Self') {
      _nameController.text = widget.initialUser['name'] ?? '';
      _phoneController.text = widget.initialUser['phoneNo'] ?? widget.initialUser['phone'] ?? '';
      _emailController.text = widget.initialUser['email'] ?? '';
      _gstController.text = widget.initialUser['gst'] ?? '';
    } else {
      _nameController.clear();
      _phoneController.clear();
      _emailController.clear();
      _gstController.clear();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _gstController.dispose();
    _orderFor.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.neutralBackground,
      appBar: AppBar(
        title: Text(
          "Confirm Your Details",
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
          onPressed: () => Get.back(result: false), // Dismiss and pass false on back
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0), // Consistent padding for screen
                child: Obx(() {
                  return Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, // Align content to start
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          "Is this order for yourself or for someone else?",
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            fontSize: 15,
                            color: AppColors.textLight,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Self/Other Radio Button Section
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.white, // Changed background to white for contrast
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.lightPurple, width: 1.0),
                          ),
                          child: IntrinsicHeight(
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      if (_orderFor.value != 'Self') {
                                        _orderFor.value = 'Self';
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 8),
                                      decoration: BoxDecoration(
                                        color: _orderFor.value == 'Self'
                                            ? AppColors.primaryPurple.withOpacity(0.1)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Radio<String>(
                                            value: 'Self',
                                            groupValue: _orderFor.value,
                                            onChanged: (String? value) {
                                              if (value != null) {
                                                _orderFor.value = value;
                                              }
                                            },
                                            activeColor: AppColors.primaryPurple,
                                            materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          Text(
                                            "Self",
                                            style: textTheme.titleSmall?.copyWith(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: _orderFor.value == 'Self'
                                                  ? AppColors.primaryPurple
                                                  : AppColors.textDark,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                VerticalDivider(
                                    color: AppColors.lightPurple.withOpacity(0.7),
                                    thickness: 1,
                                    width: 1),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      if (_orderFor.value != 'Other') {
                                        _orderFor.value = 'Other';
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 8),
                                      decoration: BoxDecoration(
                                        color: _orderFor.value == 'Other'
                                            ? AppColors.primaryPurple.withOpacity(0.1)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Radio<String>(
                                            value: 'Other',
                                            groupValue: _orderFor.value,
                                            onChanged: (String? value) {
                                              if (value != null) {
                                                _orderFor.value = value;
                                              }
                                            },
                                            activeColor: AppColors.primaryPurple,
                                            materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          Text(
                                            "Other",
                                            style: textTheme.titleSmall?.copyWith(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: _orderFor.value == 'Other'
                                                  ? AppColors.primaryPurple
                                                  : AppColors.textDark,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Name Field
                        TextFormField(
                          controller: _nameController,
                          style: textTheme.bodyMedium?.copyWith(fontSize: 16, color: AppColors.textDark),
                          decoration: InputDecoration(
                            labelText: _orderFor.value == 'Self'
                                ? "Your Name"
                                : "Recipient's Name",
                            hintText: _orderFor.value == 'Self'
                                ? "Your full name"
                                : "e.g., Jane Doe",
                            labelStyle: textTheme.labelLarge?.copyWith(
                                color: AppColors.textLight,
                                fontWeight: FontWeight.w500),
                            hintStyle: textTheme.bodyMedium?.copyWith(
                                color: AppColors.textLight.withOpacity(0.7)),
                            prefixIcon: Icon(Icons.person_outline_rounded,
                                color: AppColors.primaryPurple),
                            filled: true,
                            fillColor: AppColors.white, // Changed fill color to white
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 16.0, horizontal: 16.0),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: AppColors.lightPurple, width: 1.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: AppColors.primaryPurple, width: 2.0),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: AppColors.danger, width: 1.5),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: AppColors.danger, width: 2.0),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Full name is required';
                            }
                            return null;
                          },
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                        ),

                        const SizedBox(height: 20),

                        // Phone Number Field
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: textTheme.bodyMedium?.copyWith(fontSize: 16, color: AppColors.textDark),
                          decoration: InputDecoration(
                            labelText: "Phone Number",
                            hintText: "e.g., 9876543210",
                            labelStyle: textTheme.labelLarge?.copyWith(
                                color: AppColors.textLight,
                                fontWeight: FontWeight.w500),
                            hintStyle: textTheme.bodyMedium?.copyWith(
                                color: AppColors.textLight.withOpacity(0.7)),
                            prefixIcon: Icon(Icons.phone_outlined,
                                color: AppColors.primaryPurple),
                            filled: true,
                            fillColor: AppColors.white, // Changed fill color to white
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 16.0, horizontal: 16.0),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: AppColors.lightPurple, width: 1.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: AppColors.primaryPurple, width: 2.0),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: AppColors.danger, width: 1.5),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: AppColors.danger, width: 2.0),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Phone number is required';
                            }
                            if (value.trim().length < 10) {
                              return 'Enter a valid 10-digit number';
                            }
                            return null;
                          },
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                        ),

                        const SizedBox(height: 20),

                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: textTheme.bodyMedium?.copyWith(fontSize: 16, color: AppColors.textDark),
                          decoration: InputDecoration(
                            labelText: "Email (Optional)",
                            hintText: "e.g., example@domain.com",
                            labelStyle: textTheme.labelLarge?.copyWith(
                                color: AppColors.textLight,
                                fontWeight: FontWeight.w500),
                            hintStyle: textTheme.bodyMedium?.copyWith(
                                color: AppColors.textLight.withOpacity(0.7)),
                            prefixIcon: Icon(Icons.email_outlined,
                                color: AppColors.primaryPurple),
                            filled: true,
                            fillColor: AppColors.white, // Changed fill color to white
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 16.0, horizontal: 16.0),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: AppColors.lightPurple, width: 1.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: AppColors.primaryPurple, width: 2.0),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: AppColors.danger, width: 1.5),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: AppColors.danger, width: 2.0),
                            ),
                          ),
                          // No validator for email since it's optional and always considered valid if left empty.
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                        ),

                        const SizedBox(height: 20),

                        // GST Number Field (Optional)
                        TextFormField(
                          controller: _gstController,
                          keyboardType: TextInputType.text,
                          style: textTheme.bodyMedium?.copyWith(fontSize: 16, color: AppColors.textDark),
                          decoration: InputDecoration(
                            labelText: "GST Number (Optional)",
                            hintText: "e.g., 22AAAAA0000A1Z5",
                            labelStyle: textTheme.labelLarge?.copyWith(
                                color: AppColors.textLight,
                                fontWeight: FontWeight.w500),
                            hintStyle: textTheme.bodyMedium?.copyWith(
                                color: AppColors.textLight.withOpacity(0.7)),
                            prefixIcon: Icon(Icons.receipt_long_outlined,
                                color: AppColors.primaryPurple),
                            filled: true,
                            fillColor: AppColors.white, // Changed fill color to white
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 16.0, horizontal: 16.0),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: AppColors.lightPurple, width: 1.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: AppColors.primaryPurple, width: 2.0),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: AppColors.danger, width: 1.5),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: AppColors.danger, width: 2.0),
                            ),
                          ),
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              if (!RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$').hasMatch(value.toUpperCase())) {
                                return 'Enter a valid 15-character GST number';
                              }
                            }
                            return null;
                          },
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  );
                }),
              ),
            ),

            // Buttons Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          final updatedUser = {
                            ...widget.initialUser,
                            'name': _nameController.text.trim(),
                            'phoneNo': _phoneController.text.trim(),
                            'phone': _phoneController.text.trim(),
                            'email': _emailController.text.trim(),
                            'gst': _gstController.text.trim(),
                            'orderFor': _orderFor.value,
                          };
                          _box.write('user', updatedUser);
                          Get.back(result: true); // Close screen and pass true
                        } else {
                          _showModernSnackbar(
                            'Validation Error',
                            'Please correct the errors in the form.',
                            icon: Icons.error_outline,
                            backgroundColor: AppColors.danger,
                            isError: true,
                            colorText: AppColors.white,
                            snackPosition: SnackPosition.TOP,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: Text(
                        "Save & Continue",
                        style: textTheme.labelLarge?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      Get.back(result: false); // Close screen and pass false
                    },
                    child: Text(
                      "Cancel",
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Assuming _showModernSnackbar is a top-level function or in a utility class
void _showModernSnackbar(
    String title,
    String message, {
      IconData? icon,
      Color? backgroundColor,
      Color? colorText,
      bool isError = false,
      SnackPosition snackPosition = SnackPosition.BOTTOM,
    }) {
  Get.snackbar(
    title,
    message,
    icon: icon != null ? Icon(icon, color: colorText ?? AppColors.white) : null,
    backgroundColor: backgroundColor ?? (isError ? AppColors.danger : AppColors.success),
    colorText: colorText ?? AppColors.white,
    snackPosition: snackPosition,
    margin: const EdgeInsets.all(10),
    borderRadius: 10,
    animationDuration: const Duration(milliseconds: 300),
    duration: const Duration(seconds: 3),
  );
}
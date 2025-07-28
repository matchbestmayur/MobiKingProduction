import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Import Get package
import 'package:mobiking/app/modules/login/login_screen.dart';

import '../../controllers/login_controller.dart'; // Import your LoginController

import 'package:mobiking/app/themes/app_theme.dart'; // Import your AppTheme

void showLogoutDialog(BuildContext context) {
  // Find the LoginController instance
  final LoginController loginController = Get.find<LoginController>();
  final TextTheme textTheme = Theme.of(context).textTheme; // Get TextTheme

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.neutralBackground, // Use AppColors
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Icon(Icons.logout, color: AppColors.primaryPurple), // Use AppColors
          const SizedBox(width: 8),
          Text(
            'Logout',
            style: textTheme.titleMedium?.copyWith( // Use titleMedium
              fontWeight: FontWeight.bold,
              color: AppColors.primaryPurple, // Use AppColors
            ),
          ),
        ],
      ),
      content: Text(
        'Are you sure you want to logout from your account?',
        style: textTheme.bodyLarge?.copyWith( // Use bodyLarge
          color: AppColors.textDark, // Use AppColors for consistent dark text
        ),
      ),
      actionsPadding: const EdgeInsets.only(right: 12, bottom: 8),
      actions: [
        TextButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.cancel, color: AppColors.textLight), // Use AppColors
          label: Text(
            'Cancel',
            style: textTheme.labelLarge?.copyWith(color: AppColors.textLight), // Use labelLarge
          ),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            Navigator.of(context).pop(); // Close dialog immediately

            // ✅ Show loading indicator during logout
            Get.dialog(
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: AppColors.primaryPurple,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Logging out...',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              barrierDismissible: false,
            );

            try {
              // Call the logout method from the controller
              await loginController.logout();

              // ✅ Navigate to login screen and clear all previous routes
              Get.offAll(() => PhoneAuthScreen());

              // ✅ Optional: Show success message
              Get.snackbar(
                'Success',
                'You have been logged out successfully',
                backgroundColor: AppColors.success,
                colorText: AppColors.white,
                icon: Icon(Icons.check_circle, color: AppColors.white),
                duration: const Duration(seconds: 2),
              );

            } catch (error) {
              // ✅ Handle logout error
              Get.back(); // Close loading dialog
           /*   Get.snackbar(
                'Error',
                'Failed to logout. Please try again.',
                backgroundColor: AppColors.danger,
                colorText: AppColors.white,
                icon: Icon(Icons.error, color: AppColors.white),
                duration: const Duration(seconds: 3),
              );*/
            }
          },
          icon: const Icon(Icons.check_circle_outline, color: Colors.white), // Ensure icon color is white for contrast
          label: Text(
            'Logout',
            style: textTheme.labelLarge?.copyWith(color: Colors.white), // Use labelLarge
          ),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white, // This covers the label and icon color
            backgroundColor: AppColors.danger, // Use AppColors for a clear "danger" action
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    ),
  );
}

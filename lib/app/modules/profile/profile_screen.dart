import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobiking/app/modules/address/AddressPage.dart';
import 'package:mobiking/app/modules/policy/cancellation_policy.dart';
import 'package:mobiking/app/modules/policy/refund_policy.dart';
import 'package:mobiking/app/modules/policy/terms_conditions.dart';
import 'package:mobiking/app/modules/profile/query/query_screen.dart';
import 'package:mobiking/app/modules/profile/wishlist/Aboout_screen.dart'; // Typo: Aboout_screen should be About_screen
import 'package:mobiking/app/modules/profile/wishlist/Support_Screen.dart';
import 'package:mobiking/app/modules/profile/wishlist/Wish_list_screen.dart';
import 'package:mobiking/app/themes/app_theme.dart';
import 'package:share_plus/share_plus.dart';

import '../../widgets/profile_reusable_widget.dart'; // Ensure this widget is updated
import '../orders/order_screen.dart' show OrderHistoryScreen;
import '../policy/logout_screen.dart'; // Assuming showLogoutDialog is defined here
import '../policy/privacy_policy.dart';
import '../../controllers/login_controller.dart'; // Import your LoginController

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final LoginController loginController = Get.find<LoginController>();
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.neutralBackground, // Consistent background
      appBar: AppBar(
        title: Text(
          "My Profile", // Standard app bar title for profile
          style: textTheme.titleLarge?.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false, // Left-aligned title
        backgroundColor: AppColors.white, // White app bar
        elevation: 0.5, // Subtle shadow
        foregroundColor: AppColors.textDark, // Dark icons
        automaticallyImplyLeading: false, // If this is a bottom nav tab
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20), // Adjusted padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Info Section (Blinkit style)
              Obx(() {
                final userMap = loginController.currentUser.value;
                String userName = 'Guest User';
                String userContact = '';

                if (userMap != null) {
                  final String? name = userMap['name'] as String?;
                  final String? email = userMap['email'] as String?;
                  final String? phoneNumber = userMap['phoneNo'] as String?;

                  if (name?.isNotEmpty == true) {
                    userName = name!;
                  } else if (email?.isNotEmpty == true) {
                    userName = email!.split('@')[0]; // Use part of email as name
                  }

                  if (email?.isNotEmpty == true) {
                    userContact = email!;
                  } else if (phoneNumber?.isNotEmpty == true) {
                    userContact = phoneNumber!;
                  }
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: textTheme.headlineSmall?.copyWith( // Prominent user name
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    /*if (userContact.isNotEmpty)
                      Text(
                        userContact,
                        style: textTheme.bodyLarge?.copyWith( // Contact info
                          color: AppColors.textMedium,
                        ),
                      ),*/
                  ],
                );
              }),
              const SizedBox(height: 24), // Space after user info

              // Top 3 Action Boxes (Support, Payment, About Us)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InfoBox(
                    icon: Icons.headset_mic_outlined,
                    title: 'Support',
                    onPressed: () {
                      showSupportDialog(context); // This would navigate to your Support_Screen
                    },
                  ),
                  InfoBox(
                    icon: Icons.wallet_outlined, // Changed to a more generic wallet icon
                    title: 'Payments', // Renamed to plural
                    onPressed: () {
                      // Implement navigation to payment methods/history screen
                      // Get.to(() => PaymentScreen()); // Example
                    },
                  ),
                  InfoBox(
                    icon: Icons.info_outline,
                    title: 'About Us',
                    onPressed: () {
                      showAboutUsDialog(context); // This would navigate to your About_screen
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32), // More space before next section

              // YOUR INFORMATION Section
              Text(
                'YOUR INFORMATION',
                style: textTheme.labelSmall?.copyWith( // Subtle header
                  fontWeight: FontWeight.w700, // Make it a bit bolder
                  color: AppColors.textLight,
                  letterSpacing: 0.8, // Slightly reduced letter spacing
                ),
              ),
              const SizedBox(height: 8), // Reduced space
              ProfileListTile(
                icon: Icons.location_on_outlined,
                title: 'Addresses', // Renamed to plural for consistency
                onTap: () {
                  Get.to(
                    AddressPage(),
                    transition: Transition.rightToLeftWithFade,
                    duration: const Duration(milliseconds: 300),
                  );
                },
              ),
              ProfileListTile(
                icon: Icons.favorite_border_outlined,
                title: 'Wishlist',
                onTap: () {
                  Get.to(
                    WishlistScreen(),
                    transition: Transition.rightToLeftWithFade,
                    duration: const Duration(milliseconds: 300),
                  );
                },
              ),
              /*ProfileListTile(
                icon: Icons.message_outlined, // Keep Query icon consistent
                title: 'My Queries', // Renamed for consistency
                onTap: () {
                  Get.to(
                    QueriesScreen(),
                    transition: Transition.rightToLeftWithFade,
                    duration: const Duration(milliseconds: 300),
                  );
                },
              ),*/
              ProfileListTile(
                icon: Icons.share_outlined,
                title: 'Share The App',
                onTap: () {
                  Share.share(
                    'Check out Mobiking for wholesale mobile phones and accessories: [Your App Store Link Here]',
                    subject: 'Discover Mobiking!',
                  );
                },
              ),

              const SizedBox(height: 24), // Space before Policies section

              // POLICIES & LEGAL Section
              Text(
                'POLICIES & LEGAL',
                style: textTheme.labelSmall?.copyWith( // Subtle header
                  fontWeight: FontWeight.w700,
                  color: AppColors.textLight,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),

              ProfileListTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                onTap: () {
                  Get.to(
                    const PrivacyPolicyScreen(),
                    transition: Transition.rightToLeftWithFade,
                    duration: const Duration(milliseconds: 300),
                  );
                },
              ),
              ProfileListTile(
                icon: Icons.article_outlined,
                title: 'Terms & Conditions',
                onTap: () {
                  Get.to(
                    const TermsAndConditionsScreen(),
                    transition: Transition.rightToLeftWithFade,
                    duration: const Duration(milliseconds: 300),
                  );
                },
              ),
              ProfileListTile(
                icon: Icons.cancel_outlined,
                title: 'Cancellation Policy',
                onTap: () {
                  Get.to(
                    const CancellationPolicyScreen(),
                    transition: Transition.rightToLeftWithFade,
                    duration: const Duration(milliseconds: 300),
                  );
                },
              ),
              ProfileListTile(
                icon: Icons.money_off_csred_outlined,
                title: 'Refund Policy',
                onTap: () {
                  Get.to(
                    const RefundPolicyScreen(),
                    transition: Transition.rightToLeftWithFade,
                    duration: const Duration(milliseconds: 300),
                  );
                },
              ),

              const SizedBox(height: 32), // Space before logout

              // Logout Button (Full Width)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // This dialog should handle the actual loginController.logout() call.
                    showLogoutDialog(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger, // Use AppColors.danger for logout button
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2, // Subtle elevation
                  ),
                  child: Text(
                    'Logout',
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.white, // White text on red button
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }
}
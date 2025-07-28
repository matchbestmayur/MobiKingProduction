import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobiking/app/modules/address/AddressPage.dart';
import 'package:mobiking/app/modules/policy/cancellation_policy.dart';
import 'package:mobiking/app/modules/policy/refund_policy.dart';
import 'package:mobiking/app/modules/policy/terms_conditions.dart';
import 'package:mobiking/app/modules/profile/query/query_screen.dart';
import 'package:mobiking/app/modules/profile/wishlist/Aboout_screen.dart';

import 'package:mobiking/app/modules/profile/wishlist/Support_Screen.dart';
import 'package:mobiking/app/modules/profile/wishlist/Wish_list_screen.dart';
import 'package:mobiking/app/themes/app_theme.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';


import '../../widgets/profile_reusable_widget.dart';
import '../orders/order_screen.dart' show OrderHistoryScreen;
import '../policy/logout_screen.dart';
import '../policy/privacy_policy.dart';
import '../../controllers/login_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final LoginController loginController = Get.find<LoginController>();
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.neutralBackground,
      appBar: AppBar(
        title: Text(
          "My Profile",
          style: textTheme.titleLarge?.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        backgroundColor: AppColors.white,
        elevation: 0.5,
        foregroundColor: AppColors.textDark,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
                    userName = email!.split('@')[0];
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
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                );
              }),
              const SizedBox(height: 24),

              // ✅ Updated Top 4 Action Boxes: Your Orders, Support, Address, Wishlist
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: InfoBox(
                      icon: Icons.shopping_bag_outlined,
                      title: 'Orders',
                      onPressed: () {
                        Get.to(
                              () => const OrderHistoryScreen(),
                          transition: Transition.rightToLeftWithFade,
                          duration: const Duration(milliseconds: 300),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InfoBox(
                      icon: Icons.headset_mic_outlined,
                      title: 'Support',
                      onPressed: () {
                        Get.to(() => const QueriesScreen());
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InfoBox(
                      icon: Icons.location_on_outlined,
                      title: 'Address',
                      onPressed: () {
                        Get.to(
                          AddressPage(),
                          transition: Transition.rightToLeftWithFade,
                          duration: const Duration(milliseconds: 300),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InfoBox(
                      icon: Icons.favorite_border_outlined,
                      title: 'Wishlist',
                      onPressed: () {
                        Get.to(
                          WishlistScreen(),
                          transition: Transition.rightToLeftWithFade,
                          duration: const Duration(milliseconds: 300),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ✅ Updated YOUR INFORMATION Section (removed Address and Wishlist)
              Text(
                'YOUR INFORMATION',
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textLight,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),

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

              const SizedBox(height: 24),

              // ✅ POLICIES Section (consolidated into single tile)
              Text(
                'POLICIES',
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textLight,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),

              ProfileListTile(
                icon: Icons.policy_outlined,
                title: 'Policies & Legal',
                onTap: () {
                  _showPoliciesBottomSheet(context);
                },
              ),

              const SizedBox(height: 24),

              // ✅ SOCIAL Section
              Text(
                'SOCIAL',
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textLight,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),

              ProfileListTile(
                icon: Icons.chat_bubble_outline,
                title: 'WhatsApp',
                onTap: () {
                  _launchWhatsApp();
                },
              ),

              ProfileListTile(
                icon: Icons.info_outline,
                title: 'About Us',

                onTap: () {
                  showAboutUsDialog(context);
                },
              ),

              const SizedBox(height: 32),

              // Logout Button (Full Width)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    showLogoutDialog(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'Logout',
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Policies Bottom Sheet
  void _showPoliciesBottomSheet(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textLight.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Policies & Legal',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 20),

            _buildPolicyTile(
              context,
              Icons.privacy_tip_outlined,
              'Privacy Policy',
              'How we handle your data',
                  () {
                Navigator.pop(context);
                Get.to(
                  const PrivacyPolicyScreen(),
                  transition: Transition.rightToLeftWithFade,
                  duration: const Duration(milliseconds: 300),
                );
              },
            ),

            _buildPolicyTile(
              context,
              Icons.article_outlined,
              'Terms & Conditions',
              'Terms of service',
                  () {
                Navigator.pop(context);
                Get.to(
                  const TermsAndConditionsScreen(),
                  transition: Transition.rightToLeftWithFade,
                  duration: const Duration(milliseconds: 300),
                );
              },
            ),

            _buildPolicyTile(
              context,
              Icons.cancel_outlined,
              'Cancellation Policy',
              'Order cancellation terms',
                  () {
                Navigator.pop(context);
                Get.to(
                  const CancellationPolicyScreen(),
                  transition: Transition.rightToLeftWithFade,
                  duration: const Duration(milliseconds: 300),
                );
              },
            ),

            _buildPolicyTile(
              context,
              Icons.money_off_csred_outlined,
              'Refund Policy',
              'Refund and return policy',
                  () {
                Navigator.pop(context);
                Get.to(
                  const RefundPolicyScreen(),
                  transition: Transition.rightToLeftWithFade,
                  duration: const Duration(milliseconds: 300),
                );
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ✅ Policy Tile Builder
  Widget _buildPolicyTile(
      BuildContext context,
      IconData icon,
      String title,
      String subtitle,
      VoidCallback onTap,
      ) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppColors.primaryPurple,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textLight,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // ✅ WhatsApp Launch Function
  void _launchWhatsApp() async {
    const phoneNumber = "+1234567890"; // Replace with your WhatsApp number
    const message = "Hello! I need help with Mobiking app.";

    final whatsappUrl = "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}";

    try {
      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(Uri.parse(whatsappUrl), mode: LaunchMode.externalApplication);
      } else {/*
        Get.snackbar(
          'Error',
          'WhatsApp is not installed on your device',
          backgroundColor: AppColors.danger,
          colorText: AppColors.white,
        );*/
      }
    } catch (e) {
      /*Get.snackbar(
        'Error',
        'Could not open WhatsApp',
        backgroundColor: AppColors.danger,
        colorText: AppColors.white,
      );*/
    }
  }
}

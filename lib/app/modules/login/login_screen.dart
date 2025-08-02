import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobiking/app/controllers/login_controller.dart';
import 'package:mobiking/app/modules/opt/Otp_screen.dart';
import 'package:mobiking/app/themes/app_theme.dart';
import 'package:mobiking/app/controllers/system_ui_controller.dart';

class PhoneAuthScreen extends StatelessWidget {
  PhoneAuthScreen({Key? key}) : super(key: key);

  final LoginController loginController = Get.find();
  final SystemUIController systemUiController = Get.find();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUIController.authScreenStyle,
        child: Container(
          height: screenHeight,
          width: screenWidth,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryPurple,
                AppColors.darkPurple,
                AppColors.primaryPurple.withOpacity(0.9),
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header section - 35% of screen
                Expanded(
                  flex: 35,
                  child: _buildHeader(context, textTheme),
                ),
                // Main content - 65% of screen
                Expanded(
                  flex: 65,
                  child: _buildMainContent(context, textTheme),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🌄 Compact Header
  Widget _buildHeader(BuildContext context, TextTheme textTheme) {
    return Container(
      width: double.infinity,
      child: Stack(
        children: [
          // Subtle decorative elements
          Positioned(
            top: 20,
            right: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            top: 60,
            left: -30,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentNeon.withOpacity(0.15),
              ),
            ),
          ),

          // Main header content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white.withOpacity(0.15),
                    border: Border.all(
                      color: AppColors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.storefront_rounded,
                    size: 40,
                    color: AppColors.white,
                  ),
                ),

                const SizedBox(height: 16),

                // App name
                Text(
                  "Mobiking",
                  style: textTheme.headlineLarge?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 32,
                    letterSpacing: 1.0,
                  ),
                ),

                Text(
                  "Wholesale",
                  style: textTheme.titleLarge?.copyWith(
                    color: AppColors.white.withOpacity(0.85),
                    fontWeight: FontWeight.w300,
                    fontSize: 18,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🎴 Main Content with Sign Up Card
  Widget _buildMainContent(BuildContext context, TextTheme textTheme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            // Card Header - Fixed spacing
            _buildCardHeader(textTheme),

            const SizedBox(height: 32),

            // Phone Input - Fixed spacing
            _buildPhoneInput(context, textTheme),

            const SizedBox(height: 24),

            // OTP Button - Fixed spacing
            _buildOtpButton(textTheme),

            // Spacer to push footer to bottom
            const Spacer(),

            // Footer text - Always at bottom
            _buildFooter(textTheme),
          ],
        ),
      ),
    );
  }

  // Card Header
  Widget _buildCardHeader(TextTheme textTheme) {
    return Column(
      children: [
        // Decorative line
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryPurple,
                AppColors.accentNeon,
              ],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        const SizedBox(height: 20),

        Text(
          "Welcome Back",
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
            fontSize: 26,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          "Enter your phone number to continue",
          style: textTheme.bodyLarge?.copyWith(
            color: AppColors.textLight,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  // 📱 Phone input field
  Widget _buildPhoneInput(BuildContext context, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Mobile Number",
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
            fontSize: 15,
          ),
        ),

        const SizedBox(height: 10),

        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryPurple.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: loginController.phoneController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.neutralBackground,
              hintText: "Enter 10-digit mobile number",
              prefixIcon: Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.phone_android_rounded,
                  color: AppColors.primaryPurple,
                  size: 18,
                ),
              ),
              hintStyle: textTheme.bodyMedium?.copyWith(
                color: AppColors.textLight.withOpacity(0.7),
                fontWeight: FontWeight.w400,
              ),
              counterText: "",
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: AppColors.primaryPurple,
                  width: 2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: AppColors.lightGreyBackground,
                  width: 1,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.danger, width: 2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.danger, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty || value.length != 10 || !GetUtils.isNumericOnly(value)) {
                return 'Enter a valid 10-digit mobile number';
              }
              return null;
            },
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
        ),
      ],
    );
  }

  // 🔐 OTP Button - UPDATED to call sendOtp and navigate
  Widget _buildOtpButton(TextTheme textTheme) {
    return Obx(() => Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: loginController.isOtpLoading.value // CHANGED: Use isOtpLoading instead
              ? [
            AppColors.textLight.withOpacity(0.5),
            AppColors.textLight.withOpacity(0.7),
          ]
              : [
            AppColors.primaryPurple,
            AppColors.darkPurple,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: loginController.isOtpLoading.value
            ? []
            : [
          BoxShadow(
            color: AppColors.primaryPurple.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: loginController.isOtpLoading.value
              ? null
              : () async { // CHANGED: Make async
            final phone = loginController.phoneController.text.trim();

            // Validate phone number
            if (phone.length != 10 || !GetUtils.isNumericOnly(phone)) {
              Get.snackbar(
                "Invalid Phone Number",
                "Please enter a valid 10-digit mobile number.",
                backgroundColor: AppColors.danger,
                colorText: AppColors.white,
                margin: const EdgeInsets.all(16),
                borderRadius: 12,
                icon: const Icon(Icons.error_outline, color: Colors.white),
              );
              return;
            }

            // CHANGED: Call sendOtp method instead of direct navigation
            final otpSent = await loginController.sendOtp(phone);

            // Navigate to OTP screen only if OTP was sent successfully
            if (otpSent) {
              Get.to(() => OtpVerificationScreen(phoneNumber: phone));
            }
          },
          child: Center(
            child: loginController.isOtpLoading.value
                ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                color: AppColors.white,
                strokeWidth: 2.5,
              ),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Get OTP', // CHANGED: Better text
                  style: textTheme.titleLarge?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.sms_outlined, // CHANGED: More appropriate icon
                  color: AppColors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  // Footer
  Widget _buildFooter(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.textLight,
            height: 1.4,
            fontSize: 12,
          ),
          children: [
            const TextSpan(text: "By continuing, you agree to our "),
            TextSpan(
              text: "Terms of Service",
              style: TextStyle(
                color: AppColors.primaryPurple,
                fontWeight: FontWeight.w500,
              ),
            ),
            const TextSpan(text: " and "),
            TextSpan(
              text: "Privacy Policy",
              style: TextStyle(
                color: AppColors.primaryPurple,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

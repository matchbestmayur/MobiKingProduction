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
  final SystemUIController systemUiController = Get.find<SystemUIController>();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUIController.authScreenStyle,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(context, textTheme),
              const SizedBox(height: 40),
              _buildPhoneInput(context, textTheme),
              const SizedBox(height: 30),
              _buildOtpButton(textTheme),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // 🌄 Header with image and overlay text
  Widget _buildHeader(BuildContext context, TextTheme textTheme) {
    return Container(
      height: 380,
      width: double.infinity,
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/images/img.png'),
          fit: BoxFit.cover,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
          gradient: LinearGradient(
            colors: [
              Colors.black.withOpacity(0.3),
              AppColors.primaryPurple.withOpacity(0.6),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storefront, size: 80, color: AppColors.white.withOpacity(0.9)),
            const SizedBox(height: 16),
            Text(
              "Welcome to",
              style: textTheme.headlineSmall?.copyWith(
                color: AppColors.white.withOpacity(0.85),
              ),
            ),
            Text(
              "Mobiking Wholesale",
              textAlign: TextAlign.center,
              style: textTheme.headlineMedium?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
                fontSize: 36,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Your one-stop shop for mobile accessories.",
              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.white.withOpacity(0.95),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 📱 Phone input field
  Widget _buildPhoneInput(BuildContext context, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Enter your Mobile Number",
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: loginController.phoneController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.white,
              hintText: "e.g., 9876543210",
              prefixIcon: Icon(Icons.phone_android, color: AppColors.primaryPurple),
              hintStyle: textTheme.titleMedium?.copyWith(
                color: AppColors.textLight.withOpacity(0.6),
              ),
              counterText: "",
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.primaryPurple, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.lightPurple.withOpacity(0.7), width: 1.2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.danger, width: 2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.danger, width: 2.5),
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
        ],
      ),
    );
  }

  // 🔐 OTP Button
  Widget _buildOtpButton(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Obx(() => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryPurple,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
            shadowColor: AppColors.primaryPurple.withOpacity(0.3),
          ),
          onPressed: loginController.isLoading.value
              ? null
              : () {
            final phone = loginController.phoneController.text;
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
            Get.to(() => OtpVerificationScreen(phoneNumber: phone));
          },
          child: loginController.isLoading.value
              ? const CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 3.5,
          )
              : Text(
            'Get OTP',
            style: textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
        ),
      )),
    );
  }
}

// lib/app/modules/opt/Otp_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:mobiking/app/themes/app_theme.dart';
import 'dart:async'; // Required for Timer

import 'package:mobiking/app/controllers/login_controller.dart'; // Import LoginController
import '../bottombar/Bottom_bar.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpVerificationScreen({super.key, required this.phoneNumber});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  TextEditingController otpController = TextEditingController();
  final RxBool _isVerifyButtonLoading = false.obs;

  RxBool _isSendingOrResending = false.obs;
  int _resendTimerValue = 30;
  late RxInt _countdown;
  Timer? _resendCountdownTimer;

  final LoginController _loginController = Get.find<LoginController>();

  @override
  void initState() {
    super.initState();
    _countdown = _resendTimerValue.obs;

    // DEFER THE CALL TO THE NEXT FRAME
    // This ensures the build phase is complete before you attempt to modify
    // the TextEditingController which might trigger a rebuild.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendOrResendOtpAction(); // Call this after the first frame is built
    });
  }

  // Unified method to call loginController.login() (for sending OTP) and start the timer
  void _sendOrResendOtpAction() async {
    if (_isSendingOrResending.value) return;

    _isSendingOrResending.value = true;
    Get.snackbar(
      'Sending OTP',
      'An OTP is being sent to ${widget.phoneNumber}...',
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.primaryPurple,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      icon: const Icon(Icons.send_time_extension, color: Colors.white),
      duration: const Duration(seconds: 2),
    );

    try {
      // This line was causing the error because it's called during build via initState
      // By deferring _sendOrResendOtpAction, this is no longer during build.
      _loginController.phoneController.text = widget.phoneNumber;
      await _loginController.login(); // This should be the method that sends the OTP

      debugPrint("OTP sent to ${widget.phoneNumber} (via _loginController.login())");
      _isSendingOrResending.value = false;
      _startResendCountdown();

      Get.snackbar(
        'OTP Sent!',
        'Please check your SMS for the code.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
        icon: const Icon(Icons.check_circle_outline, color: Colors.white),
        duration: const Duration(seconds: 3),
      );
    } catch (error) {
      _isSendingOrResending.value = false;
      Get.snackbar(
        'Failed to Send OTP',
        'Could not send OTP. Please try again. Error: $error',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.danger,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
        icon: const Icon(Icons.error_outline, color: Colors.white),
      );
    }
  }

  void _startResendCountdown() {
    _countdown.value = _resendTimerValue;
    _resendCountdownTimer?.cancel();

    _resendCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown.value > 0) {
        _countdown.value--;
      } else {
        timer.cancel();
      }
    });
  }

  void _handleVerifyOtp() async {
    String otp = otpController.text.trim();

    if (otp.length == 6) {
      _isVerifyButtonLoading.value = true;

      debugPrint('OTP Submitted: $otp');
      try {
       /* await _loginController.verifyOtp(widget.phoneNumber, otp); // Use the actual verifyOtp*/

        _isVerifyButtonLoading.value = false;

        Get.offAll(() => const MainContainerScreen());
      } catch (error) {
        _isVerifyButtonLoading.value = false;
        Get.snackbar(
          'Verification Failed',
          'Please re-check OTP or try again.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.danger,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 8,
          icon: const Icon(Icons.error_outline, color: Colors.white),
        );
        print('OTP Verification Screen Error: $error');
      }
    } else {
      Get.snackbar(
        'Invalid OTP',
        'Please enter the complete 6-digit OTP.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.danger,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
        icon: const Icon(Icons.error_outline, color: Colors.white),
      );
    }
  }

  void _resendOtp() {
    if (!_isSendingOrResending.value && _countdown.value == 0) {
      debugPrint("Attempting to resend OTP to ${widget.phoneNumber}");
      _sendOrResendOtpAction();
    } else {
      debugPrint("Resend currently disabled: _isSendingOrResending.value: ${_isSendingOrResending.value}, _countdown.value: ${_countdown.value}");
    }
  }

  @override
  void dispose() {
    otpController.dispose();
    _countdown.close();
    _isVerifyButtonLoading.close();
    _isSendingOrResending.close();
    _resendCountdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.neutralBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 30),

            Icon(Icons.lock_open_rounded, size: 80, color: AppColors.primaryPurple),
            const SizedBox(height: 24),

            Text(
              "Verify Your Account",
              style: textTheme.headlineLarge?.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.w700,
                fontSize: 30,
              ),
            ),
            const SizedBox(height: 12),

            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                text: "Please enter the 6-digit code sent to \n",
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.textLight,
                ),
                children: [
                  TextSpan(
                    text: widget.phoneNumber,
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.primaryPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),

            PinCodeTextField(
              controller: otpController,
              appContext: context,
              length: 6,
              obscureText: false,
              animationType: AnimationType.scale,
              keyboardType: TextInputType.number,
              autoFocus: true,
              textStyle: textTheme.headlineSmall?.copyWith(color: AppColors.textDark, fontWeight: FontWeight.bold),
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(15),
                fieldHeight: 60,
                fieldWidth: 50,
                activeColor: AppColors.primaryPurple,
                selectedColor: AppColors.darkPurple,
                inactiveColor: AppColors.lightPurple,
                activeFillColor: Colors.transparent,
                selectedFillColor: Colors.transparent,
                inactiveFillColor: Colors.transparent,
                borderWidth: 1.5,
              ),
              animationDuration: const Duration(milliseconds: 200),
              enableActiveFill: true,
              onCompleted: (v) => _handleVerifyOtp(),
              onChanged: (value) {
                debugPrint(value);
              },
            ),

            const SizedBox(height: 40),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              child: Obx(
                    () {
                  final TextTheme textTheme = Theme.of(context).textTheme;
                  final bool buttonIsLoading = _isVerifyButtonLoading.value;

                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 18,
                        ),
                        elevation: 8,
                        shadowColor: AppColors.primaryPurple.withOpacity(0.4),
                      ),
                      onPressed: buttonIsLoading ? null : _handleVerifyOtp,
                      child: buttonIsLoading
                          ? const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 3.5,
                        ),
                      )
                          : Text(
                        'Verify OTP',
                        style: textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 30),

            Align(
              alignment: Alignment.center,
              child: Obx(() =>
              _countdown.value > 0
                  ? RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: "Resend code in ",
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.textLight),
                  children: [
                    TextSpan(
                      text: "00:${_countdown.value.toString().padLeft(2, '0')}",
                      style: textTheme.titleSmall?.copyWith(
                        color: AppColors.primaryPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: " seconds",
                      style: textTheme.bodyMedium?.copyWith(color: AppColors.textLight),
                    ),
                  ],
                ),
              )
                  : Text(
                "Didn't receive the code?",
                style: textTheme.bodyMedium?.copyWith(color: AppColors.textLight),
              ),
              ),
            ),
            const SizedBox(height: 10),

            Obx(() => TextButton(
              onPressed: (_countdown.value > 0 || _isSendingOrResending.value) ? null : _resendOtp,
              style: TextButton.styleFrom(
                foregroundColor: (_countdown.value > 0 || _isSendingOrResending.value)
                    ? AppColors.textLight.withOpacity(0.5)
                    : AppColors.primaryPurple,
              ),
              child: _isSendingOrResending.value
                  ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text("Sending OTP...",
                      style: textTheme.labelLarge?.copyWith(color: AppColors.primaryPurple)),
                ],
              )
                  : Text(
                "Resend OTP",
                style: textTheme.labelLarge?.copyWith(
                  color: (_countdown.value > 0 || _isSendingOrResending.value)
                      ? AppColors.textLight.withOpacity(0.5)
                      : AppColors.primaryPurple,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
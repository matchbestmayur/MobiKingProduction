// lib/app/controllers/system_ui_controller.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../themes/app_theme.dart';

class SystemUIController extends GetxController {
  var currentUiStyle = const SystemUiOverlayStyle().obs;

  @override
  void onInit() {
    super.onInit();
    // Set default style
    setHomeStyle();
  }

  void setHomeStyle() {
    final style = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    );
    currentUiStyle.value = style;
    SystemChrome.setSystemUIOverlayStyle(style);
  }

  void setCategoryStyle() {
    final style = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.neutralBackground,
      systemNavigationBarIconBrightness: Brightness.dark,
    );
    currentUiStyle.value = style;
    SystemChrome.setSystemUIOverlayStyle(style);
  }

  void setSearchStyle() {
    final style = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    );
    currentUiStyle.value = style;
    SystemChrome.setSystemUIOverlayStyle(style);
  }

  void setProfileStyle() {
    final style = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.neutralBackground,
      systemNavigationBarIconBrightness: Brightness.dark,
    );
    currentUiStyle.value = style;
    SystemChrome.setSystemUIOverlayStyle(style);
  }

  // ✅ NEW: Auth Screen Style
  void setAuthScreenStyle() {
    final style = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, // Light icons for auth screens
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.primaryPurple, // Brand color for auth
      systemNavigationBarIconBrightness: Brightness.light,
    );
    currentUiStyle.value = style;
    SystemChrome.setSystemUIOverlayStyle(style);
  }

  // ✅ Static property for external access
  static SystemUiOverlayStyle get authScreenStyle {
    return const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFF6C63FF), // Replace with your primary color
      systemNavigationBarIconBrightness: Brightness.light,
    );
  }
}

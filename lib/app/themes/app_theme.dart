import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Import google_fonts

class AppColors {
  static const Color primaryPurple = Color(0xFF5F13C5);
  static const Color darkPurple = Color(0xFF3E0D91);
  static const Color lightPurple = Color(0xFFD8C4F5);
  static const Color accentNeon = Color(0xFF00CCFF);
  static const Color neutralBackground = Color(0xFFF8F9FC);
  static const Color textDark = Color(0xFF1A1A1A); // Used for primary text, almost black
  static const Color textLight = Color(0xFF666666); // Lighter grey for secondary/hint text
  static const Color textMedium = Color(0xFF333333); // A slightly darker grey for important secondary text

  // Blinkit Green Colors
  static const Color primaryGreen = Color(0xFF00CCBC); // A common Blinkit green
  static const Color lightGreen = Color(0xFFE6FFF9); // A lighter shade of green for backgrounds/chips
  static const Color discountGreen = Color(0xFFE0F7FA); // A very light, almost white green for discount badges

  static const Color success = Color(0xFF328616);
  static const Color danger = Color(0xFFFF4C61);
  static const Color gradientStart = Color(0xFF5F13C5);
  static const Color gradientEnd = Color(0xFFFF4C61);

  static const Color white = Colors.white;

  // Add the new Blinkit Green color
  static const Color blinkitGreen = Color(0xFF328616); // This is the new color


  // Add a gold-like color for ratings, as seen in Blinkit
  static const Color ratingGold = Color(0xFFFFC107); // A standard amber/gold often used for stars

  // NEW COLOR ADDED HERE
  static const Color lightGreyBackground = Color(0xFFF0F0F0); // A subtle light grey for background elements or dividers
  static const Color accentOrange = Color(0xFFFF8C00); // A vibrant orange for highlights/discounts (based on the previous screenshot)
  static const Color info = Color(0xFF2196F3); // A standard blue for informational messages
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.neutralBackground,
      primaryColor: AppColors.primaryPurple,
      // Removed top-level fontFamily as each TextStyle will specify it

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter( // Using Inter
          fontSize: 20,
          fontWeight: FontWeight.w800, // ExtraBold
          color: AppColors.white,
        ),
      ),
      textTheme: TextTheme(
        // DISPLAY TEXT: Use ExtraBold for highest impact titles
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w800, // ExtraBold
          color: AppColors.textDark,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w800, // ExtraBold
          color: AppColors.textDark,
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w800, // ExtraBold
          color: AppColors.textDark,
        ),

        // HEADLINE TEXT: Still quite prominent, use ExtraBold
        headlineLarge: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w800, // ExtraBold
          color: AppColors.textDark,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w800, // ExtraBold
          color: AppColors.textDark,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w800, // ExtraBold
          color: AppColors.textDark,
        ),

        // TITLE TEXT: For item names, product titles. Can be ExtraBold for emphasis or Light for softer look
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w800, // ExtraBold
          color: AppColors.textDark,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w800, // ExtraBold
          color: AppColors.textDark,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w800, // ExtraBold
          color: AppColors.textDark,
        ),

        // BODY TEXT: Consistently use Inter Light for readability.
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w300, // Light
          color: AppColors.textMedium,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w300, // Light
          color: AppColors.textLight,
          height: 1.4,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w300, // Light
          color: AppColors.textLight,
        ),

        // LABEL TEXT: Buttons, tags, input labels. Buttons are usually prominent, so ExtraBold.
        labelLarge: GoogleFonts.inter( // Buttons
          fontSize: 16,
          fontWeight: FontWeight.w800, // ExtraBold
          color: AppColors.white,
        ),
        labelMedium: GoogleFonts.inter( // Input field labels, chips, filters
          fontSize: 14,
          fontWeight: FontWeight.w300, // Light
          color: AppColors.textMedium,
        ),
        labelSmall: GoogleFonts.inter( // Very small labels, badges, timestamps
          fontSize: 10,
          fontWeight: FontWeight.w300, // Light
          color: AppColors.textLight,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryPurple,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter( // Using Inter for buttons
            fontWeight: FontWeight.w800, // ExtraBold for buttons
            fontSize: 16,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightPurple),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryPurple),
        ),
        hintStyle: GoogleFonts.inter( // Using Inter for hints
          color: AppColors.textLight,
          fontWeight: FontWeight.w300, // Light for hints
        ),
        labelStyle: GoogleFonts.inter( // Using Inter for input labels
          color: AppColors.textMedium,
          fontWeight: FontWeight.w300, // Light for input labels
        ),
      ),
      colorScheme: ColorScheme.fromSwatch().copyWith(
        primary: AppColors.primaryPurple,
        secondary: AppColors.accentNeon,
        error: AppColors.danger,
        background: AppColors.neutralBackground,
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primaryPurple;
          }
          return AppColors.textLight;
        }),
        checkColor: MaterialStateProperty.all(AppColors.white),
        splashRadius: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        side: BorderSide(
          color: AppColors.textLight,
          width: 2,
        ),
      ),

      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primaryPurple;
          }
          return AppColors.textLight;
        }),
        splashRadius: 16,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.white;
          }
          return AppColors.white;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primaryPurple.withOpacity(0.8);
          }
          return AppColors.textLight.withOpacity(0.5);
        }),
        splashRadius: 16,
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primaryPurple,
        inactiveTrackColor: AppColors.lightPurple.withOpacity(0.5),
        thumbColor: AppColors.primaryPurple,
        overlayColor: AppColors.primaryPurple.withOpacity(0.2),
        valueIndicatorColor: AppColors.primaryPurple,
        valueIndicatorTextStyle: GoogleFonts.inter( // Using Inter for slider value
          color: AppColors.white,
          fontWeight: FontWeight.w800, // ExtraBold for clear value
          fontSize: 14,
        ),
        trackHeight: 4.0,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 24.0),
      ),
    );
  }
}
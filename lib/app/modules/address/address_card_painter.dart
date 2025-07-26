// address_card_painter.dart
import 'package:flutter/material.dart';
import 'package:mobiking/app/themes/app_theme.dart'; // Assuming AppColors are defined here

class AddressCardPainter extends CustomPainter {
  final Color backgroundColor;
  final Color accentColor;
  final bool isSelected;

  AddressCardPainter({
    required this.backgroundColor,
    required this.accentColor,
    required this.isSelected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final path = Path();

    // Draw the main background (rounded rectangle)
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final borderRadius = BorderRadius.circular(16.0); // Match container radius
    path.addRRect(borderRadius.resolve(TextDirection.ltr).toRRect(rect));
    canvas.drawPath(path, paint);

    // Draw an accent shape (e.g., a subtle curve or wave on one side)
    final accentPaint = Paint()
      ..color = accentColor.withOpacity(isSelected ? 0.15 : 0.08) // Subtle opacity
      ..style = PaintingStyle.fill;

    final accentPath = Path();

    // Example: Draw a subtle curved accent on the right side
    final accentWidth = size.width * 0.3; // Width of the accent area
    accentPath.moveTo(size.width - accentWidth, 0);
    // Create a cubic bezier curve for a soft wave effect
    accentPath.cubicTo(
      size.width - accentWidth * 0.7, size.height * 0.2,
      size.width - accentWidth * 0.3, size.height * 0.8,
      size.width, size.height,
    );
    accentPath.lineTo(size.width, 0);
    accentPath.close();

    canvas.drawPath(accentPath, accentPaint);

    // Example: Draw small decorative circles or dots
    final dotPaint = Paint()
      ..color = accentColor.withOpacity(isSelected ? 0.2 : 0.1)
      ..style = PaintingStyle.fill;

    // Top right decorative dot
    canvas.drawCircle(Offset(size.width - 20, 20), 4, dotPaint);
    // Bottom left decorative dot
    canvas.drawCircle(Offset(20, size.height - 20), 3, dotPaint);

    // Draw a subtle border if selected
    if (isSelected) {
      final borderPaint = Paint()
        ..color = accentColor // Use accent color for border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      final borderPath = Path();
      // Slightly inset the path for the border
      final insetRect = Rect.fromLTWH(1, 1, size.width - 2, size.height - 2);
      final insetBorderRadius = BorderRadius.circular(15.0); // Slightly smaller radius
      borderPath.addRRect(insetBorderRadius.resolve(TextDirection.ltr).toRRect(insetRect));
      canvas.drawPath(borderPath, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! AddressCardPainter ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.isSelected != isSelected;
  }
}
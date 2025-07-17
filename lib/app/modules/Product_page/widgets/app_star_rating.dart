// lib/screens/widgets/app_star_rating.dart
import 'package:flutter/material.dart';

class AppStarRating extends StatelessWidget {
  final double rating;
  final int ratingCount;
  final double starSize;
  final Color starColor;

  const AppStarRating({
    Key? key,
    required this.rating,
    this.ratingCount = 0,
    this.starSize = 16.0,
    this.starColor = Colors.amber, // Typical star color
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return Icon(Icons.star, color: starColor, size: starSize);
        } else if (index < rating) {
          return Icon(Icons.star_half, color: starColor, size: starSize);
        } else {
          return Icon(Icons.star_border, color: starColor, size: starSize);
        }
      }),
    );
  }
}
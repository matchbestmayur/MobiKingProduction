import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
    this.starColor = Colors.amber,
  }) : super(key: key);

  // SVG strings for different star states
  static const String _starFullSvg = '''
    <svg viewBox="0 0 24 24" fill="currentColor">
      <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/>
    </svg>
  ''';

  static const String _starHalfSvg = '''
    <svg viewBox="0 0 24 24" fill="currentColor">
      <path d="M22 9.24l-7.19-.62L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21 12 17.27 18.18 21l-1.63-7.03L22 9.24zM12 15.4V6.1l1.71 4.04 4.38.38-3.32 2.88 1 4.28L12 15.4z"/>
    </svg>
  ''';

  static const String _starEmptySvg = '''
    <svg viewBox="0 0 24 24" fill="currentColor">
      <path d="M22 9.24l-7.19-.62L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21 12 17.27 18.18 21l-1.63-7.03L22 9.24zM12 15.4l-3.76 2.27 1-4.28-3.32-2.88 4.38-.38L12 6.1l1.71 4.04 4.38.38-3.32 2.88 1 4.28L12 15.4z"/>
    </svg>
  ''';

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        String svgString;
        IconData fallbackIcon;

        if (index < rating.floor()) {
          svgString = _starFullSvg;
          fallbackIcon = Icons.star;
        } else if (index < rating) {
          svgString = _starHalfSvg;
          fallbackIcon = Icons.star_half;
        } else {
          svgString = _starEmptySvg;
          fallbackIcon = Icons.star_border;
        }

        return SvgPicture.string(
          svgString,
          width: starSize,
          height: starSize,
          placeholderBuilder: (context) => Icon(
            fallbackIcon,
            color: starColor,
            size: starSize,
          ),
        );
      }),
    );
  }
}
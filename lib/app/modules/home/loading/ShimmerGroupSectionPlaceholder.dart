import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../themes/app_theme.dart';

class ShimmerGroupSectionPlaceholder extends StatelessWidget {
  final double horizontalPadding = 16.0;
  final double bannerHeight = 140.0;
  final double sectionHeight = 280.0;
  final double cardWidth = 90.0;
  final int cardCount = 6;

  const ShimmerGroupSectionPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(children: [
        // Banner Shimmer
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Shimmer.fromColors(
            baseColor: Colors.grey,
            highlightColor: Colors.grey,
            child: Container(
              height: bannerHeight,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Title Shimmer
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Shimmer.fromColors(
            baseColor: Colors.grey,
            highlightColor: Colors.grey,
            child: Container(
              width: 200,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(4.0),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Group Grid
        SizedBox(
          height: sectionHeight,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 14.0,
                childAspectRatio: 0.5,
              ),
              itemCount: cardCount,
              itemBuilder: (context, index) {
                return Shimmer.fromColors(
                  baseColor: Colors.grey,
                  highlightColor: Colors.grey,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
      ]),
    );
  }
}

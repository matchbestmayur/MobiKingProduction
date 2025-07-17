import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../themes/app_theme.dart';

class AddressCard extends StatefulWidget {
  final String addressText;
  final String recipientName;
  final String? phoneNumber;

  const AddressCard({
    Key? key,
    required this.addressText,
    required this.recipientName,
    this.phoneNumber,
  }) : super(key: key);

  @override
  State<AddressCard> createState() => _AddressCardState();
}

class _AddressCardState extends State<AddressCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _sizeAnimation;
  bool isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300), // Consistent with your theme's animation duration
    );
    _sizeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut, // Smooth curve for expansion/collapse
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      isExpanded = !isExpanded;
      if (isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: _toggleExpansion,
      child: Container(
        padding: const EdgeInsets.all(20), // Unchanged horizontal, consistent with original
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4), // Adjusted vertical margin
        decoration: BoxDecoration(
          color: AppColors.neutralBackground,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: AppColors.textDark.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Recipient Name
            Row(
              children: [
                const Icon(Icons.person_outline, color: AppColors.textDark, size: 24),
                const SizedBox(width: 12), // Unchanged horizontal spacing
                Expanded(
                  child: Text(
                    widget.recipientName,
                    style: textTheme.titleMedium?.copyWith(
                      // Changed to titleMedium for consistency with AppTheme
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 300),
                  turns: isExpanded ? 0.5 : 0.0,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textMedium,
                    size: 24,
                  ),
                ),
              ],
            ),

            /// Expandable Section
            SizeTransition(
              sizeFactor: _sizeAnimation,
              axis: Axis.vertical,
              axisAlignment: -1.0, // Start from top
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12), // Adjusted vertical spacing

                  /// Address Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.home_outlined, color: AppColors.textMedium, size: 22),
                      const SizedBox(width: 12), // Unchanged horizontal spacing
                      Expanded(
                        child: Text(
                          widget.addressText,
                          style: textTheme.bodyLarge?.copyWith(color: AppColors.textDark),
                        ),
                      ),
                    ],
                  ),

                  /// Phone Number
                  if (widget.phoneNumber != null && widget.phoneNumber!.isNotEmpty) ...[
                    const SizedBox(height: 12), // Adjusted vertical spacing
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined, color: AppColors.textMedium, size: 22),
                        const SizedBox(width: 12), // Unchanged horizontal spacing
                        Text(
                          widget.phoneNumber!,
                          style: textTheme.bodyLarge?.copyWith(color: AppColors.textDark),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
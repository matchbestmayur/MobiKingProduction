// lib/screens/product_page/widgets/collapsible_section.dart
import 'package:flutter/material.dart';
import 'package:mobiking/app/themes/app_theme.dart'; // Ensure this path is correct

class CollapsibleSection extends StatefulWidget {
  final String title;
  final Widget content;
  final bool initiallyExpanded;
  final Widget? trailing; // Optional trailing widget for the header

  const CollapsibleSection({
    super.key,
    required this.title,
    required this.content,
    this.initiallyExpanded = false,
    this.trailing,
  });

  @override
  State<CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<CollapsibleSection> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 0, // No elevation for a flatter look
      color: AppColors.neutralBackground, // Apply neutral background here
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          InkWell(
            onTap: _toggleExpansion,
            borderRadius: BorderRadius.circular(12), // Match card border
            splashFactory: InkRipple.splashFactory, // Nice ripple effect
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (widget.trailing != null) widget.trailing!,
                  RotationTransition(
                    turns: Tween(begin: 0.0, end: 0.5).animate(_animation),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textMedium,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _animation,
            axisAlignment: 0.0,
            child: FadeTransition(
              opacity: _animation,
              child: Offstage(
                offstage: !_isExpanded && _controller.isDismissed,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), // Adjusted padding
                  child: widget.content,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
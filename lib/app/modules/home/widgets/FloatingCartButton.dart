import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

// Assuming AppColors is defined in this path or accessible globally
import 'package:mobiking/app/themes/app_theme.dart';

class FloatingCartButton extends StatefulWidget {
  final VoidCallback onTap;
  final int itemCount;
  final String label; // e.g., "View Cart"
  final List<String> productImageUrls; // Max 3 images now

  const FloatingCartButton({
    super.key,
    required this.onTap,
    this.itemCount = 0,
    this.label = "View Cart",
    this.productImageUrls = const [],
  });

  @override
  State<FloatingCartButton> createState() => _FloatingCartButtonState();
}

class _FloatingCartButtonState extends State<FloatingCartButton>
    with TickerProviderStateMixin {
  // Animation controllers for general button scale (tap feedback)
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  // Animation controller for initial fade-in of the button
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Animation controllers and animations for individual product images
  // We will manage up to 3 image animations now
  final List<AnimationController> _imageControllers = [];
  final List<Animation<Offset>> _imageSlideAnimations = [];
  final List<Animation<double>> _imageScaleAnimations = [];

  @override
  void initState() {
    super.initState();

    // Initialize button scale animation for tap feedback
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Initialize button fade-in animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward(); // Start fade-in immediately

    // Initialize product image animations
    _initImageAnimations(widget.productImageUrls);
  }

  // Helper method to (re)initialize product image animations
  void _initImageAnimations(List<String> urls) {
    _disposeImageControllers(); // Dispose previous controllers to prevent memory leaks

    _imageControllers.clear();
    _imageSlideAnimations.clear();
    _imageScaleAnimations.clear();

    // Only animate up to the first 3 images now
    final effectiveUrls = urls.take(3).toList(); // Convert to List here

    for (int i = 0; i < effectiveUrls.length; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500), // Duration for each image animation
      );
      // Slide animation from slightly below to its final position
      final slideAnimation = Tween<Offset>(
        begin: const Offset(0, 0.6), // Starts slightly lower
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutBack, // Bouncy effect
      ));
      // Scale animation from smaller to full size
      final scaleAnimation = Tween<double>(
        begin: 0.7, // Starts smaller
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.elasticOut, // Elastic effect
      ));

      _imageControllers.add(controller);
      _imageSlideAnimations.add(slideAnimation);
      _imageScaleAnimations.add(scaleAnimation);

      // Add a slight staggered delay for each image
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) { // Check if the widget is still in the tree
          controller.forward();
        }
      });
    }
  }

  // Helper method to dispose of all image animation controllers
  void _disposeImageControllers() {
    for (final controller in _imageControllers) {
      controller.dispose();
    }
  }

  @override
  void didUpdateWidget(covariant FloatingCartButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reinitialize image animations if the list of product image URLs changes (e.g., items added/removed)
    if (widget.productImageUrls.length != oldWidget.productImageUrls.length ||
        !listEquals(widget.productImageUrls, oldWidget.productImageUrls)) {
      _initImageAnimations(widget.productImageUrls);
    }

    // Trigger scale animation when item count changes
    if (widget.itemCount != oldWidget.itemCount) {
      _scaleController.forward().then((_) => _scaleController.reverse());
    }
  }

  // Helper function to compare lists for `didUpdateWidget`
  bool listEquals<T>(List<T>? a, List<T>? b) {
    if (a == b) return true;
    if (a == null || b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _disposeImageControllers(); // Ensure image controllers are disposed
    super.dispose();
  }

  // Tap down feedback
  void _onTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  // Tap up feedback and callback
  void _onTapUp(TapUpDetails details) {
    _scaleController.reverse();
    widget.onTap.call();
  }

  // Tap cancel feedback
  void _onTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    // These values are tuned to match the reference image's visual spacing and size
    double imageSize = 40.0; // Larger image size
    double imageOverlap = 20.0; // Adjusted overlap for up to 3 images

    // Calculate the width needed for the overlapping image stack (max 3 images)
    final List<String> effectiveImageUrls = widget.productImageUrls.take(3).toList(); // Convert to List here
    double stackWidth = effectiveImageUrls.isNotEmpty
        ? imageSize + (effectiveImageUrls.length - 1) * imageOverlap
        : 0.0;

    return FadeTransition(
      opacity: _fadeAnimation, // Initial fade-in animation
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: ScaleTransition(
          scale: _scaleAnimation, // Tap feedback animation
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), // Adjusted padding for button size
            decoration: BoxDecoration(
              color: AppColors.success, // Solid green background
              borderRadius: BorderRadius.circular(35), // More rounded, stadium shape
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min, // Wrap content tightly
              mainAxisAlignment: MainAxisAlignment.center, // Center content horizontally
              children: [
                // Display product images if available
                if (effectiveImageUrls.isNotEmpty) ...[ // Use effectiveImageUrls here
                  SizedBox(
                    width: stackWidth,
                    height: imageSize,
                    child: Stack(
                      children: effectiveImageUrls.asMap().entries.map((entry) { // Use effectiveImageUrls here
                        int index = entry.key;
                        String url = entry.value;

                        // Ensure we don't go out of bounds for animations lists
                        final slideAnim = index < _imageSlideAnimations.length
                            ? _imageSlideAnimations[index]
                            : const AlwaysStoppedAnimation(Offset.zero);
                        final scaleAnim = index < _imageScaleAnimations.length
                            ? _imageScaleAnimations[index]
                            : const AlwaysStoppedAnimation(1.0);

                        return Positioned(
                          left: index * imageOverlap, // Control overlap
                          child: SlideTransition(
                            position: slideAnim,
                            child: ScaleTransition(
                              scale: scaleAnim,
                              child: Container( // Using Container for more control over border
                                width: imageSize,
                                height: imageSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey[800], // Background color while loading/error
                                  border: Border.all(color: Colors.white, width: 2.0), // White border around images
                                  image: DecorationImage(
                                    image: NetworkImage(url),
                                    fit: BoxFit.cover,
                                    // Add error handling for NetworkImage
                                    onError: (exception, stackTrace) {
                                      print('Error loading image: $url, $exception');
                                    },
                                  ),
                                ),
                                // Fallback for error or while loading (e.g., an icon)
                                child: (url.isEmpty || !url.startsWith('http')) ?
                                const Center(child: Icon(Icons.image_not_supported, color: Colors.white, size: 20)) : null,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(width: 12), // Spacing between images and text
                ],
                // Animated text for item count and label
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    final slideAnimation = Tween<Offset>(
                      begin: const Offset(0, 0.5),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOut,
                    ));
                    final fadeAnimation = CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeIn,
                    );
                    return FadeTransition(
                      opacity: fadeAnimation,
                      child: SlideTransition(
                        position: slideAnimation,
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    key: ValueKey<int>(widget.itemCount), // Key is essential for AnimatedSwitcher
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.label, // e.g., "View Cart"
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w700, // Make it bolder
                          fontSize: 16, // Larger font size for the main label
                        ),
                      ),
                      Text(
                        "${widget.itemCount} items", // e.g., "2 ITEMS"
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.8), // Slightly subdued color
                          fontWeight: FontWeight.w500, // Medium weight
                          fontSize: 12, // Smaller font size for item count
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16), // Spacing before the arrow icon
                // Right-facing arrow icon (chevron)
                const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18), // Chevron icon
              ],
            ),
          ),
        ),
      ),
    );
  }
}

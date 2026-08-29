import 'package:flutter/material.dart';
import '../../theme/tokens/theme_tokens.dart';

class AppSkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const AppSkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppRadius.borderMd,
  });

  const AppSkeletonLoader.rectangular({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppRadius.borderMd,
  });

  const AppSkeletonLoader.circular({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        borderRadius = AppRadius.borderFull;

  @override
  State<AppSkeletonLoader> createState() => _AppSkeletonLoaderState();
}

class _AppSkeletonLoaderState extends State<AppSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _opacityAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
              borderRadius: widget.borderRadius,
            ),
          ),
        );
      },
    );
  }
}

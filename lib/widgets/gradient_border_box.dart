import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class GradientBorderBox extends StatelessWidget {
  final Widget child;
  final double strokeWidth;
  final double borderRadius;
  final Gradient gradient;
  final Color backgroundColor;
  final EdgeInsetsGeometry padding;

  const GradientBorderBox({
    super.key,
    required this.child,
    this.strokeWidth = 2.0,
    this.borderRadius = 16.0,
    this.gradient = AppColors.twistBrandGradient,
    this.backgroundColor = AppColors.surface,
    this.padding = const EdgeInsets.all(2.0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Container(
        margin: EdgeInsets.all(strokeWidth),
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius - strokeWidth),
        ),
        child: child,
      ),
    );
  }
}

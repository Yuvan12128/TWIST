import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_typography.dart';

enum TwistButtonVariant {
  primaryGradient, // Yellow primary button (#FFD600)
  accentPink,      // Accent button
  glass,           // Clean secondary card button (#15151B + #27272A border)
  white,           // Clean white button (e.g. Continue with Google)
  danger,          // Error action
  gold,            // Highlight yellow
}

class TwistButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? icon;
  final TwistButtonVariant variant;
  final bool isLoading;
  final double? width;
  final double height;
  final double borderRadius;
  final TextStyle? textStyle;

  const TwistButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.variant = TwistButtonVariant.primaryGradient,
    this.isLoading = false,
    this.width,
    this.height = 50,
    this.borderRadius = 14,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    Gradient? gradient;
    Color? backgroundColor;
    Border? border;
    Color contentColor = Colors.white;

    switch (variant) {
      case TwistButtonVariant.primaryGradient:
        backgroundColor = AppColors.primaryYellow;
        contentColor = const Color(0xFF0B0B0F);
        break;
      case TwistButtonVariant.accentPink:
        backgroundColor = AppColors.secondaryYellow;
        contentColor = const Color(0xFF0B0B0F);
        break;
      case TwistButtonVariant.glass:
        backgroundColor = AppColors.cardBackground;
        border = Border.all(color: AppColors.border, width: 1);
        contentColor = Colors.white;
        break;
      case TwistButtonVariant.white:
        backgroundColor = Colors.white;
        contentColor = const Color(0xFF0B0B0F);
        break;
      case TwistButtonVariant.danger:
        backgroundColor = AppColors.error;
        contentColor = Colors.white;
        break;
      case TwistButtonVariant.gold:
        backgroundColor = AppColors.primaryYellow;
        contentColor = const Color(0xFF0B0B0F);
        break;
    }

    final effectiveHeight = height < 48 ? 48.0 : height;

    return Container(
      width: width,
      height: effectiveHeight,
      constraints: BoxConstraints(minHeight: effectiveHeight),
      decoration: BoxDecoration(
        gradient: gradient,
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(contentColor),
                      ),
                    )
                  : IconTheme(
                      data: IconThemeData(color: contentColor, size: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            icon!,
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Text(
                              text,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textStyle ??
                                  AppTypography.buttonText.copyWith(
                                    color: contentColor,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

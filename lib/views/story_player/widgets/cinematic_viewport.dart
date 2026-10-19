import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../widgets/cached_image.dart';

class CinematicViewport extends StatelessWidget {
  final String imageUrl;
  final String? speaker;
  final String? ambience;

  const CinematicViewport({
    super.key,
    required this.imageUrl,
    this.speaker,
    this.ambience,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final viewportHeight = (screenWidth * 0.62).clamp(180.0, 260.0);

    return Container(
      height: viewportHeight,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.background,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Scene Artwork
          CachedImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
          ),

          // Deep Cinematic Vignette Gradient Overlay
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0x99090A0F),
                  Colors.transparent,
                  Color(0xD9090A0F),
                  AppColors.background,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.35, 0.8, 1.0],
              ),
            ),
          ),

          // Ambient Location / Speaker Tags
          if (speaker != null || ambience != null)
            Positioned(
              bottom: 12,
              left: 16,
              right: 16,
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (speaker != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.background.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primaryYellow.withOpacity(0.6), width: 1),
                      ),
                      child: Text(
                        speaker!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.badgeText.copyWith(
                          color: AppColors.primaryYellow,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  if (ambience != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border, width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.graphic_eq_rounded, size: 12, color: AppColors.primaryYellow),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              ambience!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 10.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

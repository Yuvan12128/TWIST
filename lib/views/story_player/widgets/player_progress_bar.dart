import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/localization/app_localizations.dart';

class PlayerProgressBar extends StatelessWidget {
  final int currentScene;
  final int totalEstimatedScenes;
  final int choicesMade;

  const PlayerProgressBar({
    super.key,
    required this.currentScene,
    this.totalEstimatedScenes = 5,
    this.choicesMade = 0,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (currentScene / totalEstimatedScenes).clamp(0.1, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryYellow.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.primaryYellow.withOpacity(0.3), width: 1),
                  ),
                  child: Text(
                    '${context.tr('scene')} $currentScene',
                    style: AppTypography.badgeText.copyWith(
                      color: AppColors.primaryYellow,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${context.tr('of_scenes')} $totalEstimatedScenes',
                  style: AppTypography.caption.copyWith(color: AppColors.secondaryText, fontSize: 11),
                ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.touch_app_outlined, size: 13, color: AppColors.primaryYellow),
                const SizedBox(width: 4),
                Text(
                  '$choicesMade ${choicesMade == 1 ? context.tr('choice') : context.tr('choices')}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.secondaryText,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Clean Progress Track
        Container(
          height: 4,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    width: constraints.maxWidth * progress,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.primaryYellow,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

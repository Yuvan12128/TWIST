import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/language_provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/story_model.dart';
import '../../models/story_ending_model.dart';
import '../../core/services/share_service.dart';
import '../../widgets/cached_image.dart';
import '../../widgets/twist_button.dart';

class ShareChallengeDialog extends StatelessWidget {
  final StoryModel story;
  final StoryEndingModel ending;

  const ShareChallengeDialog({
    super.key,
    required this.story,
    required this.ending,
  });

  @override
  Widget build(BuildContext context) {
    final currentLang = context.watch<LanguageProvider>().currentLanguage;
    final localizedStoryTitle = story.localizedTitle(currentLang);
    final localizedEndingTitle = ending.localizedTitle(currentLang);

    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr('share_ending_title'),
                  style: AppTypography.screenTitle.copyWith(fontSize: 18),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Visual Share Card Preview
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: ending.isSecret
                    ? AppColors.secretEndingGradient
                    : AppColors.twistBrandGradient,
                boxShadow: [
                  BoxShadow(
                    color: (ending.isSecret ? AppColors.accentGold : AppColors.primaryPink).withOpacity(0.3),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(2.5),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    // Ending Preview Image
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: CachedImage(
                          imageUrl: ending.imageUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          if (ending.isSecret)
                            Text(
                              context.tr('i_got_secret_ending'),
                              style: AppTypography.brandTitle.copyWith(
                                fontSize: 16,
                                color: AppColors.accentGold,
                              ),
                            )
                          else
                            Text(
                              '${context.tr('ending_discovered')}: "$localizedEndingTitle" 🏆',
                              style: AppTypography.brandTitle.copyWith(fontSize: 16),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            context.tr('can_you_find_it'),
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${AppStrings.appName} • $localizedStoryTitle',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Share Buttons: WhatsApp, Instagram, Copy Link, Native Share
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSocialIcon(
                  label: 'WhatsApp',
                  icon: Icons.chat_rounded,
                  color: const Color(0xFF25D366),
                  onTap: () {
                    ShareService.shareEnding(
                      storyTitle: localizedStoryTitle,
                      endingTitle: localizedEndingTitle,
                      isSecret: ending.isSecret,
                      rarity: ending.rarity,
                    );
                  },
                ),
                _buildSocialIcon(
                  label: 'Instagram',
                  icon: Icons.camera_alt_rounded,
                  color: AppColors.primaryPink,
                  onTap: () {
                    ShareService.shareEnding(
                      storyTitle: localizedStoryTitle,
                      endingTitle: localizedEndingTitle,
                      isSecret: ending.isSecret,
                      rarity: ending.rarity,
                    );
                  },
                ),
                _buildSocialIcon(
                  label: 'Copy Link',
                  icon: Icons.copy_rounded,
                  color: AppColors.accentCyan,
                  onTap: () async {
                    await ShareService.copyToClipboard(
                      'Check out my "$localizedEndingTitle" ending in $localizedStoryTitle on TWIST! https://twist-stories.web.app/play',
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(context.tr('link_copied')),
                          backgroundColor: AppColors.primaryPurple,
                        ),
                      );
                    }
                  },
                ),
                _buildSocialIcon(
                  label: 'More',
                  icon: Icons.share_rounded,
                  color: AppColors.primaryBlue,
                  onTap: () {
                    ShareService.shareEnding(
                      storyTitle: localizedStoryTitle,
                      endingTitle: localizedEndingTitle,
                      isSecret: ending.isSecret,
                      rarity: ending.rarity,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Challenge a Friend Section
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  Text(
                    context.tr('challenge_friend_title'),
                    style: AppTypography.storyCardTitle.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.tr('challenge_friend_subtitle'),
                    textAlign: TextAlign.center,
                    style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  TwistButton(
                    text: context.tr('send_story_challenge'),
                    height: 42,
                    variant: TwistButtonVariant.primaryGradient,
                    onPressed: () {
                      ShareService.challengeFriend(
                        storyTitle: localizedStoryTitle,
                        storyId: story.id,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialIcon({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.4), width: 1),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTypography.caption.copyWith(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

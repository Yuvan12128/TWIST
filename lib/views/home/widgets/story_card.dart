import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/localization/language_provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/story_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/story_feed_provider.dart';
import '../../../core/services/share_service.dart';
import '../../../widgets/cached_image.dart';
import '../../../widgets/twist_button.dart';
import '../../story_detail/story_detail_screen.dart';
import '../../story_player/story_player_screen.dart';
import '../../profile/profile_screen.dart';
import 'comments_bottom_sheet.dart';

class StoryCard extends StatelessWidget {
  final StoryModel story;

  const StoryCard({super.key, required this.story});

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StoryDetailScreen(story: story),
      ),
    );
  }

  void _openPlayer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StoryPlayerScreen(story: story),
      ),
    );
  }

  void _showComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentsBottomSheet(story: story),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().user?.uid ?? 'guest';
    final currentLang = context.watch<LanguageProvider>().currentLanguage;
    final localizedTitle = story.localizedTitle(currentLang);
    final localizedDesc = story.localizedDescription(currentLang);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Creator Header Row
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                // Creator Avatar & Info (Tappable to view profile)
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (story.creatorId.isNotEmpty) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProfileScreen(userId: story.creatorId),
                          ),
                        );
                      }
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      children: [
                        // Creator Avatar
                        Container(
                          padding: const EdgeInsets.all(1.5),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.twistBrandGradient,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: story.creatorAvatar != null
                                ? CachedImage(
                                    imageUrl: story.creatorAvatar!,
                                    width: 38,
                                    height: 38,
                                  )
                                : Container(
                                    width: 38,
                                    height: 38,
                                    color: AppColors.surfaceLight,
                                    child: const Icon(Icons.person, color: AppColors.textMuted, size: 20),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Creator name & Category
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      story.creatorName,
                                      style: AppTypography.storyCardTitle.copyWith(fontSize: 14.5),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.verified, size: 14, color: AppColors.primaryBlue),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${story.categories.join(' • ')} • ${story.duration}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textMuted,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Quick Menu / More options
                IconButton(
                  icon: const Icon(Icons.more_horiz, color: AppColors.textMuted, size: 20),
                  onPressed: () => _openDetail(context),
                  tooltip: 'Story Details',
                ),
              ],
            ),
          ),

          // Cinematic Thumbnail with Interactive Badges & Tap to Play
          GestureDetector(
            onTap: () => _openDetail(context),
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: CachedImage(
                    imageUrl: story.coverUrl,
                    fit: BoxFit.cover,
                  ),
                ),

                // Gradient Vignette Overlay
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.storyCardBackdropGradient,
                    ),
                  ),
                ),

                // Top Left: Category Tag
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.category_outlined, size: 12, color: AppColors.primaryYellow),
                        const SizedBox(width: 4),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 110),
                          child: Text(
                            story.category.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.badgeText.copyWith(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Top Right: Endings Count Badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.alt_route_rounded, size: 13, color: AppColors.primaryYellow),
                        const SizedBox(width: 4),
                        Text(
                          '${story.endingsCount} ${context.tr('endings').toUpperCase()}',
                          style: AppTypography.badgeText.copyWith(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Left inside overlay: Plays counter
                Positioned(
                  bottom: 12,
                  left: 14,
                  child: Row(
                    children: [
                      const Icon(Icons.play_circle_outline_rounded, size: 16, color: AppColors.accentCyan),
                      const SizedBox(width: 5),
                      Text(
                        '${Formatters.compactNumber(story.plays)} ${context.tr('plays').toLowerCase()}',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Story Title & Description
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _openDetail(context),
                  child: Text(
                    localizedTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.storyCardTitle.copyWith(fontSize: 17),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  localizedDesc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.storyCardDescription,
                ),
              ],
            ),
          ),

          // Action Row: Likes, Comments, Share, Save (Optimized for 320-430px)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              children: [
                // Like Button
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  icon: Icon(
                    story.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: story.isLiked ? AppColors.primaryPink : AppColors.textSecondary,
                    size: 22,
                  ),
                  onPressed: () {
                    context.read<StoryFeedProvider>().toggleLike(story.id, userId);
                  },
                ),
                Text(
                  Formatters.compactNumber(story.likes),
                  style: AppTypography.caption.copyWith(
                    color: story.isLiked ? AppColors.primaryPink : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),

                // Comment Button
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  icon: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: () => _showComments(context),
                ),
                Text(
                  Formatters.compactNumber(story.commentsCount),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),

                // Share Button
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  icon: const Icon(
                    Icons.send_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: () {
                    ShareService.challengeFriend(
                      storyTitle: localizedTitle,
                      storyId: story.id,
                    );
                  },
                ),

                const Spacer(),

                // Save / Bookmark Button
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  icon: Icon(
                    story.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    color: story.isSaved ? AppColors.primaryYellow : AppColors.textSecondary,
                    size: 22,
                  ),
                  onPressed: () {
                    context.read<StoryFeedProvider>().toggleSave(story.id);
                  },
                ),
              ],
            ),
          ),

          // MAIN BUTTON: ▶ PLAY STORY
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
            child: TwistButton(
              text: '▶ ${context.tr('play_story')}',
              height: 48,
              variant: TwistButtonVariant.primaryGradient,
              borderRadius: 14,
              textStyle: AppTypography.buttonText.copyWith(
                fontSize: 14,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w800,
              ),
              onPressed: () => _openPlayer(context),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/language_provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/utils/formatters.dart';
import '../../models/story_model.dart';
import '../../providers/story_feed_provider.dart';
import '../../repositories/story_repository.dart';
import '../../core/services/share_service.dart';
import '../../widgets/cached_image.dart';
import '../../widgets/twist_button.dart';
import '../../widgets/glass_card.dart';
import '../story_player/story_player_screen.dart';
import '../ending/all_endings_screen.dart';
import '../profile/profile_screen.dart';

class StoryDetailScreen extends StatelessWidget {
  final StoryModel story;

  const StoryDetailScreen({super.key, required this.story});

  void _startStory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StoryPlayerScreen(story: story),
      ),
    );
  }

  void _viewAllEndings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AllEndingsScreen(story: story),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storyRepo = context.read<StoryRepository>();
    final unlockedIds = storyRepo.getUnlockedEndingIds(story.id);
    final isSaved = context.watch<StoryFeedProvider>().stories
            .firstWhere((s) => s.id == story.id, orElse: () => story)
            .isSaved;
    final currentLang = context.watch<LanguageProvider>().currentLanguage;
    final localizedTitle = story.localizedTitle(currentLang);
    final localizedDesc = story.localizedDescription(currentLang);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Cinematic Header Sliver
              SliverAppBar(
                expandedHeight: 380,
                pinned: true,
                backgroundColor: AppColors.background,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.background.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                actions: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.background.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.share_outlined, color: Colors.white, size: 20),
                    ),
                    onPressed: () {
                      ShareService.challengeFriend(
                        storyTitle: localizedTitle,
                        storyId: story.id,
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedImage(
                        imageUrl: story.coverUrl,
                        fit: BoxFit.cover,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              AppColors.background.withOpacity(0.5),
                              AppColors.background,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.3, 0.7, 1.0],
                          ),
                        ),
                      ),
                      // Positioned Category Tag
                      Positioned(
                        left: 20,
                        bottom: 24,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryYellow,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            story.category.toUpperCase(),
                            style: AppTypography.badgeText.copyWith(
                              color: const Color(0xFF0B0B0F),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Story Details Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Story Title
                      Text(
                        localizedTitle,
                        style: AppTypography.brandTitle.copyWith(fontSize: 26, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 12),

                      // Creator Info (Tappable to view creator profile)
                      GestureDetector(
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
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: story.creatorAvatar != null
                                  ? CachedImage(
                                      imageUrl: story.creatorAvatar!,
                                      width: 32,
                                      height: 32,
                                    )
                                  : Container(
                                      width: 32,
                                      height: 32,
                                      color: AppColors.surfaceLight,
                                      child: const Icon(Icons.person, color: AppColors.textMuted, size: 18),
                                    ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              context.tr('created_by'),
                              style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                story.creatorName,
                                style: AppTypography.storyCardTitle.copyWith(fontSize: 13.5),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, size: 14, color: AppColors.primaryBlue),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Stats Row: Endings, Duration, Plays, Likes
                      GlassCard(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                        child: Row(
                          children: [
                            Expanded(child: _buildStatItem('${story.endingsCount}', context.tr('endings'), Icons.alt_route_rounded, AppColors.primaryYellow)),
                            _buildDivider(),
                            Expanded(child: _buildStatItem(story.duration, context.tr('duration'), Icons.timer_outlined, AppColors.accentCyan)),
                            _buildDivider(),
                            Expanded(child: _buildStatItem(Formatters.compactNumber(story.plays), context.tr('plays'), Icons.play_arrow_rounded, AppColors.primaryBlue)),
                            _buildDivider(),
                            Expanded(child: _buildStatItem(Formatters.compactNumber(story.likes), context.tr('likes'), Icons.favorite_border_rounded, AppColors.primaryYellow)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Synopsis / Description
                      Text(
                        context.tr('synopsis'),
                        style: AppTypography.screenTitle.copyWith(fontSize: 17),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        localizedDesc,
                        style: AppTypography.storyCardDescription.copyWith(
                          fontSize: 14.5,
                          height: 1.6,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Endings Discovered Progress Card
                      GlassCard(
                        onTap: () => _viewAllEndings(context),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primaryYellow.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.emoji_events_outlined, color: AppColors.primaryYellow, size: 28),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${unlockedIds.length} ${context.tr('of_scenes')} ${story.endingsCount} ${context.tr('endings_found')}',
                                    style: AppTypography.storyCardTitle.copyWith(fontSize: 14.5),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    context.tr('discoverable_endings'),
                                    style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 16),
                          ],
                        ),
                      ),
                      const SizedBox(height: 160), // Bottom space for fixed action bar
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom Fixed Action Bar: Start Story, Save, Share
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  border: Border(top: BorderSide(color: AppColors.border, width: 1)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Full Width Primary CTA: ▶ Start Story
                    TwistButton(
                      width: double.infinity,
                      height: 52,
                      text: 'Start Story',
                      icon: const Icon(Icons.play_arrow_rounded, color: Color(0xFF0B0B0F), size: 24),
                      variant: TwistButtonVariant.primaryGradient,
                      textStyle: AppTypography.buttonText.copyWith(
                        color: const Color(0xFF0B0B0F),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                      onPressed: () => _startStory(context),
                    ),
                    const SizedBox(height: 12),

                    // Secondary Action Buttons: Save & Share (48px+ touch target)
                    Row(
                      children: [
                        Expanded(
                          child: TwistButton(
                            height: 48,
                            text: isSaved ? 'Saved' : 'Save',
                            icon: Icon(
                              isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                              color: isSaved ? AppColors.primaryYellow : Colors.white,
                              size: 18,
                            ),
                            variant: TwistButtonVariant.glass,
                            textStyle: AppTypography.buttonText.copyWith(
                              color: isSaved ? AppColors.primaryYellow : Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                            onPressed: () {
                              context.read<StoryFeedProvider>().toggleSave(story.id);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TwistButton(
                            height: 48,
                            text: 'Share',
                            icon: const Icon(Icons.share_outlined, color: Colors.white, size: 18),
                            variant: TwistButtonVariant.glass,
                            textStyle: AppTypography.buttonText.copyWith(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                            onPressed: () {
                              ShareService.challengeFriend(
                                storyTitle: localizedTitle,
                                storyId: story.id,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, Color iconColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.statNumber.copyWith(fontSize: 15),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.statLabel.copyWith(fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 32,
      color: AppColors.cardBorder,
    );
  }
}

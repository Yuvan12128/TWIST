import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/story_feed_provider.dart';
import '../../../widgets/cached_image.dart';

class StoryCircleItem {
  final String label;
  final String translationKey;
  final String? imageUrl;
  final IconData? icon;
  final bool isUser;
  final String categoryKey;

  const StoryCircleItem({
    required this.label,
    required this.translationKey,
    this.imageUrl,
    this.icon,
    this.isUser = false,
    required this.categoryKey,
  });
}

class StoryCirclesRow extends StatelessWidget {
  final ValueChanged<String>? onCategorySelected;
  final VoidCallback? onAddStoryTap;

  const StoryCirclesRow({
    super.key,
    this.onCategorySelected,
    this.onAddStoryTap,
  });

  static const List<StoryCircleItem> _storyCircles = [
    StoryCircleItem(
      label: 'Your Story',
      translationKey: 'your_story',
      isUser: true,
      categoryKey: 'mine',
    ),
    StoryCircleItem(
      label: 'Trending',
      translationKey: 'trending_genre',
      imageUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=300&auto=format&fit=crop&q=80',
      icon: Icons.local_fire_department_rounded,
      categoryKey: 'All',
    ),
    StoryCircleItem(
      label: 'Mystery',
      translationKey: 'mystery_genre',
      imageUrl: 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=300&auto=format&fit=crop&q=80',
      categoryKey: 'Mystery',
    ),
    StoryCircleItem(
      label: 'Horror',
      translationKey: 'horror_genre',
      imageUrl: 'https://images.unsplash.com/photo-1509248961158-e54f6934749c?w=300&auto=format&fit=crop&q=80',
      categoryKey: 'Horror',
    ),
    StoryCircleItem(
      label: 'Love',
      translationKey: 'love_genre',
      imageUrl: 'https://images.unsplash.com/photo-1508739773434-c26b3d09e071?w=300&auto=format&fit=crop&q=80',
      categoryKey: 'Love',
    ),
    StoryCircleItem(
      label: 'College',
      translationKey: 'college_genre',
      imageUrl: 'https://images.unsplash.com/photo-1523240795612-9a054b0db644?w=300&auto=format&fit=crop&q=80',
      categoryKey: 'College',
    ),
    StoryCircleItem(
      label: 'Comedy',
      translationKey: 'comedy_genre',
      imageUrl: 'https://images.unsplash.com/photo-1514306191717-452ec28c7814?w=300&auto=format&fit=crop&q=80',
      categoryKey: 'Comedy',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final currentCat = context.watch<StoryFeedProvider>().selectedCategory;
    final user = context.watch<AuthProvider>().user;

    return SizedBox(
      height: 104,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _storyCircles.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final item = _storyCircles[index];
          final isSelected = !item.isUser &&
              (currentCat.toLowerCase() == item.categoryKey.toLowerCase() ||
                  (item.label == 'Trending' && currentCat == 'All'));

          final localizedLabel = context.tr(item.translationKey);

          return GestureDetector(
            onTap: () {
              if (item.isUser) {
                if (onAddStoryTap != null) onAddStoryTap!();
              } else {
                context.read<StoryFeedProvider>().setCategory(item.categoryKey);
                if (onCategorySelected != null) {
                  onCategorySelected!(item.categoryKey);
                }
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Story Circle Avatar
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: item.isUser
                        ? null
                        : isSelected
                            ? AppColors.twistBrandGradient
                            : const LinearGradient(
                                colors: [AppColors.cardBorder, AppColors.surfaceElevated],
                              ),
                    border: item.isUser
                        ? Border.all(color: AppColors.cardBorder, width: 2)
                        : null,
                  ),
                  padding: const EdgeInsets.all(2.5),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface,
                    ),
                    padding: const EdgeInsets.all(2),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (item.isUser)
                            user?.photoUrl != null
                                ? CachedImage(imageUrl: user!.photoUrl!)
                                : const Center(
                                    child: Icon(Icons.person_rounded, color: AppColors.textMuted, size: 28),
                                  )
                          else if (item.imageUrl != null)
                            CachedImage(imageUrl: item.imageUrl!)
                          else
                            Container(color: AppColors.surfaceLight),

                          // Plus icon overlay for user story
                          if (item.isUser)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  gradient: AppColors.twistBrandGradient,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Label
                SizedBox(
                  width: 78,
                  child: Text(
                    localizedLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTypography.caption.copyWith(
                      color: isSelected ? AppColors.primaryPink : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

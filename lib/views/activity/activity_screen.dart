import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/utils/formatters.dart';
import '../../providers/activity_provider.dart';
import '../../providers/story_feed_provider.dart';
import '../../widgets/cached_image.dart';
import '../../widgets/glass_card.dart';
import '../story_detail/story_detail_screen.dart';
import '../profile/profile_screen.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ActivityProvider>().loadActivities();
      }
    });
  }

  static const List<String> _filters = [
    'All',
    'Like',
    'Follow',
    'Challenge',
    'Achievement',
    'Milestone',
  ];

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'like':
        return Icons.favorite_rounded;
      case 'comment':
        return Icons.chat_bubble_rounded;
      case 'follow':
        return Icons.person_add_rounded;
      case 'challenge':
        return Icons.sports_martial_arts_rounded;
      case 'achievement':
        return Icons.emoji_events_rounded;
      case 'milestone':
        return Icons.local_fire_department_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'like':
        return AppColors.primaryPink;
      case 'comment':
        return AppColors.accentCyan;
      case 'follow':
        return AppColors.primaryBlue;
      case 'challenge':
        return AppColors.accentOrange;
      case 'achievement':
        return AppColors.accentGold;
      case 'milestone':
        return AppColors.primaryPurple;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activityProv = context.watch<ActivityProvider>();
    final activities = activityProv.activities;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          context.tr('activity_title'),
          style: AppTypography.screenTitle.copyWith(fontSize: 22),
        ),
        actions: [
          TextButton(
            onPressed: () => activityProv.markAllAsRead(),
            child: Text(
              context.tr('mark_all_read'),
              style: AppTypography.caption.copyWith(
                color: AppColors.primaryYellow,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Pills (Matching Reference Panel 9)
            SizedBox(
              height: 42,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = activityProv.selectedFilter.toLowerCase() == filter.toLowerCase();

                return GestureDetector(
                  onTap: () => activityProv.setFilter(filter),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryYellow : AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryYellow : AppColors.border,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        filter,
                        style: AppTypography.caption.copyWith(
                          color: isSelected ? const Color(0xFF0B0B0F) : AppColors.secondaryText,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Activities List
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primaryYellow,
              backgroundColor: AppColors.surface,
              onRefresh: () async {
                await activityProv.loadActivities(forceRefresh: true);
              },
              child: activityProv.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
                      ),
                    )
                  : activities.isEmpty
                      ? LayoutBuilder(
                          builder: (context, constraints) => SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minHeight: constraints.maxHeight),
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.notifications_none_rounded, size: 48, color: AppColors.textPlaceholder),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No notifications yet',
                                        style: AppTypography.storyCardTitle.copyWith(fontSize: 16),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        context.tr('no_activity_yet'),
                                        textAlign: TextAlign.center,
                                        style: AppTypography.storyCardDescription.copyWith(color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                          itemCount: activities.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = activities[index];
                            final icon = _getIconForType(item.type);
                            final color = _getColorForType(item.type);

                            return GlassCard(
                              onTap: () {
                                activityProv.markAsRead(item.id);
                                if (item.type.toLowerCase() == 'follow' && item.actorId != null && item.actorId!.isNotEmpty) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ProfileScreen(userId: item.actorId),
                                    ),
                                  );
                                } else if (item.storyId != null) {
                                  final stories = context.read<StoryFeedProvider>().stories;
                                  final match = stories.where((s) => s.id == item.storyId);
                                  if (match.isNotEmpty) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => StoryDetailScreen(story: match.first),
                                      ),
                                    );
                                  }
                                }
                              },
                              padding: const EdgeInsets.all(14),
                              borderRadius: 18,
                              color: AppColors.cardBackground,
                              border: Border.all(
                                color: item.isRead ? AppColors.border : AppColors.primaryYellow.withOpacity(0.5),
                                width: 1,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Leading Icon Badge / Avatar
                                  Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: item.avatarUrl != null
                                            ? CachedImage(
                                                imageUrl: item.avatarUrl!,
                                                width: 44,
                                                height: 44,
                                              )
                                            : Container(
                                                width: 44,
                                                height: 44,
                                                decoration: BoxDecoration(
                                                  color: color.withOpacity(0.18),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(icon, color: color, size: 22),
                                              ),
                                      ),
                                      if (item.avatarUrl != null)
                                        Positioned(
                                          right: 0,
                                          bottom: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(3),
                                            decoration: BoxDecoration(
                                              color: color,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(icon, color: Colors.white, size: 10),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 14),

                                  // Title, Subtitle, Time
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTypography.storyCardTitle.copyWith(
                                            fontSize: 14,
                                            fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          item.subtitle,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTypography.storyCardDescription.copyWith(
                                            fontSize: 12.5,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          Formatters.timeAgo(item.createdAt),
                                          style: AppTypography.caption.copyWith(
                                            color: AppColors.textMuted,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Unread Dot
                                  if (!item.isRead)
                                    Container(
                                      margin: const EdgeInsets.only(top: 6),
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.primaryYellow,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}

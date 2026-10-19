import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/utils/formatters.dart';
import '../../models/story_model.dart';
import '../../providers/story_feed_provider.dart';
import '../../widgets/cached_image.dart';
import '../../widgets/twist_app_bar.dart';
import '../story_detail/story_detail_screen.dart';
import '../chat/chats_screen.dart';
import 'widgets/story_card.dart';

class HomeFeedScreen extends StatefulWidget {
  final VoidCallback? onSearchTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onAddStoryTap;

  const HomeFeedScreen({
    super.key,
    this.onSearchTap,
    this.onNotificationTap,
    this.onAddStoryTap,
  });

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  final List<({String key, String trKey})> _feedTabs = const [
    (key: 'For You', trKey: 'for_you'),
    (key: 'Trending', trKey: 'trending'),
    (key: 'Following', trKey: 'following'),
  ];

  static const List<({String name, IconData icon, Color color})> _categoriesList = [
    (name: 'Love', icon: Icons.favorite_rounded, color: Color(0xFFEF4444)),
    (name: 'Horror', icon: Icons.nightlight_round, color: Color(0xFFA855F7)),
    (name: 'Mystery', icon: Icons.psychology_rounded, color: AppColors.primaryYellow),
    (name: 'College', icon: Icons.school_rounded, color: Color(0xFF3B82F6)),
    (name: 'Thriller', icon: Icons.local_fire_department_rounded, color: Color(0xFFF97316)),
    (name: 'Comedy', icon: Icons.sentiment_very_satisfied_rounded, color: Color(0xFF22C55E)),
  ];

  void _openStory(StoryModel story) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StoryDetailScreen(story: story),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedProv = context.watch<StoryFeedProvider>();
    final stories = feedProv.stories;
    final isLoading = feedProv.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: TwistAppBar(
        onSearchTap: widget.onSearchTap,
        onNotificationTap: widget.onNotificationTap,
        onChatTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ChatsScreen()),
          );
        },
      ),
      body: RefreshIndicator(
        color: AppColors.primaryYellow,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          await feedProv.loadStories();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // 1. Feed Tabs: For You | Trending | Following
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.border, width: 0.8),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: _feedTabs.map((tab) {
                      final isSelected = feedProv.currentTab == tab.key;
                      return GestureDetector(
                        onTap: () => feedProv.setTab(tab.key),
                        child: Container(
                          margin: const EdgeInsets.only(right: 22),
                          padding: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            border: isSelected
                                ? const Border(
                                    bottom: BorderSide(
                                      color: AppColors.primaryYellow,
                                      width: 2.2,
                                    ),
                                  )
                                : null,
                          ),
                          child: Text(
                            tab.key,
                            style: AppTypography.screenTitle.copyWith(
                              fontSize: 15,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? AppColors.primaryYellow : AppColors.secondaryText,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

            // 2. Stories for You Section Header & Carousel (rendered when stories are available)
            if (stories.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Stories for You',
                        style: AppTypography.screenTitle.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      GestureDetector(
                        onTap: widget.onSearchTap,
                        child: const Text(
                          'See all',
                          style: TextStyle(
                            color: AppColors.primaryYellow,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2b. Horizontal Posters Carousel
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 185,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: stories.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final story = stories[index];
                      return GestureDetector(
                        onTap: () => _openStory(story),
                        child: Container(
                          width: 125,
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border, width: 1),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CachedImage(
                                  imageUrl: story.coverUrl,
                                  fit: BoxFit.cover,
                                ),
                                Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Color(0x990B0B0F),
                                        Color(0xF00B0B0F),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      stops: [0.35, 0.7, 1.0],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 10,
                                  left: 8,
                                  right: 8,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        story.title,
                                        style: AppTypography.storyCardTitle.copyWith(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.play_circle_outline_rounded, size: 12, color: AppColors.primaryYellow),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              '${Formatters.compactNumber(story.plays)} plays',
                                              style: AppTypography.caption.copyWith(
                                                color: AppColors.secondaryText,
                                                fontSize: 10.5,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],

            // 3. Categories Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Categories',
                      style: AppTypography.screenTitle.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onSearchTap,
                      child: const Text(
                        'See all',
                        style: TextStyle(
                          color: AppColors.primaryYellow,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3b. Categories Horizontal Row (Love, Horror, Mystery, College, Thriller)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 80,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _categoriesList.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final cat = _categoriesList[index];
                    final isSelected = feedProv.selectedCategory.toLowerCase() == cat.name.toLowerCase();

                    return GestureDetector(
                      onTap: () {
                        if (isSelected) {
                          feedProv.setCategory('All');
                        } else {
                          feedProv.setCategory(cat.name);
                        }
                      },
                      child: Container(
                        width: 72,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.surfaceLight : AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppColors.primaryYellow : AppColors.border,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(cat.icon, color: cat.color, size: 24),
                            const SizedBox(height: 6),
                            Text(
                              cat.name,
                              style: AppTypography.caption.copyWith(
                                color: isSelected ? Colors.white : AppColors.secondaryText,
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // 4. Trending Stories Section Header (rendered when stories are available)
            if (stories.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 22, 16, 6),
                  child: Text(
                    'Trending Stories',
                    style: AppTypography.screenTitle.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

            // Feed List or Loading / Empty States
            if (isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
                  ),
                ),
              )
            else if (stories.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 36.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.border, width: 1),
                          ),
                          child: Icon(
                            (feedProv.selectedCategory != 'All' || feedProv.searchQuery.trim().isNotEmpty)
                                ? Icons.search_off_rounded
                                : Icons.auto_stories_rounded,
                            size: 44,
                            color: AppColors.primaryYellow,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          (feedProv.selectedCategory != 'All' || feedProv.searchQuery.trim().isNotEmpty)
                              ? context.tr('no_matching_stories')
                              : 'No Published Stories Yet',
                          style: AppTypography.screenTitle.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          (feedProv.selectedCategory != 'All' || feedProv.searchQuery.trim().isNotEmpty)
                              ? context.tr('search_clear_hint')
                              : 'Stories published on TWIST will appear here.\nPull down to refresh or check back soon.',
                          textAlign: TextAlign.center,
                          style: AppTypography.storyCardDescription.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                        if (feedProv.selectedCategory != 'All' || feedProv.searchQuery.trim().isNotEmpty) ...[
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              feedProv.setCategory('All');
                              feedProv.setSearchQuery('');
                            },
                            child: Text(
                              context.tr('show_all_stories'),
                              style: const TextStyle(
                                color: AppColors.primaryYellow,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final story = stories[index];
                    return StoryCard(story: story);
                  },
                  childCount: stories.length,
                ),
              ),

            // Bottom Spacing for navigation bar
            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),
    );
  }
}

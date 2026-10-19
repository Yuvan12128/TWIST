import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/language_provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/utils/formatters.dart';
import '../../models/story_model.dart';
import '../../models/user_model.dart';
import '../../providers/story_feed_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/cached_image.dart';
import '../../widgets/glass_card.dart';
import '../story_detail/story_detail_screen.dart';
import '../profile/profile_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedTabIndex = 0; // 0 = Stories, 1 = Storytellers
  List<UserModel> _userSearchResults = [];
  bool _isSearchingUsers = false;

  static const List<({String key, String trKey})> _categories = [
    (key: 'All', trKey: 'trending_genre'),
    (key: 'Love', trKey: 'love_genre'),
    (key: 'Horror', trKey: 'horror_genre'),
    (key: 'Mystery', trKey: 'mystery_genre'),
    (key: 'Comedy', trKey: 'comedy_genre'),
    (key: 'College', trKey: 'college_genre'),
    (key: 'Action', trKey: 'action_genre'),
    (key: 'Fantasy', trKey: 'fantasy_genre'),
    (key: 'Real Life', trKey: 'real_life_genre'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openDetail(BuildContext context, StoryModel story) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StoryDetailScreen(story: story),
      ),
    );
  }

  Future<void> _searchStorytellers(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() {
        _userSearchResults = [];
        _isSearchingUsers = false;
      });
      return;
    }

    setState(() {
      _isSearchingUsers = true;
    });

    try {
      final results = await context.read<ProfileProvider>().searchUsers(q);
      if (mounted) {
        setState(() {
          _userSearchResults = results;
          _isSearchingUsers = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _userSearchResults = [];
          _isSearchingUsers = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedProv = context.watch<StoryFeedProvider>();
    final stories = feedProv.stories;
    final selectedCategory = feedProv.selectedCategory;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Explore Header Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Explore',
                    style: AppTypography.screenTitle.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),

            // Search Bar Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: _selectedTabIndex == 0
                        ? context.tr('search_hint')
                        : 'Search storytellers by name or handle...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              if (_selectedTabIndex == 0) {
                                feedProv.setSearchQuery('');
                              } else {
                                _searchStorytellers('');
                              }
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (val) {
                    if (_selectedTabIndex == 0) {
                      feedProv.setSearchQuery(val);
                    } else {
                      _searchStorytellers(val);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Mode Selector: Stories | Storytellers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (_selectedTabIndex != 0) {
                            setState(() => _selectedTabIndex = 0);
                            feedProv.setSearchQuery(_searchController.text);
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: _selectedTabIndex == 0 ? AppColors.primaryYellow : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              'Stories',
                              style: TextStyle(
                                color: _selectedTabIndex == 0 ? const Color(0xFF0B0B0F) : AppColors.secondaryText,
                                fontWeight: _selectedTabIndex == 0 ? FontWeight.bold : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (_selectedTabIndex != 1) {
                            setState(() => _selectedTabIndex = 1);
                            _searchStorytellers(_searchController.text);
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: _selectedTabIndex == 1 ? AppColors.primaryYellow : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              'Storytellers',
                              style: TextStyle(
                                color: _selectedTabIndex == 1 ? const Color(0xFF0B0B0F) : AppColors.secondaryText,
                                fontWeight: _selectedTabIndex == 1 ? FontWeight.bold : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Tab 0: Stories View
            if (_selectedTabIndex == 0) ...[
              // Horizontal Categories Filter Chips
              SizedBox(
                height: 44,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final catItem = _categories[index];
                    final isSelected = selectedCategory.toLowerCase() == catItem.key.toLowerCase();

                    return GestureDetector(
                      onTap: () {
                        feedProv.setCategory(catItem.key);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                            catItem.key == 'All' ? 'All' : catItem.key,
                            style: AppTypography.caption.copyWith(
                              color: isSelected ? const Color(0xFF0B0B0F) : AppColors.secondaryText,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),

              // 2-Column Stories Grid
              Expanded(
                child: feedProv.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
                        ),
                      )
                    : stories.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32.0),
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
                                      (selectedCategory != 'All' || _searchController.text.trim().isNotEmpty)
                                          ? Icons.search_off_rounded
                                          : Icons.auto_stories_rounded,
                                      size: 40,
                                      color: AppColors.primaryYellow,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    (selectedCategory != 'All' || _searchController.text.trim().isNotEmpty)
                                        ? context.tr('no_matching_stories')
                                        : 'No Published Stories Yet',
                                    style: AppTypography.screenTitle.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    (selectedCategory != 'All' || _searchController.text.trim().isNotEmpty)
                                        ? context.tr('search_clear_hint')
                                        : 'Interactive stories will appear here once published.',
                                    textAlign: TextAlign.center,
                                    style: AppTypography.storyCardDescription.copyWith(color: AppColors.textMuted, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final width = constraints.maxWidth;
                              final childAspectRatio = width < 340 ? 0.62 : (width < 380 ? 0.68 : 0.72);
                              final spacing = width < 340 ? 10.0 : 14.0;

                              return GridView.builder(
                                padding: EdgeInsets.fromLTRB(
                                  width < 340 ? 12 : 16,
                                  8,
                                  width < 340 ? 12 : 16,
                                  90,
                                ),
                                physics: const BouncingScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: spacing,
                                  mainAxisSpacing: spacing,
                                  childAspectRatio: childAspectRatio,
                                ),
                                itemCount: stories.length,
                                itemBuilder: (context, index) {
                                  final story = stories[index];
                                  return _buildExploreCard(context, story);
                                },
                              );
                            },
                          ),
              ),
            ] else ...[
              // Tab 1: Storytellers (People) View
              Expanded(
                child: _isSearchingUsers
                    ? const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
                        ),
                      )
                    : _searchController.text.trim().isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32.0),
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
                                    child: const Icon(
                                      Icons.person_search_rounded,
                                      size: 40,
                                      color: AppColors.primaryYellow,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Discover Storytellers',
                                    style: AppTypography.screenTitle.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Search creators by name or username handle to view their profile and stories.',
                                    textAlign: TextAlign.center,
                                    style: AppTypography.storyCardDescription.copyWith(color: AppColors.textMuted, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _userSearchResults.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
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
                                        child: const Icon(
                                          Icons.person_off_rounded,
                                          size: 40,
                                          color: AppColors.primaryYellow,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No Storytellers Found',
                                        style: AppTypography.screenTitle.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'No creator matched "${_searchController.text.trim()}". Try another name or handle.',
                                        textAlign: TextAlign.center,
                                        style: AppTypography.storyCardDescription.copyWith(color: AppColors.textMuted, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                                physics: const BouncingScrollPhysics(),
                                itemCount: _userSearchResults.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final user = _userSearchResults[index];
                                  final email = user.email;
                                  final username = (email.contains('@'))
                                      ? email.split('@').first
                                      : user.displayName.toLowerCase().replaceAll(' ', '');

                                  return GlassCard(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => ProfileScreen(
                                            userId: user.uid,
                                            initialUser: user,
                                          ),
                                        ),
                                      );
                                    },
                                    padding: const EdgeInsets.all(12),
                                    borderRadius: 16,
                                    child: Row(
                                      children: [
                                        // User Avatar
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColors.surfaceLight,
                                            border: Border.all(color: AppColors.border, width: 1),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(24),
                                            child: user.photoUrl != null
                                                ? CachedImage(
                                                    imageUrl: user.photoUrl!,
                                                    width: 48,
                                                    height: 48,
                                                  )
                                                : const Icon(Icons.person, color: AppColors.textMuted, size: 26),
                                          ),
                                        ),
                                        const SizedBox(width: 14),

                                        // Name & Handle
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      user.displayName.isNotEmpty
                                                          ? user.displayName
                                                          : 'Storyteller',
                                                      style: AppTypography.storyCardTitle.copyWith(fontSize: 14.5),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (user.isVerified) ...[
                                                    const SizedBox(width: 4),
                                                    const Icon(Icons.verified, size: 14, color: AppColors.primaryBlue),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '@$username',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppTypography.caption.copyWith(
                                                  color: AppColors.textMuted,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // View Profile Chevron
                                        const Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          color: AppColors.textMuted,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                    ),
                                  );
                                },
                              ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExploreCard(BuildContext context, StoryModel story) {
    final currentLang = context.watch<LanguageProvider>().currentLanguage;
    final localizedTitle = story.localizedTitle(currentLang);

    return GestureDetector(
      onTap: () => _openDetail(context, story),
      child: Container(
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
              // Cover Image
              CachedImage(
                imageUrl: story.coverUrl,
                fit: BoxFit.cover,
              ),

              // Gradient Overlay
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Color(0x800B0B0F),
                      Color(0xF50B0B0F),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.3, 0.65, 1.0],
                  ),
                ),
              ),

              // Top Right: Endings badge
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.alt_route_rounded, size: 11, color: AppColors.primaryYellow),
                      const SizedBox(width: 3),
                      Text(
                        '${story.endingsCount}',
                        style: AppTypography.badgeText.copyWith(color: Colors.white, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Details: Title, Category, Plays
              Positioned(
                bottom: 12,
                left: 10,
                right: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryYellow.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        story.category.toUpperCase(),
                        style: AppTypography.badgeText.copyWith(
                          color: AppColors.primaryYellow,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      localizedTitle,
                      style: AppTypography.storyCardTitle.copyWith(fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.play_circle_fill_rounded, size: 13, color: AppColors.accentCyan),
                        const SizedBox(width: 4),
                        Text(
                          '${Formatters.compactNumber(story.plays)} ${context.tr('plays').toLowerCase()}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
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
  }
}

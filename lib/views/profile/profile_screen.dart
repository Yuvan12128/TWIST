import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../models/story_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/story_feed_provider.dart';
import '../../widgets/cached_image.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/twist_button.dart';
import '../story_detail/story_detail_screen.dart';
import '../auth/login_screen.dart';
import '../settings/settings_screen.dart';
import '../../core/localization/language_provider.dart';
import '../../core/localization/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadProfileData();
    });
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to sign out?', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Logout', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<AuthProvider>().signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  void _showModalList({required String title, required Widget child}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                title,
                style: AppTypography.screenTitle.copyWith(fontSize: 18),
              ),
            ),
            const Divider(color: AppColors.border, height: 1),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();
    final user = authProv.user;
    final profileProv = context.watch<ProfileProvider>();

    final email = user?.email;
    final username = (email != null && email.contains('@'))
        ? email.split('@').first
        : 'username';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Profile',
          style: AppTypography.screenTitle.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 24),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            tooltip: 'Settings',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        children: [
          // 1. Centered Avatar
          Center(
            child: Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceLight,
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(43),
                child: user?.photoUrl != null
                    ? CachedImage(
                        imageUrl: user!.photoUrl!,
                        width: 86,
                        height: 86,
                      )
                    : const Icon(
                        Icons.person,
                        color: AppColors.textMuted,
                        size: 48,
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 2. User Name & Username
          Center(
            child: Text(
              user?.displayName ?? 'Your Name',
              style: AppTypography.brandTitle.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              '@$username',
              style: AppTypography.caption.copyWith(
                color: AppColors.secondaryText,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 3. Stats Row (Stories | Followers | Following) Matching Reference Panel 10
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Row(
              children: [
                Expanded(child: _buildStatColumn('${profileProv.storiesPlayedCount > 0 ? profileProv.storiesPlayedCount : 12}', 'Stories')),
                Container(width: 1, height: 30, color: AppColors.border),
                Expanded(child: _buildStatColumn('120', 'Followers')),
                Container(width: 1, height: 30, color: AppColors.border),
                Expanded(child: _buildStatColumn('85', 'Following')),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. Menu Items List Matching Reference Panel 10
          _buildMenuItem(
            icon: Icons.auto_stories_outlined,
            title: 'My Stories',
            onTap: () => _showModalList(
              title: 'My Stories',
              child: _buildMyStoriesTab(context),
            ),
          ),
          const SizedBox(height: 8),

          _buildMenuItem(
            icon: Icons.bookmark_border_rounded,
            title: 'Saved',
            onTap: () => _showModalList(
              title: 'Saved Stories',
              child: _buildSavedTab(context, profileProv.savedStories),
            ),
          ),
          const SizedBox(height: 8),

          _buildMenuItem(
            icon: Icons.history_rounded,
            title: 'History',
            onTap: () => _showModalList(
              title: 'History',
              child: _buildHistoryTab(context, profileProv.historyStories),
            ),
          ),
          const SizedBox(height: 8),

          _buildMenuItem(
            icon: Icons.emoji_events_outlined,
            title: 'Achievements',
            onTap: () => _showModalList(
              title: 'Achievements',
              child: _buildAchievementsTab(context, profileProv.achievements),
            ),
          ),
          const SizedBox(height: 8),

          _buildMenuItem(
            icon: Icons.settings_outlined,
            title: 'Settings',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(height: 8),

          _buildMenuItem(
            icon: Icons.help_outline_rounded,
            title: 'Help & Support',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Support email: help@twist.app'),
                  backgroundColor: AppColors.cardBackground,
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          _buildMenuItem(
            icon: Icons.logout_rounded,
            title: 'Logout',
            isDestructive: true,
            onTap: _signOut,
          ),
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isDestructive ? AppColors.error : Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isDestructive ? AppColors.error : Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String number, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          number,
          style: AppTypography.statNumber.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTypography.statLabel.copyWith(fontSize: 10.5),
        ),
      ],
    );
  }

  Widget _buildMyStoriesTab(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.twistBrandGradient,
                ),
                child: const Icon(Icons.draw_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 14),
              Text(
                'Story Studio Drafts',
                style: AppTypography.storyCardTitle.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                'You have 1 draft story in progress: "The Midnight Dormitory"',
                textAlign: TextAlign.center,
                style: AppTypography.storyCardDescription.copyWith(color: AppColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TwistButton(
                text: 'Open Story Creator',
                height: 42,
                variant: TwistButtonVariant.primaryGradient,
                onPressed: () {
                  // Switch to Create tab
                  DefaultTabController.of(context).animateTo(2);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSavedTab(BuildContext context, List<StoryModel> stories) {
    if (stories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bookmark_border_rounded, size: 48, color: AppColors.textPlaceholder),
            const SizedBox(height: 12),
            Text('No saved stories yet', style: AppTypography.storyCardTitle.copyWith(fontSize: 16)),
            const SizedBox(height: 4),
            Text('Bookmark stories from the feed to play them later.', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.72,
      ),
      itemCount: stories.length,
      itemBuilder: (context, index) {
        final story = stories[index];
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => StoryDetailScreen(story: story)),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedImage(imageUrl: story.coverUrl, fit: BoxFit.cover),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Color(0xCC090A0F)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 10,
                  right: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        story.localizedTitle(context.watch<LanguageProvider>().currentLanguage),
                        style: AppTypography.storyCardTitle.copyWith(fontSize: 13.5),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${story.endingsCount} ${context.tr('endings')} • ${story.category}',
                        style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab(BuildContext context, List<StoryModel> stories) {
    final displayStories = stories.isNotEmpty
        ? stories
        : context.watch<StoryFeedProvider>().stories;
    final currentLang = context.watch<LanguageProvider>().currentLanguage;

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: displayStories.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final story = displayStories[index];
        return GlassCard(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => StoryDetailScreen(story: story)),
            );
          },
          padding: const EdgeInsets.all(12),
          borderRadius: 18,
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedImage(
                  imageUrl: story.coverUrl,
                  width: 60,
                  height: 60,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      story.localizedTitle(currentLang),
                      style: AppTypography.storyCardTitle.copyWith(fontSize: 14.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${story.category} • ${Formatters.compactNumber(story.plays)} ${context.tr('plays').toLowerCase()}',
                      style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14),
              const SizedBox(width: 4),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAchievementsTab(BuildContext context, List<AchievementBadge> badges) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: badges.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final badge = badges[index];

        return GlassCard(
          padding: const EdgeInsets.all(16),
          borderRadius: 18,
          border: Border.all(
            color: badge.isUnlocked ? AppColors.accentGold.withOpacity(0.5) : AppColors.cardBorder,
            width: badge.isUnlocked ? 1.2 : 1,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: badge.isUnlocked
                      ? AppColors.accentGold.withOpacity(0.18)
                      : AppColors.surfaceLight,
                  border: Border.all(
                    color: badge.isUnlocked ? AppColors.accentGold : AppColors.cardBorder,
                  ),
                ),
                child: Center(
                  child: Text(
                    badge.icon,
                    style: TextStyle(
                      fontSize: 22,
                      color: badge.isUnlocked ? null : Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          badge.title,
                          style: AppTypography.storyCardTitle.copyWith(
                            fontSize: 15,
                            color: badge.isUnlocked ? Colors.white : AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (badge.isUnlocked)
                          const Icon(Icons.check_circle_rounded, color: AppColors.accentGold, size: 16),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      badge.description,
                      style: AppTypography.caption.copyWith(
                        color: badge.isUnlocked ? AppColors.textSecondary : AppColors.textPlaceholder,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                badge.isUnlocked ? 'UNLOCKED' : 'LOCKED',
                style: AppTypography.badgeText.copyWith(
                  color: badge.isUnlocked ? AppColors.accentGold : AppColors.textPlaceholder,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

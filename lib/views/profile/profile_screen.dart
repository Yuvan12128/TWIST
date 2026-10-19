import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/services/firebase_service.dart';
import '../../core/utils/formatters.dart';
import '../../models/story_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/story_feed_provider.dart';
import '../../widgets/cached_image.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/twist_button.dart';
import '../story_detail/story_detail_screen.dart';
import '../create/create_story_screen.dart';
import '../auth/login_screen.dart';
import '../settings/settings_screen.dart';
import '../chat/chat_screen.dart';
import '../../providers/chat_provider.dart';
import '../../core/localization/language_provider.dart';
import '../../core/localization/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;
  final UserModel? initialUser;

  const ProfileScreen({
    super.key,
    this.userId,
    this.initialUser,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // State for viewing another user's profile
  UserModel? _otherUser;
  bool _isLoadingOther = false;
  bool _isFollowing = false;
  bool _followActionLoading = false;
  int _otherFollowersCount = 0;
  int _otherFollowingCount = 0;
  List<StoryModel> _otherStories = [];
  bool _openingChat = false;
  int _selectedTab = 0;

  bool get _isSelf {
    final authUser = context.read<AuthProvider>().user;
    final currentUid = authUser?.uid ?? FirebaseService.auth?.currentUser?.uid;
    if (widget.userId == null || widget.userId == currentUid) {
      return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isSelf) {
        context.read<ProfileProvider>().loadProfileData();
      } else {
        _loadOtherUserProfile();
      }
    });
  }

  Future<void> _loadOtherUserProfile() async {
    final targetId = widget.userId;
    if (targetId == null || targetId.isEmpty) return;

    setState(() {
      _isLoadingOther = true;
      if (widget.initialUser != null) {
        _otherUser = widget.initialUser;
      }
    });

    final profileProv = context.read<ProfileProvider>();
    final results = await Future.wait([
      profileProv.getUserProfile(targetId),
      profileProv.isFollowing(targetId),
      profileProv.getFollowersCount(targetId),
      profileProv.getFollowingCount(targetId),
      profileProv.getUserStories(targetId),
    ]);

    if (!mounted) return;

    final fetchedUser = results[0] as UserModel?;
    setState(() {
      if (fetchedUser != null) {
        _otherUser = fetchedUser;
      }
      _isFollowing = results[1] as bool;
      _otherFollowersCount = results[2] as int;
      _otherFollowingCount = results[3] as int;
      _otherStories = results[4] as List<StoryModel>;
      _isLoadingOther = false;
    });
  }

  Future<void> _toggleFollow() async {
    final targetId = widget.userId;
    if (targetId == null || _followActionLoading) return;

    final currentUser = context.read<AuthProvider>().user;
    final wasFollowing = _isFollowing;

    // Optimistic UI update
    setState(() {
      _isFollowing = !wasFollowing;
      _otherFollowersCount = wasFollowing
          ? (_otherFollowersCount - 1).clamp(0, 999999)
          : _otherFollowersCount + 1;
      _followActionLoading = true;
    });

    final profileProv = context.read<ProfileProvider>();
    bool success;
    if (wasFollowing) {
      success = await profileProv.unfollowUser(targetId);
    } else {
      success = await profileProv.followUser(targetId, currentUser: currentUser);
    }

    if (!mounted) return;

    if (!success) {
      // Revert if failed
      setState(() {
        _isFollowing = wasFollowing;
        _otherFollowersCount = wasFollowing
            ? _otherFollowersCount + 1
            : (_otherFollowersCount - 1).clamp(0, 999999);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update follow status. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }

    setState(() {
      _followActionLoading = false;
    });
  }

  Future<void> _openChatWithUser(UserModel targetUser) async {
    final currentUser = context.read<AuthProvider>().user;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to send messages.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (currentUser.uid == targetUser.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot message yourself.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _openingChat = true);
    final chatProv = context.read<ChatProvider>();
    final conv = await chatProv.openConversation(
      currentUser: currentUser,
      otherUser: targetUser,
    );

    if (!mounted) return;
    setState(() => _openingChat = false);

    if (conv != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversation: conv,
            otherUser: targetUser,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open conversation. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
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
    if (!_isSelf) {
      return _buildOtherUserProfile(context);
    }

    final authProv = context.watch<AuthProvider>();
    final user = authProv.user;
    final profileProv = context.watch<ProfileProvider>();

    final email = user?.email;
    final username = (email != null && email.contains('@'))
        ? email.split('@').first
        : (user?.displayName.toLowerCase().replaceAll(' ', '') ?? 'user');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline_rounded, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              username,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined, color: Colors.white, size: 24),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateStoryScreen()),
              );
            },
            tooltip: 'Create Story',
          ),
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
            onPressed: () => _showMenuBottomSheet(context),
            tooltip: 'Menu',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => profileProv.loadProfileData(),
        color: AppColors.primaryYellow,
        backgroundColor: AppColors.cardBackground,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          children: [
            // 1. Instagram Profile Header (Avatar + 3 Stats Side-by-Side)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  // Avatar with Instagram-style Glowing Story Ring
                  Stack(
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        padding: const EdgeInsets.all(2.5),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryYellow,
                              Color(0xFFFF9500),
                              Color(0xFFFF416C),
                            ],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.background,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: user?.photoUrl != null
                                ? CachedImage(
                                    imageUrl: user!.photoUrl!,
                                    width: 78,
                                    height: 78,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(
                                    Icons.person,
                                    color: AppColors.textMuted,
                                    size: 42,
                                  ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const CreateStoryScreen()),
                            );
                          },
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppColors.primaryYellow,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.background, width: 2),
                            ),
                            child: const Icon(Icons.add, size: 14, color: Color(0xFF0B0B0F)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 18),

                  // 3 Instagram Stat Columns: Stories | Followers | Following
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildInstagramStat(
                          '${profileProv.myStories.length}',
                          'Stories',
                          onTap: () => setState(() => _selectedTab = 0),
                        ),
                        _buildInstagramStat(
                          '${profileProv.followersCount}',
                          'Followers',
                          onTap: _showFollowersModal,
                        ),
                        _buildInstagramStat(
                          '${profileProv.followingCount}',
                          'Following',
                          onTap: _showFollowingModal,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. Name & Bio Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.displayName ?? 'Your Name',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Storyteller • Interactive Fiction Creator',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  if (user?.bio != null && user!.bio.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      user.bio,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 4),
                    const Text(
                      'Welcome to my TWIST profile! Explore my branching interactive stories below 📖✨',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 3. Instagram Action Buttons: Edit Profile | Share Profile | Settings
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildInstagramButton(
                      'Edit profile',
                      onTap: () => _showEditProfileModal(context, user),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInstagramButton(
                      'Share profile',
                      onTap: () => _shareProfile(username: username, name: user?.displayName),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildInstagramIconButton(
                    Icons.settings_outlined,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 4. Instagram Story Highlights Bar
            _buildStoryHighlights(),
            const SizedBox(height: 12),

            // 5. Instagram Tabs (Grid | Saved | Achievements)
            _buildInstagramTabBar(isSelf: true),

            // 6. Tab Content
            if (_selectedTab == 0)
              _buildStoriesGrid(profileProv.myStories, isSelf: true)
            else if (_selectedTab == 1)
              _buildSavedTab(context, profileProv.savedStories)
            else
              _buildAchievementsTab(context, profileProv.achievements),

            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  /// Screen view when viewing another user's profile
  Widget _buildOtherUserProfile(BuildContext context) {
    final user = _otherUser;
    final email = user?.email;
    final username = (email != null && email.contains('@'))
        ? email.split('@').first
        : (user?.displayName.toLowerCase().replaceAll(' ', '') ?? 'storyteller');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          user?.displayName ?? 'Storyteller',
          style: AppTypography.screenTitle.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white, size: 22),
            onPressed: () => _shareProfile(username: username, name: user?.displayName),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoadingOther && user == null
          ? const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
              ),
            )
          : ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                // 1. Instagram Profile Header (Avatar + 3 Stats)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      // Avatar with Instagram Ring
                      Container(
                        width: 84,
                        height: 84,
                        padding: const EdgeInsets.all(2.5),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryYellow,
                              Color(0xFFFF9500),
                              Color(0xFFFF416C),
                            ],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.background,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: user?.photoUrl != null
                                ? CachedImage(
                                    imageUrl: user!.photoUrl!,
                                    width: 78,
                                    height: 78,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(
                                    Icons.person,
                                    color: AppColors.textMuted,
                                    size: 42,
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),

                      // 3 Instagram Stat Columns
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildInstagramStat(
                              '${_otherStories.length}',
                              'Stories',
                            ),
                            _buildInstagramStat(
                              '$_otherFollowersCount',
                              'Followers',
                            ),
                            _buildInstagramStat(
                              '$_otherFollowingCount',
                              'Following',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Name, Handle & Bio
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              user?.displayName ?? 'TWIST Storyteller',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (user?.isVerified == true) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, size: 16, color: AppColors.primaryBlue),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@$username',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.secondaryText,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Storyteller',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      if (user?.bio != null && user!.bio.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          user.bio,
                          style: AppTypography.storyCardDescription.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 3. Instagram Action Buttons: Follow + Message
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TwistButton(
                          text: _isFollowing ? '✓ Following' : '+ Follow',
                          height: 38,
                          variant: _isFollowing ? TwistButtonVariant.glass : TwistButtonVariant.primaryGradient,
                          isLoading: _followActionLoading,
                          onPressed: _toggleFollow,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TwistButton(
                          text: 'Message',
                          height: 38,
                          variant: TwistButtonVariant.glass,
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Colors.white),
                          isLoading: _openingChat,
                          onPressed: user != null ? () => _openChatWithUser(user) : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildInstagramIconButton(
                        Icons.share_outlined,
                        onTap: () => _shareProfile(username: username, name: user?.displayName),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 4. Stories Section Header (Keeps 'Published Stories' for test compatibility!)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Published Stories',
                        style: AppTypography.screenTitle.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${_otherStories.length}',
                        style: AppTypography.caption.copyWith(color: AppColors.primaryYellow, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // 5. Instagram 3-Column Stories Grid
                _buildStoriesGrid(_otherStories, isSelf: false),
                const SizedBox(height: 36),
              ],
            ),
    );
  }

  Widget _buildInstagramStat(String count, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstagramButton(String label, {required VoidCallback onTap, Widget? icon}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                icon,
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstagramIconButton(IconData icon, {required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  Widget _buildStoryHighlights() {
    final highlights = [
      {'title': 'New', 'isAdd': true, 'emoji': ''},
      {'title': 'Top Plots', 'isAdd': false, 'emoji': '🏆'},
      {'title': 'Mysteries', 'isAdd': false, 'emoji': '🔍'},
      {'title': 'Endings', 'isAdd': false, 'emoji': '⚡'},
    ];

    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: highlights.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final h = highlights[index];
          final isAdd = h['isAdd'] as bool;

          return GestureDetector(
            onTap: () {
              if (isAdd) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateStoryScreen()),
                );
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isAdd ? AppColors.border : AppColors.primaryYellow.withOpacity(0.6),
                      width: 1.5,
                    ),
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.cardBackground,
                    ),
                    child: Center(
                      child: isAdd
                          ? const Icon(Icons.add, color: Colors.white, size: 22)
                          : Text(h['emoji'] as String, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  h['title'] as String,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInstagramTabBar({required bool isSelf}) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.8),
          bottom: BorderSide(color: AppColors.border, width: 0.8),
        ),
      ),
      child: Row(
        children: [
          // Grid Tab
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _selectedTab == 0 ? AppColors.primaryYellow : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Icon(
                  Icons.grid_on_sharp,
                  color: _selectedTab == 0 ? AppColors.primaryYellow : AppColors.textMuted,
                  size: 22,
                ),
              ),
            ),
          ),
          if (isSelf) ...[
            // Saved Tab
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _selectedTab = 1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: _selectedTab == 1 ? AppColors.primaryYellow : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Icon(
                    Icons.bookmark_border_rounded,
                    color: _selectedTab == 1 ? AppColors.primaryYellow : AppColors.textMuted,
                    size: 22,
                  ),
                ),
              ),
            ),
            // Achievements Tab
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _selectedTab = 2),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: _selectedTab == 2 ? AppColors.primaryYellow : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Icon(
                    Icons.emoji_events_outlined,
                    color: _selectedTab == 2 ? AppColors.primaryYellow : AppColors.textMuted,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStoriesGrid(List<StoryModel> stories, {required bool isSelf}) {
    if (stories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: const Icon(Icons.auto_stories_outlined, size: 32, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            Text(
              isSelf ? 'Share Your First Story' : 'No Stories Yet',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isSelf
                  ? 'When you publish interactive branching stories, they will appear on your profile grid.'
                  : 'This storyteller has not published any stories yet.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
            if (isSelf) ...[
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CreateStoryScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryYellow,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '+ Create Story',
                    style: TextStyle(
                      color: Color(0xFF0B0B0F),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 0.8,
      ),
      itemBuilder: (context, index) {
        final story = stories[index];
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => StoryDetailScreen(story: story)),
            );
          },
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
                    colors: [Colors.transparent, Color(0xDD000000)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.5, 1.0],
                  ),
                ),
              ),
              Positioned(
                left: 6,
                right: 6,
                bottom: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      story.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.play_arrow_rounded, color: AppColors.primaryYellow, size: 13),
                        const SizedBox(width: 2),
                        Text(
                          Formatters.compactNumber(story.plays),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (story.endingsCount > 1)
                Positioned(
                  top: 5,
                  right: 5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.call_split_rounded, size: 10, color: AppColors.primaryYellow),
                        const SizedBox(width: 2),
                        Text(
                          '${story.endingsCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showFollowersModal() {
    _showModalList(
      title: 'Followers',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.people_outline_rounded, size: 48, color: AppColors.primaryYellow),
              const SizedBox(height: 12),
              Text(
                'Followers (${context.read<ProfileProvider>().followersCount})',
                style: AppTypography.storyCardTitle.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 6),
              const Text(
                'Users who follow your interactive story releases.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFollowingModal() {
    _showModalList(
      title: 'Following',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_add_outlined, size: 48, color: AppColors.primaryYellow),
              const SizedBox(height: 12),
              Text(
                'Following (${context.read<ProfileProvider>().followingCount})',
                style: AppTypography.storyCardTitle.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 6),
              const Text(
                'Storytellers you follow across TWIST.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareProfile({String? username, String? name}) {
    final handle = username ?? 'storyteller';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Profile link copied: twist.app/@$handle'),
        backgroundColor: AppColors.cardBackground,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showMenuBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined, color: Colors.white),
                title: const Text('Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.history_rounded, color: Colors.white),
                title: const Text('Story History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showModalList(
                    title: 'History',
                    child: _buildHistoryTab(context, context.read<ProfileProvider>().historyStories),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.help_outline_rounded, color: Colors.white),
                title: const Text('Help & Support', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Support email: help@twist.app'),
                      backgroundColor: AppColors.cardBackground,
                    ),
                  );
                },
              ),
              const Divider(color: AppColors.border, height: 16),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                title: const Text('Logout', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _signOut();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProfileModal(BuildContext context, UserModel? user) {
    if (user == null) return;
    final nameController = TextEditingController(text: user.displayName);
    final bioController = TextEditingController(text: user.bio);
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Edit Profile',
                        style: AppTypography.screenTitle.copyWith(fontSize: 18),
                      ),
                      TextButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                final newName = nameController.text.trim();
                                final newBio = bioController.text.trim();
                                if (newName.isEmpty) return;

                                setModalState(() => isSaving = true);
                                await context.read<AuthProvider>().updateProfile(
                                      displayName: newName,
                                      bio: newBio,
                                    );
                                if (ctx.mounted) {
                                  Navigator.of(ctx).pop();
                                }
                              },
                        child: isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
                                ),
                              )
                            : const Text(
                                'Done',
                                style: TextStyle(
                                  color: AppColors.primaryYellow,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Name',
                      labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      filled: true,
                      fillColor: AppColors.surfaceLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.primaryYellow),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bioController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Bio',
                      labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      filled: true,
                      fillColor: AppColors.surfaceLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.primaryYellow),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
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

    if (displayStories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history_rounded, size: 48, color: AppColors.textPlaceholder),
            const SizedBox(height: 12),
            Text('No history yet', style: AppTypography.storyCardTitle.copyWith(fontSize: 16)),
            const SizedBox(height: 4),
            Text('Stories you play will appear here.', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
          ],
        ),
      );
    }

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

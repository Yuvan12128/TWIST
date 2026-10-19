import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_typography.dart';
import '../providers/activity_provider.dart';
import 'home/home_feed_screen.dart';
import 'explore/explore_screen.dart';
import 'create/create_story_screen.dart';
import 'activity/activity_screen.dart';
import 'profile/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  late final Set<int> _loadedTabs;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _loadedTabs = {_currentIndex};
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
      _loadedTabs.add(index);
    });
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return HomeFeedScreen(
          onSearchTap: () => _onTabTapped(1),
          onNotificationTap: () => _onTabTapped(3),
          onAddStoryTap: () => _onTabTapped(2),
        );
      case 1:
        return const ExploreScreen();
      case 2:
        return const CreateStoryScreen();
      case 3:
        return const ActivityScreen();
      case 4:
        return const ProfileScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = context.watch<ActivityProvider>().unreadCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: List<Widget>.generate(5, (index) {
          if (_loadedTabs.contains(index)) {
            return _buildScreen(index);
          }
          return const SizedBox.shrink();
        }),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 62,
          decoration: const BoxDecoration(
            color: AppColors.cardBackground,
            border: Border(
              top: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Tab 1: Home
              _buildNavItem(
                index: 0,
                icon: Icons.home_filled,
                inactiveIcon: Icons.home_outlined,
                label: 'Home',
              ),

              // Tab 2: Explore
              _buildNavItem(
                index: 1,
                icon: Icons.explore_rounded,
                inactiveIcon: Icons.explore_outlined,
                label: 'Explore',
              ),

              // Tab 3: Create
              _buildNavItem(
                index: 2,
                icon: Icons.add_circle_rounded,
                inactiveIcon: Icons.add_circle_outline_rounded,
                label: 'Create',
              ),

              // Tab 4: Activity
              _buildNavItem(
                index: 3,
                icon: Icons.notifications_rounded,
                inactiveIcon: Icons.notifications_none_rounded,
                label: 'Activity',
                badgeCount: unreadCount,
              ),

              // Tab 5: Profile
              _buildNavItem(
                index: 4,
                icon: Icons.person_rounded,
                inactiveIcon: Icons.person_outline_rounded,
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData inactiveIcon,
    required String label,
    int badgeCount = 0,
  }) {
    final isSelected = _currentIndex == index;
    final itemColor = isSelected ? AppColors.primaryYellow : AppColors.secondaryText;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onTabTapped(index),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    isSelected ? icon : inactiveIcon,
                    color: itemColor,
                    size: 22,
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      right: -6,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3.5),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryYellow,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  color: itemColor,
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

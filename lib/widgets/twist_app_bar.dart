import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_typography.dart';
import '../providers/activity_provider.dart';

class TwistAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onNotificationTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onChatTap;
  final bool showBack;
  final String? titleText;
  final List<Widget>? actions;

  const TwistAppBar({
    super.key,
    this.onNotificationTap,
    this.onSearchTap,
    this.onChatTap,
    this.showBack = false,
    this.titleText,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
      title: titleText != null
          ? Text(
              titleText!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.screenTitle.copyWith(fontSize: 20),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'TWIST',
                  style: AppTypography.brandTitle.copyWith(
                    color: AppColors.primaryYellow,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
      actions: actions ??
          [
            if (onSearchTap != null)
              IconButton(
                icon: const Icon(Icons.search_rounded, color: AppColors.textPrimary, size: 24),
                onPressed: onSearchTap,
                tooltip: 'Search',
              ),
            if (onNotificationTap != null)
              Consumer<ActivityProvider>(
                builder: (context, activityProv, child) {
                  final unread = activityProv.unreadCount;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary, size: 24),
                        onPressed: onNotificationTap,
                        tooltip: 'Activity',
                      ),
                      if (unread > 0)
                        Positioned(
                          right: 10,
                          top: 10,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.twistBrandGradient,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            if (onChatTap != null)
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.textPrimary, size: 22),
                onPressed: onChatTap,
                tooltip: 'Chats',
              ),
            const SizedBox(width: 8),
          ],
    );
  }
}

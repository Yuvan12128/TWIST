import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_typography.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _hapticsEnabled = true;
  bool _dataSaver = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Settings',
          style: AppTypography.screenTitle.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // 1. Edit Profile
          _buildCardItem(
            icon: Icons.person_outline_rounded,
            title: 'Edit Profile',
            subtitle: 'Change name, username, and bio',
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.secondaryText),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Edit Profile coming in next update'),
                  backgroundColor: AppColors.cardBackground,
                ),
              );
            },
          ),
          const SizedBox(height: 10),

          // 2. Notifications
          _buildCardItem(
            icon: Icons.notifications_none_rounded,
            title: 'Notifications',
            subtitle: 'Push alerts for story branches and updates',
            trailing: Switch(
              value: _notificationsEnabled,
              activeColor: AppColors.primaryYellow,
              activeTrackColor: AppColors.primaryYellow.withOpacity(0.3),
              inactiveThumbColor: AppColors.secondaryText,
              inactiveTrackColor: AppColors.surfaceElevated,
              onChanged: (val) => setState(() => _notificationsEnabled = val),
            ),
            onTap: () => setState(() => _notificationsEnabled = !_notificationsEnabled),
          ),
          const SizedBox(height: 10),

          // 3. Privacy
          _buildCardItem(
            icon: Icons.lock_outline_rounded,
            title: 'Privacy',
            subtitle: 'Control who can view your story plays and history',
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.secondaryText),
            onTap: () => _showPrivacyDialog(context),
          ),
          const SizedBox(height: 10),

          // 4. Data Usage
          _buildCardItem(
            icon: Icons.data_usage_rounded,
            title: 'Data Usage',
            subtitle: 'Data saver & media download settings',
            trailing: Switch(
              value: _dataSaver,
              activeColor: AppColors.primaryYellow,
              activeTrackColor: AppColors.primaryYellow.withOpacity(0.3),
              inactiveThumbColor: AppColors.secondaryText,
              inactiveTrackColor: AppColors.surfaceElevated,
              onChanged: (val) => setState(() => _dataSaver = val),
            ),
            onTap: () => setState(() => _dataSaver = !_dataSaver),
          ),
          const SizedBox(height: 10),

          // 5. Sound & Haptics (Story Experience)
          _buildCardItem(
            icon: Icons.volume_up_outlined,
            title: 'Sound & Audio Effects',
            subtitle: 'Cinematic music and sound transitions',
            trailing: Switch(
              value: _soundEnabled,
              activeColor: AppColors.primaryYellow,
              activeTrackColor: AppColors.primaryYellow.withOpacity(0.3),
              inactiveThumbColor: AppColors.secondaryText,
              inactiveTrackColor: AppColors.surfaceElevated,
              onChanged: (val) => setState(() => _soundEnabled = val),
            ),
            onTap: () => setState(() => _soundEnabled = !_soundEnabled),
          ),
          const SizedBox(height: 10),

          _buildCardItem(
            icon: Icons.vibration_rounded,
            title: 'Haptic Feedback',
            subtitle: 'Vibrate on dramatic choices and branch endings',
            trailing: Switch(
              value: _hapticsEnabled,
              activeColor: AppColors.primaryYellow,
              activeTrackColor: AppColors.primaryYellow.withOpacity(0.3),
              inactiveThumbColor: AppColors.secondaryText,
              inactiveTrackColor: AppColors.surfaceElevated,
              onChanged: (val) => setState(() => _hapticsEnabled = val),
            ),
            onTap: () => setState(() => _hapticsEnabled = !_hapticsEnabled),
          ),
          const SizedBox(height: 10),

          // 6. Help & Support
          _buildCardItem(
            icon: Icons.help_outline_rounded,
            title: 'Help & Support',
            subtitle: 'FAQs, report an issue, contact TWIST team',
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.secondaryText),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Support email: support@twist.app'),
                  backgroundColor: AppColors.cardBackground,
                ),
              );
            },
          ),
          const SizedBox(height: 10),

          // 7. About TWIST
          _buildCardItem(
            icon: Icons.info_outline_rounded,
            title: 'About TWIST',
            subtitle: 'Version 1.0.0 (English Edition)',
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.secondaryText),
            onTap: () => _showAboutDialog(context),
          ),
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  Widget _buildCardItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required Widget trailing,
    required VoidCallback onTap,
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
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.primaryYellow, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryYellow.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.bolt, color: AppColors.primaryYellow, size: 22),
            ),
            const SizedBox(width: 12),
            const Text(
              AppStrings.appName,
              style: TextStyle(color: AppColors.primaryYellow, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppStrings.appTagline,
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'TWIST is an interactive entertainment social platform. Your choices shape the narrative and lead to unique story endings.',
              style: TextStyle(color: AppColors.secondaryText, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.border),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Version', style: TextStyle(color: AppColors.secondaryText, fontSize: 13)),
                Text(
                  '1.0.0 (V1)',
                  style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Close',
              style: TextStyle(color: AppColors.primaryYellow, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Text(
          'Privacy Settings',
          style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Your profile and completed story endings are visible to the community. You can play stories anonymously as a Guest at any time.',
          style: TextStyle(color: AppColors.secondaryText, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Done',
              style: TextStyle(color: AppColors.primaryYellow, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}


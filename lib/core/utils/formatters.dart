import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';

class Formatters {
  Formatters._();

  static String compactNumber(int count) {
    if (count >= 1000000) {
      double millions = count / 1000000;
      return '${millions.toStringAsFixed(millions.truncateToDouble() == millions ? 0 : 1)}M';
    } else if (count >= 1000) {
      double thousands = count / 1000;
      return '${thousands.toStringAsFixed(thousands.truncateToDouble() == thousands ? 0 : 1)}K';
    }
    return count.toString();
  }

  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('MMM d').format(dateTime);
    } else if (difference.inDays >= 1) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  static Color getRarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'secret':
        return AppColors.accentGold;
      case 'rare':
        return AppColors.primaryPink;
      case 'uncommon':
        return AppColors.primaryPurple;
      case 'common':
      default:
        return AppColors.primaryBlue;
    }
  }

  static LinearGradient getRarityGradient(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'secret':
        return AppColors.secretEndingGradient;
      case 'rare':
        return AppColors.pinkPurpleGradient;
      case 'uncommon':
        return AppColors.bluePurpleGradient;
      case 'common':
      default:
        return const LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.accentCyan],
        );
    }
  }
}

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
    final difference = now.difference(dateTime.toLocal());

    if (difference.isNegative || difference.inSeconds < 45) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(dateTime.toLocal());
    }
  }

  /// Formats exact time for chat message bubbles (e.g. "1:25 PM")
  static String chatMessageTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime.toLocal());
  }

  /// Formats day separators for chat timeline (e.g. "Today", "Yesterday", "Monday, Oct 19")
  static String chatDateSeparator(DateTime dateTime) {
    final local = dateTime.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(local.year, local.month, local.day);
    final diffDays = today.difference(messageDate).inDays;

    if (diffDays == 0) {
      return 'Today';
    } else if (diffDays == 1) {
      return 'Yesterday';
    } else if (diffDays < 7 && diffDays > 0) {
      return DateFormat('EEEE').format(local);
    } else if (local.year == now.year) {
      return DateFormat('EEEE, MMM d').format(local);
    } else {
      return DateFormat('MMM d, yyyy').format(local);
    }
  }

  /// Formats timestamp for conversation list items (e.g. "1:25 PM", "Yesterday", "Oct 19")
  static String chatListTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(local.year, local.month, local.day);
    final diffDays = today.difference(messageDate).inDays;

    if (diffDays == 0) {
      return DateFormat('h:mm a').format(local);
    } else if (diffDays == 1) {
      return 'Yesterday';
    } else if (diffDays < 7 && diffDays > 0) {
      return DateFormat('EEE').format(local);
    } else if (local.year == now.year) {
      return DateFormat('MMM d').format(local);
    } else {
      return DateFormat('dd/MM/yy').format(local);
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

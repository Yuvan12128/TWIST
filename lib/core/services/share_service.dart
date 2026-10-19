import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  ShareService._();

  static Future<void> shareEnding({
    required String storyTitle,
    required String endingTitle,
    required bool isSecret,
    required String rarity,
  }) async {
    final secretTag = isSecret ? ' 🔐 SECRET ENDING FOUND!' : '';
    final text = 'I just reached the "$endingTitle" ending ($rarity)$secretTag in "$storyTitle" on TWIST!\n\n'
        'Every decision changes everything. Can you beat my path?\n\n'
        'Play TWIST now: https://twist-stories.web.app/play';

    await Share.share(text, subject: 'My TWIST Ending: $endingTitle');
  }

  static Future<void> challengeFriend({
    required String storyTitle,
    required String storyId,
  }) async {
    final text = '⚔️ Story Challenge on TWIST!\n\n'
        'I challenge you to play "$storyTitle".\n'
        'Same story. Different choice. What ending will you get?\n\n'
        'Take the challenge: https://twist-stories.web.app/story/$storyId';

    await Share.share(text, subject: 'TWIST Challenge: $storyTitle');
  }

  static Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }
}

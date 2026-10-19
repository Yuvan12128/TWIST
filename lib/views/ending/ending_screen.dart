import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/language_provider.dart';
import '../../models/story_model.dart';
import '../../models/story_ending_model.dart';
import '../../widgets/cached_image.dart';
import '../../widgets/twist_button.dart';
import 'all_endings_screen.dart';
import 'share_challenge_dialog.dart';

class EndingScreen extends StatelessWidget {
  final StoryModel story;
  final StoryEndingModel ending;
  final int choicesCount;

  const EndingScreen({
    super.key,
    required this.story,
    required this.ending,
    required this.choicesCount,
  });

  void _tryOtherEndings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AllEndingsScreen(story: story),
      ),
    );
  }

  void _shareEnding(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => ShareChallengeDialog(story: story, ending: ending),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLang = context.watch<LanguageProvider>().currentLanguage;
    final localizedEndingTitle = ending.localizedTitle(currentLang);
    final localizedEndingDesc = ending.localizedDescription(currentLang);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Cinematic Ending Artwork Card
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(21),
                  child: AspectRatio(
                    aspectRatio: 16 / 11,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedImage(
                          imageUrl: ending.imageUrl,
                          fit: BoxFit.cover,
                        ),
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Color(0x660B0B0F),
                                Color(0xEE0B0B0F),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: [0.4, 0.75, 1.0],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Yellow Ending Pill Badge (Matching Reference Panel 6)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'ENDING ${ending.id.split('_').last.replaceAll('ending', '')}'.trim().isEmpty
                      ? 'ENDING 1'
                      : 'ENDING ${ending.id.split('_').last.replaceAll('ending', '').toUpperCase()}',
                  style: AppTypography.badgeText.copyWith(
                    color: const Color(0xFF0B0B0F),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Ending Title
              Text(
                localizedEndingTitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.brandTitle.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),

              // Ending Narrative Short Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  localizedEndingDesc,
                  textAlign: TextAlign.center,
                  style: AppTypography.storyCardDescription.copyWith(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Buttons Matching Reference Panel 6:
              // 1. Primary Action: Try Other Endings (Bright Yellow)
              TwistButton(
                width: double.infinity,
                height: 52,
                text: 'Try Other Endings',
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0B0B0F), size: 22),
                variant: TwistButtonVariant.primaryGradient,
                textStyle: AppTypography.buttonText.copyWith(
                  color: const Color(0xFF0B0B0F),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
                onPressed: () => _tryOtherEndings(context),
              ),
              const SizedBox(height: 14),

              // 2. Secondary Action: Share Ending (Dark Card)
              TwistButton(
                width: double.infinity,
                height: 50,
                text: 'Share Ending',
                icon: const Icon(Icons.share_outlined, color: Colors.white, size: 20),
                variant: TwistButtonVariant.glass,
                textStyle: AppTypography.buttonText.copyWith(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                onPressed: () => _shareEnding(context),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

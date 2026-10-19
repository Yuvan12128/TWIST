import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/language_provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/utils/formatters.dart';
import '../../models/story_model.dart';
import '../../models/story_ending_model.dart';
import '../../repositories/story_repository.dart';
import '../../widgets/cached_image.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/twist_button.dart';
import '../story_player/story_player_screen.dart';
import 'share_challenge_dialog.dart';

class AllEndingsScreen extends StatefulWidget {
  final StoryModel story;

  const AllEndingsScreen({super.key, required this.story});

  @override
  State<AllEndingsScreen> createState() => _AllEndingsScreenState();
}

class _AllEndingsScreenState extends State<AllEndingsScreen> {
  List<StoryEndingModel> _endings = [];
  Set<String> _unlockedIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEndings();
  }

  Future<void> _loadEndings() async {
    final storyRepo = context.read<StoryRepository>();
    final list = await storyRepo.getStoryEndings(widget.story.id);
    final unlocked = storyRepo.getUnlockedEndingIds(widget.story.id);

    if (mounted) {
      setState(() {
        _endings = list;
        _unlockedIds = unlocked;
        _isLoading = false;
      });
    }
  }

  void _showEndingModal(StoryEndingModel ending, bool isUnlocked) {
    final currentLang = context.read<LanguageProvider>().currentLanguage;
    final localizedTitle = ending.localizedTitle(currentLang);
    final localizedDesc = ending.localizedDescription(currentLang);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isUnlocked ? context.tr('ending_discovered') : context.tr('ending_locked'),
                  style: AppTypography.screenTitle.copyWith(fontSize: 18),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (isUnlocked) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedImage(
                    imageUrl: ending.imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                localizedTitle,
                style: AppTypography.storyCardTitle.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 6),
              Text(
                localizedDesc,
                style: AppTypography.storyCardDescription.copyWith(height: 1.5),
              ),
              const SizedBox(height: 20),
              TwistButton(
                text: context.tr('share_this_ending'),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  showDialog(
                    context: context,
                    builder: (_) => ShareChallengeDialog(story: widget.story, ending: ending),
                  );
                },
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.lock_rounded, size: 48, color: AppColors.textPlaceholder),
                    const SizedBox(height: 14),
                    Text(
                      ending.isSecret ? context.tr('secret_ending_badge') : '${ending.rarity} ${context.tr('endings')}',
                      style: AppTypography.storyCardTitle.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr('locked_ending_hint'),
                      textAlign: TextAlign.center,
                      style: AppTypography.storyCardDescription.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TwistButton(
                text: context.tr('play_story_again'),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => StoryPlayerScreen(story: widget.story),
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unlockedCount = _endings.where((e) => _unlockedIds.contains(e.id)).length;
    final currentLang = context.watch<LanguageProvider>().currentLanguage;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          context.tr('all_endings'),
          style: AppTypography.screenTitle.copyWith(fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
              ),
            )
          : ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                // Story Header Info
                Text(
                  widget.story.localizedTitle(currentLang),
                  style: AppTypography.brandTitle.copyWith(fontSize: 22),
                ),
                const SizedBox(height: 6),
                Text(
                  '$unlockedCount ${context.tr('of_scenes')} ${_endings.length} ${context.tr('endings_found')}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primaryPurple,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),

                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _endings.isEmpty ? 0 : (unlockedCount / _endings.length),
                    minHeight: 5,
                    backgroundColor: AppColors.surfaceLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
                  ),
                ),
                const SizedBox(height: 24),

                // List of endings
                ..._endings.map((ending) {
                  final isUnlocked = _unlockedIds.contains(ending.id);
                  final rarityColor = Formatters.getRarityColor(ending.rarity);
                  final localizedItemTitle = isUnlocked
                      ? ending.localizedTitle(currentLang)
                      : (ending.isSecret ? context.tr('secret_ending_badge') : '${ending.rarity} ${context.tr('endings')}');

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    child: GlassCard(
                      onTap: () => _showEndingModal(ending, isUnlocked),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Status Icon: Checkmark or Lock
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isUnlocked
                                  ? AppColors.accentGreen.withOpacity(0.18)
                                  : AppColors.surfaceLight,
                              border: Border.all(
                                color: isUnlocked
                                    ? AppColors.accentGreen.withOpacity(0.5)
                                    : AppColors.cardBorder,
                                width: 1.2,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                isUnlocked ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
                                color: isUnlocked ? AppColors.accentGreen : AppColors.textPlaceholder,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Ending Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (ending.isSecret) ...[
                                      const Icon(Icons.star_rounded, size: 14, color: AppColors.accentGold),
                                      const SizedBox(width: 4),
                                    ],
                                    Flexible(
                                      child: Text(
                                        localizedItemTitle,
                                        style: AppTypography.storyCardTitle.copyWith(
                                          fontSize: 14.5,
                                          color: isUnlocked
                                              ? (ending.isSecret ? AppColors.accentGold : Colors.white)
                                              : AppColors.textMuted,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isUnlocked ? context.tr('unlocked_tap_to_view') : context.tr('locked_ending_hint'),
                                  style: AppTypography.caption.copyWith(
                                    color: isUnlocked ? AppColors.accentCyan : AppColors.textPlaceholder,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Rarity Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: rarityColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: rarityColor.withOpacity(0.3), width: 0.8),
                            ),
                            child: Text(
                              ending.rarity.toUpperCase(),
                              style: AppTypography.badgeText.copyWith(
                                color: rarityColor,
                                fontSize: 9.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}

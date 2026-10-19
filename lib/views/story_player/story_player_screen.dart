import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/language_provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/story_model.dart';
import '../../models/story_choice_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/story_player_provider.dart';
import '../../widgets/glass_card.dart';
import '../ending/ending_screen.dart';
import 'widgets/cinematic_viewport.dart';
import 'widgets/player_progress_bar.dart';
import 'widgets/choice_button.dart';

class StoryPlayerScreen extends StatefulWidget {
  final StoryModel story;
  final String? startNodeId;
  final bool isPreview;

  const StoryPlayerScreen({
    super.key,
    required this.story,
    this.startNodeId,
    this.isPreview = false,
  });

  @override
  State<StoryPlayerScreen> createState() => _StoryPlayerScreenState();
}

class _StoryPlayerScreenState extends State<StoryPlayerScreen> {
  String? _selectedChoiceId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().user?.uid ?? 'guest';
      context.read<StoryPlayerProvider>().startStory(
            story: widget.story,
            userId: userId,
            startNodeId: widget.startNodeId,
            isPreview: widget.isPreview,
          );
    });
  }

  Future<bool> _onWillPop() async {
    final playerProv = context.read<StoryPlayerProvider>();
    if (playerProv.hasEnded) return true;

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          context.tr('leave_story'),
          style: AppTypography.screenTitle.copyWith(fontSize: 18),
        ),
        content: Text(
          context.tr('leave_story_desc'),
          style: AppTypography.storyCardDescription,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.tr('keep_playing'), style: const TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(context.tr('exit'), style: const TextStyle(color: AppColors.accentRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    return shouldLeave ?? false;
  }

  void _handleChoiceTap(StoryChoiceModel choice) async {
    if (_selectedChoiceId != null) return; // Prevent double taps

    setState(() => _selectedChoiceId = choice.id);

    final userId = context.read<AuthProvider>().user?.uid ?? 'guest';
    final playerProv = context.read<StoryPlayerProvider>();

    await playerProv.selectChoice(choice: choice, userId: userId);

    if (mounted) {
      setState(() => _selectedChoiceId = null);

      if (playerProv.hasEnded && playerProv.currentEnding != null) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (ctx, anim, secAnim) => EndingScreen(
              story: widget.story,
              ending: playerProv.currentEnding!,
              choicesCount: playerProv.choicesCount,
              isPreview: widget.isPreview,
            ),
            transitionsBuilder: (ctx, animation, secAnim, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 700),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerProv = context.watch<StoryPlayerProvider>();
    final currentNode = playerProv.currentNode;
    final isTransitioning = playerProv.isTransitioning;
    final currentLang = context.watch<LanguageProvider>().currentLanguage;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldLeave = await _onWillPop();
        if (shouldLeave && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () async {
              final canPop = await _onWillPop();
              if (canPop && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          title: Text(
            widget.story.localizedTitle(currentLang),
            style: AppTypography.storyCardTitle.copyWith(fontSize: 16),
          ),
          centerTitle: true,
          actions: [
            if (widget.isPreview)
              Center(
                child: Container(
                  margin: const EdgeInsets.only(right: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryYellow.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primaryYellow, width: 1),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.visibility_rounded, size: 12, color: AppColors.primaryYellow),
                      SizedBox(width: 4),
                      Text(
                        'PREVIEW',
                        style: TextStyle(
                          color: AppColors.primaryYellow,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.more_horiz, color: Colors.white),
                onPressed: () {},
              ),
          ],
        ),
        body: playerProv.isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.tr('entering_story'),
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              )
            : playerProv.status == PlayerStatus.error
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.accentRed, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            playerProv.errorMessage ?? context.tr('error_occurred'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 15),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              final userId = context.read<AuthProvider>().user?.uid ?? 'guest';
                              playerProv.startStory(story: widget.story, userId: userId);
                            },
                            child: Text(context.tr('try_again')),
                          ),
                        ],
                      ),
                    ),
                  )
                : currentNode == null
                    ? const SizedBox()
                    : AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(opacity: animation, child: child);
                        },
                        child: Column(
                          key: ValueKey<String>(currentNode.nodeId),
                          children: [
                            // Top Progress Bar
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
                              child: PlayerProgressBar(
                                currentScene: currentNode.sceneNumber,
                                totalEstimatedScenes: widget.story.endingsCount,
                                choicesMade: playerProv.choicesCount,
                              ),
                            ),

                            // Main Scrollable Narrative Body
                            Expanded(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Cinematic Viewport Artwork
                                    CinematicViewport(
                                      imageUrl: currentNode.imageUrl,
                                      speaker: currentNode.localizedSpeaker(currentLang),
                                      ambience: currentNode.ambience,
                                    ),

                                    // Story Text Box
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                                      child: GlassCard(
                                        padding: const EdgeInsets.all(20),
                                        borderRadius: 22,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              currentNode.localizedText(currentLang),
                                              style: AppTypography.cinematicNarrative.copyWith(
                                                fontSize: 16.5,
                                                height: 1.6,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Tension / Decision Prompt
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 22.0),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.flash_on_rounded, size: 16, color: AppColors.primaryYellow),
                                          const SizedBox(width: 6),
                                          Text(
                                            context.tr('what_will_you_do'),
                                            style: AppTypography.screenTitle.copyWith(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const Spacer(),
                                          if (isTransitioning)
                                            Row(
                                              children: [
                                                const SizedBox(
                                                  width: 12,
                                                  height: 12,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  context.tr('branching_progress'),
                                                  style: AppTypography.caption.copyWith(
                                                    color: AppColors.primaryYellow,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // Branching Choice Buttons
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                      child: Column(
                                        children: currentNode.choices.map((choice) {
                                          final isSelected = _selectedChoiceId == choice.id;
                                          return ChoiceButton(
                                            choice: choice,
                                            isSelected: isSelected,
                                            isEnabled: !isTransitioning,
                                            onTap: () => _handleChoiceTap(choice),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                    const SizedBox(height: 36),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
      ),
    );
  }
}

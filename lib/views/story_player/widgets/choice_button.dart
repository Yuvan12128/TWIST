import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/localization/language_provider.dart';
import '../../../models/story_choice_model.dart';

class ChoiceButton extends StatefulWidget {
  final StoryChoiceModel choice;
  final VoidCallback onTap;
  final bool isSelected;
  final bool isEnabled;

  const ChoiceButton({
    super.key,
    required this.choice,
    required this.onTap,
    this.isSelected = false,
    this.isEnabled = true,
  });

  @override
  State<ChoiceButton> createState() => _ChoiceButtonState();
}

class _ChoiceButtonState extends State<ChoiceButton> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final currentLang = context.watch<LanguageProvider>().currentLanguage;
    final localizedLabel = widget.choice.localizedLabel(currentLang);
    final localizedHint = widget.choice.localizedConsequenceHint(currentLang);

    final backgroundColor = isSelected ? AppColors.primaryYellow : AppColors.cardBackground;
    final borderColor = isSelected ? AppColors.primaryYellow : AppColors.border;
    final textColor = isSelected ? const Color(0xFF0B0B0F) : AppColors.primaryText;
    final iconColor = isSelected ? const Color(0xFF0B0B0F) : AppColors.secondaryText;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: const BoxConstraints(minHeight: 50),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: backgroundColor,
          border: Border.all(
            color: borderColor,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.isEnabled
                ? () {
                    _animController.forward().then((_) => _animController.reverse());
                    widget.onTap();
                  }
                : null,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  // Choice Icon (e.g. Shield / Door / Check)
                  Icon(
                    isSelected ? Icons.check_circle_rounded : Icons.shield_outlined,
                    color: iconColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),

                  // Label and consequence hint
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizedLabel,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.choiceLabel.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                          ),
                        ),
                        if (localizedHint != null && localizedHint.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            localizedHint,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.choiceHint.copyWith(
                              color: isSelected
                                  ? const Color(0xFF27272A)
                                  : AppColors.textMuted,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Arrow / indicator chevron
                  Icon(
                    Icons.chevron_right_rounded,
                    color: iconColor,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

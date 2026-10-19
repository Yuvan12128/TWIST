import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_localizations.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/twist_button.dart';
import '../story_player/story_player_screen.dart';
import '../../repositories/sample_data.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final _titleController = TextEditingController();
  final _premiseController = TextEditingController();
  String? _selectedCategory;
  bool _hasCoverImage = false;

  String? _titleError;
  String? _descriptionError;
  String? _categoryError;

  final List<String> _categories = [
    'Mystery',
    'Horror',
    'Love',
    'Comedy',
    'College',
    'Sci-Fi',
    'Action',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _premiseController.dispose();
    super.dispose();
  }

  void _testPlay() {
    // Launch a demo play session using the branching engine
    final demoStory = SampleData.getStories().first;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StoryPlayerScreen(story: demoStory),
      ),
    );
  }

  void _publishDraft() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() {
        _titleError = 'Please enter a story title to save a draft';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a story title to save a draft'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('draft_saved')),
        backgroundColor: AppColors.primaryPink,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _createStory() {
    final title = _titleController.text.trim();
    final description = _premiseController.text.trim();
    final category = _selectedCategory;

    String? firstErrorMessage;
    if (title.isEmpty) {
      firstErrorMessage = 'Please enter a story title';
    } else if (description.isEmpty) {
      firstErrorMessage = 'Please enter a story description';
    } else if (category == null || category.isEmpty) {
      firstErrorMessage = 'Please select a category';
    }

    setState(() {
      _titleError = title.isEmpty ? 'Story title is required' : null;
      _descriptionError = description.isEmpty ? 'Story description is required' : null;
      _categoryError = (category == null || category.isEmpty) ? 'Please select a category' : null;
    });

    if (firstErrorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(firstErrorMessage),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Validation passed - Cover image is optional and not required
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Story created successfully!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Create Story',
          style: AppTypography.screenTitle.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _publishDraft,
            child: const Text(
              'Save Draft',
              style: TextStyle(
                color: AppColors.primaryYellow,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Upload Cover Image Box (Optional)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Cover Image',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Optional',
                    style: TextStyle(
                      color: AppColors.secondaryText.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _hasCoverImage = !_hasCoverImage;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _hasCoverImage
                            ? 'Cover image attached (Optional)'
                            : 'Cover image removed',
                      ),
                      backgroundColor: AppColors.cardBackground,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 140,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _hasCoverImage ? AppColors.primaryYellow : AppColors.border,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _hasCoverImage ? Icons.check_circle_outline_rounded : Icons.image_outlined,
                        color: _hasCoverImage ? AppColors.primaryYellow : AppColors.secondaryText,
                        size: 34,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _hasCoverImage ? 'Cover Image Attached (Optional)' : 'Upload Cover Image (Optional)',
                        style: TextStyle(
                          color: _hasCoverImage ? AppColors.primaryYellow : AppColors.secondaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _hasCoverImage ? 'Tap to remove image' : 'Tap to select an image (or leave blank)',
                        style: const TextStyle(
                          color: AppColors.textPlaceholder,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 2. Story Title Field
              const Text(
                'Story Title',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _titleError != null ? AppColors.error : AppColors.border,
                  ),
                ),
                child: TextField(
                  controller: _titleController,
                  onChanged: (val) {
                    if (_titleError != null && val.trim().isNotEmpty) {
                      setState(() => _titleError = null);
                    }
                  },
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Enter story title',
                    hintStyle: TextStyle(color: AppColors.textPlaceholder),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              if (_titleError != null) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    _titleError!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),

              // 3. Description Field
              const Text(
                'Description',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _descriptionError != null ? AppColors.error : AppColors.border,
                  ),
                ),
                child: TextField(
                  controller: _premiseController,
                  maxLines: 3,
                  onChanged: (val) {
                    if (_descriptionError != null && val.trim().isNotEmpty) {
                      setState(() => _descriptionError = null);
                    }
                  },
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Enter story description',
                    hintStyle: TextStyle(color: AppColors.textPlaceholder),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              if (_descriptionError != null) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    _descriptionError!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),

              // 4. Category Dropdown
              const Text(
                'Category',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _categoryError != null ? AppColors.error : AppColors.border,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    hint: const Text(
                      'Select category',
                      style: TextStyle(
                        color: AppColors.textPlaceholder,
                        fontSize: 14,
                      ),
                    ),
                    isExpanded: true,
                    dropdownColor: AppColors.cardBackground,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.secondaryText),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    items: _categories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat,
                        child: Text(cat),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedCategory = val;
                        _categoryError = null;
                      });
                    },
                  ),
                ),
              ),
              if (_categoryError != null) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    _categoryError!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 26),

              // 5. Main Action Button: Create Story (Bright Yellow #FFD600)
              TwistButton(
                width: double.infinity,
                height: 52,
                text: 'Create Story',
                variant: TwistButtonVariant.primaryGradient,
                textStyle: AppTypography.buttonText.copyWith(
                  color: const Color(0xFF0B0B0F),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
                onPressed: _createStory,
              ),
              const SizedBox(height: 24),

            // Branching Engine & Test Play section
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Interactive Branching Engine',
                        style: AppTypography.storyCardTitle.copyWith(fontSize: 15),
                      ),
                      const Icon(Icons.hub_outlined, color: AppColors.primaryYellow, size: 20),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Test play your interactive choices with dynamic story branching.',
                    style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  TwistButton(
                    height: 48,
                    text: 'Test Play Branch',
                    variant: TwistButtonVariant.glass,
                    textStyle: AppTypography.buttonText.copyWith(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                    onPressed: _testPlay,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

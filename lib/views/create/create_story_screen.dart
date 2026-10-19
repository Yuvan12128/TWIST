import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/story_validator.dart';
import '../../models/story_model.dart';
import '../../models/story_node_model.dart';
import '../../models/story_choice_model.dart';
import '../../models/story_ending_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../repositories/story_repository.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/twist_button.dart';
import '../story_player/story_player_screen.dart';
import '../story_detail/story_detail_screen.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> with SingleTickerProviderStateMixin {
  final _uuid = const Uuid();
  int _currentStep = 0; // 0: Details, 1: Scenes, 2: Choices, 3: Endings, 4: Review

  // Step 0: Basic Information
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _coverUrlController = TextEditingController();
  String? _selectedCategory;
  String? _titleError;
  String? _descriptionError;
  String? _categoryError;

  // Preset cover backdrops (atmospheric fallbacks if user does not provide custom cover)
  static const List<({String title, String url})> _presetCovers = [
    (title: 'Mystery Archives', url: 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=800&auto=format&fit=crop&q=80'),
    (title: 'Neon Cyberpunk', url: 'https://images.unsplash.com/photo-1508739773434-c26b3d09e071?w=800&auto=format&fit=crop&q=80'),
    (title: 'Haunted Corridor', url: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=800&auto=format&fit=crop&q=80'),
    (title: 'Campus Thriller', url: 'https://images.unsplash.com/photo-1523240795612-9a054b0db644?w=800&auto=format&fit=crop&q=80'),
  ];

  static const List<String> _categories = [
    'Mystery',
    'Horror',
    'Love',
    'Comedy',
    'College',
    'Sci-Fi',
    'Action',
    'Fantasy',
    'Real Life',
  ];

  // Step 1 & 2: Story Nodes & Choices
  String _startNodeId = 'node_start';
  final List<StoryNodeModel> _nodes = [];

  // Step 3: Endings
  final List<StoryEndingModel> _endings = [];

  // Step 4: Review & Publish State
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    _initializeDefaultDraft();
  }

  void _initializeDefaultDraft() {
    // Start with a clean, intuitive first node & first ending
    _nodes.add(
      const StoryNodeModel(
        nodeId: 'node_start',
        storyId: 'draft',
        textMap: {'en': ''},
        imageUrl: '',
        sceneNumber: 1,
        choices: [],
      ),
    );

    _endings.add(
      const StoryEndingModel(
        id: 'ending_1',
        storyId: 'draft',
        titleMap: {'en': ''},
        descriptionMap: {'en': ''},
        imageUrl: '',
        rarity: 'Common',
        rarityPercentage: 50.0,
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _coverUrlController.dispose();
    super.dispose();
  }

  String get _effectiveCoverUrl {
    final custom = _coverUrlController.text.trim();
    if (custom.isNotEmpty) return custom;
    // Contextual fallback by category or default
    return _presetCovers.first.url;
  }

  StoryValidationResult get _validationResult {
    return StoryValidator.validate(
      title: _titleController.text,
      description: _descriptionController.text,
      category: _selectedCategory,
      startNodeId: _startNodeId,
      nodes: _nodes,
      endings: _endings,
    );
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step.clamp(0, 4));
  }

  // ==========================================
  // Node Operations
  // ==========================================
  void _addNewNode() {
    final newId = 'node_${_nodes.length + 1}_${_uuid.v4().substring(0, 4)}';
    setState(() {
      _nodes.add(
        StoryNodeModel(
          nodeId: newId,
          storyId: 'draft',
          textMap: {'en': ''},
          imageUrl: '',
          sceneNumber: _nodes.length + 1,
          choices: [],
        ),
      );
    });
    _showEditNodeDialog(_nodes.last);
  }

  void _showEditNodeDialog(StoryNodeModel node) {
    final titleCtrl = TextEditingController(text: node.speakerMap?['en'] ?? '');
    final textCtrl = TextEditingController(text: node.textMap['en'] ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: AppColors.border)),
        title: Row(
          children: [
            const Icon(Icons.movie_creation_outlined, color: AppColors.primaryYellow, size: 22),
            const SizedBox(width: 10),
            Text(
              node.nodeId == _startNodeId ? 'Edit Start Scene' : 'Edit Scene',
              style: AppTypography.screenTitle.copyWith(fontSize: 18),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Scene / Speaker Name (Optional)', style: TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                  child: TextField(
                    controller: titleCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'e.g. The Attic or Detective Ray',
                      hintStyle: TextStyle(color: AppColors.textPlaceholder, fontSize: 13),
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Story Narrative Content *', style: TextStyle(color: AppColors.primaryText, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                  child: TextFormField(
                    controller: textCtrl,
                    maxLines: 5,
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'Scene content cannot be empty' : null,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Write what happens in this scene for the reader...',
                      hintStyle: TextStyle(color: AppColors.textPlaceholder, fontSize: 13),
                      contentPadding: EdgeInsets.all(14),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          TwistButton(
            text: 'Save Scene',
            height: 38,
            variant: TwistButtonVariant.primaryGradient,
            textStyle: AppTypography.buttonText.copyWith(color: const Color(0xFF0B0B0F), fontSize: 13, fontWeight: FontWeight.bold),
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                final idx = _nodes.indexWhere((n) => n.nodeId == node.nodeId);
                if (idx != -1) {
                  setState(() {
                    _nodes[idx] = _nodes[idx].copyWith(
                      textMap: {'en': textCtrl.text.trim()},
                      speakerMap: titleCtrl.text.trim().isNotEmpty ? {'en': titleCtrl.text.trim()} : null,
                    );
                  });
                }
                Navigator.of(ctx).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  void _deleteNode(String nodeId) {
    if (_nodes.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A story must have at least one scene.'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() {
      _nodes.removeWhere((n) => n.nodeId == nodeId);
      if (_startNodeId == nodeId && _nodes.isNotEmpty) {
        _startNodeId = _nodes.first.nodeId;
      }
      // Clean up references pointing to deleted node
      for (var i = 0; i < _nodes.length; i++) {
        final updatedChoices = _nodes[i].choices.map((c) {
          if (c.nextNodeId == nodeId) {
            return StoryChoiceModel(
              id: c.id,
              nodeId: c.nodeId,
              labelMap: c.labelMap,
              nextNodeId: null,
              endingId: c.endingId,
              key: c.key,
              riskLevel: c.riskLevel,
            );
          }
          return c;
        }).toList();
        _nodes[i] = _nodes[i].copyWith(choices: updatedChoices);
      }
    });
  }

  // ==========================================
  // Choice Operations
  // ==========================================
  void _addChoiceToNode(StoryNodeModel node) {
    final choiceId = 'choice_${_uuid.v4().substring(0, 6)}';
    final choiceKey = String.fromCharCode(65 + node.choices.length); // A, B, C...

    final newChoice = StoryChoiceModel(
      id: choiceId,
      nodeId: node.nodeId,
      labelMap: const {'en': ''},
      nextNodeId: null,
      endingId: null,
      key: choiceKey,
      riskLevel: 'bold',
    );

    final idx = _nodes.indexWhere((n) => n.nodeId == node.nodeId);
    if (idx != -1) {
      setState(() {
        final currentChoices = List<StoryChoiceModel>.from(_nodes[idx].choices);
        currentChoices.add(newChoice);
        _nodes[idx] = _nodes[idx].copyWith(choices: currentChoices);
      });
    }
  }

  void _updateChoice(String nodeId, String choiceId, {String? text, String? nextNodeId, String? endingId, bool isEnding = false}) {
    final nodeIdx = _nodes.indexWhere((n) => n.nodeId == nodeId);
    if (nodeIdx == -1) return;

    final choiceIdx = _nodes[nodeIdx].choices.indexWhere((c) => c.id == choiceId);
    if (choiceIdx == -1) return;

    final oldChoice = _nodes[nodeIdx].choices[choiceIdx];
    final updatedChoices = List<StoryChoiceModel>.from(_nodes[nodeIdx].choices);

    updatedChoices[choiceIdx] = StoryChoiceModel(
      id: oldChoice.id,
      nodeId: nodeId,
      labelMap: text != null ? {'en': text} : oldChoice.labelMap,
      consequenceHintMap: oldChoice.consequenceHintMap,
      nextNodeId: isEnding ? null : (nextNodeId ?? oldChoice.nextNodeId),
      endingId: isEnding ? (endingId ?? oldChoice.endingId) : null,
      key: oldChoice.key,
      riskLevel: oldChoice.riskLevel,
    );

    setState(() {
      _nodes[nodeIdx] = _nodes[nodeIdx].copyWith(choices: updatedChoices);
    });
  }

  void _deleteChoice(String nodeId, String choiceId) {
    final nodeIdx = _nodes.indexWhere((n) => n.nodeId == nodeId);
    if (nodeIdx == -1) return;

    setState(() {
      final updated = List<StoryChoiceModel>.from(_nodes[nodeIdx].choices)..removeWhere((c) => c.id == choiceId);
      _nodes[nodeIdx] = _nodes[nodeIdx].copyWith(choices: updated);
    });
  }

  // ==========================================
  // Ending Operations
  // ==========================================
  void _addNewEnding() {
    final endingId = 'ending_${_endings.length + 1}_${_uuid.v4().substring(0, 4)}';
    final newEnding = StoryEndingModel(
      id: endingId,
      storyId: 'draft',
      titleMap: const {'en': ''},
      descriptionMap: const {'en': ''},
      imageUrl: '',
      rarity: _endings.isEmpty ? 'Common' : (_endings.length == 1 ? 'Secret' : 'Rare'),
      rarityPercentage: 25.0,
      isSecret: _endings.length == 1,
    );

    setState(() {
      _endings.add(newEnding);
    });
    _showEditEndingDialog(newEnding);
  }

  void _showEditEndingDialog(StoryEndingModel ending) {
    final titleCtrl = TextEditingController(text: ending.titleMap['en'] ?? '');
    final descCtrl = TextEditingController(text: ending.descriptionMap['en'] ?? '');
    String selectedRarity = ending.rarity;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: AppColors.border)),
          title: Row(
            children: [
              const Icon(Icons.emoji_events_outlined, color: AppColors.accentGold, size: 22),
              const SizedBox(width: 10),
              Text('Edit Ending', style: AppTypography.screenTitle.copyWith(fontSize: 18)),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ending Title *', style: TextStyle(color: AppColors.primaryText, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                    child: TextFormField(
                      controller: titleCtrl,
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'Ending title is required' : null,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'e.g. The Secret Portal or Tragic Hero',
                        hintStyle: TextStyle(color: AppColors.textPlaceholder, fontSize: 13),
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Ending Narrative *', style: TextStyle(color: AppColors.primaryText, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                    child: TextFormField(
                      controller: descCtrl,
                      maxLines: 4,
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'Ending narrative is required' : null,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Describe how the story concludes in this branch...',
                        hintStyle: TextStyle(color: AppColors.textPlaceholder, fontSize: 13),
                        contentPadding: EdgeInsets.all(14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Ending Rarity', style: TextStyle(color: AppColors.primaryText, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedRarity,
                        isExpanded: true,
                        dropdownColor: AppColors.cardBackground,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        items: ['Common', 'Uncommon', 'Rare', 'Secret'].map((r) {
                          return DropdownMenuItem<String>(
                            value: r,
                            child: Text(r),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedRarity = val);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            TwistButton(
              text: 'Save Ending',
              height: 38,
              variant: TwistButtonVariant.primaryGradient,
              textStyle: AppTypography.buttonText.copyWith(color: const Color(0xFF0B0B0F), fontSize: 13, fontWeight: FontWeight.bold),
              onPressed: () {
                if (formKey.currentState?.validate() == true) {
                  final idx = _endings.indexWhere((e) => e.id == ending.id);
                  if (idx != -1) {
                    setState(() {
                      _endings[idx] = StoryEndingModel(
                        id: ending.id,
                        storyId: 'draft',
                        titleMap: {'en': titleCtrl.text.trim()},
                        descriptionMap: {'en': descCtrl.text.trim()},
                        imageUrl: ending.imageUrl,
                        rarity: selectedRarity,
                        isSecret: selectedRarity == 'Secret',
                        rarityPercentage: selectedRarity == 'Secret' ? 10.0 : 35.0,
                      );
                    });
                  }
                  Navigator.of(ctx).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _deleteEnding(String endingId) {
    if (_endings.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A story must have at least one ending.'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() {
      _endings.removeWhere((e) => e.id == endingId);
      // Clean up choices pointing to deleted ending
      for (var i = 0; i < _nodes.length; i++) {
        final updatedChoices = _nodes[i].choices.map((c) {
          if (c.endingId == endingId) {
            return StoryChoiceModel(
              id: c.id,
              nodeId: c.nodeId,
              labelMap: c.labelMap,
              nextNodeId: null,
              endingId: null,
              key: c.key,
              riskLevel: c.riskLevel,
            );
          }
          return c;
        }).toList();
        _nodes[i] = _nodes[i].copyWith(choices: updatedChoices);
      }
    });
  }

  // ==========================================
  // Preview Flow
  // ==========================================
  void _startPreview() {
    final validation = _validationResult;
    if (!validation.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot preview: ${validation.errors.first}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final draftStoryId = 'preview_${_uuid.v4().substring(0, 8)}';
    final storyRepo = context.read<StoryRepository>();

    final previewStory = StoryModel(
      id: draftStoryId,
      titleMap: {'en': _titleController.text.trim()},
      descriptionMap: {'en': _descriptionController.text.trim()},
      coverUrl: _effectiveCoverUrl,
      category: _selectedCategory ?? 'General',
      categories: [_selectedCategory ?? 'General'],
      creatorId: context.read<AuthProvider>().user?.uid ?? 'creator',
      creatorName: context.read<AuthProvider>().user?.displayName ?? 'Storyteller',
      duration: '${(_nodes.length * 1.5).ceil()} min',
      startNodeId: _startNodeId,
      endingsCount: _endings.length,
      createdAt: DateTime.now(),
    );

    // Cache draft nodes and endings into repository in-memory
    final nodeMap = {for (final n in _nodes) n.nodeId: n.copyWith(storyId: draftStoryId)};
    final endingList = _endings.map((e) => StoryEndingModel(
      id: e.id,
      storyId: draftStoryId,
      titleMap: e.titleMap,
      descriptionMap: e.descriptionMap,
      imageUrl: e.imageUrl,
      rarity: e.rarity,
      isSecret: e.isSecret,
    )).toList();

    storyRepo.cacheStoryNodes(draftStoryId, nodeMap);
    storyRepo.cacheStoryEndings(draftStoryId, endingList);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StoryPlayerScreen(
          story: previewStory,
          startNodeId: _startNodeId,
          isPreview: true,
        ),
      ),
    );
  }

  // ==========================================
  // Publish Flow
  // ==========================================
  Future<void> _publishStory() async {
    final validation = _validationResult;
    if (!validation.isValid) {
      _goToStep(4);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please resolve validation errors before publishing: ${validation.errors.first}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: AppColors.border)),
        title: const Text('Publish Story?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Your story "${_titleController.text.trim()}" with ${_nodes.length} scenes and ${_endings.length} endings will be published to the TWIST community.',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          TwistButton(
            text: 'Confirm & Publish',
            height: 40,
            variant: TwistButtonVariant.primaryGradient,
            textStyle: AppTypography.buttonText.copyWith(color: const Color(0xFF0B0B0F), fontSize: 13, fontWeight: FontWeight.bold),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isPublishing = true);

    final currentUser = context.read<AuthProvider>().user;
    final currentUid = currentUser?.uid ?? 'anonymous_creator';
    final storyId = 'story_${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4().substring(0, 6)}';

    final publishedStory = StoryModel(
      id: storyId,
      titleMap: {'en': _titleController.text.trim()},
      descriptionMap: {'en': _descriptionController.text.trim()},
      availableLanguages: const ['en', 'ta', 'tanglish'],
      coverUrl: _effectiveCoverUrl,
      category: _selectedCategory ?? 'General',
      categories: [_selectedCategory ?? 'General'],
      creatorId: currentUid,
      creatorName: currentUser?.displayName.isNotEmpty == true ? currentUser!.displayName : 'TWIST Storyteller',
      creatorAvatar: currentUser?.photoUrl,
      duration: '${(_nodes.length * 1.5).ceil()} min',
      plays: 0,
      likes: 0,
      commentsCount: 0,
      endingsCount: _endings.length,
      startNodeId: _startNodeId,
      createdAt: DateTime.now(),
    );

    final preparedNodes = _nodes.map((n) => n.copyWith(storyId: storyId)).toList();
    final preparedEndings = _endings.map((e) => StoryEndingModel(
      id: e.id,
      storyId: storyId,
      titleMap: e.titleMap,
      descriptionMap: e.descriptionMap,
      imageUrl: e.imageUrl.isNotEmpty ? e.imageUrl : _effectiveCoverUrl,
      rarity: e.rarity,
      isSecret: e.isSecret,
    )).toList();

    final storyRepo = context.read<StoryRepository>();
    final success = await storyRepo.publishStory(
      story: publishedStory,
      nodes: preparedNodes,
      endings: preparedEndings,
    );

    if (!mounted) return;
    setState(() => _isPublishing = false);

    if (success) {
      // Reload profile data so published story appears in My Stories
      context.read<ProfileProvider>().loadProfileData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Story published successfully! 🎉'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Navigate to story details
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => StoryDetailScreen(story: publishedStory),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to publish story to Firebase. Please try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ==========================================
  // UI Builder
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            'Story Studio',
            style: AppTypography.screenTitle.copyWith(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          actions: [
            // Quick Test Play Preview button
            IconButton(
              icon: const Icon(Icons.play_circle_outline_rounded, color: AppColors.primaryYellow, size: 24),
              tooltip: 'Preview Story',
              onPressed: _startPreview,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Top Step Progress Indicator
              _buildStepIndicator(),

              // Current Step Content View
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _buildCurrentStepContent(),
                ),
              ),

              // Bottom Navigation & Actions Bar
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = [
      (label: 'Details', icon: Icons.info_outline_rounded),
      (label: 'Scenes', icon: Icons.movie_creation_outlined),
      (label: 'Choices', icon: Icons.alt_route_rounded),
      (label: 'Endings', icon: Icons.emoji_events_outlined),
      (label: 'Review', icon: Icons.verified_outlined),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length, (idx) {
          final isCurrent = _currentStep == idx;
          final isCompleted = _currentStep > idx;

          return Expanded(
            child: GestureDetector(
              onTap: () => _goToStep(idx),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isCurrent ? AppColors.primaryYellow : (isCompleted ? AppColors.accentGold : Colors.transparent),
                      width: 2.5,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      steps[idx].icon,
                      size: 18,
                      color: isCurrent ? AppColors.primaryYellow : (isCompleted ? Colors.white : AppColors.textMuted),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      steps[idx].label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                        color: isCurrent ? AppColors.primaryYellow : (isCompleted ? Colors.white : AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStepDetails();
      case 1:
        return _buildStepScenes();
      case 2:
        return _buildStepChoices();
      case 3:
        return _buildStepEndings();
      case 4:
      default:
        return _buildStepReview();
    }
  }

  // ==========================================
  // Step 0: Basic Details
  // ==========================================
  Widget _buildStepDetails() {
    return ListView(
      key: const ValueKey('step_details'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        Text('Step 1 of 5', style: AppTypography.caption.copyWith(color: AppColors.primaryYellow, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Basic Information', style: AppTypography.screenTitle.copyWith(fontSize: 20)),
        const SizedBox(height: 4),
        Text('Give your story a compelling title, premise, and genre category.', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 20),

        // Story Title
        const Text('Story Title *', style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _titleError != null ? AppColors.error : AppColors.border),
          ),
          child: TextField(
            controller: _titleController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            onChanged: (val) {
              if (_titleError != null && val.trim().isNotEmpty) {
                setState(() => _titleError = null);
              }
            },
            decoration: const InputDecoration(
              hintText: 'e.g. Whispers of the Midnight Clocktower',
              hintStyle: TextStyle(color: AppColors.textPlaceholder, fontSize: 13),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: InputBorder.none,
            ),
          ),
        ),
        if (_titleError != null) ...[
          const SizedBox(height: 4),
          Text(_titleError!, style: const TextStyle(color: AppColors.error, fontSize: 11.5)),
        ],
        const SizedBox(height: 18),

        // Story Description
        const Text('Description / Premise *', style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _descriptionError != null ? AppColors.error : AppColors.border),
          ),
          child: TextField(
            controller: _descriptionController,
            maxLines: 4,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            onChanged: (val) {
              if (_descriptionError != null && val.trim().isNotEmpty) {
                setState(() => _descriptionError = null);
              }
            },
            decoration: const InputDecoration(
              hintText: 'Set the premise. What challenge or mystery will players face?',
              hintStyle: TextStyle(color: AppColors.textPlaceholder, fontSize: 13),
              contentPadding: EdgeInsets.all(16),
              border: InputBorder.none,
            ),
          ),
        ),
        if (_descriptionError != null) ...[
          const SizedBox(height: 4),
          Text(_descriptionError!, style: const TextStyle(color: AppColors.error, fontSize: 11.5)),
        ],
        const SizedBox(height: 18),

        // Category Dropdown
        const Text('Genre Category *', style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _categoryError != null ? AppColors.error : AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              hint: const Text('Select a genre category', style: TextStyle(color: AppColors.textPlaceholder, fontSize: 13)),
              isExpanded: true,
              dropdownColor: AppColors.cardBackground,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.secondaryText),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
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
          Text(_categoryError!, style: const TextStyle(color: AppColors.error, fontSize: 11.5)),
        ],
        const SizedBox(height: 18),

        // Cover Image (Optional)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Cover Image URL', style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600)),
            Text('Optional', style: TextStyle(color: AppColors.secondaryText.withOpacity(0.8), fontSize: 11.5)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: _coverUrlController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'Paste custom cover image URL or pick below',
              hintStyle: TextStyle(color: AppColors.textPlaceholder, fontSize: 12),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: InputBorder.none,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 12),

        // Preset Cover Backdrops
        const Text('Or choose a themed backdrop:', style: TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
        const SizedBox(height: 8),
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _presetCovers.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (ctx, index) {
              final preset = _presetCovers[index];
              final isSelected = _coverUrlController.text == preset.url;

              return GestureDetector(
                onTap: () {
                  setState(() => _coverUrlController.text = preset.url);
                },
                child: Container(
                  width: 120,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isSelected ? AppColors.primaryYellow : AppColors.border, width: isSelected ? 2 : 1),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                      child: Text(
                        preset.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? AppColors.primaryYellow : Colors.white,
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ==========================================
  // Step 1: Scenes (Nodes)
  // ==========================================
  Widget _buildStepScenes() {
    return ListView(
      key: const ValueKey('step_scenes'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Step 2 of 5', style: AppTypography.caption.copyWith(color: AppColors.primaryYellow, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Story Scenes', style: AppTypography.screenTitle.copyWith(fontSize: 20)),
              ],
            ),
            TwistButton(
              text: '+ Add Scene',
              height: 38,
              variant: TwistButtonVariant.primaryGradient,
              textStyle: AppTypography.buttonText.copyWith(color: const Color(0xFF0B0B0F), fontSize: 12, fontWeight: FontWeight.bold),
              onPressed: _addNewNode,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text('Create the scenes where your story takes place. Every scene presents choices.', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 16),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _nodes.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final node = _nodes[index];
            final isStart = node.nodeId == _startNodeId;
            final speaker = node.speakerMap?['en'];

            return GlassCard(
              padding: const EdgeInsets.all(14),
              borderRadius: 16,
              border: Border.all(
                color: isStart ? AppColors.primaryYellow : AppColors.border,
                width: isStart ? 1.5 : 1,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (isStart)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primaryYellow,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'START SCENE',
                                style: TextStyle(color: Color(0xFF0B0B0F), fontSize: 9.5, fontWeight: FontWeight.w900),
                              ),
                            )
                          else
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'SCENE ${index + 1}',
                                style: const TextStyle(color: AppColors.secondaryText, fontSize: 10, fontWeight: FontWeight.w600),
                              ),
                            ),
                          Text(
                            speaker?.isNotEmpty == true ? speaker! : 'Scene ${index + 1}',
                            style: AppTypography.storyCardTitle.copyWith(fontSize: 14),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: AppColors.primaryYellow, size: 20),
                            tooltip: 'Edit Scene Content',
                            onPressed: () => _showEditNodeDialog(node),
                          ),
                          if (!isStart)
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                              tooltip: 'Delete Scene',
                              onPressed: () => _deleteNode(node.nodeId),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    node.text.isNotEmpty ? node.text : '(No narrative content written yet. Tap edit icon above)',
                    style: TextStyle(
                      color: node.text.isNotEmpty ? AppColors.secondaryText : AppColors.textPlaceholder,
                      fontSize: 12.5,
                      fontStyle: node.text.isEmpty ? FontStyle.italic : FontStyle.normal,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${node.choices.length} choices configured',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                      if (!isStart)
                        GestureDetector(
                          onTap: () {
                            setState(() => _startNodeId = node.nodeId);
                          },
                          child: const Text(
                            'Set as Start Scene',
                            style: TextStyle(color: AppColors.primaryYellow, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ==========================================
  // Step 2: Choices & Connections
  // ==========================================
  Widget _buildStepChoices() {
    return ListView(
      key: const ValueKey('step_choices'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        Text('Step 3 of 5', style: AppTypography.caption.copyWith(color: AppColors.primaryYellow, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Choices & Branching', style: AppTypography.screenTitle.copyWith(fontSize: 20)),
        const SizedBox(height: 4),
        Text('Connect choices from each scene to either another scene or an ending.', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 16),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _nodes.length,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (context, nodeIdx) {
            final node = _nodes[nodeIdx];
            final isStart = node.nodeId == _startNodeId;

            return GlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(isStart ? Icons.flag_rounded : Icons.alt_route_rounded, color: AppColors.primaryYellow, size: 18),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                isStart ? 'Start Scene: "${node.speakerMap?['en'] ?? 'Scene 1'}"' : 'Scene ${nodeIdx + 1}: "${node.speakerMap?['en'] ?? node.nodeId}"',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.storyCardTitle.copyWith(fontSize: 14.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      TwistButton(
                        text: '+ Choice',
                        height: 32,
                        variant: TwistButtonVariant.primaryGradient,
                        textStyle: const TextStyle(color: Color(0xFF0B0B0F), fontSize: 11, fontWeight: FontWeight.bold),
                        onPressed: () => _addChoiceToNode(node),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (node.choices.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Center(
                        child: Text(
                          'No choices added yet. Tap "+ Choice" to create player decisions.',
                          style: TextStyle(color: AppColors.textPlaceholder, fontSize: 12),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: node.choices.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (ctx, choiceIdx) {
                        final choice = node.choices[choiceIdx];
                        final leadsToEnding = choice.leadsToEnding;

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 11,
                                    backgroundColor: AppColors.primaryYellow,
                                    child: Text(
                                      choice.key,
                                      style: const TextStyle(color: Color(0xFF0B0B0F), fontSize: 10.5, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: TextEditingController(text: choice.label)..selection = TextSelection.collapsed(offset: choice.label.length),
                                      style: const TextStyle(color: Colors.white, fontSize: 13),
                                      decoration: const InputDecoration(
                                        hintText: 'Enter choice text (e.g. Open the secret drawer)',
                                        hintStyle: TextStyle(color: AppColors.textPlaceholder, fontSize: 12),
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      onChanged: (val) {
                                        _updateChoice(node.nodeId, choice.id, text: val);
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 16),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => _deleteChoice(node.nodeId, choice.id),
                                  ),
                                ],
                              ),
                              const Divider(color: AppColors.border, height: 16),

                              // Destination Selector
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Leads to: ', style: TextStyle(color: AppColors.secondaryText, fontSize: 11.5)),
                                      const SizedBox(width: 4),

                                      // Toggle: Scene vs Ending
                                      ChoiceChip(
                                        label: const Text('Scene', style: TextStyle(fontSize: 10.5)),
                                        selected: !leadsToEnding,
                                        selectedColor: AppColors.primaryYellow,
                                        backgroundColor: AppColors.cardBackground,
                                        labelStyle: TextStyle(color: !leadsToEnding ? const Color(0xFF0B0B0F) : Colors.white, fontWeight: FontWeight.bold),
                                        visualDensity: VisualDensity.compact,
                                        onSelected: (val) {
                                          if (val) {
                                            final otherNodes = _nodes.where((n) => n.nodeId != node.nodeId).toList();
                                            final target = otherNodes.isNotEmpty ? otherNodes.first.nodeId : null;
                                            _updateChoice(node.nodeId, choice.id, nextNodeId: target, isEnding: false);
                                          }
                                        },
                                      ),
                                      const SizedBox(width: 6),
                                      ChoiceChip(
                                        label: const Text('Ending', style: TextStyle(fontSize: 10.5)),
                                        selected: leadsToEnding,
                                        selectedColor: AppColors.accentGold,
                                        backgroundColor: AppColors.cardBackground,
                                        labelStyle: TextStyle(color: leadsToEnding ? const Color(0xFF0B0B0F) : Colors.white, fontWeight: FontWeight.bold),
                                        visualDensity: VisualDensity.compact,
                                        onSelected: (val) {
                                          if (val) {
                                            final target = _endings.isNotEmpty ? _endings.first.id : null;
                                            _updateChoice(node.nodeId, choice.id, endingId: target, isEnding: true);
                                          }
                                        },
                                      ),
                                    ],
                                  ),

                                  // Destination Dropdown
                                  Container(
                                    width: 140,
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.cardBackground,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: leadsToEnding ? choice.endingId : choice.nextNodeId,
                                        hint: Text(leadsToEnding ? 'Pick Ending' : 'Pick Scene', style: const TextStyle(color: AppColors.textPlaceholder, fontSize: 11.5)),
                                        isExpanded: true,
                                        dropdownColor: AppColors.cardBackground,
                                        style: const TextStyle(color: Colors.white, fontSize: 11.5),
                                        items: leadsToEnding
                                            ? _endings.map((e) {
                                                return DropdownMenuItem<String>(
                                                  value: e.id,
                                                  child: Text(e.title.isNotEmpty ? e.title : e.id, overflow: TextOverflow.ellipsis),
                                                );
                                              }).toList()
                                            : _nodes.where((n) => n.nodeId != node.nodeId).map((n) {
                                                final name = n.speakerMap?['en'] ?? n.nodeId;
                                                return DropdownMenuItem<String>(
                                                  value: n.nodeId,
                                                  child: Text(name, overflow: TextOverflow.ellipsis),
                                                );
                                              }).toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            if (leadsToEnding) {
                                              _updateChoice(node.nodeId, choice.id, endingId: val, isEnding: true);
                                            } else {
                                              _updateChoice(node.nodeId, choice.id, nextNodeId: val, isEnding: false);
                                            }
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ==========================================
  // Step 3: Endings
  // ==========================================
  Widget _buildStepEndings() {
    return ListView(
      key: const ValueKey('step_endings'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Step 4 of 5', style: AppTypography.caption.copyWith(color: AppColors.primaryYellow, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Story Endings', style: AppTypography.screenTitle.copyWith(fontSize: 20)),
              ],
            ),
            TwistButton(
              text: '+ Add Ending',
              height: 38,
              variant: TwistButtonVariant.primaryGradient,
              textStyle: AppTypography.buttonText.copyWith(color: const Color(0xFF0B0B0F), fontSize: 12, fontWeight: FontWeight.bold),
              onPressed: _addNewEnding,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text('Create climaxes, secret twists, or tragic conclusions for your story.', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 16),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _endings.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final ending = _endings[index];
            final isSecret = ending.isSecret || ending.rarity == 'Secret';

            return GlassCard(
              padding: const EdgeInsets.all(14),
              borderRadius: 16,
              border: Border.all(
                color: isSecret ? AppColors.accentGold : AppColors.border,
                width: isSecret ? 1.5 : 1,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isSecret ? AppColors.accentGold.withOpacity(0.2) : AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: isSecret ? AppColors.accentGold : AppColors.border),
                            ),
                            child: Text(
                              ending.rarity.toUpperCase(),
                              style: TextStyle(
                                color: isSecret ? AppColors.accentGold : Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            ending.title.isNotEmpty ? ending.title : 'Ending ${index + 1}',
                            style: AppTypography.storyCardTitle.copyWith(fontSize: 14),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: AppColors.primaryYellow, size: 20),
                            onPressed: () => _showEditEndingDialog(ending),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                            onPressed: () => _deleteEnding(ending.id),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ending.description.isNotEmpty ? ending.description : '(No ending narrative written yet. Tap edit icon to write)',
                    style: TextStyle(
                      color: ending.description.isNotEmpty ? AppColors.secondaryText : AppColors.textPlaceholder,
                      fontSize: 12.5,
                      fontStyle: ending.description.isEmpty ? FontStyle.italic : FontStyle.normal,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ==========================================
  // Step 4: Review, Preview & Publish
  // ==========================================
  Widget _buildStepReview() {
    final validation = _validationResult;

    return ListView(
      key: const ValueKey('step_review'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        Text('Step 5 of 5', style: AppTypography.caption.copyWith(color: AppColors.primaryYellow, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Review & Publish', style: AppTypography.screenTitle.copyWith(fontSize: 20)),
        const SizedBox(height: 4),
        Text('Verify your branching logic, test play the story, and publish to TWIST.', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 18),

        // 1. Validation Checklist Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: validation.isValid ? const Color(0x1F22C55E) : const Color(0x1FEF4444),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: validation.isValid ? AppColors.success : AppColors.error,
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    validation.isValid ? Icons.check_circle_rounded : Icons.warning_rounded,
                    color: validation.isValid ? AppColors.success : AppColors.error,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    validation.isValid ? 'Validation Checks Passed!' : '${validation.errors.length} Issues to Fix',
                    style: TextStyle(
                      color: validation.isValid ? AppColors.success : AppColors.error,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (validation.isValid)
                const Text(
                  'Every playable path leads to an ending with zero broken branches. Your story is ready for players!',
                  style: TextStyle(color: Colors.white, fontSize: 12.5),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: validation.errors.map((err) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                          Expanded(
                            child: Text(err, style: const TextStyle(color: Colors.white, fontSize: 12.5)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

              if (validation.warnings.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Divider(color: AppColors.border),
                const SizedBox(height: 4),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: validation.warnings.map((w) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.primaryYellow),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(w, style: const TextStyle(color: AppColors.secondaryText, fontSize: 11.5)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 2. Story Overview Card
        GlassCard(
          padding: const EdgeInsets.all(16),
          borderRadius: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _titleController.text.isNotEmpty ? _titleController.text : 'Untitled Story',
                style: AppTypography.storyCardTitle.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                '${_selectedCategory ?? 'Uncategorized'} • ${(_nodes.length * 1.5).ceil()} min read',
                style: AppTypography.caption.copyWith(color: AppColors.primaryYellow, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                _descriptionController.text.isNotEmpty ? _descriptionController.text : 'No description provided.',
                style: const TextStyle(color: AppColors.secondaryText, fontSize: 12.5),
              ),
              const Divider(color: AppColors.border, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatPill('${_nodes.length}', 'Scenes'),
                  _buildStatPill('${_nodes.fold<int>(0, (sum, n) => sum + n.choices.length)}', 'Choices'),
                  _buildStatPill('${_endings.length}', 'Endings'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 3. Test Play Preview Mode
        TwistButton(
          width: double.infinity,
          height: 50,
          text: 'Test Play Preview',
          icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
          variant: TwistButtonVariant.glass,
          textStyle: AppTypography.buttonText.copyWith(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          onPressed: _startPreview,
        ),
        const SizedBox(height: 12),

        // 4. Publish Button
        TwistButton(
          width: double.infinity,
          height: 52,
          text: _isPublishing ? 'Publishing to TWIST...' : 'Publish Story to TWIST',
          icon: _isPublishing ? null : const Icon(Icons.rocket_launch_rounded, color: Color(0xFF0B0B0F), size: 20),
          variant: TwistButtonVariant.primaryGradient,
          isLoading: _isPublishing,
          textStyle: AppTypography.buttonText.copyWith(
            color: const Color(0xFF0B0B0F),
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
          onPressed: _isPublishing ? null : _publishStory,
        ),
      ],
    );
  }

  Widget _buildStatPill(String count, String label) {
    return Column(
      children: [
        Text(count, style: AppTypography.statNumber.copyWith(fontSize: 17, color: AppColors.primaryYellow)),
        const SizedBox(height: 2),
        Text(label, style: AppTypography.statLabel.copyWith(fontSize: 11)),
      ],
    );
  }

  // ==========================================
  // Bottom Bar
  // ==========================================
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            TwistButton(
              text: '← Back',
              height: 42,
              width: 100,
              variant: TwistButtonVariant.glass,
              textStyle: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              onPressed: () => _goToStep(_currentStep - 1),
            )
          else
            const SizedBox(width: 100),

          if (_currentStep < 4)
            TwistButton(
              text: 'Next Step →',
              height: 42,
              width: 130,
              variant: TwistButtonVariant.primaryGradient,
              textStyle: const TextStyle(color: Color(0xFF0B0B0F), fontSize: 13, fontWeight: FontWeight.bold),
              onPressed: () {
                if (_currentStep == 0) {
                  // Validate step 0 fields
                  final title = _titleController.text.trim();
                  final desc = _descriptionController.text.trim();
                  setState(() {
                    _titleError = title.isEmpty ? 'Title is required' : null;
                    _descriptionError = desc.isEmpty ? 'Description is required' : null;
                    _categoryError = _selectedCategory == null ? 'Select a category' : null;
                  });
                  if (title.isEmpty || desc.isEmpty || _selectedCategory == null) return;
                }
                _goToStep(_currentStep + 1);
              },
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}

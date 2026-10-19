import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/story_model.dart';
import '../models/story_node_model.dart';
import '../models/story_choice_model.dart';
import '../models/story_ending_model.dart';
import '../models/story_play_model.dart';
import '../models/user_choice_model.dart';
import '../repositories/story_repository.dart';
import '../core/services/analytics_service.dart';

enum PlayerStatus {
  idle,
  loading,
  playing,
  transitioning,
  ended,
  error,
}

class StoryPlayerProvider extends ChangeNotifier {
  final StoryRepository _storyRepository;
  final AnalyticsService _analyticsService;
  final _uuid = const Uuid();

  StoryModel? _story;
  StoryNodeModel? _currentNode;
  StoryEndingModel? _currentEnding;
  PlayerStatus _status = PlayerStatus.idle;
  String? _errorMessage;

  String _sessionId = '';
  final List<String> _visitedNodeIds = [];
  final List<StoryChoiceModel> _chosenChoices = [];
  final List<StoryNodeModel> _visitedNodes = [];
  Set<String> _unlockedEndingIds = {};
  List<StoryEndingModel> _allStoryEndings = [];

  // Getters
  StoryModel? get story => _story;
  StoryNodeModel? get currentNode => _currentNode;
  StoryEndingModel? get currentEnding => _currentEnding;
  PlayerStatus get status => _status;
  bool get isLoading => _status == PlayerStatus.loading;
  bool get isTransitioning => _status == PlayerStatus.transitioning;
  bool get hasEnded => _status == PlayerStatus.ended;
  String? get errorMessage => _errorMessage;

  List<StoryChoiceModel> get chosenChoices => List.unmodifiable(_chosenChoices);
  List<String> get visitedNodeIds => List.unmodifiable(_visitedNodeIds);
  Set<String> get unlockedEndingIds => _unlockedEndingIds;
  List<StoryEndingModel> get allStoryEndings => _allStoryEndings;

  int get choicesCount => _chosenChoices.length;
  int get currentSceneNumber => _currentNode?.sceneNumber ?? 1;

  StoryPlayerProvider(this._storyRepository, this._analyticsService);

  Future<void> startStory({
    required StoryModel story,
    required String userId,
    String? startNodeId,
  }) async {
    _story = story;
    _status = PlayerStatus.loading;
    _errorMessage = null;
    _visitedNodeIds.clear();
    _chosenChoices.clear();
    _visitedNodes.clear();
    _currentEnding = null;
    _sessionId = _uuid.v4();
    notifyListeners();

    _analyticsService.logStoryStart(
      storyId: story.id,
      storyTitle: story.title,
    );

    try {
      // Load all endings metadata for this story
      _allStoryEndings = await _storyRepository.getStoryEndings(story.id);
      _unlockedEndingIds = _storyRepository.getUnlockedEndingIds(story.id);

      final targetNodeId = startNodeId ?? story.startNodeId;
      final node = await _storyRepository.getStoryNode(story.id, targetNodeId);

      if (node != null) {
        _currentNode = node;
        _visitedNodeIds.add(node.nodeId);
        _visitedNodes.add(node);
        _status = PlayerStatus.playing;
      } else {
        _status = PlayerStatus.error;
        _errorMessage = 'Could not load story scene.';
      }
    } catch (e) {
      _status = PlayerStatus.error;
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<void> selectChoice({
    required StoryChoiceModel choice,
    required String userId,
  }) async {
    if (_status != PlayerStatus.playing || _currentNode == null || _story == null) return;

    _status = PlayerStatus.transitioning;
    _chosenChoices.add(choice);
    notifyListeners();

    // 1. Record analytics
    _analyticsService.logChoiceSelected(
      storyId: _story!.id,
      nodeId: _currentNode!.nodeId,
      choiceId: choice.id,
      choiceLabel: choice.label,
      sceneNumber: _currentNode!.sceneNumber,
    );

    // 2. Record choice locally without per-choice Firestore writes
    final userChoice = UserChoiceModel(
      id: _uuid.v4(),
      userId: userId,
      storyId: _story!.id,
      nodeId: _currentNode!.nodeId,
      choiceId: choice.id,
      choiceLabel: choice.label,
      chosenAt: DateTime.now(),
    );
    await _storyRepository.recordUserChoice(userChoice);

    // Brief tension pause for cinematic transition effect
    await Future.delayed(const Duration(milliseconds: 400));

    // 3. Branching logic: Check if choice directly triggers an ending
    if (choice.leadsToEnding) {
      await _triggerEnding(choice.endingId!, userId);
      return;
    }

    // 4. Branching logic: Advance to next story node
    if (choice.nextNodeId != null && choice.nextNodeId!.isNotEmpty) {
      final nextNode = await _storyRepository.getStoryNode(_story!.id, choice.nextNodeId!);
      if (nextNode != null) {
        _currentNode = nextNode;
        _visitedNodeIds.add(nextNode.nodeId);
        _visitedNodes.add(nextNode);

        // Check if the next node is an ending node itself
        if (nextNode.isEnding && nextNode.endingId != null) {
          await _triggerEnding(nextNode.endingId!, userId);
          return;
        }

        _status = PlayerStatus.playing;
      } else {
        _status = PlayerStatus.error;
        _errorMessage = 'Branching node not found.';
      }
    } else {
      _status = PlayerStatus.error;
      _errorMessage = 'Unlinked choice branch.';
    }

    notifyListeners();
  }

  Future<void> _triggerEnding(String endingId, String userId) async {
    if (_story == null) return;

    final ending = await _storyRepository.getEndingById(_story!.id, endingId);
    _currentEnding = ending;
    _status = PlayerStatus.ended;

    // Persist completed play session with full choice history to Firestore and unlock ending locally
    await _storyRepository.recordStoryPlay(
      StoryPlayModel(
        id: _sessionId,
        storyId: _story!.id,
        userId: userId,
        nodesVisited: List.from(_visitedNodeIds),
        choiceIds: _chosenChoices.map((c) => c.id).toList(),
        endingId: endingId,
        isCompleted: true,
        startedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        completedAt: DateTime.now(),
      ),
    );

    _unlockedEndingIds = _storyRepository.getUnlockedEndingIds(_story!.id);

    // Track completion & ending unlocked
    _analyticsService.logStoryCompleted(
      storyId: _story!.id,
      endingId: endingId,
      choicesCount: _chosenChoices.length,
    );

    if (ending != null) {
      _analyticsService.logEndingUnlocked(
        storyId: _story!.id,
        endingId: ending.id,
        endingTitle: ending.title,
        rarity: ending.rarity,
        isSecret: ending.isSecret,
      );
    }

    notifyListeners();
  }

  Future<void> replayCurrentStory(String userId) async {
    if (_story == null) return;
    _analyticsService.logStoryReplay(storyId: _story!.id);
    await startStory(story: _story!, userId: userId);
  }

  Future<void> refreshEndings() async {
    if (_story == null) return;
    _allStoryEndings = await _storyRepository.getStoryEndings(_story!.id);
    _unlockedEndingIds = _storyRepository.getUnlockedEndingIds(_story!.id);
    notifyListeners();
  }
}

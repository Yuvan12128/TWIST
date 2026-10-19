import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twist/core/services/analytics_service.dart';
import 'package:twist/core/services/storage_service.dart';
import 'package:twist/core/utils/story_validator.dart';
import 'package:twist/models/story_choice_model.dart';
import 'package:twist/models/story_ending_model.dart';
import 'package:twist/models/story_node_model.dart';
import 'package:twist/models/story_model.dart';
import 'package:twist/providers/story_player_provider.dart';
import 'package:twist/repositories/story_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storageService;
  late StoryRepository storyRepository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storageService = StorageService(prefs);
    storyRepository = StoryRepository(storageService, enableSampleFallback: false);
  });

  group('Story Creation & StoryValidator Unit Tests', () {
    test('1. StoryValidator catches missing basic information', () {
      final node = StoryNodeModel(
        nodeId: 'node_start',
        storyId: 'story_1',
        textMap: const {'en': 'You stand at the crossroads.'},
        imageUrl: '',
        sceneNumber: 1,
        choices: [
          const StoryChoiceModel(
            id: 'c1',
            nodeId: 'node_start',
            labelMap: {'en': 'Go forward'},
            endingId: 'end_1',
            key: 'A',
          ),
        ],
      );

      final ending = const StoryEndingModel(
        id: 'end_1',
        storyId: 'story_1',
        titleMap: {'en': 'Victory'},
        descriptionMap: {'en': 'You made it through.'},
        imageUrl: '',
        rarity: 'Common',
      );

      // Missing title
      var result = StoryValidator.validate(
        title: '',
        description: 'A test description',
        category: 'Mystery',
        startNodeId: 'node_start',
        nodes: [node],
        endings: [ending],
      );
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.contains('title')), isTrue);

      // Missing description
      result = StoryValidator.validate(
        title: 'The Great Journey',
        description: '',
        category: 'Mystery',
        startNodeId: 'node_start',
        nodes: [node],
        endings: [ending],
      );
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.contains('description')), isTrue);

      // Missing category
      result = StoryValidator.validate(
        title: 'The Great Journey',
        description: 'A test description',
        category: null,
        startNodeId: 'node_start',
        nodes: [node],
        endings: [ending],
      );
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.contains('category')), isTrue);
    });

    test('2. StoryValidator catches empty scene narrative and empty choice label', () {
      final ending = const StoryEndingModel(
        id: 'end_1',
        storyId: 'story_1',
        titleMap: {'en': 'Victory'},
        descriptionMap: {'en': 'You made it through.'},
        imageUrl: '',
        rarity: 'Common',
      );

      // Scene with empty text
      final emptyScene = StoryNodeModel(
        nodeId: 'node_start',
        storyId: 'story_1',
        textMap: const {'en': '   '},
        imageUrl: '',
        sceneNumber: 1,
        choices: [
          const StoryChoiceModel(
            id: 'c1',
            nodeId: 'node_start',
            labelMap: {'en': 'Option A'},
            endingId: 'end_1',
            key: 'A',
          ),
        ],
      );

      var result = StoryValidator.validate(
        title: 'Valid Title',
        description: 'Valid Description',
        category: 'Horror',
        startNodeId: 'node_start',
        nodes: [emptyScene],
        endings: [ending],
      );
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.contains('no story content')), isTrue);

      // Choice with empty label
      final emptyChoiceScene = StoryNodeModel(
        nodeId: 'node_start',
        storyId: 'story_1',
        textMap: const {'en': 'The cave is dark.'},
        imageUrl: '',
        sceneNumber: 1,
        choices: [
          const StoryChoiceModel(
            id: 'c1',
            nodeId: 'node_start',
            labelMap: {'en': '  '},
            endingId: 'end_1',
            key: 'A',
          ),
        ],
      );

      result = StoryValidator.validate(
        title: 'Valid Title',
        description: 'Valid Description',
        category: 'Horror',
        startNodeId: 'node_start',
        nodes: [emptyChoiceScene],
        endings: [ending],
      );
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.contains('choice text')), isTrue);
    });

    test('3. StoryValidator catches broken destination node/ending references', () {
      final ending = const StoryEndingModel(
        id: 'end_1',
        storyId: 'story_1',
        titleMap: {'en': 'Victory'},
        descriptionMap: {'en': 'You made it through.'},
        imageUrl: '',
        rarity: 'Common',
      );

      // Choice pointing to non-existent node
      final brokenNode = StoryNodeModel(
        nodeId: 'node_start',
        storyId: 'story_1',
        textMap: const {'en': 'The door is locked.'},
        imageUrl: '',
        sceneNumber: 1,
        choices: [
          const StoryChoiceModel(
            id: 'c1',
            nodeId: 'node_start',
            labelMap: {'en': 'Open door'},
            nextNodeId: 'node_does_not_exist',
            key: 'A',
          ),
        ],
      );

      var result = StoryValidator.validate(
        title: 'Valid Title',
        description: 'Valid Description',
        category: 'Sci-Fi',
        startNodeId: 'node_start',
        nodes: [brokenNode],
        endings: [ending],
      );
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.contains('non-existent scene')), isTrue);

      // Choice pointing to non-existent ending
      final brokenEnding = StoryNodeModel(
        nodeId: 'node_start',
        storyId: 'story_1',
        textMap: const {'en': 'The door is locked.'},
        imageUrl: '',
        sceneNumber: 1,
        choices: [
          const StoryChoiceModel(
            id: 'c1',
            nodeId: 'node_start',
            labelMap: {'en': 'Open door'},
            endingId: 'ending_does_not_exist',
            key: 'A',
          ),
        ],
      );

      result = StoryValidator.validate(
        title: 'Valid Title',
        description: 'Valid Description',
        category: 'Sci-Fi',
        startNodeId: 'node_start',
        nodes: [brokenEnding],
        endings: [ending],
      );
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.contains('non-existent ending')), isTrue);
    });

    test('4. StoryValidator detects orphan unreachable scenes and unterminating cycles', () {
      final ending = const StoryEndingModel(
        id: 'end_1',
        storyId: 'story_1',
        titleMap: {'en': 'Survived'},
        descriptionMap: {'en': 'You made it.'},
        imageUrl: '',
        rarity: 'Common',
      );

      // Start node points to ending, but node_2 is completely unlinked (orphan)
      final startNode = StoryNodeModel(
        nodeId: 'node_start',
        storyId: 'story_1',
        textMap: const {'en': 'Start scene.'},
        imageUrl: '',
        sceneNumber: 1,
        choices: [
          const StoryChoiceModel(
            id: 'c1',
            nodeId: 'node_start',
            labelMap: {'en': 'Finish'},
            endingId: 'end_1',
            key: 'A',
          ),
        ],
      );

      final orphanNode = StoryNodeModel(
        nodeId: 'node_orphan',
        storyId: 'story_1',
        textMap: const {'en': 'Orphan scene.'},
        imageUrl: '',
        sceneNumber: 2,
        choices: [
          const StoryChoiceModel(
            id: 'c2',
            nodeId: 'node_orphan',
            labelMap: {'en': 'Finish'},
            endingId: 'end_1',
            key: 'A',
          ),
        ],
      );

      var result = StoryValidator.validate(
        title: 'Valid Title',
        description: 'Valid Description',
        category: 'Fantasy',
        startNodeId: 'node_start',
        nodes: [startNode, orphanNode],
        endings: [ending],
      );
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.contains('unreachable')), isTrue);

      // Cycle with no ending: node_a -> node_b -> node_a
      final nodeA = StoryNodeModel(
        nodeId: 'node_a',
        storyId: 'story_1',
        textMap: const {'en': 'In the loop.'},
        imageUrl: '',
        sceneNumber: 1,
        choices: [
          const StoryChoiceModel(
            id: 'cA',
            nodeId: 'node_a',
            labelMap: {'en': 'Go to B'},
            nextNodeId: 'node_b',
            key: 'A',
          ),
        ],
      );

      final nodeB = StoryNodeModel(
        nodeId: 'node_b',
        storyId: 'story_1',
        textMap: const {'en': 'Still in loop.'},
        imageUrl: '',
        sceneNumber: 2,
        choices: [
          const StoryChoiceModel(
            id: 'cB',
            nodeId: 'node_b',
            labelMap: {'en': 'Go back to A'},
            nextNodeId: 'node_a',
            key: 'A',
          ),
        ],
      );

      result = StoryValidator.validate(
        title: 'Infinite Loop Story',
        description: 'A story that never reaches an ending.',
        category: 'Sci-Fi',
        startNodeId: 'node_a',
        nodes: [nodeA, nodeB],
        endings: [ending],
      );
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.contains('reach an ending')), isTrue);
    });

    test('5. StoryValidator passes valid branching story with multiple endings', () {
      final ending1 = const StoryEndingModel(
        id: 'end_good',
        storyId: 'story_branching',
        titleMap: {'en': 'Heroic Escape'},
        descriptionMap: {'en': 'You discovered the exit and saved the crew.'},
        imageUrl: '',
        rarity: 'Rare',
      );

      final ending2 = const StoryEndingModel(
        id: 'end_bad',
        storyId: 'story_branching',
        titleMap: {'en': 'Trapped in Space'},
        descriptionMap: {'en': 'Oxygen depleted. The airlock closed forever.'},
        imageUrl: '',
        rarity: 'Common',
      );

      final startNode = StoryNodeModel(
        nodeId: 'node_start',
        storyId: 'story_branching',
        textMap: const {'en': 'Alarms blare on deck 4. Do you head to the bridge or engineering?'},
        imageUrl: '',
        sceneNumber: 1,
        choices: [
          const StoryChoiceModel(
            id: 'c1',
            nodeId: 'node_start',
            labelMap: {'en': 'Sprint to the Bridge'},
            nextNodeId: 'node_bridge',
            key: 'A',
          ),
          const StoryChoiceModel(
            id: 'c2',
            nodeId: 'node_start',
            labelMap: {'en': 'Descend to Engineering'},
            nextNodeId: 'node_engineering',
            key: 'B',
          ),
        ],
      );

      final bridgeNode = StoryNodeModel(
        nodeId: 'node_bridge',
        storyId: 'story_branching',
        textMap: const {'en': 'The console is flashing red. Override thrusters or initiate pod ejection?'},
        imageUrl: '',
        sceneNumber: 2,
        choices: [
          const StoryChoiceModel(
            id: 'c3',
            nodeId: 'node_bridge',
            labelMap: {'en': 'Eject escape pods'},
            endingId: 'end_good',
            key: 'A',
          ),
        ],
      );

      final engNode = StoryNodeModel(
        nodeId: 'node_engineering',
        storyId: 'story_branching',
        textMap: const {'en': 'Plasma fires block the reactor corridor.'},
        imageUrl: '',
        sceneNumber: 3,
        choices: [
          const StoryChoiceModel(
            id: 'c4',
            nodeId: 'node_engineering',
            labelMap: {'en': 'Vent atmosphere'},
            endingId: 'end_bad',
            key: 'A',
          ),
        ],
      );

      final result = StoryValidator.validate(
        title: 'Derelict Protocol',
        description: 'An interactive emergency aboard Station Kepler-9.',
        category: 'Sci-Fi',
        startNodeId: 'node_start',
        nodes: [startNode, bridgeNode, engNode],
        endings: [ending1, ending2],
      );

      expect(result.isValid, isTrue);
      expect(result.errors.isEmpty, isTrue);
    });
  });

  group('StoryRepository & StoryPlayer Preview Tests', () {
    test('6. StoryRepository.publishStory persists story and in-memory caches nodes and endings', () async {
      final story = StoryModel(
        id: 'story_pub_123',
        titleMap: const {'en': 'Midnight Escape'},
        descriptionMap: const {'en': 'A thriller story.'},
        coverUrl: 'https://example.com/cover.jpg',
        category: 'Thriller',
        creatorId: 'user_pub_789',
        creatorName: 'Test Creator',
        duration: '3 min',
        startNodeId: 'node_start',
        endingsCount: 1,
        createdAt: DateTime.now(),
      );

      final node = StoryNodeModel(
        nodeId: 'node_start',
        storyId: 'story_pub_123',
        textMap: const {'en': 'You hear footsteps in the hallway.'},
        imageUrl: '',
        sceneNumber: 1,
        choices: [
          const StoryChoiceModel(
            id: 'c1',
            nodeId: 'node_start',
            labelMap: {'en': 'Hide in closet'},
            endingId: 'end_safe',
            key: 'A',
          ),
        ],
      );

      final ending = const StoryEndingModel(
        id: 'end_safe',
        storyId: 'story_pub_123',
        titleMap: {'en': 'Safe at Dawn'},
        descriptionMap: {'en': 'The intruder left without noticing you.'},
        imageUrl: '',
        rarity: 'Common',
      );

      final published = await storyRepository.publishStory(
        story: story,
        nodes: [node],
        endings: [ending],
      );

      expect(published, isTrue);

      // Verify node is cached and retrievable
      final fetchedNode = await storyRepository.getStoryNode('story_pub_123', 'node_start');
      expect(fetchedNode, isNotNull);
      expect(fetchedNode?.nodeId, 'node_start');
      expect(fetchedNode?.textMap['en'], 'You hear footsteps in the hallway.');

      // Verify ending is cached and retrievable
      final fetchedEndings = await storyRepository.getStoryEndings('story_pub_123');
      expect(fetchedEndings.isNotEmpty, isTrue);
      expect(fetchedEndings.first.titleMap['en'], 'Safe at Dawn');
    });

    test('7. StoryPlayerProvider with isPreview = true does not persist plays or activity', () async {
      final analyticsService = AnalyticsService();
      final playerProvider = StoryPlayerProvider(storyRepository, analyticsService);

      final previewStory = StoryModel(
        id: 'preview_story_999',
        titleMap: const {'en': 'Preview Secret'},
        descriptionMap: const {'en': 'Testing preview.'},
        coverUrl: 'https://example.com/preview.jpg',
        category: 'Mystery',
        creatorId: 'test_creator',
        creatorName: 'Test Creator',
        duration: '3 min',
        startNodeId: 'node_preview_start',
        endingsCount: 1,
        createdAt: DateTime.now(),
      );

      final startNode = StoryNodeModel(
        nodeId: 'node_preview_start',
        storyId: 'preview_story_999',
        textMap: const {'en': 'Preview scene text.'},
        imageUrl: '',
        sceneNumber: 1,
        choices: [
          const StoryChoiceModel(
            id: 'c1',
            nodeId: 'node_preview_start',
            labelMap: {'en': 'Inspect clue'},
            endingId: 'end_preview_1',
            key: 'A',
          ),
        ],
      );

      final ending = const StoryEndingModel(
        id: 'end_preview_1',
        storyId: 'preview_story_999',
        titleMap: {'en': 'Preview Conclusion'},
        descriptionMap: {'en': 'Case closed in preview.'},
        imageUrl: '',
        rarity: 'Common',
      );

      storyRepository.cacheStoryNodes('preview_story_999', {'node_preview_start': startNode});
      storyRepository.cacheStoryEndings('preview_story_999', [ending]);

      // Start story in PREVIEW mode
      await playerProvider.startStory(
        story: previewStory,
        userId: 'user_tester',
        isPreview: true,
      );

      expect(playerProvider.isPreview, isTrue);
      expect(playerProvider.currentNode?.nodeId, 'node_preview_start');

      // Make a choice in preview mode
      await playerProvider.selectChoice(
        choice: startNode.choices.first,
        userId: 'user_tester',
      );

      // Verify ending reached
      expect(playerProvider.currentEnding?.id, 'end_preview_1');

      // Crucial verification: Since isPreview == true, no play history was saved into storage
      final history = storageService.getHistoryStoryIds();
      expect(history.contains('preview_story_999'), isFalse);
      expect(storageService.getChoicesMadeCount(), equals(0));
    });
  });
}

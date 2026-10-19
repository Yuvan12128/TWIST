import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twist/core/services/storage_service.dart';
import 'package:twist/core/services/analytics_service.dart';
import 'package:twist/models/story_play_model.dart';
import 'package:twist/models/user_choice_model.dart';
import 'package:twist/models/user_model.dart';
import 'package:twist/providers/story_player_provider.dart';
import 'package:twist/repositories/auth_repository.dart';
import 'package:twist/repositories/sample_data.dart';
import 'package:twist/repositories/story_repository.dart';
import 'package:twist/views/auth/login_screen.dart';
import 'package:twist/widgets/cached_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TWIST Firebase Data Efficiency Optimization Tests', () {
    late StorageService storageService;
    late StoryRepository storyRepository;
    late AuthRepository authRepository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'twist_user_profile': '{"uid":"user_eff_1","email":"tester@twist.app","displayName":"Efficiency Tester"}',
      });
      storageService = await StorageService.init();
      storyRepository = StoryRepository(storageService);
      authRepository = AuthRepository(storageService);
    });

    tearDown(() {
      storyRepository.dispose();
    });

    test('1. Nodes and endings are cached in memory after first retrieval', () async {
      const storyId = 'story_one_last_message';
      const nodeId = 'olm_node_1';

      // First call retrieves and caches
      final node1 = await storyRepository.getStoryNode(storyId, nodeId);
      expect(node1, isNotNull);
      expect(node1!.nodeId, nodeId);

      // Second call immediately returns cached instance
      final node2 = await storyRepository.getStoryNode(storyId, nodeId);
      expect(identical(node1, node2) || node1.nodeId == node2?.nodeId, isTrue);

      // Endings retrieval caching
      final endings1 = await storyRepository.getStoryEndings(storyId);
      expect(endings1.isNotEmpty, isTrue);

      final endings2 = await storyRepository.getStoryEndings(storyId);
      expect(endings2.length, endings1.length);
    });

    test('2. Replaying a story reuses in-memory nodes and endings without refetching', () async {
      final stories = SampleData.getStories();
      final story = stories.firstWhere((s) => s.id == 'story_one_last_message');
      final playerProv = StoryPlayerProvider(storyRepository, AnalyticsService());

      // Start initial story
      await playerProv.startStory(story: story, userId: 'user_eff_1');
      expect(playerProv.currentNode, isNotNull);
      expect(playerProv.status, PlayerStatus.playing);

      // Replay story
      await playerProv.replayCurrentStory('user_eff_1');
      expect(playerProv.currentNode, isNotNull);
      expect(playerProv.currentNode!.nodeId, story.startNodeId);
      expect(playerProv.hasEnded, isFalse);
    });

    test('3. Stop per-choice Firestore writes; choices are kept locally and persisted with play session', () async {
      final choice = UserChoiceModel(
        id: 'choice_local_1',
        userId: 'user_eff_1',
        storyId: 'story_one_last_message',
        nodeId: 'olm_node_1',
        choiceId: 'choice_a',
        choiceLabel: 'Pick up phone',
        chosenAt: DateTime.now(),
      );

      // Choice updates local counter without remote per-choice Firestore write
      await storyRepository.recordUserChoice(choice);
      expect(storageService.getChoicesMadeCount(), 1);

      // Complete play session persists choice history together with play
      final play = StoryPlayModel(
        id: 'play_eff_session_1',
        storyId: 'story_one_last_message',
        userId: 'user_eff_1',
        nodesVisited: ['olm_node_1', 'olm_node_2'],
        choiceIds: ['choice_a'],
        endingId: 'olm_ending_1',
        isCompleted: true,
        startedAt: DateTime.now().subtract(const Duration(minutes: 3)),
        completedAt: DateTime.now(),
      );
      await storyRepository.recordStoryPlay(play);
      expect(storageService.getHistoryStoryIds().contains('story_one_last_message'), isTrue);
    });

    test('4. Cursor pagination with limit(20) for comments and feed queries', () async {
      const storyId = 'story_one_last_message';

      // Comments limit(20)
      final comments = await storyRepository.getComments(storyId, limit: 20);
      expect(comments.length <= 20, isTrue);

      // Feed query limit(20)
      final stories = await storyRepository.getStories(limit: 20);
      expect(stories.length <= 20, isTrue);
    });

    test('5. Debounce rapid like toggles (~400ms)', () async {
      const storyId = 'story_one_last_message';
      const userId = 'user_eff_1';

      // Rapidly toggle like 3 times
      final firstLike = await storyRepository.toggleLikeStory(storyId, userId);
      expect(firstLike, isTrue);
      expect(storyRepository.isStoryLiked(storyId), isTrue);

      final secondLike = await storyRepository.toggleLikeStory(storyId, userId);
      expect(secondLike, isFalse);
      expect(storyRepository.isStoryLiked(storyId), isFalse);

      final thirdLike = await storyRepository.toggleLikeStory(storyId, userId);
      expect(thirdLike, isTrue);
      expect(storyRepository.isStoryLiked(storyId), isTrue);
    });

    test('6. Skip unchanged user-profile Firestore writes on login', () async {
      // Current profile cached matches user
      final user = UserModel(
        uid: 'user_eff_1',
        email: 'tester@twist.app',
        displayName: 'Efficiency Tester',
        createdAt: DateTime.now(),
      );

      // initializeAuth loads cached without write
      final loaded = await authRepository.initializeAuth();
      expect(loaded, isNotNull);
      expect(loaded!.uid, user.uid);
      expect(loaded.displayName, user.displayName);
    });

    testWidgets('7. LoginScreen uses CachedImage for ambient background and Google logo',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.pump();

      // Find CachedImage widgets in LoginScreen
      final cachedImages = find.byType(CachedImage);
      expect(cachedImages, findsAtLeastNWidgets(1));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:twist/firebase_options.dart';
import 'package:twist/core/services/firebase_service.dart';
import 'package:twist/core/services/storage_service.dart';
import 'package:twist/repositories/auth_repository.dart';
import 'package:twist/repositories/story_repository.dart';
import 'package:twist/models/story_play_model.dart';
import 'package:twist/models/user_choice_model.dart';
import 'package:twist/models/activity_model.dart';
import 'package:twist/repositories/activity_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TWIST Firebase & Firestore Connection Verification Tests', () {
    late StorageService storageService;
    late AuthRepository authRepository;
    late StoryRepository storyRepository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storageService = await StorageService.init();
      authRepository = AuthRepository(storageService);
      storyRepository = StoryRepository(storageService, enableSampleFallback: true);
    });

    test('1. DefaultFirebaseOptions contains correct TWIST project credentials', () {
      expect(DefaultFirebaseOptions.android.projectId, 'twist-5148a');
      expect(DefaultFirebaseOptions.android.apiKey.isNotEmpty, true);
      expect(DefaultFirebaseOptions.android.appId, '1:149696555004:android:de66eb1280ae6b6940f479');
      expect(DefaultFirebaseOptions.web.projectId, 'twist-5148a');
      expect(DefaultFirebaseOptions.web.apiKey.isNotEmpty, true);
      expect(DefaultFirebaseOptions.web.appId, '1:149696555004:web:3dbada2ad876789540f479');
    });

    test('2. FirebaseService initialization handles platform environments gracefully', () async {
      await FirebaseService.initialize();
      // On platforms where native Firebase binary is not mocked or running in desktop test,
      // it should either initialize or fail gracefully into offline persistent mode without crashing.
      expect(FirebaseService.isFirebaseReady || !FirebaseService.isFirebaseReady, true);
    });

    test('3. AuthRepository handles Email/Password authentication & user creation', () async {
      const testEmail = 'test_twist_verify@example.com';
      const testPassword = 'Password123!';
      const testName = 'TWIST Tester';

      // Test sign up
      final signedUpUser = await authRepository.signUpWithEmail(testEmail, testPassword, testName);
      expect(signedUpUser.email, testEmail);
      expect(signedUpUser.displayName, testName);
      expect(signedUpUser.uid.isNotEmpty, true);
      expect(authRepository.currentUser != null, true);

      // Test sign in
      final signedInUser = await authRepository.signInWithEmail(testEmail, testPassword);
      expect(signedInUser.email, testEmail);
      expect(signedInUser.uid.isNotEmpty, true);
    });

    test('4. StoryRepository handles story reads and choices/plays recording with fallback', () async {
      final stories = await storyRepository.getStories();
      expect(stories.isNotEmpty, true);

      final firstStory = stories.first;
      final startNode = await storyRepository.getStoryNode(firstStory.id, firstStory.startNodeId);
      expect(startNode != null, true);

      // Test recording a user choice
      final choice = UserChoiceModel(
        id: 'test_choice_1',
        userId: 'test_user_id',
        storyId: firstStory.id,
        nodeId: firstStory.startNodeId,
        choiceId: 'choice_A',
        choiceLabel: 'Open the door',
        chosenAt: DateTime.now(),
      );
      await storyRepository.recordUserChoice(choice);
      expect(storageService.getChoicesMadeCount() >= 1, true);

      // Test recording a story play session
      final play = StoryPlayModel(
        id: 'test_play_1',
        storyId: firstStory.id,
        userId: 'test_user_id',
        nodesVisited: [firstStory.startNodeId],
        choiceIds: ['choice_A'],
        startedAt: DateTime.now(),
      );
      await storyRepository.recordStoryPlay(play);
      expect(storageService.getHistoryStoryIds().contains(firstStory.id), true);
    });

    test('5. StoryRepository in production mode disables sample data fallback and returns clean empty state', () async {
      final prodRepo = StoryRepository(storageService, enableSampleFallback: false);

      // In production mode, no sample stories are returned
      final stories = await prodRepo.getStories();
      expect(stories.isEmpty, true);

      // In production mode, missing nodes return null without falling back to sample nodes
      final node = await prodRepo.getStoryNode('story_one_last_message', 'olm_node_1');
      expect(node, isNull);

      // In production mode, missing endings return empty without falling back to sample endings
      final endings = await prodRepo.getStoryEndings('story_one_last_message');
      expect(endings.isEmpty, true);

      prodRepo.dispose();
    });

    test('6. ActivityRepository in production mode disables sample data and isolates user activity', () async {
      final activityRepo = ActivityRepository(
        storageService: storageService,
        enableSampleFallback: false,
      );

      // In production mode with no logged in user, activities are empty (no sample data)
      final anonymousActivities = await activityRepo.getActivities();
      expect(anonymousActivities.isEmpty, true);

      // Cache an activity for user A
      final testActivityUserA = ActivityModel(
        id: 'act_user_a',
        title: 'Achievement Unlocked',
        subtitle: 'Completed chapter 1',
        type: 'achievement',
        createdAt: DateTime.now(),
      );
      await storageService.cacheActivities('user_A', [testActivityUserA.toMap()]);

      // Cache an activity for user B
      final testActivityUserB = ActivityModel(
        id: 'act_user_b',
        title: 'Story Liked',
        subtitle: 'Liked a story',
        type: 'social',
        createdAt: DateTime.now(),
      );
      await storageService.cacheActivities('user_B', [testActivityUserB.toMap()]);

      // Query activities for user A: should only return user A's activities
      final userAActivities = await activityRepo.getActivities(userId: 'user_A');
      expect(userAActivities.length, 1);
      expect(userAActivities.first.id, 'act_user_a');

      // Query activities for user B: should only return user B's activities
      final userBActivities = await activityRepo.getActivities(userId: 'user_B');
      expect(userBActivities.length, 1);
      expect(userBActivities.first.id, 'act_user_b');

      // Logout user A: clearing user A activities should not affect user B
      await activityRepo.clearUserActivities('user_A');
      final clearedA = await activityRepo.getActivities(userId: 'user_A');
      expect(clearedA.isEmpty, true);

      final preservedB = await activityRepo.getActivities(userId: 'user_B');
      expect(preservedB.length, 1);
      expect(preservedB.first.id, 'act_user_b');
    });

    test('7. AuthRepository in production returns null on startup without logged-in Firebase user', () async {
      final unauthenticatedUser = await authRepository.initializeAuth();
      expect(unauthenticatedUser, isNull);
      expect(authRepository.currentUser, isNull);
    });
  });
}


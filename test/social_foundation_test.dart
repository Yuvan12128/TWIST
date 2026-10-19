import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twist/core/services/storage_service.dart';
import 'package:twist/models/user_model.dart';
import 'package:twist/repositories/social_repository.dart';
import 'package:twist/repositories/story_repository.dart';
import 'package:twist/providers/auth_provider.dart';
import 'package:twist/repositories/auth_repository.dart';
import 'package:twist/providers/profile_provider.dart';
import 'package:twist/providers/story_feed_provider.dart';
import 'package:twist/core/localization/language_provider.dart';
import 'package:twist/core/services/analytics_service.dart';
import 'package:twist/views/profile/profile_screen.dart';
import 'package:twist/views/explore/explore_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storageService;
  late SocialRepository socialRepository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storageService = StorageService(prefs);
    socialRepository = SocialRepository(storageService);
  });

  group('TWIST Real User Connection & Social Foundation Tests', () {
    test('1. Follow and Unfollow works with deterministic IDs and prevents duplicate/self-follow', () async {
      const userA = 'user_alice_123';
      const userB = 'user_bob_456';

      final userAModel = UserModel(
        uid: userA,
        email: 'alice@twist.app',
        displayName: 'Alice Voyager',
        createdAt: DateTime.now(),
      );

      // Self follow should be rejected
      final selfFollowResult = await socialRepository.followUser(userA, currentUser: userAModel);
      expect(selfFollowResult, isFalse, reason: 'Users cannot follow themselves');

      // Check initial follow state
      final initialIsFollowing = await socialRepository.isFollowing(userB);
      expect(initialIsFollowing, isFalse);

      // Follow userB
      final followResult = await socialRepository.followUser(userB, currentUser: userAModel);
      expect(followResult, isTrue);

      // Follower count for userB
      final userBFollowers = await socialRepository.getFollowersCount(userB);
      expect(userBFollowers, equals(1));

      // Following count for userA
      final userAFollowing = await socialRepository.getFollowingCount(userA);
      expect(userAFollowing, equals(1));

      // Calling followUser again does not duplicate the relationship
      await socialRepository.followUser(userB, currentUser: userAModel);
      final deduplicatedFollowers = await socialRepository.getFollowersCount(userB);
      expect(deduplicatedFollowers, equals(1), reason: 'Follow relationship is idempotent');

      // Unfollow userB
      final unfollowResult = await socialRepository.unfollowUser(userB, currentUserId: userA);
      expect(unfollowResult, isTrue);

      final userBFollowersAfterUnfollow = await socialRepository.getFollowersCount(userB);
      expect(userBFollowersAfterUnfollow, equals(0));
    });

    test('2. Clean new user profile has 0 followers, 0 following and 0 stories', () {
      final newUser = UserModel(
        uid: 'new_google_uid_999',
        email: 'newuser@gmail.com',
        displayName: 'New Voyager',
        createdAt: DateTime.now(),
      );

      expect(newUser.followersCount, equals(0));
      expect(newUser.followingCount, equals(0));
      expect(newUser.storiesPlayedCount, equals(0));
      expect(newUser.endingsFoundCount, equals(0));
      expect(newUser.choicesMadeCount, equals(0));
      expect(newUser.isVerified, isFalse);

      final map = newUser.toMap();
      expect(map['followersCount'], equals(0));
      expect(map['followingCount'], equals(0));

      final restored = UserModel.fromMap(map, docId: 'new_google_uid_999');
      expect(restored.uid, equals('new_google_uid_999'));
      expect(restored.displayName, equals('New Voyager'));
      expect(restored.isVerified, isFalse);
    });

    testWidgets('3. ProfileScreen displays other user profile with Follow button and back arrow', (tester) async {
      final authRepo = AuthRepository(storageService);
      final authProv = AuthProvider(authRepo);
      final storyRepo = StoryRepository(storageService, enableSampleFallback: false);
      final profileProv = ProfileProvider(storyRepo, storageService, socialRepository: socialRepository);
      final feedProv = StoryFeedProvider(storyRepo, AnalyticsService());
      final langProv = LanguageProvider(storageService);

      final otherUser = UserModel(
        uid: 'creator_raghav_77',
        email: 'raghav@twist.app',
        displayName: 'Raghav Storyteller',
        bio: 'Master of mystery and sci-fi twists.',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProv),
            ChangeNotifierProvider.value(value: profileProv),
            ChangeNotifierProvider.value(value: feedProv),
            ChangeNotifierProvider.value(value: langProv),
          ],
          child: MaterialApp(
            home: ProfileScreen(
              userId: 'creator_raghav_77',
              initialUser: otherUser,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify name, bio, and Follow button appear
      expect(find.text('Raghav Storyteller'), findsAtLeastNWidgets(1));
      expect(find.text('@raghav'), findsOneWidget);
      expect(find.text('Master of mystery and sci-fi twists.'), findsOneWidget);
      expect(find.text('+ Follow'), findsOneWidget);
      expect(find.text('Published Stories'), findsOneWidget);
    });

    testWidgets('4. ExploreScreen includes Stories and Storytellers tab switcher', (tester) async {
      final storyRepo = StoryRepository(storageService, enableSampleFallback: false);
      final profileProv = ProfileProvider(storyRepo, storageService, socialRepository: socialRepository);
      final feedProv = StoryFeedProvider(storyRepo, AnalyticsService());
      final langProv = LanguageProvider(storageService);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: profileProv),
            ChangeNotifierProvider.value(value: feedProv),
            ChangeNotifierProvider.value(value: langProv),
          ],
          child: const MaterialApp(
            home: ExploreScreen(),
          ),
        ),
      );

      await tester.pump();

      // Verify Stories and Storytellers mode pills are present
      expect(find.text('Stories'), findsOneWidget);
      expect(find.text('Storytellers'), findsOneWidget);

      // Tap Storytellers tab
      await tester.tap(find.text('Storytellers'));
      await tester.pump();

      // Discover Storytellers prompt appears
      expect(find.text('Discover Storytellers'), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:twist/core/services/storage_service.dart';
import 'package:twist/core/services/firebase_service.dart';
import 'package:twist/repositories/auth_repository.dart';
import 'package:twist/repositories/activity_repository.dart';
import 'package:twist/core/services/analytics_service.dart';
import 'package:twist/repositories/story_repository.dart';
import 'package:twist/providers/story_feed_provider.dart';
import 'package:twist/providers/profile_provider.dart';
import 'package:twist/providers/auth_provider.dart';
import 'package:twist/providers/activity_provider.dart';
import 'package:twist/core/localization/language_provider.dart';
import 'package:twist/core/localization/app_localizations.dart';
import 'package:twist/core/localization/app_language.dart';
import 'package:twist/views/main_navigation_screen.dart';
import 'package:twist/views/home/home_feed_screen.dart';
import 'package:twist/views/profile/profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TWIST App Startup Performance Optimization Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'twist_user_profile': '{"uid":"cached_user_123","email":"fast@twist.app","displayName":"Fast Voyager"}',
      });
    });

    test('1. Concurrently initializing StorageService and FirebaseService completes efficiently', () async {
      final stopwatch = Stopwatch()..start();

      final storageFuture = StorageService.init();
      final firebaseFuture = FirebaseService.initialize();

      final storageService = await storageFuture;
      await firebaseFuture;
      stopwatch.stop();

      expect(storageService, isNotNull);
      // Concurrently executing storage & firebase should complete under 100ms in unit test
      expect(stopwatch.elapsedMilliseconds < 100, isTrue);
    });

    test('2. AuthRepository initializeAuth uses fast local cache path without blocking on network', () async {
      final storageService = await StorageService.init();
      final authRepo = AuthRepository(storageService);

      final stopwatch = Stopwatch()..start();
      final user = await authRepo.initializeAuth();
      stopwatch.stop();

      expect(user, isNotNull);
      expect(user!.uid, 'cached_user_123');
      expect(user.displayName, 'Fast Voyager');
      // Local cache path must be near instantaneous (under 15ms)
      expect(stopwatch.elapsedMilliseconds < 15, isTrue);
    });

    testWidgets('3. MainNavigationScreen lazily mounts only the active tab on startup',
        (WidgetTester tester) async {
      final storageService = await StorageService.init();
      final authRepo = AuthRepository(storageService);
      final storyRepo = StoryRepository(storageService);
      final activityRepo = ActivityRepository();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ActivityProvider>(
              create: (_) => ActivityProvider(activityRepo),
            ),
            ChangeNotifierProvider<StoryFeedProvider>(
              create: (_) => StoryFeedProvider(storyRepo, AnalyticsService()),
            ),
            ChangeNotifierProvider<ProfileProvider>(
              create: (_) => ProfileProvider(storyRepo, storageService),
            ),
            ChangeNotifierProvider<AuthProvider>(
              create: (_) => AuthProvider(authRepo),
            ),
            ChangeNotifierProvider<LanguageProvider>(
              create: (_) => LanguageProvider(storageService),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates(AppLanguage.en),
            home: const MainNavigationScreen(initialIndex: 0),
          ),
        ),
      );
      await tester.pump();

      // Verify HomeFeedScreen (Tab 0) is mounted on launch
      expect(find.byType(HomeFeedScreen), findsOneWidget);

      // Verify off-screen tabs like ProfileScreen (Tab 4) are NOT mounted on startup
      expect(find.byType(ProfileScreen), findsNothing);

      // Switch to Profile Tab (index 4)
      final profileNavFinder = find.text('Profile');
      expect(profileNavFinder, findsOneWidget);
      await tester.tap(profileNavFinder);
      await tester.pump();

      // Now ProfileScreen should be mounted on demand
      expect(find.byType(ProfileScreen), findsOneWidget);
    });
  });
}

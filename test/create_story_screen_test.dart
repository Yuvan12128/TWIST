import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twist/core/localization/app_language.dart';
import 'package:twist/core/localization/app_localizations.dart';
import 'package:twist/core/services/storage_service.dart';
import 'package:twist/providers/auth_provider.dart';
import 'package:twist/providers/profile_provider.dart';
import 'package:twist/repositories/auth_repository.dart';
import 'package:twist/repositories/social_repository.dart';
import 'package:twist/repositories/story_repository.dart';
import 'package:twist/views/create/create_story_screen.dart';
import 'package:twist/widgets/twist_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storageService;
  late AuthRepository authRepository;
  late AuthProvider authProvider;
  late StoryRepository storyRepository;
  late SocialRepository socialRepository;
  late ProfileProvider profileProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storageService = StorageService(prefs);
    authRepository = AuthRepository(storageService);
    authProvider = AuthProvider(authRepository);
    storyRepository = StoryRepository(storageService, enableSampleFallback: false);
    socialRepository = SocialRepository(storageService);
    profileProvider = ProfileProvider(storyRepository, storageService, socialRepository: socialRepository);

    // Mock active user
    await authProvider.signUpWithEmail('creator@twist.app', 'password123', 'Test Storyteller');
  });

  Widget buildTestableWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        Provider<StoryRepository>.value(value: storyRepository),
        ChangeNotifierProvider<ProfileProvider>.value(value: profileProvider),
      ],
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: [
          AppLocalizationsDelegate(AppLanguage.en),
        ],
        home: CreateStoryScreen(),
      ),
    );
  }

  group('CreateStoryScreen Validation & Step Flow Tests', () {
    testWidgets('1. Title, description and category start empty with correct placeholders', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Check Title placeholder
      expect(find.text('e.g. Whispers of the Midnight Clocktower'), findsOneWidget);
      // Check Description placeholder
      expect(find.text('Set the premise. What challenge or mystery will players face?'), findsOneWidget);
      // Check Category placeholder
      expect(find.text('Select a genre category'), findsOneWidget);

      // Verify no fake pre-filled text
      expect(find.text('Midnight in Room 304'), findsNothing);
      expect(find.textContaining('A late-night study session'), findsNothing);

      // Verify Cover Image is clearly marked optional
      expect(find.text('Optional'), findsOneWidget);
    });

    testWidgets('2. Validation fails and blocks progression when fields are empty', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Tap "Next Step →" button while empty
      final nextButtonFinder = find.widgetWithText(TwistButton, 'Next Step →');
      expect(nextButtonFinder, findsOneWidget);
      await tester.tap(nextButtonFinder);
      await tester.pumpAndSettle();

      // Validation errors trigger
      expect(find.text('Title is required'), findsOneWidget);
      expect(find.text('Description is required'), findsOneWidget);
      expect(find.text('Select a category'), findsOneWidget);

      // Still on step 1
      expect(find.text('Step 1 of 5'), findsOneWidget);
    });

    testWidgets('3. Validation fails when title is entered but description is empty', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Enter title only
      await tester.enterText(find.byType(TextField).first, 'Escape from the Haunted Lab');
      await tester.pumpAndSettle();

      // Tap Next Step
      final nextButtonFinder = find.widgetWithText(TwistButton, 'Next Step →');
      await tester.tap(nextButtonFinder);
      await tester.pumpAndSettle();

      // Title error is gone, description and category errors remain
      expect(find.text('Title is required'), findsNothing);
      expect(find.text('Description is required'), findsOneWidget);
      expect(find.text('Select a category'), findsOneWidget);
    });

    testWidgets('4. Validation fails when title and description entered but category not selected', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Enter title
      await tester.enterText(find.byType(TextField).at(0), 'Escape from the Haunted Lab');
      // Enter description
      await tester.enterText(find.byType(TextField).at(1), 'Trapped in an underground facility with rogue AI.');
      await tester.pumpAndSettle();

      // Tap Next Step
      final nextButtonFinder = find.widgetWithText(TwistButton, 'Next Step →');
      await tester.tap(nextButtonFinder);
      await tester.pumpAndSettle();

      // Only category error triggers
      expect(find.text('Title is required'), findsNothing);
      expect(find.text('Description is required'), findsNothing);
      expect(find.text('Select a category'), findsOneWidget);
    });

    testWidgets('5. Step 0 succeeds without cover image when required fields are filled', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // 1. Enter title
      await tester.enterText(find.byType(TextField).at(0), 'Escape from the Haunted Lab');
      // 2. Enter description
      await tester.enterText(find.byType(TextField).at(1), 'Trapped in an underground facility with rogue AI.');
      await tester.pumpAndSettle();

      // 3. Select Category
      final categoryDropdown = find.byType(DropdownButton<String>);
      await tester.tap(categoryDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sci-Fi').last);
      await tester.pumpAndSettle();

      // 4. Do NOT upload or enter cover image (image is OPTIONAL)
      // Tap Next Step
      final nextButtonFinder = find.widgetWithText(TwistButton, 'Next Step →');
      await tester.tap(nextButtonFinder);
      await tester.pumpAndSettle();

      // Successfully transitioned to Step 2: Scenes!
      expect(find.text('Step 2 of 5'), findsOneWidget);
      expect(find.text('Story Scenes'), findsOneWidget);
      expect(find.text('START SCENE'), findsOneWidget);
    });
  });
}

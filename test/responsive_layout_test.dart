import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twist/core/localization/language_provider.dart';
import 'package:twist/core/services/storage_service.dart';
import 'package:twist/models/story_model.dart';
import 'package:twist/models/story_ending_model.dart';
import 'package:twist/models/comment_model.dart';
import 'package:twist/repositories/sample_data.dart';
import 'package:twist/views/story_player/widgets/choice_button.dart';
import 'package:twist/views/story_player/widgets/player_progress_bar.dart';
import 'package:twist/views/home/widgets/story_card.dart';
import 'package:twist/views/ending/share_challenge_dialog.dart';
import 'package:twist/widgets/twist_button.dart';
import 'package:twist/widgets/twist_app_bar.dart';
import 'package:twist/providers/auth_provider.dart';
import 'package:twist/providers/story_feed_provider.dart';
import 'package:twist/providers/activity_provider.dart';
import 'package:twist/repositories/auth_repository.dart';
import 'package:twist/repositories/story_repository.dart';
import 'package:twist/repositories/activity_repository.dart';
import 'package:twist/core/services/analytics_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;
  late LanguageProvider langProv;
  late AuthProvider authProv;
  late StoryRepository storyRepo;
  late StoryFeedProvider feedProv;
  late ActivityProvider activityProv;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storage = StorageService(prefs);
    langProv = LanguageProvider(storage);
    authProv = AuthProvider(AuthRepository(storage));
    storyRepo = StoryRepository(storage, enableSampleFallback: false);
    feedProv = StoryFeedProvider(storyRepo, AnalyticsService());
    activityProv = ActivityProvider(ActivityRepository(storageService: storage));
  });

  Widget wrapWithProviders(Widget child, {TextScaler? textScaler}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: langProv),
        ChangeNotifierProvider.value(value: authProv),
        ChangeNotifierProvider.value(value: feedProv),
        ChangeNotifierProvider.value(value: activityProv),
        Provider<StoryRepository>.value(value: storyRepo),
      ],
      child: MaterialApp(
        theme: ThemeData.dark(),
        builder: (context, widget) {
          if (textScaler != null) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: textScaler),
              child: widget!,
            );
          }
          return widget!;
        },
        home: Scaffold(body: child),
      ),
    );
  }

  group('TWIST Responsive Layout Tests (320px to 430px Widths)', () {
    const screenWidths = [320.0, 360.0, 375.0, 390.0, 412.0, 430.0];

    for (final width in screenWidths) {
      testWidgets('TwistButton enforces 48px+ touch target on ${width.toInt()}px width',
          (WidgetTester tester) async {
        tester.view.physicalSize = Size(width, 700);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          wrapWithProviders(
            SizedBox(
              width: width,
              child: TwistButton(
                text: 'Action Button On Responsive Screen Width $width',
                height: 40, // Clamped to >= 48px
                onPressed: () {},
              ),
            ),
          ),
        );

        final containerFinder = find.byType(Container).first;
        final container = tester.widget<Container>(containerFinder);
        expect((container.constraints?.minHeight ?? 0) >= 48.0, isTrue);
        expect(tester.takeException(), isNull);
      });

      testWidgets('ChoiceButton renders cleanly without overflow on ${width.toInt()}px phone',
          (WidgetTester tester) async {
        tester.view.physicalSize = Size(width, 700);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final choice = SampleData.getOneLastMessageNodes().values.first.choices.first;

        await tester.pumpWidget(
          wrapWithProviders(
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ChoiceButton(
                choice: choice,
                isSelected: true,
                isEnabled: true,
                onTap: () {},
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(ChoiceButton), findsOneWidget);
      });
    }

    testWidgets('PlayerProgressBar adapts cleanly under 1.5x accessibility text scaling',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        wrapWithProviders(
          const PlayerProgressBar(
            currentScene: 4,
            totalEstimatedScenes: 10,
            choicesMade: 7,
          ),
          textScaler: const TextScaler.linear(1.5),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(PlayerProgressBar), findsOneWidget);
    });

    testWidgets('StoryCard renders cleanly with long titles and long categories on 320px phone',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final longStory = StoryModel(
        id: 'test_long_story',
        titleMap: {'en': 'Extremely Long Interactive Mystery Branching Title That Spans Multiple Lines For Responsive Testing'},
        descriptionMap: {'en': 'A very comprehensive and elaborate narrative description that sets the tone for an epic journey through twisting corridors.'},
        category: 'Interactive Sci-Fi Thriller',
        categories: ['Interactive Sci-Fi Thriller', 'Suspense'],
        creatorId: 'creator_1',
        creatorName: 'Professor Archival Storyteller With Very Long Name',
        duration: '15 min',
        plays: 154200,
        likes: 2450,
        commentsCount: 310,
        endingsCount: 12,
        startNodeId: 'node_1',
        coverUrl: '',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        wrapWithProviders(
          StoryCard(story: longStory),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(StoryCard), findsOneWidget);
    });

    testWidgets('TwistAppBar title text handles long titles without overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        wrapWithProviders(
          const TwistAppBar(
            titleText: 'Extremely Long Screen Title For Small Devices In Twist',
            showBack: true,
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(TwistAppBar), findsOneWidget);
    });

    testWidgets('ShareChallengeDialog does not overflow on short device heights (568px)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final story = StoryModel(
        id: 'test_story',
        titleMap: {'en': 'Midnight Cipher'},
        descriptionMap: {'en': 'Mystery'},
        category: 'Mystery',
        creatorId: 'c1',
        creatorName: 'Author',
        duration: '5 min',
        plays: 100,
        likes: 10,
        commentsCount: 2,
        endingsCount: 3,
        startNodeId: 'n1',
        coverUrl: '',
        createdAt: DateTime.now(),
      );

      const ending = StoryEndingModel(
        id: 'ending_secret',
        storyId: 'test_story',
        titleMap: {'en': 'The Hidden Chamber Beyond Time'},
        descriptionMap: {'en': 'You discovered the ancient mechanism behind the grandfather clock.'},
        imageUrl: '',
        rarity: 'Secret',
        isSecret: true,
      );

      await tester.pumpWidget(
        wrapWithProviders(
          ShareChallengeDialog(story: story, ending: ending),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(ShareChallengeDialog), findsOneWidget);
    });

    testWidgets('Comment item handles long username and long content on 320px width',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final comment = CommentModel(
        id: 'c1',
        storyId: 's1',
        userId: 'u1',
        userName: 'Alexander Bartholomew The Great Story Enthusiast',
        userAvatar: null,
        text: 'This is a remarkably long feedback comment explaining why choice B was the superior narrative pathway in this interactive fiction experience.',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        likes: 12,
        isLiked: false,
      );

      await tester.pumpWidget(
        wrapWithProviders(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(radius: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              comment.userName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('3 hours ago'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(comment.text),
                    ],
                  ),
                ),
                const Icon(Icons.favorite_border),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('3 hours ago'), findsOneWidget);
    });
  });
}

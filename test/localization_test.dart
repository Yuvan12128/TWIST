import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twist/core/localization/app_language.dart';
import 'package:twist/core/localization/app_localizations.dart';
import 'package:twist/core/localization/language_provider.dart';
import 'package:twist/core/localization/translations/en.dart';
import 'package:twist/core/services/storage_service.dart';
import 'package:twist/models/story_choice_model.dart';
import 'package:twist/models/story_ending_model.dart';
import 'package:twist/models/story_model.dart';
import 'package:twist/models/story_node_model.dart';
import 'package:twist/repositories/sample_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('English-only V1 Language & Localization Engine', () {
    test('Default language is English', () {
      expect(AppLanguage.en.code, 'en');
      expect(AppLanguage.fromCode('en'), AppLanguage.en);
      expect(AppLanguage.fromCode(null), AppLanguage.en);
      expect(AppLanguage.fromCode('unknown'), AppLanguage.en);
      expect(AppLanguage.en.displayName, 'English');
    });

    test('getLocalizedText resolves English text directly', () {
      final content = {
        'en': 'One Last Message',
        'ta': 'கடைசி செய்தி',
        'tanglish': 'Oru Kadaisi Message',
      };
      expect(AppLanguage.getLocalizedText(content, AppLanguage.en), 'One Last Message');
    });

    test('English dictionary contains all required UI keys', () {
      final requiredKeys = [
        'app_name',
        'app_tagline',
        'nav_home',
        'nav_explore',
        'nav_create',
        'nav_activity',
        'nav_profile',
        'for_you',
        'trending',
        'following',
        'play_story',
        'start_story',
        'what_will_you_do',
        'replay_story',
        'try_other_endings',
        'all_endings',
        'settings',
        'logout',
        'welcome_back',
        'continue_with_google',
        'continue_with_email',
        'continue_as_guest',
      ];

      for (final key in requiredKeys) {
        expect(enTranslations.containsKey(key), true, reason: 'Missing translation for $key');
        expect(enTranslations[key]!.isNotEmpty, true);
      }
    });
  });

  group('Story Models English-Only Integrity', () {
    test('StoryModel returns English title and description by default', () {
      final story = StoryModel(
        id: 'story_test_1',
        titleMap: {
          'en': 'One Last Message',
          'ta': 'கடைசி செய்தி',
          'tanglish': 'Oru Kadaisi Message',
        },
        descriptionMap: {
          'en': 'One message changes everything.',
          'ta': 'ஒரு செய்தி எல்லாவற்றையும் மாற்றுகிறது.',
          'tanglish': 'Oru message ellathayum maathiduthu.',
        },
        coverUrl: 'https://example.com/cover.jpg',
        category: 'Mystery',
        creatorId: 'auth_1',
        creatorName: 'Alex',
        duration: '8 min',
        createdAt: DateTime.now(),
      );

      // Verifying default English getters
      expect(story.title, 'One Last Message');
      expect(story.description, 'One message changes everything.');
      expect(story.localizedTitle(AppLanguage.en), 'One Last Message');
      expect(story.localizedDescription(AppLanguage.en), 'One message changes everything.');

      final map = story.toMap();
      final restored = StoryModel.fromMap(map, docId: 'story_test_1');
      expect(restored.title, 'One Last Message');
    });

    test('StoryNodeModel and StoryChoiceModel English text resolution', () {
      final choiceA = StoryChoiceModel(
        id: 'c_a',
        nodeId: 'node_1',
        key: 'A',
        labelMap: {
          'en': 'Call the number',
          'ta': 'எண்ணை அழைக்கவும்',
          'tanglish': 'Number-ku call pannu',
        },
        consequenceHintMap: {
          'en': 'High risk of uncovering secrets',
          'ta': 'ரகசியங்களை கண்டறியும் அபாயம்',
        },
        nextNodeId: 'node_2',
      );

      final node = StoryNodeModel(
        nodeId: 'node_1',
        storyId: 'story_test',
        imageUrl: 'https://example.com/node.jpg',
        textMap: {
          'en': 'Don\'t go home tonight.',
          'ta': 'இன்று இரவு வீட்டிற்கு செல்லாதே.',
          'tanglish': 'Innaiku night veetukku pogaatha.',
        },
        choices: [choiceA],
      );

      expect(node.text, 'Don\'t go home tonight.');
      expect(node.localizedText(AppLanguage.en), 'Don\'t go home tonight.');
      expect(choiceA.label, 'Call the number');
      expect(choiceA.localizedLabel(AppLanguage.en), 'Call the number');
      expect(choiceA.consequenceHint, 'High risk of uncovering secrets');
    });

    test('StoryEndingModel English text resolution', () {
      final ending = StoryEndingModel(
        id: 'end_truth',
        storyId: 'story_test',
        imageUrl: 'https://example.com/end.jpg',
        titleMap: {
          'en': 'THE TRUTH',
          'ta': 'உண்மை',
          'tanglish': 'THE TRUTH',
        },
        descriptionMap: {
          'en': 'You discovered what really happened.',
          'ta': 'உண்மையில் என்ன நடந்தது என்று கண்டுபிடித்துவிட்டாய்.',
        },
        rarity: 'Secret',
        isSecret: true,
      );

      expect(ending.title, 'THE TRUTH');
      expect(ending.description, 'You discovered what really happened.');
      expect(ending.localizedTitle(AppLanguage.en), 'THE TRUTH');
      expect(ending.localizedDescription(AppLanguage.en), 'You discovered what really happened.');
    });
  });

  group('Sample Data "One Last Message" English Narrative & Branching', () {
    test('"One Last Message" contains complete branching in English', () {
      final stories = SampleData.getStories();
      final olm = stories.firstWhere((s) => s.id == 'story_one_last_message');

      expect(olm.title, 'One Last Message');
      expect(olm.description, contains('One message changed everything.'));
      expect(olm.category, 'Mystery');

      final nodes = SampleData.getOneLastMessageNodes();
      expect(nodes.length >= 8, true);

      final startNode = nodes[olm.startNodeId];
      expect(startNode != null, true);
      expect(startNode!.text, contains('Don\'t go home tonight'));
      expect(startNode.choices.length, 3);

      // Verify all choices in English
      for (final choice in startNode.choices) {
        expect(choice.label.isNotEmpty, true);
        expect(choice.labelMap['en']!.isNotEmpty, true);
      }

      // Verify all 5 endings in English
      final endings = SampleData.getOneLastMessageEndings();
      expect(endings.length, 5);

      for (final ending in endings.values) {
        expect(ending.title.isNotEmpty, true);
        expect(ending.description.isNotEmpty, true);
        expect(ending.titleMap['en']!.isNotEmpty, true);
        expect(ending.descriptionMap['en']!.isNotEmpty, true);
      }
    });
  });

  group('LanguageProvider English-only V1 Enforcement', () {
    test('LanguageProvider defaults and locks to English without prompting on launch', () async {
      SharedPreferences.setMockInitialValues({
        'twist_selected_language': 'en',
      });

      final prefs = await SharedPreferences.getInstance();
      final storageService = StorageService(prefs);
      final provider = LanguageProvider(storageService);

      expect(provider.currentLanguage, AppLanguage.en);
      expect(provider.locale.languageCode, 'en');
      expect(provider.hasSelectedInitialLanguage, true,
          reason: 'Must be true to skip language selection screen completely');
    });
  });

  group('UI Localizations English Rendering Test', () {
    testWidgets('AppLocalizations renders English text in UI', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storageService = StorageService(prefs);
      final provider = LanguageProvider(storageService);

      Widget buildTestApp() {
        return MaterialApp(
          locale: provider.locale,
          supportedLocales: const [
            Locale('en', ''),
          ],
          localizationsDelegates: AppLocalizations.localizationsDelegates(provider.currentLanguage),
          home: Builder(
            builder: (innerContext) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(innerContext.tr('what_will_you_do')),
                      Text(innerContext.tr('play_story')),
                      Text(innerContext.tr('nav_home')),
                      Text(innerContext.tr('nav_explore')),
                      Text(innerContext.tr('nav_create')),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('What will you do?'), findsOneWidget);
      expect(find.text('PLAY STORY'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Explore'), findsOneWidget);
      expect(find.text('Create'), findsOneWidget);
    });
  });
}

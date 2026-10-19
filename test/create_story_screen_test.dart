import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twist/views/create/create_story_screen.dart';
import 'package:twist/core/localization/app_localizations.dart';
import 'package:twist/core/localization/app_language.dart';

import 'package:twist/widgets/twist_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestableWidget() {
    return const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: [
        AppLocalizationsDelegate(AppLanguage.en),
      ],
      home: CreateStoryScreen(),
    );
  }

  group('CreateStoryScreen Validation & Optional Cover Tests', () {
    testWidgets('1. Title, description and category start empty with correct placeholders', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Check Title placeholder
      expect(find.text('Enter story title'), findsOneWidget);
      // Check Description placeholder
      expect(find.text('Enter story description'), findsOneWidget);
      // Check Category placeholder
      expect(find.text('Select category'), findsOneWidget);

      // Verify no pre-filled text
      expect(find.text('Midnight in Room 304'), findsNothing);
      expect(find.textContaining('A late-night study session'), findsNothing);

      // Verify Cover Image is clearly marked optional
      expect(find.textContaining('Optional'), findsWidgets);
    });

    testWidgets('2. Validation fails and blocks creation when fields are empty', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Tap "Create Story" button while empty
      final buttonFinder = find.widgetWithText(TwistButton, 'Create Story');
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      // Title validation triggers
      expect(find.text('Please enter a story title'), findsWidgets);
      expect(find.text('Story created successfully!'), findsNothing);
    });

    testWidgets('3. Validation fails when title is entered but description is empty', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Enter title only
      await tester.enterText(find.byType(TextField).first, 'Escape from the Haunted Lab');
      await tester.pumpAndSettle();

      // Tap "Create Story" button
      final buttonFinder = find.widgetWithText(TwistButton, 'Create Story');
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      // Description validation triggers
      expect(find.text('Please enter a story description'), findsWidgets);
      expect(find.text('Story created successfully!'), findsNothing);
    });

    testWidgets('4. Validation fails when title and description entered but category not selected', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Enter title
      await tester.enterText(find.byType(TextField).at(0), 'Escape from the Haunted Lab');
      // Enter description
      await tester.enterText(find.byType(TextField).at(1), 'Trapped in an underground facility with rogue AI.');
      await tester.pumpAndSettle();

      // Tap "Create Story" button
      final buttonFinder = find.widgetWithText(TwistButton, 'Create Story');
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      // Category validation triggers
      expect(find.text('Please select a category'), findsWidgets);
      expect(find.text('Story created successfully!'), findsNothing);
    });

    testWidgets('5. Story creation succeeds without cover image when required fields are filled', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // 1. Enter title
      await tester.enterText(find.byType(TextField).at(0), 'Escape from the Haunted Lab');
      // 2. Enter description
      await tester.enterText(find.byType(TextField).at(1), 'Trapped in an underground facility with rogue AI.');
      await tester.pumpAndSettle();

      // 3. Select Category
      final categoryDropdown = find.byType(DropdownButton<String>);
      await tester.ensureVisible(categoryDropdown);
      await tester.tap(categoryDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sci-Fi').last);
      await tester.pumpAndSettle();

      // 4. Do NOT upload or select cover image (image is OPTIONAL)
      // Tap "Create Story" button
      final buttonFinder = find.widgetWithText(TwistButton, 'Create Story');
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      // Success snackbar is shown!
      expect(find.text('Story created successfully!'), findsOneWidget);
    });
  });
}

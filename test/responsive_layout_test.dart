import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twist/core/localization/language_provider.dart';
import 'package:twist/core/services/storage_service.dart';
import 'package:twist/repositories/sample_data.dart';
import 'package:twist/views/story_player/widgets/choice_button.dart';
import 'package:twist/widgets/twist_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TWIST Responsive Layout Tests (320px Small Phone)', () {
    testWidgets('TwistButton enforces 48px+ touch target and handles text overflow on 320px',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: TwistButton(
                text: 'This is a very long button text that must not overflow the screen',
                height: 40, // requests <48, but should be clamped to >=48
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      final containerFinder = find.byType(Container).first;
      final container = tester.widget<Container>(containerFinder);
      expect((container.constraints?.minHeight ?? 0) >= 48.0, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ChoiceButton renders cleanly without overflow on 320px phone',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = StorageService(prefs);
      final langProv = LanguageProvider(storage);

      final choice = SampleData.getOneLastMessageNodes().values.first.choices.first;

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: langProv,
          child: MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ChoiceButton(
                  choice: choice,
                  isSelected: true,
                  isEnabled: true,
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(ChoiceButton), findsOneWidget);
    });

    testWidgets('ChoiceButton maintains 48px+ touch target', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = StorageService(prefs);
      final langProv = LanguageProvider(storage);

      final choice = SampleData.getOneLastMessageNodes().values.first.choices.first;

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: langProv,
          child: MaterialApp(
            home: Scaffold(
              body: ChoiceButton(
                choice: choice,
                isSelected: false,
                isEnabled: true,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      final containerFinder = find.byWidgetPredicate(
        (widget) => widget is Container && (widget.constraints?.minHeight ?? 0) >= 48.0,
      );
      expect(containerFinder, findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

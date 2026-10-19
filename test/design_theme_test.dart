import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twist/core/constants/app_colors.dart';
import 'package:twist/core/theme/app_theme.dart';
import 'package:twist/widgets/glass_card.dart';
import 'package:twist/widgets/twist_button.dart';

void main() {
  group('TWIST Design System - Exact Yellow Color Palette Verification', () {
    test('Exact hex colors match Dark + Yellow design specification', () {
      expect(AppColors.background, const Color(0xFF0B0B0F));
      expect(AppColors.cardBackground, const Color(0xFF15151B));
      expect(AppColors.primaryYellow, const Color(0xFFFFD600));
      expect(AppColors.secondaryYellow, const Color(0xFFF4C400));
      expect(AppColors.primaryText, const Color(0xFFFFFFFF));
      expect(AppColors.secondaryText, const Color(0xFFA1A1AA));
      expect(AppColors.border, const Color(0xFF27272A));
      expect(AppColors.success, const Color(0xFF22C55E));
      expect(AppColors.error, const Color(0xFFEF4444));
    });

    test('ThemeData reflects Yellow primary, dark background and border', () {
      final theme = AppTheme.darkTheme;
      expect(theme.scaffoldBackgroundColor, const Color(0xFF0B0B0F));
      expect(theme.colorScheme.primary, const Color(0xFFFFD600));
      expect(theme.colorScheme.secondary, const Color(0xFFF4C400));
      expect(theme.colorScheme.surface, const Color(0xFF15151B));
      expect(theme.colorScheme.error, const Color(0xFFEF4444));
      expect(theme.dividerTheme.color, const Color(0xFF27272A));
    });
  });

  group('TWIST Widgets - Lightweight Yellow Design Verification', () {
    testWidgets('TwistButton renders primary Yellow button correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TwistButton(
              text: 'PLAY STORY',
              variant: TwistButtonVariant.primaryGradient,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('PLAY STORY'), findsOneWidget);
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, AppColors.primaryYellow);
    });

    testWidgets('TwistButton renders secondary dark card button correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TwistButton(
              text: 'SHARE ENDING',
              variant: TwistButtonVariant.glass,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('SHARE ENDING'), findsOneWidget);
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, AppColors.cardBackground);
    });

    testWidgets('GlassCard renders with cardBackground and simple border without heavy blur', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassCard(
              child: Text('Card Content'),
            ),
          ),
        ),
      );

      expect(find.text('Card Content'), findsOneWidget);
      // Ensure no BackdropFilter is used in GlassCard
      expect(find.byType(BackdropFilter), findsNothing);

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, AppColors.cardBackground);
      expect((decoration.border as Border).top.color, AppColors.border);
    });
  });
}

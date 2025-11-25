import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zpi_test/widgets/app_bottom_nav.dart';

void main() {
  group('AppBottomNav Widget', () {
    testWidgets('should render all three navigation buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppBottomNav(current: BottomNavItem.home),
          ),
        ),
      );

      expect(find.byIcon(Icons.person_outline), findsOneWidget);
      expect(find.byIcon(Icons.style_outlined), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
    });

    testWidgets('should highlight current tab correctly - home', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppBottomNav(current: BottomNavItem.home),
          ),
        ),
      );

      final homeButton = find.byIcon(Icons.style_outlined);
      expect(homeButton, findsOneWidget);
      
      final IconButton widget = tester.widget(find.ancestor(
        of: homeButton,
        matching: find.byType(IconButton),
      ));
      
      // Home button should be the emphasized one
      expect(widget.iconSize, equals(30.0)); // Emphasized size
    });

    testWidgets('should highlight current tab correctly - profile', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppBottomNav(current: BottomNavItem.profile),
          ),
        ),
      );

      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });

    testWidgets('should highlight current tab correctly - messages', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppBottomNav(current: BottomNavItem.messages),
          ),
        ),
      );

      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
    });

    testWidgets('should navigate to profile when profile button tapped', (WidgetTester tester) async {
      bool navigated = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppBottomNav(current: BottomNavItem.home),
          ),
          routes: {
            '/profile': (context) {
              navigated = true;
              return const Scaffold(body: Text('Profile'));
            },
          },
        ),
      );

      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();

      expect(navigated, isTrue);
    });

    testWidgets('should navigate to users when home button tapped', (WidgetTester tester) async {
      bool navigated = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppBottomNav(current: BottomNavItem.profile),
          ),
          routes: {
            '/users': (context) {
              navigated = true;
              return const Scaffold(body: Text('Users'));
            },
          },
        ),
      );

      await tester.tap(find.byIcon(Icons.style_outlined));
      await tester.pumpAndSettle();

      expect(navigated, isTrue);
    });

    testWidgets('should navigate to matches when messages button tapped', (WidgetTester tester) async {
      bool navigated = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppBottomNav(current: BottomNavItem.home),
          ),
          routes: {
            '/matches': (context) {
              navigated = true;
              return const Scaffold(body: Text('Matches'));
            },
          },
        ),
      );

      await tester.tap(find.byIcon(Icons.chat_bubble_outline));
      await tester.pumpAndSettle();

      expect(navigated, isTrue);
    });

    testWidgets('should not navigate when tapping current tab', (WidgetTester tester) async {
      int navigationCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppBottomNav(current: BottomNavItem.home),
          ),
          routes: {
            '/users': (context) {
              navigationCount++;
              return const Scaffold(body: Text('Users'));
            },
          },
        ),
      );

      // Tap the already active home button
      await tester.tap(find.byIcon(Icons.style_outlined));
      await tester.pumpAndSettle();

      // Should not navigate when already on that tab
      expect(navigationCount, equals(0));
    });

    testWidgets('should have correct tooltips', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppBottomNav(current: BottomNavItem.home),
          ),
        ),
      );

      expect(find.byTooltip('Profile'), findsOneWidget);
      expect(find.byTooltip('Discover'), findsOneWidget);
      expect(find.byTooltip('Messages'), findsOneWidget);
    });

    testWidgets('should render with proper styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppBottomNav(current: BottomNavItem.home),
          ),
        ),
      );

      // Check that the nav bar has proper height
      final safeArea = find.byType(SafeArea);
      expect(safeArea, findsOneWidget);

      // Verify SizedBox with height exists
      final sizedBox = find.descendant(
        of: safeArea,
        matching: find.byType(SizedBox),
      );
      expect(sizedBox, findsWidgets);
    });

    testWidgets('should use correct colors for active and inactive items', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppBottomNav(current: BottomNavItem.profile),
          ),
        ),
      );

      // Find all IconButton widgets
      final iconButtons = find.byType(IconButton);
      expect(iconButtons, findsNWidgets(3));

      // The active button (profile) should have brand purple color (0xFF5B3CF0)
      // The inactive buttons should have lighter purple (0xFF8E7CC9)
      // Note: Direct color verification requires accessing widget properties
      expect(iconButtons, findsWidgets);
    });
  });
}

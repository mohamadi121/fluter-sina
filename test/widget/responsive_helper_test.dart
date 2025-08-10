import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asoud/core/utils/responsive_helper.dart';

void main() {
  group('Responsive Helper Tests', () {
    testWidgets('ResponsiveHelper identifies mobile screen correctly', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final isMobile = ResponsiveHelper.isMobile(context);
              final screenSize = ResponsiveHelper.getScreenSize(context);
              
              return Scaffold(
                body: Column(
                  children: [
                    Text('Is Mobile: $isMobile'),
                    Text('Screen Size: $screenSize'),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Is Mobile: true'), findsOneWidget);
      expect(find.text('Screen Size: ScreenSize.mobile'), findsOneWidget);
    });

    testWidgets('ResponsiveHelper identifies tablet screen correctly', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final isTablet = ResponsiveHelper.isTablet(context);
              final screenSize = ResponsiveHelper.getScreenSize(context);
              
              return Scaffold(
                body: Column(
                  children: [
                    Text('Is Tablet: $isTablet'),
                    Text('Screen Size: $screenSize'),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Is Tablet: true'), findsOneWidget);
      expect(find.text('Screen Size: ScreenSize.tablet'), findsOneWidget);
    });

    testWidgets('ResponsiveLayout shows correct widget for screen size', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800)); // Mobile size
      
      await tester.pumpWidget(
        const MaterialApp(
          home: ResponsiveLayout(
            mobile: Text('Mobile Layout'),
            tablet: Text('Tablet Layout'),
            desktop: Text('Desktop Layout'),
          ),
        ),
      );

      expect(find.text('Mobile Layout'), findsOneWidget);
      expect(find.text('Tablet Layout'), findsNothing);
      expect(find.text('Desktop Layout'), findsNothing);
    });

    testWidgets('AdaptiveScaffold shows bottom navigation on mobile', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800)); // Mobile size
      
      await tester.pumpWidget(
        MaterialApp(
          home: AdaptiveScaffold(
            body: const Text('Content'),
            selectedIndex: 0,
            onDestinationSelected: (index) {},
            destinations: const [
              AdaptiveNavigationItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              AdaptiveNavigationItem(
                icon: Icon(Icons.search),
                label: 'Search',
              ),
            ],
          ),
        ),
      );

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
    });

    testWidgets('AdaptiveScaffold shows navigation rail on tablet', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200)); // Tablet size
      
      await tester.pumpWidget(
        MaterialApp(
          home: AdaptiveScaffold(
            body: const Text('Content'),
            selectedIndex: 0,
            onDestinationSelected: (index) {},
            destinations: const [
              AdaptiveNavigationItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              AdaptiveNavigationItem(
                icon: Icon(Icons.search),
                label: 'Search',
              ),
            ],
          ),
        ),
      );

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
    });
  });
}

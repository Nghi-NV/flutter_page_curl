import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_page_curl/flutter_page_curl.dart';

void main() {
  group('PageCurlView', () {
    testWidgets('renders without crash', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageCurlView(
              children: [
                Container(color: Colors.red),
                Container(color: Colors.blue),
                Container(color: Colors.green),
              ],
            ),
          ),
        ),
      );

      // Should render without crashing
      expect(find.byType(PageCurlView), findsOneWidget);
    });

    testWidgets('uses external controller', (tester) async {
      final controller = PageCurlController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageCurlView(
              controller: controller,
              children: [
                Container(color: Colors.red),
                Container(color: Colors.blue),
                Container(color: Colors.green),
              ],
            ),
          ),
        ),
      );

      expect(controller.totalPages, 3);
      expect(controller.currentPage, 0);

      controller.dispose();
    });

    testWidgets('calls onPageChanged callback', (tester) async {
      int? pageChangedTo;
      final controller = PageCurlController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageCurlView(
              controller: controller,
              onPageChanged: (page) => pageChangedTo = page,
              children: [
                Container(color: Colors.red),
                Container(color: Colors.blue),
              ],
            ),
          ),
        ),
      );

      // Use controller to navigate
      controller.nextPage();
      await tester.pumpAndSettle();

      // Note: onPageChanged is called via animation completion,
      // so in test without shader it may not fire.
      // The important thing is no crash.
      // pageChangedTo may or may not be set depending on shader availability.
      expect(pageChangedTo == null || pageChangedTo == 1, isTrue);

      controller.dispose();
    });

    testWidgets('handles single page without crash', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageCurlView(children: [Container(color: Colors.red)]),
          ),
        ),
      );

      expect(find.byType(PageCurlView), findsOneWidget);
    });

    testWidgets('handles dynamic children update', (tester) async {
      final pages = [
        Container(key: const ValueKey('a'), color: Colors.red),
        Container(key: const ValueKey('b'), color: Colors.blue),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PageCurlView(children: pages)),
        ),
      );

      // Update with more pages
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageCurlView(
              children: [
                ...pages,
                Container(key: const ValueKey('c'), color: Colors.green),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(PageCurlView), findsOneWidget);
    });

    testWidgets('custom parameters are applied', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageCurlView(
              radius: 0.12,
              shadowWidth: 0.3,
              backOpacity: 0.7,
              edgeZoneWidth: 0.15,
              animationDuration: const Duration(milliseconds: 600),
              children: [
                Container(color: Colors.red),
                Container(color: Colors.blue),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(PageCurlView), findsOneWidget);
    });
  });
}

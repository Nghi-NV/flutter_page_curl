import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_page_curl/flutter_page_curl.dart';

void main() {
  group('PageCurlController', () {
    late PageCurlController controller;

    setUp(() {
      controller = PageCurlController(radius: 0.08);
      controller.totalPages = 5;
    });

    tearDown(() {
      controller.dispose();
    });

    test('initial state is correct', () {
      expect(controller.currentPage, 0);
      expect(controller.curlProgress, 0.0);
      expect(controller.isCurling, false);
      expect(controller.isReverse, false);
      expect(controller.hasNextPage, true);
      expect(controller.hasPreviousPage, false);
    });

    test('startCurl forward sets correct state', () {
      controller.startCurl(const Offset(0.9, 0.5));
      expect(controller.isCurling, true);
      expect(controller.isReverse, false);
      expect(controller.curlPosition, const Offset(0.9, 0.5));
    });

    test('startCurl reverse when no previous page does nothing', () {
      controller.startCurl(const Offset(0.1, 0.5), reverse: true);
      expect(controller.isCurling, false);
    });

    test('startCurl reverse on page > 0 works', () {
      controller.jumpToPage(2);
      controller.startCurl(const Offset(0.1, 0.5), reverse: true);
      expect(controller.isCurling, true);
      expect(controller.isReverse, true);
    });

    test('startCurl forward when no next page does nothing', () {
      controller.jumpToPage(4); // last page
      controller.startCurl(const Offset(0.9, 0.5));
      expect(controller.isCurling, false);
    });

    test('updateCurl updates position and direction', () {
      controller.startCurl(const Offset(0.9, 0.5));
      controller.updateCurl(const Offset(0.5, 0.5));
      expect(controller.curlPosition, const Offset(0.5, 0.5));
      expect(controller.curlProgress, closeTo(0.4, 0.01));
    });

    test('updateCurl without starting does nothing', () {
      controller.updateCurl(const Offset(0.5, 0.5));
      expect(controller.isCurling, false);
      expect(controller.curlProgress, 0.0);
    });

    test('endCurl commits on high progress', () {
      controller.startCurl(const Offset(0.9, 0.5));
      controller.updateCurl(const Offset(0.3, 0.5));
      final shouldCommit = controller.endCurl();
      expect(shouldCommit, true);
    });

    test('endCurl cancels on low progress', () {
      controller.startCurl(const Offset(0.9, 0.5));
      controller.updateCurl(const Offset(0.8, 0.5));
      final shouldCommit = controller.endCurl();
      expect(shouldCommit, false);
    });

    test('endCurl commits on high velocity', () {
      controller.startCurl(const Offset(0.9, 0.5));
      controller.updateCurl(const Offset(0.8, 0.5));
      final shouldCommit = controller.endCurl(velocity: -1000.0);
      expect(shouldCommit, true);
    });

    test('commitCurl advances page forward', () {
      controller.startCurl(const Offset(0.9, 0.5));
      controller.commitCurl();
      expect(controller.currentPage, 1);
      expect(controller.isCurling, false);
    });

    test('commitCurl goes back when reverse', () {
      controller.jumpToPage(3);
      controller.startCurl(const Offset(0.1, 0.5), reverse: true);
      controller.commitCurl();
      expect(controller.currentPage, 2);
    });

    test('cancelCurl resets curl state', () {
      controller.startCurl(const Offset(0.9, 0.5));
      controller.updateCurl(const Offset(0.5, 0.5));
      controller.cancelCurl();
      expect(controller.isCurling, false);
      expect(controller.curlProgress, 0.0);
      expect(controller.currentPage, 0);
    });

    test('nextPage increments current page', () {
      controller.nextPage();
      expect(controller.currentPage, 1);
    });

    test('previousPage decrements current page', () {
      controller.jumpToPage(3);
      controller.previousPage();
      expect(controller.currentPage, 2);
    });

    test('jumpToPage clamps to valid range', () {
      controller.jumpToPage(10);
      expect(controller.currentPage, 4);
      controller.jumpToPage(-1);
      expect(controller.currentPage, 0);
    });

    test('page boundary checks are correct', () {
      expect(controller.hasNextPage, true);
      expect(controller.hasPreviousPage, false);

      controller.jumpToPage(2);
      expect(controller.hasNextPage, true);
      expect(controller.hasPreviousPage, true);

      controller.jumpToPage(4);
      expect(controller.hasNextPage, false);
      expect(controller.hasPreviousPage, true);
    });

    test('notifies listeners on state changes', () {
      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      controller.startCurl(const Offset(0.9, 0.5));
      expect(notifyCount, 1);

      controller.updateCurl(const Offset(0.5, 0.5));
      expect(notifyCount, 2);

      controller.cancelCurl();
      expect(notifyCount, 3);
    });

    test('curl direction is calculated correctly for horizontal drag', () {
      controller.startCurl(const Offset(0.9, 0.5));
      controller.updateCurl(const Offset(0.5, 0.5));

      // Direction should be pointing right (from current to start)
      expect(controller.curlDirection.dx, closeTo(1.0, 0.01));
      expect(controller.curlDirection.dy, closeTo(0.0, 0.01));
    });

    test('curl direction handles diagonal drag', () {
      controller.startCurl(const Offset(0.9, 0.3));
      controller.updateCurl(const Offset(0.5, 0.7));

      // Direction should have both dx and dy components
      expect(controller.curlDirection.dx, greaterThan(0));
      expect(controller.curlDirection.dy, lessThan(0));
    });
  });
}

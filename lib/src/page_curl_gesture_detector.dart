import 'package:flutter/widgets.dart';

import 'page_curl_controller.dart';

/// Detects edge-swipe gestures and feeds them to [PageCurlController].
///
/// Only activates curl when the touch starts within the edge zone
/// (configurable percentage of screen width from left/right edges).
class PageCurlGestureDetector extends StatelessWidget {
  const PageCurlGestureDetector({
    super.key,
    required this.controller,
    required this.child,
    this.edgeZoneWidth = 0.2,
    this.onCurlEnd,
  });

  /// The controller to feed gesture data to.
  final PageCurlController controller;

  /// The child widget to wrap with gesture detection.
  final Widget child;

  /// Width of the edge zone as fraction of total width (0-1).
  /// Default 0.2 = 20% from each edge.
  final double edgeZoneWidth;

  /// Called when the curl gesture ends.
  /// Returns true if page should be committed, false if cancelled.
  final void Function(bool shouldCommit, double velocity)? onCurlEnd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (details) => _onPanStart(context, details),
      onPanUpdate: (details) => _onPanUpdate(context, details),
      onPanEnd: (details) => _onPanEnd(details),
      child: child,
    );
  }

  void _onPanStart(BuildContext context, DragStartDetails details) {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final localPos = renderBox.globalToLocal(details.globalPosition);

    // Normalize position to 0-1
    final normalized = Offset(
      (localPos.dx / size.width).clamp(0.0, 1.0),
      (localPos.dy / size.height).clamp(0.0, 1.0),
    );

    // Check if touch is in edge zone
    final isRightEdge = normalized.dx > (1.0 - edgeZoneWidth);
    final isLeftEdge = normalized.dx < edgeZoneWidth;

    if (isRightEdge && controller.hasNextPage) {
      controller.startCurl(normalized, reverse: false);
    } else if (isLeftEdge && controller.hasPreviousPage) {
      controller.startCurl(normalized, reverse: true);
    }
  }

  void _onPanUpdate(BuildContext context, DragUpdateDetails details) {
    if (!controller.isCurling) return;

    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final localPos = renderBox.globalToLocal(details.globalPosition);

    // Normalize position to 0-1
    final normalized = Offset(
      (localPos.dx / size.width).clamp(0.0, 1.0),
      (localPos.dy / size.height).clamp(0.0, 1.0),
    );

    controller.updateCurl(normalized);
  }

  void _onPanEnd(DragEndDetails details) {
    if (!controller.isCurling) return;

    final velocity = details.velocity.pixelsPerSecond.dx;
    final shouldCommit = controller.endCurl(velocity: velocity);
    onCurlEnd?.call(shouldCommit, velocity);
  }
}

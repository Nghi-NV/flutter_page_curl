import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'page_curl_controller.dart';
import 'page_curl_painter.dart';

/// A widget that displays children with an interactive page curl effect.
///
/// Uses a GLSL fragment shader to render a realistic page curl animation
/// that responds to touch gestures from the screen edges.
///
/// ```dart
/// PageCurlView(
///   children: [
///     Container(color: Colors.red, child: Center(child: Text('Page 1'))),
///     Container(color: Colors.blue, child: Center(child: Text('Page 2'))),
///     Container(color: Colors.green, child: Center(child: Text('Page 3'))),
///   ],
/// )
/// ```
class PageCurlView extends StatefulWidget {
  const PageCurlView({
    super.key,
    required this.children,
    this.controller,
    this.radius = 0.08,
    this.shadowWidth = 0.15,
    this.backOpacity = 0.5,
    this.edgeZoneWidth = 0.2,
    this.animationDuration = const Duration(milliseconds: 400),
    this.animationCurve = Curves.easeOut,
    this.onPageChanged,
  });

  /// The pages to display.
  final List<Widget> children;

  /// Optional external controller. If not provided, an internal one is created.
  final PageCurlController? controller;

  /// Cylinder radius for the curl effect (normalized 0-1).
  final double radius;

  /// Shadow width multiplier.
  final double shadowWidth;

  /// Back page darkening factor (0-1).
  final double backOpacity;

  /// Width of edge zone for gesture activation (fraction of width, 0-1).
  final double edgeZoneWidth;

  /// Duration of the commit/cancel animation.
  final Duration animationDuration;

  /// Curve for the commit/cancel animation.
  final Curve animationCurve;

  /// Called when the page changes.
  final ValueChanged<int>? onPageChanged;

  @override
  State<PageCurlView> createState() => _PageCurlViewState();
}

class _PageCurlViewState extends State<PageCurlView>
    with TickerProviderStateMixin {
  late PageCurlController _controller;
  bool _ownController = false;

  ui.FragmentShader? _shader;
  bool _shaderLoaded = false;
  bool _shaderFailed = false;

  // Page image keys for capture
  final Map<int, GlobalKey> _pageKeys = {};

  // Cached page images for shader
  final Map<int, ui.Image> _pageImages = {};
  bool _needsCapture = false;

  // Animation for commit/cancel
  AnimationController? _animController;
  Animation<double>? _curlAnimation;
  Offset _animStartCurlPos = Offset.zero;
  Offset _animEndCurlPos = Offset.zero;
  bool _animIsCommit = false;

  @override
  void initState() {
    super.initState();
    _initController();
    _loadShader();
    _preCaptureAdjacentPages();
  }

  void _initController() {
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownController = false;
    } else {
      _controller = PageCurlController(radius: widget.radius);
      _ownController = true;
    }
    _controller.totalPages = widget.children.length;

    // Initialize page keys
    for (int i = 0; i < widget.children.length; i++) {
      _pageKeys[i] = GlobalKey();
    }
  }

  Future<void> _loadShader() async {
    final paths = [
      'packages/flutter_page_curl/shaders/page_curl.frag',
      'shaders/page_curl.frag',
    ];

    for (final path in paths) {
      try {
        final program = await ui.FragmentProgram.fromAsset(path);
        if (mounted) {
          setState(() {
            _shader = program.fragmentShader();
            _shaderLoaded = true;
          });
        }
        return;
      } catch (_) {}
    }

    if (mounted) {
      setState(() => _shaderFailed = true);
    }
  }

  /// Capture a page widget to ui.Image via its RepaintBoundary.
  Future<ui.Image?> _capturePageImage(int pageIndex) async {
    final key = _pageKeys[pageIndex];
    if (key == null) return null;

    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null || !boundary.hasSize) return null;

    try {
      final image = await boundary.toImage(pixelRatio: 1.0);
      return image;
    } catch (_) {
      return null;
    }
  }

  /// Eagerly pre-capture adjacent pages so images are ready when curl starts.
  void _preCaptureAdjacentPages() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final current = _controller.currentPage;
      bool changed = false;

      // Capture current page
      if (!_pageImages.containsKey(current)) {
        final img = await _capturePageImage(current);
        if (img != null) {
          _pageImages[current] = img;
          changed = true;
        }
      }
      // Capture previous page
      if (current > 0 && !_pageImages.containsKey(current - 1)) {
        final img = await _capturePageImage(current - 1);
        if (img != null) {
          _pageImages[current - 1] = img;
          changed = true;
        }
      }
      // Capture next page
      if (current < widget.children.length - 1 &&
          !_pageImages.containsKey(current + 1)) {
        final img = await _capturePageImage(current + 1);
        if (img != null) {
          _pageImages[current + 1] = img;
          changed = true;
        }
      }

      if (mounted && changed) setState(() {});
    });
  }

  void _onCurlStart() {
    // Don't clear images — reuse pre-captured ones for zero-delay shader start.
    // Only schedule re-capture if any are missing.
    final current = _controller.currentPage;
    final next = _controller.isReverse
        ? (current - 1).clamp(0, widget.children.length - 1)
        : (current + 1).clamp(0, widget.children.length - 1);

    if (!_pageImages.containsKey(current) || !_pageImages.containsKey(next)) {
      _needsCapture = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        if (!_pageImages.containsKey(current)) {
          final img = await _capturePageImage(current);
          if (img != null) _pageImages[current] = img;
        }
        if (!_pageImages.containsKey(next)) {
          final img = await _capturePageImage(next);
          if (img != null) _pageImages[next] = img;
        }
        if (mounted) setState(() => _needsCapture = false);
      });
    }
  }

  void _onCurlEnd(bool shouldCommit, double velocity) {
    if (!_controller.isCurling) return;

    _animIsCommit = shouldCommit;
    _animStartCurlPos = _controller.curlPosition;

    if (shouldCommit) {
      _animEndCurlPos = _controller.isReverse
          ? const Offset(1.0, 0.5)
          : const Offset(-0.5, 0.5);
    } else {
      _animEndCurlPos = _controller.startPosition;
    }

    _animController?.dispose();
    _animController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _curlAnimation = CurvedAnimation(
      parent: _animController!,
      curve: widget.animationCurve,
    );

    _animController!.addListener(_onAnimationTick);
    _animController!.addStatusListener(_onAnimationStatus);
    _animController!.forward();
  }

  void _onAnimationTick() {
    final t = _curlAnimation!.value;
    final pos = Offset.lerp(_animStartCurlPos, _animEndCurlPos, t)!;
    _controller.updateCurl(pos);
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      final previousPage = _controller.currentPage;
      if (_animIsCommit) {
        _controller.commitCurl();
        _pageImages.clear(); // Clear stale images after page change
        if (_controller.currentPage != previousPage) {
          widget.onPageChanged?.call(_controller.currentPage);
        }
        _preCaptureAdjacentPages(); // Pre-capture for new page
      } else {
        _controller.cancelCurl();
      }
      _animController?.dispose();
      _animController = null;
    }
  }

  @override
  void didUpdateWidget(covariant PageCurlView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _initController();
    }
    if (oldWidget.children.length != widget.children.length) {
      _controller.totalPages = widget.children.length;
      for (int i = 0; i < widget.children.length; i++) {
        _pageKeys.putIfAbsent(i, () => GlobalKey());
      }
      _pageImages.clear();
    }
  }

  @override
  void dispose() {
    _animController?.dispose();
    if (_ownController) _controller.dispose();
    for (final image in _pageImages.values) {
      image.dispose();
    }
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _PageCurlGestureWrapper(
      controller: _controller,
      edgeZoneWidth: widget.edgeZoneWidth,
      onCurlStart: _onCurlStart,
      onCurlEnd: _onCurlEnd,
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final currentPage = _controller.currentPage;
    final isCurling = _controller.isCurling;

    // Always keep pages in the Stack — never remove them.
    final children = <Widget>[];
    if (currentPage > 0) {
      children.add(_buildPage(currentPage - 1));
    }
    if (currentPage < widget.children.length - 1) {
      children.add(_buildPage(currentPage + 1));
    }
    children.add(_buildPage(currentPage)); // current page on top

    // Overlay shader on top of pages when curling with captured images
    if (isCurling && _shaderLoaded && !_shaderFailed) {
      final nextPageIndex = _controller.isReverse
          ? (currentPage - 1).clamp(0, widget.children.length - 1)
          : (currentPage + 1).clamp(0, widget.children.length - 1);

      final currentImage = _pageImages[currentPage];
      final nextImage = _pageImages[nextPageIndex];

      if (currentImage != null && nextImage != null) {
        children.add(
          Positioned.fill(
            child: CustomPaint(
              painter: PageCurlPainter(
                shader: _shader!,
                controller: _controller,
                currentPageImage: currentImage,
                nextPageImage: nextImage,
                shadowWidth: widget.shadowWidth,
                backOpacity: widget.backOpacity,
              ),
            ),
          ),
        );
      } else if (_needsCapture) {
        _preCaptureAdjacentPages();
      }
    }

    return Stack(fit: StackFit.expand, children: children);
  }

  Widget _buildPage(int index) {
    if (index < 0 || index >= widget.children.length) {
      return const SizedBox.shrink();
    }
    return RepaintBoundary(
      key: _pageKeys[index],
      child: widget.children[index],
    );
  }
}

/// Internal gesture wrapper that triggers onCurlStart and onCurlEnd.
class _PageCurlGestureWrapper extends StatefulWidget {
  const _PageCurlGestureWrapper({
    required this.controller,
    required this.child,
    required this.onCurlStart,
    required this.onCurlEnd,
    this.edgeZoneWidth = 0.2,
  });

  final PageCurlController controller;
  final Widget child;
  final VoidCallback onCurlStart;
  final void Function(bool shouldCommit, double velocity) onCurlEnd;
  final double edgeZoneWidth;

  @override
  State<_PageCurlGestureWrapper> createState() =>
      _PageCurlGestureWrapperState();
}

class _PageCurlGestureWrapperState extends State<_PageCurlGestureWrapper> {
  // Pending gesture — saved on panStart, confirmed on panUpdate
  Offset? _pendingStartPos;
  bool? _pendingIsRightEdge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (details) => _onPanStart(context, details),
      onPanUpdate: (details) => _onPanUpdate(context, details),
      onPanEnd: (details) => _onPanEnd(details),
      child: widget.child,
    );
  }

  void _onPanStart(BuildContext context, DragStartDetails details) {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final localPos = renderBox.globalToLocal(details.globalPosition);
    final normalized = Offset(
      (localPos.dx / size.width).clamp(0.0, 1.0),
      (localPos.dy / size.height).clamp(0.0, 1.0),
    );

    final isRightEdge = normalized.dx > (1.0 - widget.edgeZoneWidth);
    final isLeftEdge = normalized.dx < widget.edgeZoneWidth;

    // Don't start curl yet — save pending state for direction validation
    if (isRightEdge && widget.controller.hasNextPage) {
      _pendingStartPos = normalized;
      _pendingIsRightEdge = true;
    } else if (isLeftEdge && widget.controller.hasPreviousPage) {
      _pendingStartPos = normalized;
      _pendingIsRightEdge = false;
    } else {
      _pendingStartPos = null;
      _pendingIsRightEdge = null;
    }
  }

  void _onPanUpdate(BuildContext context, DragUpdateDetails details) {
    // If curl already started, just update position
    if (widget.controller.isCurling) {
      final renderBox = context.findRenderObject() as RenderBox;
      final size = renderBox.size;
      final localPos = renderBox.globalToLocal(details.globalPosition);
      final normalized = Offset(
        (localPos.dx / size.width).clamp(0.0, 1.0),
        (localPos.dy / size.height).clamp(0.0, 1.0),
      );
      widget.controller.updateCurl(normalized);
      return;
    }

    // If we have a pending gesture, validate swipe direction
    if (_pendingStartPos != null && _pendingIsRightEdge != null) {
      final dx = details.delta.dx;

      // Skip if no clear horizontal movement yet
      if (dx.abs() < 0.5) return;

      final isValid = _pendingIsRightEdge! ? dx < 0 : dx > 0;

      if (isValid) {
        // Direction matches — start curl
        final reverse = !_pendingIsRightEdge!;
        widget.controller.startCurl(_pendingStartPos!, reverse: reverse);
        widget.onCurlStart();

        // Immediately update to current position
        final renderBox = context.findRenderObject() as RenderBox;
        final size = renderBox.size;
        final localPos = renderBox.globalToLocal(details.globalPosition);
        final normalized = Offset(
          (localPos.dx / size.width).clamp(0.0, 1.0),
          (localPos.dy / size.height).clamp(0.0, 1.0),
        );
        widget.controller.updateCurl(normalized);
      }
      // Clear pending on any clear direction (valid or invalid)
      _pendingStartPos = null;
      _pendingIsRightEdge = null;
    }
  }

  void _onPanEnd(DragEndDetails details) {
    _pendingStartPos = null;
    _pendingIsRightEdge = null;
    if (!widget.controller.isCurling) return;
    final velocity = details.velocity.pixelsPerSecond.dx;
    final shouldCommit = widget.controller.endCurl(velocity: velocity);
    widget.onCurlEnd(shouldCommit, velocity);
  }
}

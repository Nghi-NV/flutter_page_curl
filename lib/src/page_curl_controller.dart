import 'package:flutter/widgets.dart';

/// Controls the page curl animation state.
///
/// Provides methods to programmatically navigate pages and
/// track the current curl state for the shader.
class PageCurlController extends ChangeNotifier {
  PageCurlController({this.initialPage = 0, this.radius = 0.08})
      : _currentPage = initialPage,
        _curlProgress = 0.0,
        _isCurling = false,
        _isReverse = false;

  /// Initial page index.
  final int initialPage;

  /// Cylinder radius (normalized, 0-1).
  final double radius;

  int _currentPage;
  double _curlProgress;
  bool _isCurling;
  bool _isReverse;
  Offset _curlPosition = Offset.zero;
  Offset _curlDirection = const Offset(1.0, 0.0);
  Offset _startPosition = Offset.zero;

  /// Current page index.
  int get currentPage => _currentPage;

  /// Curl progress (0.0 = flat, 1.0 = fully turned).
  double get curlProgress => _curlProgress;

  /// Whether a curl animation is actively happening.
  bool get isCurling => _isCurling;

  /// Whether the curl is going in reverse (previous page).
  bool get isReverse => _isReverse;

  /// Current curl position (normalized 0-1).
  Offset get curlPosition => _curlPosition;

  /// Current curl direction vector (normalized).
  Offset get curlDirection => _curlDirection;

  /// Start position of the curl gesture (normalized 0-1).
  Offset get startPosition => _startPosition;

  /// Total number of pages.
  int totalPages = 0;

  /// Whether there is a next page available.
  bool get hasNextPage => _currentPage < totalPages - 1;

  /// Whether there is a previous page available.
  bool get hasPreviousPage => _currentPage > 0;

  /// Start a curl gesture from a given position.
  ///
  /// [startPos] is the normalized position (0-1) where the touch began.
  /// [reverse] indicates whether we're going to the previous page.
  void startCurl(Offset startPos, {bool reverse = false}) {
    if (reverse && !hasPreviousPage) return;
    if (!reverse && !hasNextPage) return;

    _isCurling = true;
    _isReverse = reverse;
    _startPosition = startPos;
    _curlPosition = startPos;
    _curlDirection = reverse ? const Offset(-1.0, 0.0) : const Offset(1.0, 0.0);
    _curlProgress = 0.0;
    notifyListeners();
  }

  /// Update the curl with a new finger position.
  ///
  /// [currentPos] is the normalized position (0-1) of the finger.
  void updateCurl(Offset currentPos) {
    if (!_isCurling) return;

    _curlPosition = currentPos;

    // Calculate direction from current toward start (points toward uncurled side)
    final delta = _startPosition - currentPos;
    final length = delta.distance;
    if (length > 0.001) {
      _curlDirection = Offset(delta.dx / length, delta.dy / length);
    }

    // Calculate progress based on horizontal movement
    if (_isReverse) {
      _curlProgress = (currentPos.dx - _startPosition.dx).clamp(0.0, 1.0);
    } else {
      _curlProgress = (_startPosition.dx - currentPos.dx).clamp(0.0, 1.0);
    }

    notifyListeners();
  }

  /// End the curl gesture. Returns true if page should be committed.
  ///
  /// [velocity] is the horizontal velocity of the gesture.
  /// [commitThreshold] is the progress threshold to commit (default 0.3).
  /// [velocityThreshold] is the velocity threshold to commit (default 800).
  bool endCurl({
    double velocity = 0.0,
    double commitThreshold = 0.3,
    double velocityThreshold = 800.0,
  }) {
    if (!_isCurling) return false;

    // Determine if we should commit based on progress or velocity
    final shouldCommit =
        _curlProgress > commitThreshold || velocity.abs() > velocityThreshold;

    return shouldCommit;
  }

  /// Complete the curl animation (page turn committed).
  void commitCurl() {
    if (_isReverse) {
      _currentPage = (_currentPage - 1).clamp(0, totalPages - 1);
    } else {
      _currentPage = (_currentPage + 1).clamp(0, totalPages - 1);
    }
    _isCurling = false;
    _curlProgress = 0.0;
    notifyListeners();
  }

  /// Cancel the curl animation (return to flat).
  void cancelCurl() {
    _isCurling = false;
    _curlProgress = 0.0;
    notifyListeners();
  }

  /// Programmatically go to the next page with animation.
  void nextPage() {
    if (!hasNextPage) return;
    startCurl(const Offset(1.0, 0.5));
    _curlProgress = 1.0;
    commitCurl();
  }

  /// Programmatically go to the previous page with animation.
  void previousPage() {
    if (!hasPreviousPage) return;
    startCurl(const Offset(0.0, 0.5), reverse: true);
    _curlProgress = 1.0;
    commitCurl();
  }

  /// Jump to a specific page without animation.
  void jumpToPage(int page) {
    _currentPage = page.clamp(0, totalPages - 1);
    _isCurling = false;
    _curlProgress = 0.0;
    notifyListeners();
  }
}

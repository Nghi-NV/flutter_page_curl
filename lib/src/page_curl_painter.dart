import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'page_curl_controller.dart';

/// CustomPainter that renders the page curl effect using a GLSL shader.
class PageCurlPainter extends CustomPainter {
  PageCurlPainter({
    required this.shader,
    required this.controller,
    required this.currentPageImage,
    required this.nextPageImage,
    this.shadowWidth = 0.15,
    this.backOpacity = 0.5,
  }) : super(repaint: controller);

  /// The compiled fragment shader.
  final ui.FragmentShader shader;

  /// The controller providing curl state.
  final PageCurlController controller;

  /// Rasterized image of the current page.
  final ui.Image currentPageImage;

  /// Rasterized image of the next (or previous) page.
  final ui.Image nextPageImage;

  /// Shadow width multiplier.
  final double shadowWidth;

  /// Back page opacity/darkening factor (0=transparent, 1=full opacity).
  final double backOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    // Float uniforms (order must match GLSL)
    int idx = 0;

    // uSize (vec2)
    shader.setFloat(idx++, size.width);
    shader.setFloat(idx++, size.height);

    // uCurlPos (vec2) - normalized position
    shader.setFloat(idx++, controller.curlPosition.dx);
    shader.setFloat(idx++, controller.curlPosition.dy);

    // uCurlDir (vec2) - normalized direction
    shader.setFloat(idx++, controller.curlDirection.dx);
    shader.setFloat(idx++, controller.curlDirection.dy);

    // uRadius (float)
    shader.setFloat(idx++, controller.radius);

    // uShadowWidth (float)
    shader.setFloat(idx++, shadowWidth);

    // uBackOpacity (float)
    shader.setFloat(idx++, backOpacity);

    // uReverse (float)
    shader.setFloat(idx++, controller.isReverse ? 1.0 : 0.0);

    // Image samplers
    shader.setImageSampler(0, currentPageImage);
    shader.setImageSampler(1, nextPageImage);

    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant PageCurlPainter oldDelegate) {
    return oldDelegate.currentPageImage != currentPageImage ||
        oldDelegate.nextPageImage != nextPageImage ||
        oldDelegate.controller != controller;
  }
}

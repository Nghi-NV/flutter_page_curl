# flutter_page_curl

A high-performance page curl effect for Flutter, powered by GLSL fragment shaders. Creates realistic, interactive page-turning animations that respond to touch gestures.

[![pub package](https://img.shields.io/pub/v/flutter_page_curl.svg)](https://pub.dev/packages/flutter_page_curl)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

![Page Curl Demo](https://raw.githubusercontent.com/Nghi-NV/flutter_page_curl/main/assets/page_curl_demo.gif)

## Features

- 🚀 **GPU-accelerated** — GLSL fragment shader runs entirely on the GPU
- 👆 **Interactive gestures** — Curl follows your finger precisely from screen edges
- ↔️ **Bidirectional** — Swipe left-to-right or right-to-left to navigate
- 📄 **Realistic rendering** — Cylinder deformation, shadows, and back-page shading
- 🎛️ **Customizable** — Control radius, shadow, opacity, edge zones, and animation
- 🔒 **Direction-aware** — Only triggers when swiping in the correct direction

## Getting Started

Add the dependency:

```yaml
dependencies:
  flutter_page_curl: ^0.1.0
```

## Usage

### Basic

```dart
import 'package:flutter_page_curl/flutter_page_curl.dart';

PageCurlView(
  children: [
    Container(color: Colors.red, child: Center(child: Text('Page 1'))),
    Container(color: Colors.blue, child: Center(child: Text('Page 2'))),
    Container(color: Colors.green, child: Center(child: Text('Page 3'))),
  ],
)
```

### With Controller

```dart
final controller = PageCurlController();

PageCurlView(
  controller: controller,
  radius: 0.06,
  shadowWidth: 0.12,
  backOpacity: 0.6,
  edgeZoneWidth: 0.3,
  onPageChanged: (page) => print('Page: $page'),
  children: pages,
)

// Programmatic navigation
controller.nextPage();
controller.previousPage();
controller.goToPage(2);
```

### Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `children` | `List<Widget>` | required | The pages to display |
| `controller` | `PageCurlController?` | null | Optional external controller |
| `radius` | `double` | 0.08 | Curl cylinder radius (0-1) |
| `shadowWidth` | `double` | 0.15 | Shadow width multiplier |
| `backOpacity` | `double` | 0.5 | Back page darkening (0-1) |
| `edgeZoneWidth` | `double` | 0.2 | Edge zone for gesture activation (0-1) |
| `animationDuration` | `Duration` | 400ms | Commit/cancel animation duration |
| `animationCurve` | `Curve` | easeOut | Animation curve |
| `onPageChanged` | `ValueChanged<int>?` | null | Page change callback |

## How It Works

The page curl effect is rendered by a custom GLSL fragment shader that:

1. Computes the distance from each pixel to the curl axis
2. Maps pixels onto a cylinder surface for the curling region
3. Applies shadow and back-page tinting for realism
4. Handles both forward and reverse curl via UV mirroring

Page content is captured as textures via `RepaintBoundary.toImage()` and passed to the shader each frame.

## Requirements

- Flutter ≥ 3.10.0 (for `FragmentProgram` support)
- Dart ≥ 3.0.0
- Impeller rendering backend (enabled by default on iOS, opt-in on Android)

## License

MIT — see [LICENSE](LICENSE) for details.

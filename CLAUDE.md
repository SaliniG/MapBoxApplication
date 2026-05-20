# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run the app
flutter run

# Analyze / lint
flutter analyze

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Get dependencies
flutter pub get
```

## Architecture

This is a Flutter app with a single screen (`MapScreen`) that renders an interactive Mapbox map via the `flutter_map` package (not the official Mapbox Flutter SDK — tiles are served via a Mapbox style URL in `AppConstants.mapBoxIntegrationUrl`).

**Key relationships:**
- `main.dart` → boots `MapScreen`
- `lib/ui/mapscreen.dart` — all map logic lives here: location fetching, tap-to-add-marker, polyline, and polygon rendering
- `lib/utils/constants.dart` — holds the Mapbox tile URL (with embedded access token) and the default center (`LatLng(9.5, 76.3)`, Kerala, India)
- `lib/utils/asset_path.dart` — single reference to the GIF marker asset at `assets/gif/map_gif.gif`

**State model in `MapScreen`:**
- `latLngList` — single source of truth; every tap appends a point. The same list drives markers, the polyline, and the polygon simultaneously.
- `_selectedIndex` (`ValueNotifier<int>`) — flips from 0 → 1 once GPS location is obtained, which shifts the initial map center to the user's current position.
- `getLocation()` runs once on `initState`, requests permissions, fetches the device position, prepends it to `latLngList`, and moves the camera.

**Map layers rendered (in order):** `TileLayer` → `MarkerLayer` (GIF at each tap point) → `PolylineLayer` (blue line connecting all points) → `PolygonLayer` (filled purple polygon over all points).

## Assets

- `assets/gif/` — animated GIF used as marker icon
- `assets/images/` — declared in pubspec but currently unused

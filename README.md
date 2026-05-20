# WayMapper

A Flutter map application built with [flutter_map](https://pub.dev/packages/flutter_map) and Mapbox tile styles. The app provides an interactive map experience with real-time GPS tracking, search, road routing, and a clean BLoC-driven state architecture.

---

## Features

### Map & Navigation
- **Interactive map** — tap anywhere to drop a GIF-animated marker
- **GPS location** — automatically centers the map on your current position at launch
- **Zoom controls** — dedicated zoom in / zoom out buttons on the right panel
- **Compass** — resets the map bearing to north with a single tap

### Map Styles
Switch between four Mapbox tile styles instantly:
- Custom Style (default)
- Streets
- Satellite
- Outdoors

### Markers & Drawing
- **Tap to add markers** — each tap places an animated GIF marker at that coordinate
- **Polyline** — a blue line connects all placed markers in order
- **Polygon** — a filled purple polygon is drawn over all placed points
- **Undo** — removes the last placed marker
- **Clear all** — removes every marker, the polyline, and the polygon in one tap

### Distance
- **Live km badge** — shows the total straight-line distance across all markers, updated after every tap

### Search & Geocoding
- **Search bar** — type an address or place name to search
- **Autocomplete suggestions** — up to 5 results appear as you type (500 ms debounce) powered by the free Nominatim API
- **Tap to navigate** — selecting a suggestion moves the camera to that location instantly

### Road Routing
- **Road route toggle** — when enabled, the app fetches a real driving route between markers using the free OSRM API
- The route polyline snaps to actual roads and updates as new markers are added

### Dark Mode
- Full dark / light theme toggle via a button in the right panel
- All FABs, badges, and UI surfaces adapt to the current theme

### Share Location
- Share your current GPS coordinates via the device share sheet

---

## Architecture

```
lib/
├── bloc/
│   ├── map_event.dart   # All user actions (tap, undo, clear, route toggle …)
│   ├── map_state.dart   # Immutable state (markers, routePoints, tileUrl …)
│   └── map_bloc.dart    # Business logic + OSRM route fetching
├── ui/
│   └── mapscreen.dart   # Single screen: map layers, FABs, search bar
└── utils/
    ├── constants.dart       # Mapbox style URLs
    ├── secrets.dart         # Mapbox token — gitignored, never committed
    └── secrets.example.dart # Template for local setup
```

State is managed with **flutter_bloc**. The map always starts clean — no markers or routes are persisted between sessions.

---

## Getting Started

### Prerequisites
- Flutter SDK
- A Mapbox public access token

### Setup

1. Clone the repository
   ```bash
   git clone https://github.com/SaliniG/MapBoxApplication.git
   cd MapBoxApplication
   ```

2. Create your secrets file
   ```bash
   cp lib/utils/secrets.example.dart lib/utils/secrets.dart
   ```
   Open `lib/utils/secrets.dart` and replace `YOUR_MAPBOX_PUBLIC_TOKEN` with your actual token from [mapbox.com](https://mapbox.com).

3. Install dependencies
   ```bash
   flutter pub get
   ```

4. Run the app
   ```bash
   flutter run
   ```

5. Allow location permission when prompted — the map will center on your current position.

---

## APIs Used

| API | Purpose | Key required |
|-----|---------|--------------|
| Mapbox Styles | Map tile rendering | Yes (public token) |
| Nominatim (OSM) | Address search & autocomplete | No |
| OSRM | Driving route calculation | No |

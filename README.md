# map_box_application

Displays a full-screen Mapbox map using any style map:

Utilize the Mapbox Flutter plugin to render a full-screen interactive map. Choose any Mapbox style (e.g., streets, satellite) to customize the map's appearance.
Main Dart file code that initializes the Mapbox map:

Created a Flutter application that initializes a Mapbox map by setting up the necessary access token and configuring the initial camera position. This code ensures the map loads when the app starts.
Add a static marker at a predefined location on the map:

Use the addSymbol method to place a static marker at a specific latitude and longitude on the map. Customize the marker's icon as needed.
Draw a line:

Use the addLine method to draw a line on the map between predefined points. This can be used to represent routes or boundaries.
A highlighted area:

Use the addFill method to highlight a polygonal area on the map. This is useful for emphasizing regions such as parks, zones, or specific areas of interest.
Directional arrows on the map:


Implement an onMapClick listener that allows users to tap on the map to place a marker at the tapped location. This feature enhances interactivity and user engagement.
Allowing the user to draw lines on the map through user interaction:

Capture multiple tap events and dynamically draw a line based on the collected points. This allows users to create custom paths or routes directly on the map.
Allowing the user to highlight areas on the map through user interaction:

Capture user-defined polygon points through multiple taps and use these points to draw and highlight areas on the map. This feature allows users to define and visualize custom areas.
Allowing the user to add arrows directly on the map through user interaction:

Similar to adding markers, this feature allows users to place directional arrows by tapping on the map. Use custom arrow icons to represent these symbols.
Allow users to place GIF markers on the map by tapping:

Extend marker functionality to support animated GIFs. When a user taps on the map, place a marker with a GIF icon, enhancing visual appeal and providing dynamic content.









## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

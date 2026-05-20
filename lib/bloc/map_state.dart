import 'package:latlong2/latlong.dart';
import 'package:map_box_application/utils/constants.dart';

class MapState {
  final List<LatLng> markers;
  final List<LatLng> routePoints;
  final bool roadRouteEnabled;
  final String tileUrl;
  final bool locationFetched;
  final bool sessionActive; // true only after user taps the map this session

  const MapState({
    this.markers = const [],
    this.routePoints = const [],
    this.roadRouteEnabled = false,
    this.tileUrl = AppConstants.mapBoxIntegrationUrl,
    this.locationFetched = false,
    this.sessionActive = false,
  });

  MapState copyWith({
    List<LatLng>? markers,
    List<LatLng>? routePoints,
    bool? roadRouteEnabled,
    String? tileUrl,
    bool? locationFetched,
    bool? sessionActive,
  }) {
    return MapState(
      markers: markers ?? this.markers,
      routePoints: routePoints ?? this.routePoints,
      roadRouteEnabled: roadRouteEnabled ?? this.roadRouteEnabled,
      tileUrl: tileUrl ?? this.tileUrl,
      locationFetched: locationFetched ?? this.locationFetched,
      sessionActive: sessionActive ?? this.sessionActive,
    );
  }

  double get totalDistanceKm {
    const calc = Distance();
    // When a road route exists, sum along the actual polyline for road distance
    if (routePoints.length >= 2) {
      double total = 0;
      for (int i = 0; i < routePoints.length - 1; i++) {
        total += calc.as(LengthUnit.Kilometer, routePoints[i], routePoints[i + 1]);
      }
      return total;
    }
    // Fall back to straight-line distance between markers
    if (markers.length < 2) return 0;
    double total = 0;
    for (int i = 0; i < markers.length - 1; i++) {
      total += calc.as(LengthUnit.Kilometer, markers[i], markers[i + 1]);
    }
    return total;
  }
}

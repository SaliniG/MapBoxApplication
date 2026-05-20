import 'package:latlong2/latlong.dart';

abstract class MapEvent {}

class MapTapped extends MapEvent {
  final LatLng latLng;
  MapTapped(this.latLng);
}

class LocationObtained extends MapEvent {
  final LatLng latLng;
  LocationObtained(this.latLng);
}

class MarkerUndone extends MapEvent {}

class MarkersCleared extends MapEvent {}

class MarkersLoaded extends MapEvent {
  final List<LatLng> markers;
  MarkersLoaded(this.markers);
}

class TileUrlChanged extends MapEvent {
  final String url;
  TileUrlChanged(this.url);
}

class RoadRouteToggled extends MapEvent {}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'map_event.dart';
import 'map_state.dart';


class MapBloc extends Bloc<MapEvent, MapState> {
  MapBloc() : super(const MapState()) {
    on<MapTapped>(_onMapTapped);
    on<LocationObtained>(_onLocationObtained);
    on<MarkerUndone>(_onMarkerUndone);
    on<MarkersCleared>(_onMarkersCleared);
    on<MarkersLoaded>(_onMarkersLoaded);
    on<TileUrlChanged>(_onTileUrlChanged);
    on<RoadRouteToggled>(_onRoadRouteToggled);
  }

  Future<void> _onMapTapped(MapTapped event, Emitter<MapState> emit) async {
    final updated = [...state.markers, event.latLng];
    emit(state.copyWith(markers: updated, sessionActive: true));
    if (state.roadRouteEnabled && updated.length >= 2) {
      await _fetchRoute(updated, emit);
    }
  }

  void _onLocationObtained(LocationObtained event, Emitter<MapState> emit) {
    final updated = [...state.markers, event.latLng];
    emit(state.copyWith(markers: updated, locationFetched: true));
  }

  void _onMarkerUndone(MarkerUndone event, Emitter<MapState> emit) {
    if (state.markers.isEmpty) return;
    final updated = [...state.markers]..removeLast();
    emit(state.copyWith(markers: updated, routePoints: []));
  }

  void _onMarkersCleared(MarkersCleared event, Emitter<MapState> emit) {
    emit(state.copyWith(markers: [], routePoints: []));
  }

  void _onMarkersLoaded(MarkersLoaded event, Emitter<MapState> emit) {
    emit(state.copyWith(markers: event.markers));
  }

  void _onTileUrlChanged(TileUrlChanged event, Emitter<MapState> emit) {
    emit(state.copyWith(tileUrl: event.url));
  }

  Future<void> _onRoadRouteToggled(RoadRouteToggled event, Emitter<MapState> emit) async {
    final enabled = !state.roadRouteEnabled;
    emit(state.copyWith(roadRouteEnabled: enabled, routePoints: []));
    if (enabled && state.markers.length >= 2) {
      await _fetchRoute(state.markers, emit);
    }
  }

  Future<void> _fetchRoute(List<LatLng> markers, Emitter<MapState> emit) async {
    final coords = markers.map((e) => '${e.longitude},${e.latitude}').join(';');
    try {
      final response = await http.get(Uri.parse(
        'http://router.project-osrm.org/route/v1/driving/$coords?overview=full&geometries=geojson',
      ));
      final data   = jsonDecode(response.body);
      final points = data['routes'][0]['geometry']['coordinates'] as List;
      emit(state.copyWith(
        routePoints: points.map((c) => LatLng(c[1] as double, c[0] as double)).toList(),
      ));
    } catch (e) {
      debugPrint('Route error: $e');
    }
  }


}

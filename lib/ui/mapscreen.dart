import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:map_box_application/bloc/map_bloc.dart';
import 'package:map_box_application/bloc/map_event.dart';
import 'package:map_box_application/bloc/map_state.dart';
import 'package:map_box_application/main.dart';
import 'package:map_box_application/utils/asset_path.dart';
import 'package:map_box_application/utils/constants.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController         _mapController    = MapController();
  final TextEditingController _searchController = TextEditingController();
  final Location              _location         = Location();
  late LocationData           _currentPosition;
  bool                        _locationFetched  = false;
  List<Map<String, dynamic>>  _suggestions      = [];
  Timer?                      _debounce;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }


  Future<void> _fetchLocation() async {
    try {
      try {
        bool ok = await _location.serviceEnabled();
        if (!ok) { ok = await _location.requestService(); if (!ok) return; }
      } catch (_) {}

      PermissionStatus perm = await _location.hasPermission();
      if (perm == PermissionStatus.denied) {
        perm = await _location.requestPermission();
        if (perm != PermissionStatus.granted) return;
      }

      _currentPosition = await _location.getLocation();
      _locationFetched = true;
      final latLng = LatLng(_currentPosition.latitude!, _currentPosition.longitude!);
      if (mounted) {
        context.read<MapBloc>().add(LocationObtained(latLng));
        _mapController.move(latLng, 13);
      }
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MapBloc, MapState>(
      builder: (context, state) {
        final isDark    = Theme.of(context).brightness == Brightness.dark;
        final cardColor = isDark ? Colors.grey[850]! : Colors.white;

        return Scaffold(
          body: Stack(
            children: [
              // ── Map ──────────────────────────────────────────────────
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: state.locationFetched && state.markers.isNotEmpty
                      ? state.markers.first
                      : AppConstants.initialLocation,
                  initialZoom: 10,
                  onTap: (_, latLng) => context.read<MapBloc>().add(MapTapped(latLng)),
                ),
                children: [
                  TileLayer(
                    urlTemplate: state.tileUrl,
                    userAgentPackageName: AppConstants.userAgentPackageName,
                  ),
                  MarkerLayer(
                    markers: state.markers.map((e) => Marker(
                      point: e,
                      alignment: Alignment.center,
                      child: GestureDetector(
                        onTap: () => _showMarkerInfo(context, e),
                        child: Image.asset(AssetsPath.mapGif),
                      ),
                    )).toList(),
                  ),
                  if (state.sessionActive)
                    PolylineLayer(polylines: [
                      Polyline(
                        points: state.roadRouteEnabled ? state.routePoints : state.markers,
                        color: state.roadRouteEnabled ? Colors.green.shade600 : Colors.blue,
                        strokeWidth: 3,
                      ),
                    ]),
                  if (state.sessionActive)
                    PolygonLayer(polygons: [
                      Polygon(
                        points: state.markers,
                        color: Colors.purple.shade100.withValues(alpha: 0.5),
                        isFilled: true,
                      ),
                    ]),
                ],
              ),

              // ── Search bar ────────────────────────────────────────────
              Positioned(
                top: 46,
                left: 14,
                right: 72,
                child: Material(
                  elevation: 6,
                  shadowColor: Colors.black26,
                  borderRadius: BorderRadius.circular(26),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search location...',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                      prefixIcon: const Icon(Icons.search_rounded, color: Colors.blue),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.arrow_forward_rounded, color: Colors.blue, size: 20),
                        onPressed: () => _searchLocation(_searchController.text),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(26),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: cardColor,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: _onSearchChanged,
                    onSubmitted: _searchLocation,
                  ),
                ),
              ),

              // ── Suggestions dropdown ──────────────────────────────────
              if (_suggestions.isNotEmpty)
                Positioned(
                  top: 104,
                  left: 14,
                  right: 72,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(14),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: _suggestions.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final s = _suggestions[i];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.location_on_outlined, color: Colors.blue, size: 20),
                            title: Text(
                              s['name'] as String,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                            onTap: () => _selectSuggestion(s),
                          );
                        },
                      ),
                    ),
                  ),
                ),

              // ── Badges ────────────────────────────────────────────────
              if (_suggestions.isEmpty)
              Positioned(
                top: 108,
                left: 14,
                child: _pill(
                  color: Colors.blue.shade700,
                  icon: Icons.place_rounded,
                  label: '${state.markers.length}',
                ),
              ),
              if (_suggestions.isEmpty && state.markers.length >= 2)
                Positioned(
                  top: 108,
                  left: 72,
                  child: _pill(
                    color: Colors.black87,
                    icon: Icons.straighten_rounded,
                    label: _formatDistance(state.totalDistanceKm),
                  ),
                ),

              // ── Action buttons (bottom-left) ──────────────────────────
              Positioned(
                bottom: 24,
                left: 14,
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _actionBtn(Icons.undo_rounded,         Colors.orange.shade600, () => context.read<MapBloc>().add(MarkerUndone()),  'Undo'),
                      const SizedBox(width: 6),
                      _actionBtn(Icons.delete_sweep_rounded, Colors.red.shade500,    () => context.read<MapBloc>().add(MarkersCleared()), 'Clear'),
                      const SizedBox(width: 6),
                      _actionBtn(Icons.ios_share_rounded,    Colors.teal.shade500,   () => _shareLocation(context),                      'Share'),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Right FAB column ───────────────────────────────────────────
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _fab(heroTag: 'theme',    icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, onTap: () => MyApp.of(context).toggleTheme(), small: true),
              _gap,
              _fab(heroTag: 'style',   icon: Icons.layers_rounded,   onTap: () => _showStylePicker(context, state), small: true),
              _gap,
              _fab(heroTag: 'route',   icon: Icons.alt_route_rounded, onTap: () => context.read<MapBloc>().add(RoadRouteToggled()), small: true, color: state.roadRouteEnabled ? Colors.green.shade600 : null),
              _gap,
              _fab(heroTag: 'compass', icon: Icons.explore_rounded,   onTap: () => _mapController.rotate(0), small: true),
              _gap,
              _fab(heroTag: 'zoom_in', icon: Icons.add_rounded,       onTap: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1), small: true),
              _gap,
              _fab(heroTag: 'zoom_out',icon: Icons.remove_rounded,    onTap: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1), small: true),
              _gap,
              _fab(heroTag: 'my_location', icon: Icons.my_location_rounded, onTap: _goToCurrentLocation, color: Colors.blue),
            ],
          ),
        );
      },
    );
  }

  // ─── Reusable widgets ──────────────────────────────────────────────────────

  static const _gap = SizedBox(height: 8);

  Widget _fab({required String heroTag, required IconData icon, required VoidCallback onTap, bool small = false, Color? color}) {
    return Builder(builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final bg = color ?? (isDark ? Colors.grey[850] : Colors.white);
      final fg = color != null ? Colors.white : (isDark ? Colors.white70 : Colors.blueGrey.shade700);
      if (small) {
        return FloatingActionButton.small(heroTag: heroTag, onPressed: onTap, backgroundColor: bg, elevation: 3, child: Icon(icon, color: fg, size: 20));
      }
      return FloatingActionButton(heroTag: heroTag, onPressed: onTap, backgroundColor: bg, elevation: 4, child: Icon(icon, color: fg));
    });
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }

  Widget _pill({required Color color, required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ─── Actions ───────────────────────────────────────────────────────────────

  void _goToCurrentLocation() {
    if (_locationFetched) {
      _mapController.move(LatLng(_currentPosition.latitude!, _currentPosition.longitude!), 15);
    }
  }

  void _shareLocation(BuildContext context) {
    final c = _mapController.camera.center;
    final text = 'Lat: ${c.latitude.toStringAsFixed(6)}, Lng: ${c.longitude.toStringAsFixed(6)}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied: $text'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (query.trim().length < 3) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () => _fetchSuggestions(query));
  }

  Future<void> _fetchSuggestions(String query) async {
    try {
      final res = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5&addressdetails=1'),
        headers: {'User-Agent': AppConstants.userAgentPackageName},
      );
      final results = jsonDecode(res.body) as List;
      if (mounted) {
        setState(() {
          _suggestions = results.map((r) => {
            'name': r['display_name'] as String,
            'lat':  r['lat'] as String,
            'lon':  r['lon'] as String,
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Suggestion error: $e');
    }
  }

  void _selectSuggestion(Map<String, dynamic> s) {
    _mapController.move(
      LatLng(double.parse(s['lat'] as String), double.parse(s['lon'] as String)),
      13,
    );
    _searchController.clear();
    setState(() => _suggestions = []);
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _suggestions = []);
    try {
      final res = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1'),
        headers: {'User-Agent': AppConstants.userAgentPackageName},
      );
      final results = jsonDecode(res.body) as List;
      if (results.isEmpty) return;
      _mapController.move(
        LatLng(double.parse(results[0]['lat'] as String), double.parse(results[0]['lon'] as String)),
        13,
      );
      _searchController.clear();
    } catch (e) {
      debugPrint('Search error: $e');
    }
  }

  void _showStylePicker(BuildContext context, MapState state) {
    final styles = {
      'Custom':    AppConstants.mapBoxIntegrationUrl,
      'Streets':   AppConstants.mapBoxStreetsUrl,
      'Satellite': AppConstants.mapBoxSatelliteUrl,
      'Outdoors':  AppConstants.mapBoxOutdoorsUrl,
    };
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 12),
            const Text('Map Style', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            ...styles.entries.map((e) => ListTile(
              leading: Icon(Icons.map_outlined, color: Colors.blue.shade700),
              title: Text(e.key),
              trailing: state.tileUrl == e.value ? Icon(Icons.check_circle, color: Colors.blue.shade700) : null,
              onTap: () {
                context.read<MapBloc>().add(TileUrlChanged(e.value));
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showMarkerInfo(BuildContext context, LatLng point) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 12),
            const Align(alignment: Alignment.centerLeft, child: Text('Marker Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            const SizedBox(height: 12),
            _infoRow(Icons.swap_vert_rounded,  'Latitude',  point.latitude.toStringAsFixed(6)),
            const SizedBox(height: 8),
            _infoRow(Icons.swap_horiz_rounded, 'Longitude', point.longitude.toStringAsFixed(6)),
          ],
        ),
      ),
    );
  }

  String _formatDistance(double km) {
    if (km < 1) return '${(km * 1000).round()} m';
    final s = km.toStringAsFixed(2)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
    return '$s km';
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue.shade700, size: 17),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}

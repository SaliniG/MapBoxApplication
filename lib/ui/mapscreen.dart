import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:map_box_application/utils/asset_path.dart';
import 'package:map_box_application/utils/constants.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  late LocationData _currentPosition;
  Location location = Location();
  List<LatLng> latLngList = [];
  late ValueNotifier<int> _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = ValueNotifier<int>(0);
    getLocation();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: null,
      builder: (context, snapshot) {
        return ValueListenableBuilder<int>(
          valueListenable: _selectedIndex,
          builder: (context, value, child) {
            return FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _selectedIndex == 1 ? latLngList[0] : AppConstants.initialLocation,
                initialZoom: 10,
                onTap: (position, latLng) {
                  setState(
                    () {
                      latLngList.add(latLng);
                    },
                  );
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: AppConstants.mapBoxIntegrationUrl,
                  userAgentPackageName: AppConstants.userAgentPackageName,
                ),
                MarkerLayer(
                    markers: List<Marker>.from(
                  latLngList.map(
                    (e) => Marker(
                      point: e,
                      alignment: Alignment.center,
                      child: Image.asset(
                        AssetsPath.mapGif,
                      ),
                    ),
                  ),
                ).toList()),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: latLngList,
                      color: Colors.blue,
                      strokeWidth: 2,
                    ),
                  ],
                ),
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: latLngList,
                      color: Colors.purple.shade100.withOpacity(0.5),
                      isFilled: true,
                    )
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  getLocation() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _currentPosition = await location.getLocation();
    _selectedIndex.value = 1;
    latLngList.add(LatLng(_currentPosition.latitude!, _currentPosition.longitude!));
    _mapController.move(LatLng(_currentPosition.latitude!, _currentPosition.longitude!), 13);
  }
}

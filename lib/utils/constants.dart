import 'package:latlong2/latlong.dart';
import 'secrets.dart';

class AppConstants {
  static const _base = 'https://api.mapbox.com/styles/v1';

  static const mapBoxIntegrationUrl = '$_base/salini-geetha/clwabkimg02yc01qzctvm4565/tiles/256/{z}/{x}/{y}@2x?access_token=$mapboxToken';
  static const mapBoxStreetsUrl     = '$_base/mapbox/streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token=$mapboxToken';
  static const mapBoxSatelliteUrl   = '$_base/mapbox/satellite-streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token=$mapboxToken';
  static const mapBoxOutdoorsUrl    = '$_base/mapbox/outdoors-v12/tiles/256/{z}/{x}/{y}@2x?access_token=$mapboxToken';
  static const mapBoxDarkUrl        = '$_base/mapbox/dark-v11/tiles/256/{z}/{x}/{y}@2x?access_token=$mapboxToken';

  static const userAgentPackageName = 'com.example.app';
  static const initialLocation = LatLng(9.5, 76.3);
}

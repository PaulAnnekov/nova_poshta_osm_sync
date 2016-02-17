import 'package:nova_poshta_osm_sync/leaflet/leaflet.dart' as L;

class LatLon {
  num lat, lon;

  LatLon(this.lat, this.lon);

  bool operator ==(LatLon other) => lat == other.lat && lon == other.lon;

  L.LatLng toLeaflet() {
    return L.latLng(lat, lon);
  }

  String toId() {
    return '$lat $lon';
  }

  List toList() {
    return [lat, lon];
  }

  String toString() {
    return '$lat, $lon';
  }
}
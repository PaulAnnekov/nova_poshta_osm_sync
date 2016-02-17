import 'package:nova_poshta_osm_sync/lat_lng.dart';

class Branch {
  int number;
  LatLng loc;
  Branch(this.loc, [this.number]);
}
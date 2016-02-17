import 'package:nova_poshta_osm_sync/lat_lng.dart';
import 'package:nova_poshta_osm_sync/branch.dart';
import 'package:nova_poshta_osm_sync/location_name.dart';

class OsmBranch extends Branch {
  LocationName city;
  OsmBranch(LatLng loc, int number, this.city) : super(loc, number);
}
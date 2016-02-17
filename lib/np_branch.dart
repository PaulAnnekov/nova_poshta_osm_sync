import 'package:nova_poshta_osm_sync/lat_lon.dart';
import 'package:nova_poshta_osm_sync/branch.dart';
import "package:nova_poshta_osm_sync/location_name.dart";

class NpBranch extends Branch {
  LocationName city;
  NpBranch(LatLon loc, Map customTags, this.city, int number) : super(loc, customTags, number);
}
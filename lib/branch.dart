import 'package:nova_poshta_osm_sync/lat_lon.dart';

class Branch {
  int number;
  LatLon loc;
  Map customTags;

  Branch(this.loc, this.customTags, [this.number]);

  String toString() {
    return '$runtimeType $customTags $loc $number';
  }
}
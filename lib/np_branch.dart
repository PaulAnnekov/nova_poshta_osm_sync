import 'package:nova_poshta_osm_sync/lat_lon.dart';
import 'package:nova_poshta_osm_sync/branch.dart';
import "package:nova_poshta_osm_sync/location_name.dart";
import 'package:logging/logging.dart';

final Logger log = new Logger('np_branch');

class NpBranch extends Branch {
  LocationName city;
  NpBranch(LatLon loc, Map customTags, this.city, int number) : super(loc, customTags, number);

  getStreet() {
    var match = new RegExp(r'/.*: [^ ]+ ([^,0-9]+)/').firstMatch(customTags['addr']);
    if (!match) {
      log.warning("Can't get city for $this");
      return null;
    }

    return match.group(1);
  }
}
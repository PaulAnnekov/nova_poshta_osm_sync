import 'package:nova_poshta_osm_sync/lat_lon.dart';
import 'package:nova_poshta_osm_sync/branch.dart';
import 'package:logging/logging.dart';

final Logger log = new Logger('osm_branch');

class OsmBranch extends Branch {
  OsmBranch(LatLon loc, Map customTags) : super(loc, customTags) {
    number = _getOsmmBranchId();
  }

  int _getOsmmBranchId() {
    RegExp numberRegExp = new RegExp('([0-9]+)');
    RegExp cleanerRegExp = new RegExp('[0-9]+ {0,1}кг');
    List<int> numbers = [];
    ['branch', 'name', 'ref', 'official_name'].forEach((tag) {
      if (customTags[tag] == null)
        return;
      String branch = customTags[tag].replaceAll(cleanerRegExp, '');
      var matches = numberRegExp.allMatches(branch);
      if (matches.length > 1)
        log.warning("osmm $this '$tag' tag contains more then one numbers sequence");
      if (matches.isNotEmpty)
        numbers.add(int.parse(matches.first.group(0)));
    });
    var isSame = numbers.every((number) {
      return numbers[0] == number;
    });
    if (!isSame)
      log.warning("numbers from tags are not equal for $this");
    return numbers.isNotEmpty && isSame ? numbers[0] : null;
  }
}
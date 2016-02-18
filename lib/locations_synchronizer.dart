import "package:nova_poshta_osm_sync/branch.dart";
import "package:nova_poshta_osm_sync/lat_lon.dart";
import "package:nova_poshta_osm_sync/branches_processor.dart";
import "package:nova_poshta_osm_sync/location_processor.dart";

class LocationsSynchronizer {
  BranchesProcessor _branchesProcessor;
  LocationsSynchronizer(this._branchesProcessor);

  List<Map<String, Branch>> sync() {
    List<Map<String, Branch>> results = [];
    this._branchesProcessor.groupedBranches.forEach((groupId, branches) {
      results.addAll(_syncSingle(groupId, branches));
    });

    return results;
  }

  List<Map<String, Branch>> _syncSingle(groupId, Map<String, List<Branch>> branches) {
    List<Map<String, Branch>> results = [];
    branches['npms'].forEach((npm) {
      var osmm = _getBranchByNumber(branches['osmms'], npm.number);
      if (osmm == -1)
        return false;
      if (_isNear(npm.loc, branches['osmms'][osmm].loc)) {
        results.add({
          'result': branches['osmms'][osmm],
          'from': npm
        });
      }
    });

    return results;
  }

  _isNear(LatLon point1, LatLon point2, [num max = 100]) {
    return LocationsProcessor.calculateDistance(point1, point2) <= max;
  }

  int _getBranchByNumber(List<Branch> branches, int number) {
    var branch = branches.firstWhere((Branch branch) {
      if (branch.number == null)
        return false;
      return branch.number == number;
    }, orElse: () => null);
    return branches.indexOf(branch);
  }
}
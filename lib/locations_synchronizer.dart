import "package:nova_poshta_osm_sync/branch.dart";
import "package:nova_poshta_osm_sync/lat_lon.dart";
import "package:nova_poshta_osm_sync/branches_processor.dart";
import "package:nova_poshta_osm_sync/location_processor.dart";

class LocationsSynchronizer {
  BranchesProcessor _branchesProcessor;
  LocationsSynchronizer(this._branchesProcessor);

  sync() {
    this._branchesProcessor.groupedBranches.forEach((groupId, branches) => _syncSingle(groupId, branches));
  }

  _syncSingle(groupId, Map<String, List<Branch>> branches) {
    List npmRemove = [];
    List osmRemove = [];
    branches['npms'].forEach((npm) {
      var osmm = _getBranchByNumber(branches['osmms'], npm.number);
      if (osmm == null)
        return;
      if (_isNear(npm.loc, osmm.loc)) {
        npmRemove.add(npm);
        osmRemove.add(osmm);
      }
    });
    npmRemove.forEach((branch) {
      this._branchesProcessor.groupedBranches[groupId]['npms'].remove(branch);
    });
    osmRemove.forEach((branch) {
      this._branchesProcessor.groupedBranches[groupId]['osmms'].remove(branch);
    });
  }

  _isNear(LatLon point1, LatLon point2, [num max = 100]) {
    return LocationsProcessor.calculateDistance(point1, point2) <= max;
  }

  _getBranchByNumber(List<Branch> branches, int number) {
    return branches.firstWhere((Branch branch) {
      if (branch.number == null)
        return false;
      return branch.number == number;
    }, orElse: () => null);
  }
}
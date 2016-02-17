import "package:nova_poshta_osm_sync/branches_processor.dart";
import "package:nova_poshta_osm_sync/location_processor.dart";

class LocationsSynchronizer {
  BranchesProcessor _branchesProcessor;
  LocationsSynchronizer(this._branchesProcessor);

  sync() {
    this._branchesProcessor.groupedBranches.forEach((groupId, branches) => _syncSingle(groupId, branches));
  }

  _syncSingle(groupId, Map<String, List<Map>> branches) {
    List npmRemove = [];
    List osmRemove = [];
    branches['npms'].forEach((npm) {
      var osmm = _getBranchByNumber(branches['osmms'], npm['tags']['n']);
      if (osmm == null)
        return;
      if (_isNear([npm['lat'], npm['lon']], [osmm['lat'], osmm['lon']])) {
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

  _isNear(List<double> point1, List<double> point2, [num max = 100]) {
    return LocationsProcessor.calculateDistance(point1, point2) <= max;
  }

  _getBranchByNumber(List<Map> branches, String number) {
    return branches.firstWhere((Map branch) {
      if (branch['tags']['n'] == null)
        return false;
      return n == number;
    }, orElse: () => null);
  }
}
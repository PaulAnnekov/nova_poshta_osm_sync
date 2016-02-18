import "package:nova_poshta_osm_sync/branch.dart";
import "package:nova_poshta_osm_sync/lat_lon.dart";
import "package:nova_poshta_osm_sync/branches_processor.dart";
import "package:nova_poshta_osm_sync/location_processor.dart";

class LocationsSynchronizer {
  BranchesProcessor _branchesProcessor;
  List<Map<String, Branch>> _results = [];
  LocationsSynchronizer(this._branchesProcessor);

  List<Map<String, Branch>> sync() {
    this._branchesProcessor.groupedBranches.forEach((groupId, branches) => _syncSingle(branches));
    return _results;
  }

  _syncSingle(Map<String, List<Branch>> branches) {
    _checkNear(branches);
    return _results;
  }

  _isMerged(Branch branch) {
    return _results.any((result) => result['from'] == branch || result['result'] == branch);
  }

  _checkNear(Map<String, List<Branch>> branches) {
    branches['npms'].forEach((npm) {
      if (_isMerged(npm))
        return;
      var osmm = _getBranchByNumber(branches['osmms'], npm.number);
      if (osmm == null)
        return;
      if (_isNear(npm.loc, osmm.loc)) {
        _results.add({
          'result': osmm,
          'from': npm
        });
      }
    });
  }

  _isNear(LatLon point1, LatLon point2, [num max = 100]) {
    return LocationsProcessor.calculateDistance(point1, point2) <= max;
  }

  Branch _getBranchByNumber(List<Branch> branches, int number) {
    var branch = branches.firstWhere((Branch branch) {
      if (branch.number == null)
        return false;
      return branch.number == number;
    }, orElse: () => null);
    return branch;
  }
}
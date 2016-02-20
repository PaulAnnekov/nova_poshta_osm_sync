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
    _mergeSingle(branches);
    _mergeNear(branches);
    _mergeNearDifferentNumbers(branches);
    return _results;
  }

  _isMerged(Branch branch) {
    return _results.any((result) => result['from'] == branch || result['result'] == branch);
  }

  /**
   * Merge an NP single in a city.
   */
  _mergeSingle(Map<String, List<Branch>> branches) {
    branches['npms'].forEach((npm) {
      if (_isMerged(npm) || branches['osmms'].isNotEmpty)
        return;
      _results.add({
        'result': npm,
        'from': npm
      });
    });
  }

  /**
   * Merge an NP and OSM branch with different numbers and a distance of less than 100 meters.
   */
  _mergeNearDifferentNumbers(Map<String, List<Branch>> branches) {
    branches['npms'].forEach((npm) {
      if (_isMerged(npm))
        return;
      for (var osmm in branches['osmms']) {
        if (!_isMerged(osmm) && _isNear(npm.loc, osmm.loc, 100)) {
          _results.add({
            'result': osmm,
            'from': npm
          });
          return;
        }
      }
    });
  }

  /**
   * Merge an NP and OSM branch with the same number and a distance of less than 300 meters.
   */
  _mergeNear(Map<String, List<Branch>> branches) {
    branches['npms'].forEach((npm) {
      if (_isMerged(npm))
        return;
      var osmm = _getBranchByNumber(branches['osmms'], npm.number);
      if (osmm == null)
        return;
      if (_isNear(npm.loc, osmm.loc, 300)) {
        _results.add({
          'result': osmm,
          'from': npm
        });
      }
    });
  }

  _isNear(LatLon point1, LatLon point2, num max) {
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
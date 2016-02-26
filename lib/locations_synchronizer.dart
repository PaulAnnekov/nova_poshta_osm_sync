import "package:nova_poshta_osm_sync/branch.dart";
import "package:nova_poshta_osm_sync/np_branch.dart";
import "package:nova_poshta_osm_sync/lat_lon.dart";
import "package:nova_poshta_osm_sync/branches_processor.dart";
import "package:nova_poshta_osm_sync/location_processor.dart";

class LocationsSynchronizer {
  BranchesProcessor _branchesProcessor;
  LocationsProcessor _locationsProcessor;
  List<Map<String, Branch>> _results = [];
  LocationsSynchronizer(this._branchesProcessor, this._locationsProcessor);

  List<Map<String, Branch>> sync() {
    this._branchesProcessor.groupedBranches.forEach((groupId, branches) => _syncSingle(branches));
    return _results;
  }

  _syncSingle(Map<String, List<Branch>> branches) {
    _mergeSingle(branches);
    _mergeNear(branches);
    _mergeNearDifferentNumbers(branches);
    _mergeNearHouseNumber(branches);
    _mergeNpNoMatch(branches);
    _mergeByRoadAndHouse(branches);
    _mergeByCitySize(branches);
    return _results;
  }

  _isMerged(Branch branch) {
    return _results.any((result) => result['from'] == branch || result['result'] == branch);
  }

  /**
   * Merge an NP and OSM branch with the same number into branch that house_number + road combination more relevant
   * towards NP address.
   */
  _mergeByRoadAndHouse(Map<String, List<Branch>> branches) {
    branches['npms'].forEach((NpBranch npm) {
      if (_isMerged(npm))
        return;
      var osmm = _getBranchByNumber(branches['osmms'], npm.number);
      if (osmm == null || _isMerged(osmm))
        return;
      var npAddress = npm.getAddress();
      if (npAddress == null)
        return;
      var npNomatimAddress = _locationsProcessor.getAddress(npm.loc);
      var osmNomatimAddress = _locationsProcessor.getAddress(osmm.loc);
      if (npNomatimAddress == null || osmNomatimAddress == null)
        return;
      var npRelevancy = _checkRelevancy(npAddress, npNomatimAddress);
      var osmRelevancy = _checkRelevancy(npAddress, osmNomatimAddress);
      if (npRelevancy == 0 && osmRelevancy == 0)
        return;
      _results.add({
        'result': npRelevancy > osmRelevancy ? npm : osmm,
        'from': npRelevancy > osmRelevancy ? osmm : npm
      });
    });
  }

  _checkRelevancy(Map correct, Map guess) {
    return (correct['street'] == guess['street'] ? 1 : 0) + (correct['house'] == guess['house'] ? 1 : 0);
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
   * Merge by city size.
   */
  _mergeByCitySize(Map<String, List<Branch>> branches) {
    branches['npms'].forEach((npm) {
      if (_isMerged(npm))
        return;
      var osmm = _getBranchByNumber(branches['osmms'], npm.number);
      if (osmm == null || _isMerged(osmm))
        return;
      _results.add({
        'result': branches['npms'].length >= 4 ? npm : osmm,
        'from': branches['npms'].length >= 4 ? osmm : npm
      });
    });
  }

  /**
   * Merge an NP with no OSM match.
   */
  _mergeNpNoMatch(Map<String, List<Branch>> branches) {
    branches['npms'].forEach((npm) {
      if (_isMerged(npm))
        return;
      for (var osmm in branches['osmms']) {
        if (!_isMerged(osmm) && osmm.number == npm.number)
          return;
      }
      _results.add({
        'result': npm,
        'from': npm
      });
    });
  }

  /**
   * Merge an NP and OSM branch with the same house number and a distance of less than 300 meters.
   */
  _mergeNearHouseNumber(Map<String, List<Branch>> branches) {
    branches['npms'].forEach((npm) {
      if (_isMerged(npm))
        return;
      for (var osmm in branches['osmms']) {
        var npHouse = _locationsProcessor.getAddress(npm.loc)['house'];
        var osmHouse = _locationsProcessor.getAddress(osmm.loc)['house'];
        if (!_isMerged(osmm) && _isNear(npm.loc, osmm.loc, 300) && npHouse == osmHouse)
        {
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
      if (osmm == null || _isMerged(osmm))
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
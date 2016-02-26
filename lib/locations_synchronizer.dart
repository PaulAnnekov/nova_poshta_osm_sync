import 'dart:mirrors';
import "package:nova_poshta_osm_sync/branch.dart";
import "package:nova_poshta_osm_sync/np_branch.dart";
import "package:nova_poshta_osm_sync/lat_lon.dart";
import "package:nova_poshta_osm_sync/location_name.dart";
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
    _mergeByRoadAndHouse(branches);
    _mergeNearDescription(branches);
    _mergeByCitySize(branches);
    _mergeNpNoMatch(branches);
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
        'from': npRelevancy > osmRelevancy ? osmm : npm,
        'strategy': 'mergeByRoadAndHouse'
      });
    });
  }

  _checkRelevancy(Map correct, Map guess) {
    var relevancy = 0;
    if (correct['house'] == guess['house']) {
      relevancy++;
      if (correct['street'] == guess['street']) {
        relevancy++;
      }
    }
    return relevancy;
  }

  /**
   * Merge an NPs in a city w/o OSMs.
   */
  _mergeSingle(Map<String, List<Branch>> branches) {
    branches['npms'].forEach((npm) {
      if (_isMerged(npm) || branches['osmms'].isNotEmpty)
        return;
      _results.add({
        'result': npm,
        'from': npm,
        'strategy': 'mergeSingle'
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
      var osmm;
      if (branches['npms'].length == 1 && branches['osmms'].length == 1 && branches['osmms'][0].number == null)
        osmm = branches['osmms'][0];
      else
        osmm = _getBranchByNumber(branches['osmms'], npm.number);
      if (osmm == null || _isMerged(osmm))
        return;
      _results.add({
        'result': branches['npms'].length >= 4 ? npm : osmm,
        'from': branches['npms'].length >= 4 ? osmm : npm,
        'strategy': 'mergeByCitySize'
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
        'from': npm,
        'strategy': 'mergeNpNoMatch'
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
      var npHouse = _locationsProcessor.getAddress(npm.loc)['house'];
      if (npHouse == null)
        return;
      for (var osmm in branches['osmms']) {
        var osmHouse = _locationsProcessor.getAddress(osmm.loc)['house'];
        if (!_isMerged(osmm) && _isNear(npm.loc, osmm.loc, 300) && npHouse != null && npHouse == osmHouse)
        {
          _results.add({
            'result': osmm,
            'from': npm,
            'strategy': 'mergeNearHouseNumber'
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
            'from': npm,
            'strategy': 'mergeNearDifferentNumbers'
          });
          return;
        }
      }
    });
  }

  /**
   * Merge an NP and OSM branch with different numbers, a distance of less than 300 meters and if we can find NP
   * house + street in `description` tag of OSM.
   */
  _mergeNearDescription(Map<String, List<Branch>> branches) {
    branches['npms'].forEach((NpBranch npm) {
      if (_isMerged(npm))
        return;
      var npAddress = npm.getAddress();
      if (npAddress == null)
        return;
      for (var osmm in branches['osmms']) {
        if (_isMerged(osmm) || osmm.customTags['description'] == null)
          continue;
        var description = new LocationName(osmm.customTags['description']).toString();
        if (_isNear(npm.loc, osmm.loc, 300) && description.contains(npAddress['house'].toString()) &&
            description.contains(npAddress['street'].toString()))
        {
          _results.add({
            'result': osmm,
            'from': npm,
            'strategy': 'mergeNearDescription'
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
          'from': npm,
          'strategy': 'mergeNear'
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
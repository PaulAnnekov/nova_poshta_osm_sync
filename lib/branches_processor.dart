import "package:nova_poshta_osm_sync/branch.dart";
import "package:nova_poshta_osm_sync/osm_branch.dart";
import "package:nova_poshta_osm_sync/np_branch.dart";

class BranchesProcessor {
  Map<String, Map<String, List<Branch>>> groupedBranches = {};

  _add(String groupId, Branch branch, String group) {
    groupId = groupId.toLowerCase();
    if (!groupedBranches.containsKey(groupId))
      groupedBranches[groupId] = {'osmms': [], 'npms': []};
    groupedBranches[groupId][group].add(branch);
  }

  renameGroup(String oldId, String newId) {
    // newId == oldId - "кримське дзержинськаміськарада донецькаобласть" case
    if (groupedBranches[oldId] == null || newId == oldId)
      return;
    groupedBranches[oldId]['osmms'].forEach((marker) => _add(newId, marker, 'osmms'));
    groupedBranches[oldId]['npms'].forEach((marker) => _add(newId, marker, 'npms'));
    groupedBranches.remove(oldId);
  }

  addOsmm(String groupId, OsmBranch osmm) {
    _add(groupId, osmm, 'osmms');
  }

  addNpm(String groupId, NpBranch npm) {
    _add(groupId, npm, 'npms');
  }

  Map<String, List> getGroup(String groupId) {
    return groupedBranches[groupId] ?? {'osmms': [], 'npms': []};
  }
}
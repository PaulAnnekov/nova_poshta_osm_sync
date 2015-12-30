class BranchesProcessor {
  Map<String, Map<String, List>> groupedBranches = {};

  _add(String groupId, Map marker, String group) {
    groupId = groupId.toLowerCase();
    if (!groupedBranches.containsKey(groupId))
      groupedBranches[groupId] = {'osmms': [], 'npms': []};
    groupedBranches[groupId][group].add(marker);
  }

  addOsmm(String groupId, Map osmm) {
    _add(groupId, osmm, 'osmms');
  }

  addNpm(String groupId, Map osmm) {
    _add(groupId, osmm, 'npms');
  }
}
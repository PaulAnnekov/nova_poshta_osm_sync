class BranchesProcessor {
  Map<String, Map<String, List>> groupedBranches = {};

  _add(String groupId, Map marker, String group) {
    groupId = groupId.toLowerCase();
    if (!groupedBranches.containsKey(groupId))
      groupedBranches[groupId] = {'osmms': [], 'npms': []};
    groupedBranches[groupId][group].add(marker);
  }

  renameGroup(String oldId, String newId) {
    // newId == oldId - "кримське дзержинськаміськарада донецькаобласть" case
    if (groupedBranches[oldId] == null || newId == oldId)
      return;
    groupedBranches[oldId]['osmms'].forEach((marker) => _add(newId, marker, 'osmms'));
    groupedBranches[oldId]['npms'].forEach((marker) => _add(newId, marker, 'npms'));
    groupedBranches.remove(oldId);
  }

  addOsmm(String groupId, Map osmm) {
    _add(groupId, osmm, 'osmms');
  }

  addNpm(String groupId, Map npm) {
    _add(groupId, npm, 'npms');
  }

  Map<String, List> getGroup(String groupId) {
    return groupedBranches[groupId] ?? {'osmms': [], 'npms': []};
  }
}
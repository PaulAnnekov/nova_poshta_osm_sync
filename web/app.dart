import 'dart:html';
import 'dart:convert';
import 'dart:collection';
import 'dart:js' as js;
import 'package:nova_poshta_osm_sync/location_processor.dart';
import 'package:nova_poshta_osm_sync/branches_processor.dart';
import 'package:nova_poshta_osm_sync/map_wrapper.dart';
import 'package:nova_poshta_osm_sync/location_name.dart';
import 'package:logging/logging.dart';

List<Map> npms;
List<Map> osmms;
LocationsProcessor locationsProcessor;
final Logger log = new Logger('main');
final BranchesProcessor branchesProcessor = new BranchesProcessor();

determineOsmmsBranchId() {
  osmms = osmms.map((node) {
    node['tags']['n'] = getOsmmBranchId(node) ?? 'unknown';
    return node;
  }).toList();
}

int getOsmmBranchId(Map osmm) {
  int idFromBranch;
  int idFromName;
  Map<String, String> tags = osmm['tags'];
  RegExp numberRegExp = new RegExp('([0-9]+)');
  RegExp cleanerRegExp = new RegExp('[0-9]+ {0,1}кг');
  if (tags['branch'] != null)
  {
    String branch = tags['branch'].replaceAll(cleanerRegExp, '');
    var matches = numberRegExp.allMatches(branch);
    if (matches.length > 1)
      log.warning("osmm $osmm 'branch' tag contains more then one numbers sequence");
    if (matches.length)
      idFromBranch = int.parse(matches.first.group(0));
  }
  String name = tags['name'].replaceAll(cleanerRegExp, '');
  var matches = numberRegExp.allMatches(name);
  if (matches.length > 1)
    log.warning("osmm $osmm 'name' tag contains more then one numbers sequence");
  if (matches.isNotEmpty)
    idFromName = int.parse(matches.first.group(0));
  if (idFromBranch != null && idFromName != null && idFromName != idFromBranch)
    log.warning("id from 'name' tag is not equal to id from 'branch' tag for $osmm");

  return idFromBranch != null ? idFromBranch : idFromName;
}

LinkedHashMap<String, LocationName> getGroupIdParts(address) {
  String placeTag = LocationsProcessor.NAME_PRIORITY.firstWhere((name) {
    if (address[name] != null)
      return true;
  }, orElse: () => null);
  LinkedHashMap nameParts = new LinkedHashMap();
  nameParts['place'] = placeTag != null ? new LocationName(address[placeTag]) : null;
  if (address['county'] != null && placeTag != 'city')
    nameParts['county'] = new LocationName(address['county']);
  if (address['state'] != null)
    nameParts['state'] = new LocationName(address['state']);
  return nameParts;
}

groupByPlace() {
  osmms.forEach((node) {
    Map address = locationsProcessor.getLocation(node['lat'],
        node['lon'])['address'];
    var groupParts = getGroupIdParts(address);
    if (groupParts['place'] == null) {
      log.info('Can not find place tag for: $node ($address)');
      return;
    }
    branchesProcessor.addOsmm(groupParts.values.join(' '), node);
  });

  npms.forEach((node) {
    Map address = locationsProcessor.getLocation(node['lat'],
        node['lon'])['address'];
    var groupParts = getGroupIdParts(address);
    var isSearch = false;
    var npmCity = new LocationName.fromNP(node['city']);
    if (groupParts['place'] != null && groupParts['place'] != npmCity) {
      log.fine('NP city and Nomatim city differs for: $node ($address)');
      isSearch = true;
    }
    if (groupParts['place'] == null) {
      log.fine('Can not find place tag for: $node ($address)');
      isSearch = true;
    }
    if (isSearch) {
      var location = locationsProcessor.getClosestLocationByPlace(npmCity,
          [node['lat'], node['lon']]);
      // TODO: de-duplicate
      if (location == null) {
        log.fine("Can not find node's city in locations: $node");
        // Nomatim location has bad place name. We rename this place to NP's one. Fixes Лопатин case.
        var oldId = groupParts.values.join(' ');
        groupParts['place'] = npmCity;
        // Don't rename NP locations. They have higher priority. Fixes Требухів and Дударків case.
        if (branchesProcessor.getGroup(oldId)['npms'].isEmpty) {
          var newId = groupParts.values.join(' ');
          branchesProcessor.renameGroup(oldId, newId);
        }
      } else {
        var oldId = groupParts.values.join(' ');
        groupParts = getGroupIdParts(location['address']);
        if (branchesProcessor.getGroup(oldId)['npms'].isEmpty) {
          var newId = groupParts.values.join(' ');
          branchesProcessor.renameGroup(oldId, newId);
        }
      }
    }
    branchesProcessor.addNpm(groupParts.values.join(' '), node);
  });
}

onReady(_) async {
  await window.animationFrame;
  js.context['Leaflet'] = js.context['L'].callMethod('noConflict');

  var response = await HttpRequest.getString('//localhost:8081/npm.json');
  npms = JSON.decode(response);
  response = await HttpRequest.getString('//localhost:8081/osmm.json');
  osmms = JSON.decode(response)['elements'];
  response = await HttpRequest.getString('//localhost:8081/locations_cache.json');
  locationsProcessor = new LocationsProcessor(JSON.decode(response));

  npms = npms.map((branch) {
    branch['tags'] = {
      'n': branch['n'],
      'addr': branch['addr'],
      'city': branch['city'],
    };
    return branch;
  }).toList();

  MapWrapper map = new MapWrapper(locationsProcessor);
  determineOsmmsBranchId();
  groupByPlace();
  map.displayMarkers(osmms, MapWrapper.OSMM_COLOR, 'OSMMs');
  map.displayMarkers(npms, MapWrapper.NPM_COLOR, 'NPMs');
  map.initMap();
  map.displayCities(branchesProcessor);
}

main() async {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });
  // Workaround for https://github.com/dart-lang/sdk/issues/25318#issuecomment-167682786
  var leaflet = new ScriptElement()..src =
      'https://cdnjs.cloudflare.com/ajax/libs/leaflet/0.7.7/leaflet-src.js';
  leaflet.onLoad.listen(onReady);
  document.body.append(leaflet);
}


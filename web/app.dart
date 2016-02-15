import 'dart:html';
import 'dart:convert';
import 'dart:collection';
import 'dart:js' as js;
import 'package:nova_poshta_osm_sync/location_processor.dart';
import 'package:nova_poshta_osm_sync/branches_processor.dart';
import 'package:nova_poshta_osm_sync/map_wrapper.dart';
import 'package:nova_poshta_osm_sync/location_name.dart';
import 'package:nova_poshta_osm_sync/ui_loader.dart';
import 'package:logging/logging.dart';

List<Map> npms;
List<Map> osmms;
LocationsProcessor locationsProcessor;
final Logger log = new Logger('main');
final BranchesProcessor branchesProcessor = new BranchesProcessor();
final UILoader uiLoader = new UILoader(querySelector('#loader'));

determineOsmmsBranchId() {
  osmms = osmms.map((node) {
    node['tags']['n'] = getOsmmBranchId(node) ?? 'unknown';
    return node;
  }).toList();
}

bool NPCityExists(LocationName city) {
  if (city == null)
    return false;
  return npms.any((node) => new LocationName.fromNP(node['city']) == city);
}

int getOsmmBranchId(Map osmm) {
  Map<String, String> tags = osmm['tags'];
  RegExp numberRegExp = new RegExp('([0-9]+)');
  RegExp cleanerRegExp = new RegExp('[0-9]+ {0,1}кг');
  List<int> numbers = [];
  ['branch', 'name', 'ref'].forEach((tag) {
    if (tags[tag] == null)
      return;
    String branch = tags[tag].replaceAll(cleanerRegExp, '');
    var matches = numberRegExp.allMatches(branch);
    if (matches.length > 1)
      log.warning("osmm $osmm '$tag' tag contains more then one numbers sequence");
    if (matches.isNotEmpty)
      numbers.add(int.parse(matches.first.group(0)));
  });
  var isSame = numbers.every((number) {
    return numbers[0] == number;
  });
  if (!isSame)
    log.warning("numbers from tags are not equal for $osmm");
  return numbers.isNotEmpty && isSame ? numbers[0] : null;
}

LinkedHashMap<String, LocationName> getGroupIdParts(Map address, [LocationName preferredCity]) {
  // preferredCity (aka NP city) ignores tags priority. Fixes Ладижин (Вінницька область) case.
  LinkedHashMap<String, LocationName> places = new LinkedHashMap();
  LocationsProcessor.NAME_PRIORITY.forEach((name) {
    if (address[name] != null)
      places[name] = new LocationName(address[name]);
  });
  String placeTag;
  if (preferredCity != null && places.values.contains(preferredCity)) {
    placeTag = places.keys.elementAt(places.values.toList().indexOf(preferredCity));
  } else {
    placeTag = !places.isEmpty ? places.keys.first : null;
  }

  LinkedHashMap nameParts = new LinkedHashMap();
  nameParts['place'] = places[placeTag];
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
    var npmCity = new LocationName.fromNP(node['city']);
    var groupParts = getGroupIdParts(address, npmCity);
    var isSearch = false;
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
      String oldId = groupParts.values.join(' ');
      LocationName oldPlace = groupParts['place'];
      if (location == null) {
        log.fine("Can not find node's city in locations: $node");
        // Nomatim location has bad place name. We rename this place to NP's one. Fixes Лопатин case.
        groupParts['place'] = npmCity;
      } else {
        groupParts = getGroupIdParts(location['address']);
      }
      // Don't rename NP locations. They have higher priority. Fixes Требухів and Дударків/Угринів (Івано-Франківськ)
      // cases.
      if (!NPCityExists(oldPlace)) {
        var newId = groupParts.values.join(' ');
        branchesProcessor.renameGroup(oldId, newId);
      }
    }
    branchesProcessor.addNpm(groupParts.values.join(' '), node);
  });
}

onReady(_) async {
  uiLoader.setState(UIStates.init);
  await window.animationFrame;
  js.context['Leaflet'] = js.context['L'].callMethod('noConflict');

  await uiLoader.setState(UIStates.data);
  var response = await HttpRequest.getString('//localhost:8081/npm.json');
  npms = JSON.decode(response);
  response = await HttpRequest.getString('//localhost:8081/osmm.json');
  osmms = JSON.decode(response)['elements'];
  response = await HttpRequest.getString('//localhost:8081/locations_cache.json');
  locationsProcessor = new LocationsProcessor(JSON.decode(response));

  await uiLoader.setState(UIStates.prepare);
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
  await uiLoader.setState(UIStates.group);
  groupByPlace();
  await uiLoader.setState(UIStates.display);
  map.displayMarkers(osmms, MapWrapper.OSMM_COLOR, 'OSMMs');
  map.displayMarkers(npms, MapWrapper.NPM_COLOR, 'NPMs');
  map.initMap();
  map.displayCities(branchesProcessor);
  uiLoader.setState(UIStates.end);
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


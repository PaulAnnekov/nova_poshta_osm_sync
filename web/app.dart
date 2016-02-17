import 'dart:html';
import 'dart:convert';
import 'dart:collection';
import 'dart:js' as js;
import 'package:nova_poshta_osm_sync/location_processor.dart';
import 'package:nova_poshta_osm_sync/lat_lon.dart';
import 'package:nova_poshta_osm_sync/branches_processor.dart';
import 'package:nova_poshta_osm_sync/locations_synchronizer.dart';
import 'package:nova_poshta_osm_sync/map_wrapper.dart';
import 'package:nova_poshta_osm_sync/location_name.dart';
import 'package:nova_poshta_osm_sync/ui_loader.dart';
import 'package:nova_poshta_osm_sync/osm_branch.dart';
import 'package:nova_poshta_osm_sync/np_branch.dart';
import 'package:logging/logging.dart';

List<NpBranch> npms = [];
List<OsmBranch> osmms = [];
LocationsProcessor locationsProcessor;
final Logger log = new Logger('main');
final BranchesProcessor branchesProcessor = new BranchesProcessor();
final UILoader uiLoader = new UILoader(querySelector('#loader'));

bool NPCityExists(LocationName city) {
  if (city == null)
    return false;
  return npms.any((node) => node.city == city);
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

groupByPlace() async {
  await uiLoader.setState(UIStates.group, 'OSM');
  osmms.forEach((node) {
    Map address = locationsProcessor.getLocation(node.loc)['address'];
    var groupParts = getGroupIdParts(address);
    if (groupParts['place'] == null) {
      log.info('Can not find place tag for: $node ($address)');
      return;
    }
    branchesProcessor.addOsmm(groupParts.values.join(' '), node);
  });
  await uiLoader.setState(UIStates.group, 'NP');
  npms.forEach((node) {
    Map address = locationsProcessor.getLocation(node.loc)['address'];
    var groupParts = getGroupIdParts(address, node.city);
    var isSearch = false;
    if (groupParts['place'] != null && groupParts['place'] != node.city) {
      log.fine('NP city and Nomatim city differs for: $node ($address)');
      isSearch = true;
    }
    if (groupParts['place'] == null) {
      log.fine('Can not find place tag for: $node ($address)');
      isSearch = true;
    }
    if (isSearch) {
      var location = locationsProcessor.getClosestLocationByPlace(node.city, node.loc);
      String oldId = groupParts.values.join(' ');
      LocationName oldPlace = groupParts['place'];
      if (location == null) {
        log.fine("Can not find node's city in locations: $node");
        // Nomatim location has bad place name. We rename this place to NP's one. Fixes Лопатин case.
        groupParts['place'] = node.city;
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
  var jsonNpms = JSON.decode(response);
  response = await HttpRequest.getString('//localhost:8081/osmm.json');
  var jsonOsmms = JSON.decode(response)['elements'];
  response = await HttpRequest.getString('//localhost:8081/locations_cache.json');
  locationsProcessor = new LocationsProcessor(JSON.decode(response));

  await uiLoader.setState(UIStates.prepare);
  jsonNpms.forEach((node) {
    NpBranch branch = new NpBranch(
      new LatLon(node['lat'], node['lon']),
      {'addr': node['addr']},
      new LocationName.fromNP(node['city']),
      node['n']
    );
    npms.add(branch);
  });

  jsonOsmms.forEach((node) {
    OsmBranch branch = new OsmBranch(
        new LatLon(node['lat'], node['lon']),
        node['tags']
    );
    osmms.add(branch);
  });

  MapWrapper map = new MapWrapper(locationsProcessor);
  LocationsSynchronizer locationsSynchronizer = new LocationsSynchronizer(branchesProcessor);
  await uiLoader.setState(UIStates.group);
  await groupByPlace();
  await uiLoader.setState(UIStates.sync);
  locationsSynchronizer.sync();
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


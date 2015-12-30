import 'dart:html';
import 'dart:convert';
import 'dart:collection';
import 'dart:math';
import 'dart:js' as js;
import 'package:nova_poshta_osm_sync/leaflet/leaflet.dart' as L;
import 'package:logging/logging.dart';

L.LeafletMap map;
L.ControlLayers controlLayers;
List<Map> npms;
List<Map> osmms;
LocationsProcessor locationsProcessor;
final Logger log = new Logger('main');
final BranchesProcessor branchesProcessor = new BranchesProcessor();

double degreeToRadian(double value) {
  return value * PI / 180;
}

double calculateDistance(List<double> point1, List<double> point2) {
  var R = 6371000; // metres
  var fi1 = degreeToRadian(point1[0]);
  var fi2 = degreeToRadian(point2[0]);
  var deltaFi = degreeToRadian(point2[0] - point1[0]);
  var deltaL = degreeToRadian(point2[1] - point1[1]);

  var a = sin(deltaFi / 2) * sin(deltaFi / 2) + cos(fi1) * cos(fi2) *
    sin(deltaL / 2) * sin(deltaL / 2);
  var c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return R * c;
}

class LocationsProcessor {
  Map<String, Map> _locations;
  static List NAME_PRIORITY = ['village', 'town', 'city'];

  LocationsProcessor(Map<String, Map> locations) {
    _locations = locations;
  }

  Map getClosestLocationByPlace(String place, List<double> latlon,
      [num maxDistance = 20000]) {
    place = place.toLowerCase();
    Map closestLocation = null;
    double closestDistance = null;
    for (String i in _locations.keys) {
      Map location = _locations[i];
      Map<String, String> address = location['address'];
      bool isMatch = LocationsProcessor.NAME_PRIORITY.firstWhere((name) {
        if (address[name] != null && address[name].toLowerCase() == place)
          return true;
      }, orElse: () => null) != null;
      if (!isMatch)
        continue;
      double distance = calculateDistance([latlon[0], latlon[1]],
          [location['lat'], location['lon']]);
      if (distance > maxDistance)
        continue;
      if (closestDistance == null || distance < closestDistance) {
        closestDistance = distance;
        closestLocation = location;
      }
    }
    return closestLocation;
  }

  getLocation(double lat, double lon) {
    return _locations['$lat $lon'];
  }
}

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

L.LayerGroup displayMarkers(List<Map> nodes, String color, String layerName) {
  L.LayerGroup layerGroup = L.layerGroup();
  nodes.forEach((node) {
    Map address = locationsProcessor.getLocation(node['lat'],
        node['lon'])['address'];
    String text = '<b>lat</b>: ${node['lat']}<br>' +
    '<b>lon</b>: ${node['lon']}<br>';
    node['tags'].forEach((key, value) {
      text += '<b>$key</b>: $value<br>';
    });
    text += '<br>';
    address.forEach((key, value) {
      text += '<b>$key</b>: $value<br>';
    });
    L.CircleMarker marker = L.circleMarker(L.latLng(node['lat'], node['lon']),
        new L.PathOptions(color: color, fillOpacity: '0')).bindPopup(text);
    marker.addTo(layerGroup);
  });
  controlLayers.addOverlay(layerGroup, layerName);
  return layerGroup;
}

LinkedHashMap<String, String> getGroupIdParts(address) {
  String placeTag = LocationsProcessor.NAME_PRIORITY.firstWhere((name) {
    if (address[name] != null)
      return true;
  }, orElse: () => null);
  LinkedHashMap nameParts = new LinkedHashMap();
  if (placeTag != null)
    nameParts['place'] = address[placeTag];
  if (address['county'] != null && placeTag != 'city')
    nameParts['county'] = address['county'];
  if (address['state'] != null)
    nameParts['state'] = address['state'];
  return nameParts;
}

String getNPMCity(String city) {
  var cityParts = city.split('(');
  return cityParts[0].trim();
}

List<L.Polygon> getCitiesPolygon(List nodes, String groupId, String color) {
  if (nodes.isEmpty)
    return [];
  List<L.Polygon> markers = [];
  double minLat = 100.0, maxLat = -1.0, minLon = 100.0, maxLon = -1.0;
  nodes.forEach((Map node) {
    if (node['lat'] < minLat)
      minLat = node['lat'];
    if (node['lat'] > maxLat)
      maxLat = node['lat'];
    if (node['lon'] < minLon)
      minLon = node['lon'];
    if (node['lon'] > maxLon)
      maxLon = node['lon'];
  });
  L.Polygon marker = L.polygon([L.latLng(maxLat, minLon),
    L.latLng(minLat, minLon), L.latLng(minLat, maxLon),
    L.latLng(maxLat, maxLon)], new L.PathOptions(color: color))
    .bindPopup(groupId);
  markers.add(marker);

  return markers;
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
    var npmCity = getNPMCity(node['city']);
    if (groupParts['place'] != null &&
        groupParts['place'].toLowerCase() != npmCity.toLowerCase()) {
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
      if (location == null)
        log.fine("Can not find node's city in locations: $node");
      else
        groupParts = getGroupIdParts(location['address']);
    }
    branchesProcessor.addNpm(groupParts.values.join(' '), node);
  });

  L.LayerGroup osmmGroup = L.layerGroup();
  L.LayerGroup npmGroup = L.layerGroup();
  L.LayerGroup unitedGroup = L.layerGroup();
  branchesProcessor.groupedBranches.forEach((id, Map nodes) {
    getCitiesPolygon(nodes['osmms'], id, 'blue').forEach((marker)
    => marker.addTo(osmmGroup));
    getCitiesPolygon(nodes['npms'], id, 'red').forEach((marker)
    => marker.addTo(npmGroup));
    getCitiesPolygon(nodes['osmms']..addAll(nodes['npms']), id, 'green')
        .forEach((marker) => marker.addTo(unitedGroup));
  });
  controlLayers.addOverlay(osmmGroup, 'OSM cities');
  controlLayers.addOverlay(npmGroup, 'NP cities');
  controlLayers.addOverlay(unitedGroup, 'United cities');
}

onReady(_) async {
  await window.animationFrame;
  js.context['Leaflet'] = js.context['L'].callMethod('noConflict');

  controlLayers = L.controlLayers(null, null,
      new L.ControlLayersOptions(collapsed: false));
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

  determineOsmmsBranchId();
  L.LayerGroup osmmsGroup = displayMarkers(osmms, 'blue', 'OSMMs');
  L.LayerGroup npmsGroup = displayMarkers(npms, 'red', 'NPMs');
  groupByPlace();

  map = L.map('map', new L.MapOptions(
      layers: [new L.TileLayer('http://{s}.tile.osm.org/{z}/{x}/{y}.png'),
      osmmsGroup, npmsGroup],
      center: L.latLng(48.45, 31.5),
      zoom: 7
  ));
  controlLayers.addTo(map);
}

main() async {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });
  // Workaround for https://github.com/dart-lang/sdk/issues/25318#issuecomment-167682786
  var leaflet = new ScriptElement()..src =
      'http://cdn.leafletjs.com/leaflet/v0.7.7/leaflet.js';
  leaflet.onLoad.listen(onReady);
  document.body.append(leaflet);
}


import 'dart:html';
import 'dart:convert';
import 'package:leaflet/leaflet.dart';
import 'package:logging/logging.dart';

LeafletMap map;
List<Map> npms;
List<Map> osmms;
Map<String, Map> locations;
final Logger log = new Logger('main');
final BranchesProcessor branchesProcessor = new BranchesProcessor();

class BranchesProcessor {
  Map groupedBranches = {};

  _add(String groupId, Map marker, String group) {
    if (!groupedBranches.containsKey(groupId))
      groupedBranches[groupId] = {'osmms': [], 'npms': []};
    groupedBranches[groupId][group].add(osmms);
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
    node['tags']['n'] = getOsmmBranchId(node);
    return node;
  }).toList();
}

int getOsmmBranchId(Map osmm) {
  int idFromBranch;
  int idFromName;
  Map<String, String> tags = osmm['tags'];
  if (tags['branch'] != null)
  {
    var matches = tags['branch'].allMatches(r'[0-9]+');
    if (matches.length > 1)
      log.warning("osmm $osmm 'branch' tag contains more then one numbers sequence");
    if (matches.length)
      idFromBranch = int.parse(matches.first.toString());
  }
  var matches = tags['name'].allMatches(r'[0-9]+');
  if (matches.length > 1)
    log.warning("osmm $osmm 'name' tag contains more then one numbers sequence");
  if (matches.length)
    idFromName = int.parse(matches.first.toString());
  if (idFromBranch != null && idFromName != null && idFromName != idFromBranch)
    log.warning("id from 'name' tag is not equal to id from 'branch' tag for $osmm");

  return idFromBranch != null ? idFromBranch : idFromName;
}

displayMarkers(List<Map> nodes, String color) {
  var markers = new FeatureGroup();
  nodes.forEach((node) {
    Map address = getLocation(node['lat'], node['lon'])['address'];
    String text = '<b>lat</b>: ${node['lat']}<br>' +
    '<b>lon</b>: ${node['lon']}<br>';
    node['tags'].forEach((key, value) {
      text += '<b>$key</b>: $value<br>';
    });
    text += '<br>';
    address.forEach((key, value) {
      text += '<b>$key</b>: $value<br>';
    });
    CircleMarker marker = new CircleMarker(new LatLng(node['lat'], node['lon']), color: color, fillOpacity: '0')
      ..bindPopup(text);
    markers.addLayer(marker);
  });
  map.addLayer(markers);
}

String getPlaceId(address) {
  List namePriority = ['village', 'town', 'city'];
  String placeTag = namePriority.firstWhere((name) {
    if (address[name] != null)
      return true;
  }, orElse: () => null);
  if (placeTag == null) {
    return null;
  }
  List nameParts = [address[placeTag]];
  if (address['county'] != null && placeTag != 'city')
    nameParts.add(address['county']);
  if (address['state'] != null)
    nameParts.add(address['state']);
  return nameParts.join(' ');
}

groupByPlace() {
  osmms.forEach((node) {
    Map address = getLocation(node['lat'], node['lon'])['address'];
    String groupName = getPlaceId(address);
    if (groupName == null) {
      log.info('Can not find place tag for: $node ($address)');
      return;
    }
    branchesProcessor.addOsmm(groupName, node);
  });

  /*var markers = new FeatureGroup();
  groups.forEach((id, List<Map> nodes) {
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
    Polygon marker = new Polygon([new LatLng(maxLat, minLon), new LatLng(minLat, minLon), new LatLng(minLat, maxLon),
      new LatLng(maxLat, maxLon)])..bindPopup(id);
    markers.addLayer(marker);
  });
  map.addLayer(markers);*/
}

getLocation(double lat, double lon) {
  return locations['$lat $lon'];
}

main() async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });
  map = new LeafletMap.selector('map',
  new MapOptions()
    ..layers = [new TileLayer(url: 'http://{s}.tile.osm.org/{z}/{x}/{y}.png')]
    )
    ..setView(new LatLng(48.45, 31.5), 7);

  var response = await HttpRequest.getString('//localhost:8081/npm.json');
  npms = JSON.decode(response);
  response = await HttpRequest.getString('//localhost:8081/osmm.json');
  osmms = JSON.decode(response)['elements'];
  response = await HttpRequest.getString('//localhost:8081/locations_cache.json');
  locations = JSON.decode(response);

  npms = npms.map((branch) {
    branch['tags'] = {
      'n': branch['n'],
      'addr': branch['addr'],
      'city': branch['city'],
    };
    return branch;
  }).toList();

  determineOsmmsBranchId();
  displayMarkers(osmms, 'blue');
  displayMarkers(npms, 'red');
  groupByPlace();
}


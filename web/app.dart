import 'dart:html';
import 'dart:convert';
import 'package:leaflet/leaflet.dart';
import 'package:logging/logging.dart';

LeafletMap map;
List<Map> npm;
List<Map> osmm;
Map<String, Map> locations;
final Logger log = new Logger('main');

displayOsmms() {
  var markers = new FeatureGroup();
  osmm.forEach((place) {
    Map address = getLocation(place['lat'], place['lon'])['address'];
    String text = '<b>lat</b>: ${place['lat']}<br>' +
    '<b>lon</b>: ${place['lon']}<br>';
    place['tags'].forEach((key, value) {
      text += '<b>' + key + '</b>: ' + value + '<br>';
    });
    text += '<br>';
    address.forEach((key, value) {
      text += '<b>' + key + '</b>: ' + value + '<br>';
    });
    CircleMarker marker = new CircleMarker(new LatLng(place['lat'], place['lon']), color: 'blue', fillOpacity: '0')
      ..bindPopup(text);
    markers.addLayer(marker);
  });
  map.addLayer(markers);
}

displayNpms() {
  var markers = new FeatureGroup();
  npm.forEach((branch) {
    double lat = double.parse(branch['y']), lon = double.parse(branch['x']);
    Map address = getLocation(lat, lon)['address'];
    String text = '<b>lat</b>: ' + branch['y'] + '<br>' +
    '<b>lon</b>: ' + branch['x'] + '<br>' +
    '<b># </b>: ' + branch['n'] + '<br>' +
    '<b>addr</b>: ' + branch['addr'] + '<br>' +
    '<b>city</b>: ' + branch['city'] + '<br>';
    text += '<br>';
    address.forEach((key, value) {
      text += '<b>' + key + '</b>: ' + value + '<br>';
    });
    CircleMarker marker = new CircleMarker(new LatLng(branch['y'], branch['x']), color: 'red', fillOpacity: '0')
      ..bindPopup(text);
    markers.addLayer(marker);
  });
  map.addLayer(markers);
}

groupByPlace() {
  List namePriority = ['village', 'town', 'city'];
  Map groups = {};
  osmm.forEach((node) {
    Map address = getLocation(node['lat'], node['lon'])['address'];
    String placeTag = namePriority.firstWhere((name) {
      if (address[name] != null)
        return true;
    }, orElse: () => null);
    if (placeTag == null) {
      log.info('Can not find place tag for: $node ($address)');
      return;
    }
    List nameParts = [address[placeTag]];
    if (address['county'] != null && placeTag != 'city')
      nameParts.add(address['county']);
    if (address['state'] != null)
      nameParts.add(address['state']);
    String groupName = nameParts.join(' ');
    if (!groups.containsKey(groupName))
      groups[groupName] = [];
    groups[groupName].add(node);
  });

  var markers = new FeatureGroup();
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
  map.addLayer(markers);
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
  npm = JSON.decode(response);
  response = await HttpRequest.getString('//localhost:8081/osmm.json');
  osmm = JSON.decode(response)['elements'];
  response = await HttpRequest.getString('//localhost:8081/locations_cache.json');
  locations = JSON.decode(response);

  displayOsmms();
  displayNpms();
  groupByPlace();
}


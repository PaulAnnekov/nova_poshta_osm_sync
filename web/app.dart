import 'dart:html';
import 'dart:convert';
import 'package:leaflet/leaflet.dart';

main() async {
  var map = new LeafletMap.selector('map',
  new MapOptions()
    ..layers = [new TileLayer(url: 'http://{s}.tile.osm.org/{z}/{x}/{y}.png')]
    )
    ..setView(new LatLng(48.45, 31.5), 7);

  var response = await HttpRequest.getString('//localhost:8081/npm.json');
  List<Map> npm = JSON.decode(response);
  response = await HttpRequest.getString('//localhost:8081/osmm.json');
  List<Map> osmm = JSON.decode(response)['elements'];
  response = await HttpRequest.getString('//localhost:8081/locations_cache.json');
  Map<String, Map> locations = JSON.decode(response);

  var markers = new FeatureGroup();
  osmm.forEach((place) {
    Map address = locations['${place['lat']} ${place['lon']}']['address'];
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

  markers = new FeatureGroup();
  npm.forEach((branch) {
    double lat = double.parse(branch['y']), lon = double.parse(branch['x']);
    Map address = locations['$lat $lon']['address'];
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


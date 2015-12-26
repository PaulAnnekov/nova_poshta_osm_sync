#!/usr/bin/env dart

import 'dart:async';
import 'dart:core';
import 'dart:io';
import 'dart:convert';
import 'package:logging/logging.dart';

final Logger log = new Logger('main');
final Uri root = Platform.script.resolve('..');
LocationsCache locationsCache;

class LocationsCache {
  Map locations;
  File file;

  LocationsCache() {
    file = new File.fromUri(root.resolve('locations_cache.json'));
    if (!file.existsSync())
      file.writeAsStringSync('{}', flush: true);
    String data = file.readAsStringSync();
    locations = JSON.decode(data);
  }

  isExists(double lat, double lon) {
    return locations.containsKey('$lat $lon');
  }

  get() {
    return locations;
  }

  add(List<double> position, Map location) {
    this.locations[position[0].toString() + ' ' + position[1].toString()]
      = location;
    file.writeAsString(JSON.encode(this.locations), flush: true);
  }
}

main() async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });
  locationsCache = new LocationsCache();
  Map data = JSON.decode(new File.fromUri(root.resolve('data.json')).readAsStringSync());
  List nodes = data['elements'];
  int total = nodes.length;
  log.info('Total nodes: $total');
  List<List<double>> positions = [];
  nodes.forEach((node) {
    if (!locationsCache.isExists(node['lat'], node['lon']))
      positions.add([node['lat'], node['lon']]);
  });
  log.info('Already cached locations: ${nodes.length - positions.length}');
  while (positions.length > 0) {
    var position = positions.first.toList();
    await getNodes(position).then((Map location) {
      positions.removeAt(0);
      log.info('${positions.length} locations left');
      locationsCache.add(position, location);
      /*Map filtered = {};
      locations.forEach((Map location) {
        int id = int.parse(location['osm_id']);
        location['address'].remove('country');
        location['address'].remove('country_code');
        filtered[id] = location['address'];
        filtered[id]['lat'] = location['lat'];
        filtered[id]['lon'] = location['lon'];
      });*/

    });
  }
}

Future<Map> getNodes(List<double> position) async {
  HttpClient client = new HttpClient();
  Uri url = new Uri.http('nominatim.openstreetmap.org', '/reverse', {
    'format': 'json',
    'lat': position[0].toString(),
    'lon': position[1].toString(),
    'zoom': '18',
    'email': 'paul.annekov@gmail.com',
    'accept-language': 'uk'
  });
  var request = await client.getUrl(url);
  var response = await request.close();
  var locations = await response.transform(UTF8.decoder).join();
  return JSON.decode(locations);
}
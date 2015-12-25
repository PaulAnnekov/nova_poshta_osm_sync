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

  isExists(int locationId) {
    return locations.containsKey(locationId.toString());
  }

  get() {
    return locations;
  }

  add(Map locations) {
    this.locations.addAll(locations);
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
  List<int> ids = [];
  nodes.forEach((node) {
    if (!locationsCache.isExists(node['id']))
      ids.add(node['id']);
  });
  log.info('Already cached locations: ${nodes.length - ids.length}');
  while (ids.length > 0) {
    await getNodes(ids.take(50).toList()).then((List locations) {
      Map toAdd = {};
      locations.forEach((Map location) {
        toAdd[location['osm_id']] = location;
        ids.remove(int.parse(location['osm_id']));
      });
      log.info('${ids.length} locations left');
      locationsCache.add(toAdd);
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

Future<List> getNodes(List<int> ids) async {
  String osmIds = ids.map((id) => 'N' + id.toString()).join(',');
  HttpClient client = new HttpClient();
  Uri url = new Uri.http('nominatim.openstreetmap.org', '/lookup', {
    'format': 'json',
    'osm_ids': osmIds,
    'email': 'paul.annekov@gmail.com',
    'accept-language': 'uk'
  });
  var request = await client.getUrl(url);
  var response = await request.close();
  var locations = await response.transform(UTF8.decoder).join();
  return JSON.decode(locations);
}
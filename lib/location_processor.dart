import 'dart:math';
import 'package:nova_poshta_osm_sync/location_name.dart';
import 'package:nova_poshta_osm_sync/lat_lon.dart';
import 'package:logging/logging.dart';

final Logger log = new Logger('location_processor');

class LocationsProcessor {
  Map<String, Map> _locations;
  static List NAME_PRIORITY = ['village', 'town', 'city'];

  LocationsProcessor(Map<String, Map> locations) {
    _locations = {};
    locations.forEach((id, data) {
      data['loc'] = new LatLon(data['lat'], data['lon']);
      _locations[id] = data;
    });
  }

  Map getClosestLocationByPlace(LocationName place, LatLon from, [num maxDistance = 20000]) {
    Map closestLocation = null;
    double closestDistance = null;
    for (String i in _locations.keys) {
      Map location = _locations[i];
      Map<String, String> address = location['address'];
      bool isMatch = LocationsProcessor.NAME_PRIORITY.firstWhere((name) {
        if (address[name] != null && new LocationName(address[name]) == place)
          return true;
      }, orElse: () => null) != null;
      if (!isMatch)
        continue;
      double distance = calculateDistance(from, location['loc']);
      if (distance > maxDistance)
        continue;
      if (closestDistance == null || distance < closestDistance) {
        closestDistance = distance;
        closestLocation = location;
      }
    }
    return closestLocation;
  }

  getLocation(LatLon latLon) {
    return _locations[latLon.toId()];
  }

  getAddress(LatLon latLon) {
    var location = _locations[latLon.toId()];
    var street = location['address']['road'];
    if (street == null)
      return null;
    var match = new RegExp(r'((.+) |(.+))').firstMatch(street);
    if (match == null) {
      log.shout("Can't get street for location: $location");
      return null;
    }
    return {"street": match.group(1), "house": location['address']['house_number']};
  }

  /**
   * Calculates distance between two geographical coordinates in metres.
   */
  static double calculateDistance(LatLon point1, LatLon point2) {
    var R = 6371000; // metres
    var fi1 = _degreeToRadian(point1.lat);
    var fi2 = _degreeToRadian(point2.lat);
    var deltaFi = _degreeToRadian(point2.lat - point1.lat);
    var deltaL = _degreeToRadian(point2.lon - point1.lon);

    var a = sin(deltaFi / 2) * sin(deltaFi / 2) + cos(fi1) * cos(fi2) *
        sin(deltaL / 2) * sin(deltaL / 2);
    var c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
  }

  static double _degreeToRadian(double value) {
    return value * PI / 180;
  }
}
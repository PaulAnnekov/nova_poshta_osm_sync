import 'dart:math';

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
      double distance = _calculateDistance([latlon[0], latlon[1]],
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

  double _calculateDistance(List<double> point1, List<double> point2) {
    var R = 6371000; // metres
    var fi1 = _degreeToRadian(point1[0]);
    var fi2 = _degreeToRadian(point2[0]);
    var deltaFi = _degreeToRadian(point2[0] - point1[0]);
    var deltaL = _degreeToRadian(point2[1] - point1[1]);

    var a = sin(deltaFi / 2) * sin(deltaFi / 2) + cos(fi1) * cos(fi2) *
        sin(deltaL / 2) * sin(deltaL / 2);
    var c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
  }

  double _degreeToRadian(double value) {
    return value * PI / 180;
  }
}
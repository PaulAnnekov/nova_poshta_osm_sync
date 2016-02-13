import 'package:nova_poshta_osm_sync/leaflet/leaflet.dart' as L;
import 'package:nova_poshta_osm_sync/branches_processor.dart';
import 'package:nova_poshta_osm_sync/location_processor.dart';

class MapWrapper {
  L.Map map;
  L.ControlLayers controlLayers;
  List<L.ILayer> layerGroups = [];
  LocationsProcessor _locationsProcessor;

  MapWrapper(LocationsProcessor locationsProcessor) {
    _locationsProcessor = locationsProcessor;
    controlLayers = L.controlLayers(null, null,
        new L.ControlLayersOptions(collapsed: false));
    layerGroups.add(
        L.tileLayer('http://{s}.tile.osm.org/{z}/{x}/{y}.png'));
  }

  initMap() {
    map = L.map('map', new L.MapOptions(
        layers: layerGroups,
        center: L.latLng(48.45, 31.5),
        zoom: 7
    ));
    controlLayers.addTo(map);
  }

  displayMarkers(List<Map> nodes, String color, String layerName) {
    L.LayerGroup layerGroup = L.layerGroup();
    nodes.forEach((node) {
      Map address = _locationsProcessor.getLocation(node['lat'],
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
          new L.PathOptions(color: color, fillOpacity: 0)).bindPopup(text);
      marker.addTo(layerGroup);
    });
    controlLayers.addOverlay(layerGroup, '<span style="color: $color">$layerName</span>');
    layerGroups.add(layerGroup);
  }

  displayCities(BranchesProcessor branchesProcessor) {
    L.LayerGroup osmmGroup = L.layerGroup();
    L.LayerGroup npmGroup = L.layerGroup();
    L.LayerGroup unitedGroup = L.layerGroup();
    branchesProcessor.groupedBranches.forEach((id, Map nodes) {
      _getCitiesPolygon(nodes['osmms'], id, 'blue').forEach((marker)
      => marker.addTo(osmmGroup));
      _getCitiesPolygon(nodes['npms'], id, 'red').forEach((marker)
      => marker.addTo(npmGroup));
      _getCitiesPolygon(new List.from(nodes['osmms'])..addAll(nodes['npms']),
          id, 'green').forEach((marker) => marker.addTo(unitedGroup));
    });
    controlLayers.addOverlay(osmmGroup, 'OSM cities');
    controlLayers.addOverlay(npmGroup, 'NP cities');
    controlLayers.addOverlay(unitedGroup, 'United cities');
  }

  List<L.Path> _getCitiesPolygon(List nodes, String groupId, String color) {
    if (nodes.isEmpty)
      return [];
    List<L.Path> markers = [];
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
    L.Path marker;
    // If single branch in city - draw dot, not polygon. Polygon won't be rendered.
    if (minLat == maxLat && minLon == maxLon) {
      marker = L.circleMarker(L.latLng(minLat, maxLon),
          new L.CircleMarkerPathOptions(color: color, fillOpacity: 1, radius: 2)).bindPopup(groupId);
    } else {
      marker = L.polygon([L.latLng(maxLat, minLon),
      L.latLng(minLat, minLon), L.latLng(minLat, maxLon),
      L.latLng(maxLat, maxLon)], new L.PathOptions(color: color))
          .bindPopup(groupId);
      // TODO: fails in Chrome https://github.com/dart-lang/sdk/issues/25777
      marker.on('dblclick', (event) {
        marker.bringToBack();
      });
    }
    markers.add(marker);

    return markers;
  }
}
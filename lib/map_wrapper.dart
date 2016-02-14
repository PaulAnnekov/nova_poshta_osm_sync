import 'package:nova_poshta_osm_sync/leaflet/leaflet.dart' as L;
import 'package:nova_poshta_osm_sync/turf/turf.dart' as turf;
import 'package:nova_poshta_osm_sync/branches_processor.dart';
import 'package:nova_poshta_osm_sync/location_processor.dart';

class MapWrapper {
  L.Map map;
  L.ControlLayers controlLayers;
  List<L.ILayer> layerGroups = [];
  LocationsProcessor _locationsProcessor;
  static String NPM_COLOR = 'red';
  static String OSMM_COLOR = 'blue';
  static String JOIN_COLOR = 'green';

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
    controlLayers.addOverlay(osmmGroup, '<span style="color: $OSMM_COLOR">OSM cities</span>');
    controlLayers.addOverlay(npmGroup, '<span style="color: $NPM_COLOR">NP cities</span>');
    controlLayers.addOverlay(unitedGroup, '<span style="color: $JOIN_COLOR">United cities</span>');
  }

  bool _isPolygon(List<Map> nodes) {
    var temp = [];
    nodes.forEach((node) {
      var isExist = temp.firstWhere((tempNode) => tempNode['lat'] == node['lat'] && tempNode['lon'] == node['lon'],
          orElse: () => null);
      if (isExist == null)
        temp.add(node);
    });
    return temp.length > 2;
  }

  List<L.Path> _getCitiesPolygon(List<Map> nodes, String groupId, String color) {
    if (nodes.isEmpty)
      return [];
    List<L.Path> markers = [];
    L.Path marker;
    // If single branch in city - draw dot, not polygon. Polygon won't be rendered.
    if (!_isPolygon(nodes)) {
      // Hack to make leaflet draw polyline for single point too.
      nodes.add(nodes[0]);
      List<L.LatLng> points = [];
      nodes.forEach((Map node) => points.add(L.latLng(node['lat'], node['lon'])));
      marker = L.polyline(points, new L.PathOptions(color: color)).bindPopup(groupId);
    } else {
      List<turf.FeatureOptions> points = [];
      nodes.forEach((Map node) {
        points.add(new turf.FeatureOptions(
          type: "Feature",
          geometry: new turf.GeometryOptions(type: "Point", coordinates: [node['lat'], node['lon']])
        ));
      });
      List<List<num>> polygonPoints = turf.convex(new turf.ConvexOptions(type: "FeatureCollection", features: points))
          .geometry.coordinates.first;
      List<L.LatLng> leafletPolygon = [];
      polygonPoints.forEach((point) => leafletPolygon.add(L.latLng(point[0], point[1])));
      marker = L.polygon(leafletPolygon, new L.PathOptions(color: color)).bindPopup(groupId);
      // TODO: fails in Chrome https://github.com/dart-lang/sdk/issues/25777
      marker.on('dblclick', (event) {
        marker.bringToBack();
      });
    }
    markers.add(marker);

    return markers;
  }
}
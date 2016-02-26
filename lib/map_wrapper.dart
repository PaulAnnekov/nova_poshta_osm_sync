import 'package:nova_poshta_osm_sync/leaflet/leaflet.dart' as L;
import 'package:nova_poshta_osm_sync/turf/turf.dart' as turf;
import 'package:nova_poshta_osm_sync/branches_processor.dart';
import 'package:nova_poshta_osm_sync/branch.dart';
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

  displayMarkers(List<Branch> nodes, String color, String layerName) {
    L.LayerGroup layerGroup = L.layerGroup();
    nodes.forEach((node) {
      Map address = _locationsProcessor.getLocation(node.loc)['address'];
      String text = '<b>loc</b>: ${node.loc}<br>';
      node.customTags.forEach((key, value) {
        text += '<b>$key</b>: $value<br>';
      });
      text += '<br>';
      address.forEach((key, value) {
        text += '<b>$key</b>: $value<br>';
      });
      // Very sloooow, because uses div, but circleMarker does not support inner text.
      L.Marker marker = L.marker(node.loc.toLeaflet(), new L.MarkerOptions(icon: L.divIcon(
          new L.DivIconOptions(html: node.number ?? 'u', className: color, iconSize: L.point(25, 25)))))
          .bindPopup(text);
      marker.addTo(layerGroup);
    });
    controlLayers.addOverlay(layerGroup, '<span style="color: $color">$layerName (${nodes.length})</span>');
    layerGroups.add(layerGroup);
  }

  displayResults(List<Map<String, dynamic>> results) {
    L.LayerGroup layerGroup = L.layerGroup();
    results.forEach((result) {
      var polyline = L.polyline([result['from'].loc.toLeaflet(), result['result'].loc.toLeaflet()],
          new L.PathOptions(color: 'green')).bindPopup(result['strategy']);
      polyline.addTo(layerGroup);
      if (result['from'] == result['result'])
        return;
      var polylineDecorator = L.polylineDecorator(polyline, new L.PolylineDecoratorOptions(patterns:
        [new L.Pattern(repeat: 0, offset: '100%', symbol: L.arrowHead(new L.SymbolArrowHeadOptions(pixelSize: 15,
        pathOptions: new L.PathOptions(color: 'green', fillOpacity: 0.5), polygon: false)))]));
      polylineDecorator.addTo(layerGroup);
    });
    controlLayers.addOverlay(layerGroup, '<span style="color: green">Merges (${results.length})</span>');
    layerGroups.add(layerGroup);
  }

  displayUnmerged(BranchesProcessor branchesProcessor, List<Map<String, Branch>> results) {
    List<Branch> unmergedOsm = [];
    List<Branch> unmergedNp = [];
    branchesProcessor.groupedBranches.forEach((groupId, branches) {
      branches['osmms'].forEach((branch) {
        for (var merge in results) {
          if (merge['from'] == branch || merge['result'] == branch)
            return;
        }
        unmergedOsm.add(branch);
      });
      branches['npms'].forEach((branch) {
        for (var merge in results) {
          if (merge['from'] == branch || merge['result'] == branch)
            return;
        }
        unmergedNp.add(branch);
      });
    });
    displayMarkers(unmergedOsm, 'blue', 'Unmerged OSM');
    displayMarkers(unmergedNp, 'red', 'Unmerged NP');
  }

  displayCities(BranchesProcessor branchesProcessor) {
    L.LayerGroup osmmGroup = L.layerGroup();
    L.LayerGroup npmGroup = L.layerGroup();
    L.LayerGroup unitedGroup = L.layerGroup();
    int osmCities = 0, npCities = 0, unitedCities = 0;
    branchesProcessor.groupedBranches.forEach((id, Map nodes) {
      osmCities += nodes['osmms'].isNotEmpty ? 1 : 0;
      npCities += nodes['npms'].isNotEmpty ? 1 : 0;
      unitedCities += nodes['osmms'].isNotEmpty || nodes['npms'].isNotEmpty ? 1 : 0;
      _getCitiesPolygon(nodes['osmms'], id, 'blue').forEach((marker)
      => marker.addTo(osmmGroup));
      _getCitiesPolygon(nodes['npms'], id, 'red').forEach((marker)
      => marker.addTo(npmGroup));
      _getCitiesPolygon(new List.from(nodes['osmms'])..addAll(nodes['npms']),
          id, 'green').forEach((marker) => marker.addTo(unitedGroup));
    });
    controlLayers.addOverlay(osmmGroup, '<span style="color: $OSMM_COLOR">OSM cities ($osmCities)</span>');
    controlLayers.addOverlay(npmGroup, '<span style="color: $NPM_COLOR">NP cities ($npCities)</span>');
    controlLayers.addOverlay(unitedGroup, '<span style="color: $JOIN_COLOR">United cities ($unitedCities)</span>');
  }

  bool _isPolygon(List<Branch> nodes) {
    List<Branch> temp = [];
    nodes.forEach((node) {
      var isExist = temp.firstWhere((tempNode) => tempNode.loc == node.loc, orElse: () => null);
      if (isExist == null)
        temp.add(node);
    });
    return temp.length > 2;
  }

  List<L.Path> _getCitiesPolygon(List<Branch> nodes, String groupId, String color) {
    if (nodes.isEmpty)
      return [];
    List<L.Path> markers = [];
    L.Path marker;
    // If single branch in city - draw dot, not polygon. Polygon won't be rendered.
    if (!_isPolygon(nodes)) {
      // Hack to make leaflet draw polyline for single point too.
      nodes.add(nodes[0]);
      List<L.LatLng> points = [];
      nodes.forEach((node) => points.add(node.loc.toLeaflet()));
      marker = L.polyline(points, new L.PathOptions(color: color)).bindPopup(groupId);
    } else {
      List<turf.FeatureOptions> points = [];
      nodes.forEach((node) {
        points.add(new turf.FeatureOptions(
          type: "Feature",
          geometry: new turf.GeometryOptions(type: "Point", coordinates: node.loc.toList())
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
library L;

import 'package:js/js.dart';

@anonymous
@JS()
class TileLayer {
  external factory TileLayer();
}

@anonymous
@JS()
class LatLng {
  external factory LatLng(
      {double lat,
      double lng
      });
  external double get lat;
  external set lat(double v);
  external double get lng;
  external set lng(double v);
}

@anonymous
@JS()
class MapOptions {
  external factory MapOptions(
      {List<TileLayer> layers,
      LatLng center,
      int zoom
      });
  external List<TileLayer> get layers;
  external set layers(List<TileLayer> v);
  external LatLng get center;
  external set center(LatLng v);
  external int get zoom;
  external set zoom(int v);
}

@anonymous
@JS()
class PathOptions {
  external factory PathOptions(
      {String color,
      String fillOpacity});
  external String get color;
  external set color(String v);
  external String get fillOpacity;
  external set fillOpacity(String v);
}

@anonymous
@JS()
class LayerGroup {}

@JS()
@anonymous
class LeafletMap {
  external factory LeafletMap();
  external setView(LatLng center, int zoom);
}

@anonymous
@JS()
class CircleMarker {
  external factory CircleMarker();
  external CircleMarker addTo(LayerGroup layerGroup);
  external CircleMarker bindPopup(String text);
}

@JS('L.map')
external LeafletMap map(String id, [MapOptions options]);

@JS('L.layerGroup')
external LayerGroup layerGroup();

@JS('L.circleMarker')
external CircleMarker circleMarker(LatLng latlng, PathOptions options);

@JS()
class control {
  external addLayer(String id, Map options);
  external bindPopup(String text, Map options);
}

@JS('L.control.layers')
external Layers layers(Map<String, TileLayer> baseLayers, [Map<String, LayerGroup> overlays]);

@anonymous
@JS()
class Layers {
  external factory Layers();
  external addTo(LeafletMap map);
}

@JS('L.latLng')
external LatLng latLng(double lat, double lng);

@JS('L.tileLayer')
external TileLayer tileLayer(String urlTemplate);


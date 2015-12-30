// Workaround for using 'L'
// https://github.com/dart-lang/sdk/issues/25318#issuecomment-167616022
@JS('Leaflet')
library L;

import 'package:js/js.dart';

@JS('tileLayer')
class TileLayer implements ILayer {
  external factory TileLayer(String urlTemplate);
}

@anonymous
@JS()
class ILayer {}

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
class LayerGroup implements ILayer {
  external factory LayerGroup();
  external LayerGroup addLayer(Polygon polygon);
}

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

@JS()
external CircleMarker circleMarker(LatLng latlng, PathOptions options);

@anonymous
@JS()
class Polygon {
  external factory Polygon();
  external Polygon addTo(LayerGroup layerGroup);
  external Polygon bindPopup(String text);
}

@JS()
external Polygon polygon(List<LatLng> latlngs, [PathOptions options]);

@JS()
external LeafletMap map(String id, [MapOptions options]);

@JS()
external LayerGroup layerGroup();

@anonymous
@JS()
class ControlLayersOptions {
  external factory ControlLayersOptions({bool collapsed: true});
}

@JS('control.layers')
external ControlLayers controlLayers([baseLayers, overlays,
  ControlLayersOptions options]);

@anonymous
@JS()
class ControlLayers {
  external factory ControlLayers();
  external addTo(LeafletMap map);
  external addBaseLayer(TileLayer layer, String name);
  external addOverlay(LayerGroup layer, String name);
}

@JS()
external LatLng latLng(num lat, num lng);
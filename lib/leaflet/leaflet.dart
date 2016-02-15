// Workaround for using 'L'
// https://github.com/dart-lang/sdk/issues/25318#issuecomment-167616022
@JS('Leaflet')
library L;

import 'package:js/js.dart';

// Can't add @anonymous and @JS(). It will crash compiler.
class ILayer {}

typedef void Callback(event);

@anonymous
@JS()
class Path {
  external factory Path();
  external Path addTo(LayerGroup layerGroup);
  external Path bindPopup(String text);
  external Path bringToBack();
  external Path on(String type, Callback callback);
}

@anonymous
@JS()
class Marker {
  external factory Marker();
  external Marker addTo(LayerGroup layerGroup);
  external Marker bindPopup(String text);
}

@anonymous
@JS()
class DivIcon {
  external factory DivIcon();
}

@anonymous
@JS()
class TileLayer implements ILayer {
  external factory TileLayer();
}

@anonymous
@JS()
class LatLng {
  external factory LatLng();
}

@anonymous
@JS()
class Point {
  external factory Point();
}

@anonymous
@JS()
class LayerGroup implements ILayer {
  external factory LayerGroup();
  external LayerGroup addLayer(Polygon polygon);
}

@JS()
@anonymous
class Map {
  external factory Map();
  external setView(LatLng center, int zoom);
}

@anonymous
@JS()
class CircleMarker extends Path {
  external factory CircleMarker();
}

@anonymous
@JS()
class Polygon extends Path {
  external factory Polygon();
}

@anonymous
@JS()
class Polyline extends Path {
  external factory Polyline();
}

@anonymous
@JS()
class ControlLayers {
  external factory ControlLayers();
  external addTo(Map map);
  external addBaseLayer(TileLayer layer, String name);
  external addOverlay(LayerGroup layer, String name);
}

@anonymous
@JS()
class ControlLayersOptions {
  external factory ControlLayersOptions({bool collapsed: true});
}

@anonymous
@JS()
class MapOptions {
  external factory MapOptions({
    List<TileLayer> layers,
    LatLng center,
    int zoom
  });
}

@anonymous
@JS()
class PathOptions {
  external factory PathOptions({String color, num fillOpacity});
}

@anonymous
@JS()
class MarkerOptions {
  external factory MarkerOptions({DivIcon icon});
}

@anonymous
@JS()
class DivIconOptions {
  external factory DivIconOptions({String className, String html, Point iconSize});
}

@anonymous
@JS()
class CircleMarkerPathOptions extends PathOptions {
  external factory CircleMarkerPathOptions({String color, num fillOpacity, num radius});
}

@JS()
external Map map(String id, [MapOptions options]);

@JS()
external TileLayer tileLayer(String urlTemplate);

@JS()
external CircleMarker circleMarker(LatLng latlng, CircleMarkerPathOptions options);

@JS()
external Marker marker(LatLng latlng, MarkerOptions options);

@JS()
external Polyline polyline(List<LatLng> latlngs, [PathOptions options]);

@JS()
external DivIcon divIcon([DivIconOptions options]);

@JS()
external Polygon polygon(List<LatLng> latlngs, [PathOptions options]);

@JS()
external LayerGroup layerGroup();

@JS('control.layers')
external ControlLayers controlLayers([baseLayers, overlays,
  ControlLayersOptions options]);

@JS()
external LatLng latLng(num lat, num lng);

@JS()
external Point point(num width, num height);
// Workaround for using 'L'
// https://github.com/dart-lang/sdk/issues/25318#issuecomment-167616022
@JS('Leaflet')
library L;

import 'package:js/js.dart';

// Can't add @anonymous and @JS(). It will crash compiler.
class ILayer {}

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

@anonymous
@JS()
class Polygon {
  external factory Polygon();
  external Polygon addTo(LayerGroup layerGroup);
  external Polygon bindPopup(String text);
}

@anonymous
@JS()
class ControlLayers {
  external factory ControlLayers();
  external addTo(LeafletMap map);
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
  external factory PathOptions({String color, String fillOpacity});
}

@JS()
external LeafletMap map(String id, [MapOptions options]);

@JS()
external TileLayer tileLayer(String urlTemplate);

@JS()
external CircleMarker circleMarker(LatLng latlng, PathOptions options);

@JS()
external Polygon polygon(List<LatLng> latlngs, [PathOptions options]);

@JS()
external LayerGroup layerGroup();

@JS('control.layers')
external ControlLayers controlLayers([baseLayers, overlays,
  ControlLayersOptions options]);

@JS()
external LatLng latLng(num lat, num lng);
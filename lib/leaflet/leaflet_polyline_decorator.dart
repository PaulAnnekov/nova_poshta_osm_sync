@JS('Leaflet')
part of L;

@anonymous
@JS()
class PolylineDecorator {
  external factory PolylineDecorator();
  external PolylineDecorator addTo(LayerGroup layerGroup);
}

@anonymous
@JS()
class SymbolArrowHead {
  external factory SymbolArrowHead();
}

@anonymous
@JS()
class SymbolArrowHeadOptions {
  external factory SymbolArrowHeadOptions({num pixelSize: 10, polygon: true, num headAngle: 60,
    PathOptions pathOptions});
}

@anonymous
@JS()
class Pattern {
  external factory Pattern({num repeat, String offset, SymbolArrowHead symbol});
}

@anonymous
@JS()
class PolylineDecoratorOptions {
  external factory PolylineDecoratorOptions({List<Pattern> patterns});
}

@JS()
external PolylineDecorator polylineDecorator(Polyline polyline, [PolylineDecoratorOptions options]);

@JS('Symbol.arrowHead')
external SymbolArrowHead arrowHead([SymbolArrowHeadOptions options]);
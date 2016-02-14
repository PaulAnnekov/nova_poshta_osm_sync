@JS('turf')
library turf;

import 'package:js/js.dart';

@anonymous
@JS()
class GeometryOptions {
  external factory GeometryOptions({String type, List<num> coordinates});
}

@anonymous
@JS()
class FeatureOptions {
  external factory FeatureOptions({String type, GeometryOptions geometry});
}

@anonymous
@JS()
class PolygonGeometryOptions {
  external factory PolygonGeometryOptions({String type, List<List<List<num>>> coordinates});
  external List<List<List<num>>> get coordinates;
}

@anonymous
@JS()
class PolygonOptions {
  external factory PolygonOptions({String type, PolygonGeometryOptions geometry});
  external PolygonGeometryOptions get geometry;
}

@anonymous
@JS()
class ConvexOptions {
  external factory ConvexOptions({String type, List<FeatureOptions> features});
}

@JS()
external PolygonOptions convex(ConvexOptions options);
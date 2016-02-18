// Workaround for using 'L'
// https://github.com/dart-lang/sdk/issues/25318#issuecomment-167616022
@JS('Leaflet')
library L;

import 'package:js/js.dart';

part 'leaflet_base.dart';
part 'leaflet_polyline_decorator.dart';
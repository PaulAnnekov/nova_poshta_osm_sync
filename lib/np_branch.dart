import 'package:nova_poshta_osm_sync/lat_lon.dart';
import 'package:nova_poshta_osm_sync/branch.dart';
import "package:nova_poshta_osm_sync/location_name.dart";
import 'package:logging/logging.dart';

final Logger log = new Logger('np_branch');

class NpBranch extends Branch {
  LocationName city;
  Match _parsedAddress;
  NpBranch(LatLon loc, Map customTags, this.city, int number) : super(loc, customTags, number);

  _parseAddress() {
    if (_parsedAddress != null)
      return;
    /**
     * Should match:
     * Відділення № 163 (до 10 кг), Міні-відділення: бульв. Лепсе, 29 (маг."Фора")
     * Відділення №7 (до 30 кг на одне місце): вул. Червоногвардійська, 8 (м.Чернігівська)
     * Відділення №1: вул. Леніна, 248/1
     * Відділення №1: вул. Жовтнева, 72а
     * Відділення: вул. Леніна,109
     * Відділення №4: (до 30 кг)проспект Миру 72/5 (ТЦ "Проспект")
     * Відділення №7: просп. Перемоги, 46-а
     */
    _parsedAddress = new RegExp(r"[\u0400-\u04FF.]+ ([\u0400-\u04FF -']+)[ ,]{1,2}([0-9][0-9-/\\\u0400-\u04FF]*)")
        .firstMatch(customTags['addr']);
    if (_parsedAddress == null) {
      throw new Exception("Can't get address for $this");
    }
  }

  Map<String, LocationName> getAddress() {
    _parseAddress();
    if (_parsedAddress == null)
      return null;
    return {
      "street": new LocationName(_parsedAddress.group(1)),
      "house": new LocationName(_parsedAddress.group(2))
    };
  }
}
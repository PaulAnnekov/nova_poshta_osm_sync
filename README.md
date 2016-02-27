Syncs Nova Poshta's branches from Nova Poshta's website to OSM.

Data preparation:
-----------------
Put Nova Poshta's markers to `data/npm.json`. Format:

```
[{
  "n": 1, // branch number in city
  "lon": 36.938391476870000,
  "lat": 50.295151744070000,
  "addr": "Відділення №1: вул. Дзержинського, 17",
  "city": "Вовчанськ"
},...]
```

Put OSM's markers to `data/osmm.json`. Format:                                      
```
{
 "elements": [{
   "type": "node",
   "id": 306635381,
   "lat": 48.4609747,
   "lon": 35.0581093,
   "tags": {
     "amenity": "post_office",
     "name": "Нова Пошта: Склад №32 (поштовий центр)",
     "operator": "Нова Пошта",
     ...
   }
 },...]
}  
```

You can get them from http://overpass-turbo.eu/ using:
```
[out:json];
(
  node["name"~"Нова Пошта"];
  node["name"~"Новая Почта"];
  node["operator"~"Новая Почта"];
  node["operator"~"Нова Пошта"];
);
out body;
```

Run `dart main.dart` to generate `data/locations_cache.json`.

Data analyze:
-------------
Run `pub serve web data` and open http://localhost:8080/ in browser to see results on map.

Edge cases:
-----------
- Group by cities
  - [x] Требухів и Дударків
  - [x] Бориспіль (Мартусівка)
  - [x] Лопатин
  - [x] Угринів (Івано-Франківськ)
  - [x] Ладижин (Вінницька область)
- Merges
  - [x] Днепропетровск (Отделение 9)
  - [x] Тростянець (Сумська область)
  - [x] Одеса (Відділення №1)
  - [x] Козелець (Чернігівська область)
  - [x] Тарасовка (Киевская область)
  - [x] Сумы (Отделение 3 НП 1 OSM)
      
TODO:
-----
- Add `fixme` tag for branches with doubtful location.
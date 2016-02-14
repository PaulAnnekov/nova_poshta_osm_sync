Syncs Nova Poshta's branches from Nova Poshta's website to OSM.

Data preparation:
-----------------
Put Nova Poshta's markers to `data/npm.json`. Format:

```
[{
  "n": "1", // branch number in city
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
);
out body;
```

Run `dart main.dart` to generate `data/locations_cache.json`.

Data analyze:
-------------
Run `pub serve web data` and open http://localhost:8080/ in browser to see results on map.

Edge cases:
-----------
- Требухів и Дударків
- Бориспіль (Мартусівка)
- Лопатин

TODO:
-----
- null біловодськийрайон луганськаобласть
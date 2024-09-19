# Postleitzahlen

This repository contains the shapes of german postcode areas (Postleitzahlengebiete) in compressed geojson and topojson format.

## Data

* [GeoJSON, Brotli Compressed](data/postleitzahlen.geojson.br) (18MB)
* [TopoJSON, Brotli Compressed](data/postleitzahlen.topojson.br) (11MB)

## Source

Extracted from [OpenStreetMap](http://www.openstreetmap.org/) via [Overpass](https://overpass-turbo.eu/)

Overpass Query:

```
[out:json];
area[wikidata="Q183"]->.searchArea;
(
	relation["type"="boundary"]["boundary"="postal_code"](area.searchArea);
);
out body geom;
```
## Alternatives

* [Postleitzahlen-Scraper](https://github.com/yetzt/postleitzahlen-scraper) - A program that downloads non-free postcode geometries from the german postal service.


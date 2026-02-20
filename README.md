# Postleitzahlen

This repository contains the shapes of german postcode areas (Postleitzahlengebiete) in compressed geojson and topojson format.

## Data

See [Releases](https://github.com/yetzt/postleitzahlen/releases)

## Source

Extracted from [OpenStreetMap](http://www.openstreetmap.org/) via [Overpass](https://overpass-turbo.eu/)

Overpass Query:

``` ql
area[wikidata="Q183"]->.searchArea;
(
	// Postcodes within Germany
	// captures some non-German postcodes due to incongruent boundaries in OSM
	relation["type"="boundary"]["boundary"="postal_code"](area.searchArea);

	// Explicit German postcodes (Jungholz, Kleinwalsertal)
	relation["type"="boundary"]["boundary"="postal_code"]["postal_code:DE"];

	// Special Case: Büsingen (not captured in searchArea)
	relation["type"="boundary"]["boundary"="postal_code"]["postal_code"="78266"];
);
out body geom;
```

## Importer

Included in this repository is the import script used to generate the data files: `sh bin/import.sh`

## Alternatives

* [Postleitzahlen-Scraper](https://github.com/yetzt/postleitzahlen-scraper) - A program that downloads non-free postcode geometries from the german postal service.

